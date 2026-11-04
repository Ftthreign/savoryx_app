import 'package:injectable/injectable.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';

@lazySingleton
class GetAccountByIdUseCase {
  final AccountRepository _repository;

  const GetAccountByIdUseCase(this._repository);

  Future<AccountEntity?> call(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Account ID cannot be empty');
    }
    return _repository.getAccountById(id);
  }
}
