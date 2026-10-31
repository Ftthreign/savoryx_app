import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/tables/accounts_table.dart';
import 'package:savoryx/core/database/tables/categories_table.dart';
import 'package:savoryx/core/database/tables/transactions_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [LocalTransactions, LocalAccounts, LocalCategories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// Emits a continuous, reactive stream of recent transactions ordered by event time descending.
  Stream<List<LocalTransaction>> watchRecentTransactions({int limit = 50}) {
    return (select(localTransactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.transactionTime)])
          ..limit(limit))
        .watch();
  }

  /// Emits a continuous stream of transactions belonging to a specific account.
  Stream<List<LocalTransaction>> watchTransactionsByAccount(String accountId) {
    return (select(localTransactions)
          ..where((t) => t.deletedAt.isNull() & t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionTime)]))
        .watch();
  }

  /// Finds a transaction record by its unique UUID string.
  Future<LocalTransaction?> getTransactionById(String id) {
    return (select(localTransactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Atomically inserts a transaction record and adjusts the associated account balance.
  /// Guarantees that neither record is updated without the other (zero desync).
  Future<void> createTransactionWithBalanceAdjustment({
    required LocalTransactionsCompanion transactionCompanion,
    required String accountId,
    required BigInt balanceDelta,
  }) {
    return transaction(() async {
      // 1. Insert transaction into append-only ledger
      await into(localTransactions).insert(transactionCompanion);

      // 2. Fetch target account for balance adjustment
      final account = await (select(localAccounts)
            ..where((t) => t.id.equals(accountId)))
          .getSingleOrNull();
      if (account == null) {
        throw StateError('Cannot adjust balance: account $accountId not found');
      }

      // 3. Calculate new balance using deterministic integer math
      final newBalance = account.balance + balanceDelta;

      // 4. Update account balance with tombstone-safe query
      await (update(localAccounts)..where((t) => t.id.equals(accountId))).write(
        LocalAccountsCompanion(
          balance: Value(newBalance),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );
    });
  }

  /// Atomically soft-deletes a transaction and reverses its balance effect on the account.
  Future<void> softDeleteTransactionWithBalanceReversal({
    required String transactionId,
    required String accountId,
    required BigInt balanceReversalDelta,
  }) {
    return transaction(() async {
      final now = DateTime.now().toUtc();

      // 1. Mark transaction as soft-deleted
      await (update(localTransactions)
            ..where((t) => t.id.equals(transactionId)))
          .write(
        LocalTransactionsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );

      // 2. Reverse balance impact on the account
      final account = await (select(localAccounts)
            ..where((t) => t.id.equals(accountId)))
          .getSingleOrNull();
      if (account != null) {
        final newBalance = account.balance + balanceReversalDelta;
        await (update(localAccounts)..where((t) => t.id.equals(accountId)))
            .write(
          LocalAccountsCompanion(
            balance: Value(newBalance),
            updatedAt: Value(now),
            isSynced: const Value(false),
          ),
        );
      }
    });
  }
}
