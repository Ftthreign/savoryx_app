import 'package:injectable/injectable.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';

@lazySingleton
class CreateAccountUseCase {
  final AccountRepository _repository;

  const CreateAccountUseCase(this._repository);

  Future<void> call(AccountEntity account) {
    if (account.id.trim().isEmpty) {
      throw ArgumentError('Account ID cannot be empty');
    }
    if (account.name.trim().isEmpty) {
      throw ArgumentError('Account name cannot be empty');
    }
    return _repository.createAccount(account);
  }
}
