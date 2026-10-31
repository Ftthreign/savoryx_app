import 'package:injectable/injectable.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/transaction_repository.dart';

@lazySingleton
class WatchRecentTransactionsUseCase {
  final TransactionRepository _repository;

  const WatchRecentTransactionsUseCase(this._repository);

  Stream<List<TransactionEntity>> call({int limit = 50}) {
    return _repository.watchRecentTransactions(limit: limit);
  }
}
