import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

abstract interface class TransactionLocalDataSource {
  Future<void> createTransaction(TransactionEntity transaction);
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 50});
  Future<void> deleteTransaction(String id);
  Future<TransactionEntity?> getTransactionById(String id);
}

@LazySingleton(as: TransactionLocalDataSource)
class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final AppDatabase _db;

  TransactionLocalDataSourceImpl(this._db);

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {
    final delta = transaction.type == TransactionType.income
        ? BigInt.from(transaction.amount)
        : -BigInt.from(transaction.amount);

    final companion = LocalTransactionsCompanion(
      id: Value(transaction.id),
      accountId: Value(transaction.accountId),
      categoryId: Value(transaction.categoryId),
      amount: Value(BigInt.from(transaction.amount)),
      currency: const Value('IDR'),
      exchangeRateToBase: Value(BigInt.from(1000000)),
      baseAmount: Value(BigInt.from(transaction.amount)),
      type: Value(transaction.type.toDbString()),
      transactionTime: Value(transaction.transactionDate),
      note: Value(transaction.note.isEmpty ? null : transaction.note),
      createdAt: Value(transaction.createdAt),
      updatedAt: Value(transaction.updatedAt),
      deletedAt: Value(transaction.deletedAt),
      isSynced: Value(transaction.isSynced),
    );

    await _db.transactionDao.createTransactionWithBalanceAdjustment(
      transactionCompanion: companion,
      accountId: transaction.accountId,
      balanceDelta: delta,
    );
  }

  @override
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 50}) {
    return _db.transactionDao
        .watchRecentTransactions(limit: limit)
        .map((records) => records.map(_mapToEntity).toList());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final existing = await _db.transactionDao.getTransactionById(id);
    if (existing == null) {
      throw StateError('Cannot delete: Transaction with ID $id not found');
    }

    final reversalDelta =
        existing.type == 'INCOME' ? -existing.amount : existing.amount;

    await _db.transactionDao.softDeleteTransactionWithBalanceReversal(
      transactionId: id,
      accountId: existing.accountId,
      balanceReversalDelta: reversalDelta,
    );
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    final record = await _db.transactionDao.getTransactionById(id);
    return record != null ? _mapToEntity(record) : null;
  }

  TransactionEntity _mapToEntity(LocalTransaction tx) {
    return TransactionEntity(
      id: tx.id,
      accountId: tx.accountId,
      categoryId: tx.categoryId,
      amount:
          tx.amount.isValidInt ? tx.amount.toInt() : tx.amount.abs().toInt(),
      type: TransactionType.fromString(tx.type),
      note: tx.note ?? '',
      transactionDate: tx.transactionTime,
      isSynced: tx.isSynced,
      createdAt: tx.createdAt,
      updatedAt: tx.updatedAt,
      deletedAt: tx.deletedAt,
    );
  }
}
