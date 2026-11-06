import 'package:injectable/injectable.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';

@lazySingleton
class WatchAccountsUseCase {
  final AccountRepository _repository;

  const WatchAccountsUseCase(this._repository);

  Stream<List<AccountEntity>> call() => _repository.watchActiveAccounts();
}
