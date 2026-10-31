import 'package:injectable/injectable.dart';
import 'package:savoryx/features/transaction/data/datasources/transaction_local_datasource.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/transaction_repository.dart';

/// Concrete implementation of TransactionRepository interfacing with local SQLite datasource.
@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource _localDataSource;

  TransactionRepositoryImpl(this._localDataSource);

  @override
  Future<void> createTransaction(TransactionEntity transaction) {
    return _localDataSource.createTransaction(transaction);
  }

  @override
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 50}) {
    return _localDataSource.watchRecentTransactions(limit: limit);
  }

  @override
  Future<void> deleteTransaction(String id) {
    return _localDataSource.deleteTransaction(id);
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) {
    return _localDataSource.getTransactionById(id);
  }
}
