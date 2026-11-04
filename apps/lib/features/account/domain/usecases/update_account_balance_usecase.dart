import 'package:injectable/injectable.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';

@lazySingleton
class UpdateAccountBalanceUseCase {
  final AccountRepository _repository;

  const UpdateAccountBalanceUseCase(this._repository);

  Future<void> call(String id, BigInt newBalance) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Account ID cannot be empty');
    }
    return _repository.updateBalance(id, newBalance);
  }
}
