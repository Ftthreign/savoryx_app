import 'package:injectable/injectable.dart';
import 'package:savoryx/features/transaction/domain/repositories/transaction_repository.dart';

@lazySingleton
class DeleteTransactionUseCase {
  final TransactionRepository _repository;

  const DeleteTransactionUseCase(this._repository);

  Future<void> call(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Transaction ID cannot be empty');
    }
    return _repository.deleteTransaction(id);
  }
}
