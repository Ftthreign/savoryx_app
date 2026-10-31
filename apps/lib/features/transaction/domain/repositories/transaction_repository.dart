import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

abstract interface class TransactionRepository {
  Future<void> createTransaction(TransactionEntity transaction);

  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 50});

  Future<void> deleteTransaction(String id);

  Future<TransactionEntity?> getTransactionById(String id);
}
