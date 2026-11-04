import 'package:injectable/injectable.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';

@lazySingleton
class GetAccountsUseCase {
  final AccountRepository _repository;

  const GetAccountsUseCase(this._repository);

  Future<List<AccountEntity>> call() => _repository.getActiveAccounts();
}
