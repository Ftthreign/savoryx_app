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

  Stream<List<LocalTransaction>> watchTransactionsByAccount(String accountId) {
    return (select(localTransactions)
          ..where((t) => t.deletedAt.isNull() & t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionTime)]))
        .watch();
  }

  Future<LocalTransaction?> getTransactionById(String id) {
    return (select(localTransactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertTransaction(LocalTransactionsCompanion companion) {
    return into(localTransactions).insert(companion);
  }

  Future<void> createTransactionWithBalanceAdjustment({
    required LocalTransactionsCompanion transactionCompanion,
    required String accountId,
    required BigInt balanceDelta,
  }) {
    return transaction(() async {
      await into(localTransactions).insert(transactionCompanion);

      final account = await (select(localAccounts)
            ..where((t) => t.id.equals(accountId)))
          .getSingleOrNull();
      if (account == null) {
        throw StateError('Cannot adjust balance: account $accountId not found');
      }

      final newBalance = account.balance + balanceDelta;

      await (update(localAccounts)..where((t) => t.id.equals(accountId))).write(
        LocalAccountsCompanion(
          balance: Value(newBalance),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );
    });
  }

  Future<void> softDeleteTransactionWithBalanceReversal({
    required String transactionId,
    required String accountId,
    required BigInt balanceReversalDelta,
  }) {
    return transaction(() async {
      final now = DateTime.now().toUtc();

      await (update(localTransactions)
            ..where((t) => t.id.equals(transactionId)))
          .write(
        LocalTransactionsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );

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

  Future<List<LocalTransaction>> getPendingSyncTransactions() {
    return (select(localTransactions)
          ..where((t) => t.isSynced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
        .get();
  }

  Future<int> markTransactionsAsSynced(List<String> ids) {
    if (ids.isEmpty) return Future.value(0);
    return (update(localTransactions)..where((t) => t.id.isIn(ids))).write(
      const LocalTransactionsCompanion(
        isSynced: Value(true),
      ),
    );
  }

  Future<int> reconcileRemoteTombstones(List<String> deletedIds) {
    if (deletedIds.isEmpty) return Future.value(0);
    final now = DateTime.now().toUtc();
    return (update(localTransactions)..where((t) => t.id.isIn(deletedIds)))
        .write(
      LocalTransactionsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(true),
      ),
    );
  }
}
