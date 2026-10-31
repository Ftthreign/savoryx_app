import 'package:injectable/injectable.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/transaction_repository.dart';

@lazySingleton
class CreateTransactionUseCase {
  final TransactionRepository _repository;

  const CreateTransactionUseCase(this._repository);

  Future<void> call(TransactionEntity transaction) async {
    if (transaction.amount <= 0) {
      throw ArgumentError(
          'Transaction amount must be strictly greater than zero minor units');
    }
    if (transaction.accountId.trim().isEmpty) {
      throw ArgumentError('Account ID cannot be empty');
    }
    return _repository.createTransaction(transaction);
  }
}
