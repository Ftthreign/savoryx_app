import 'package:savoryx/features/account/domain/entities/account_entity.dart';

abstract interface class AccountRepository {
  Future<List<AccountEntity>> getActiveAccounts();

  Stream<List<AccountEntity>> watchActiveAccounts();

  Future<AccountEntity?> getAccountById(String id);

  Future<void> createAccount(AccountEntity account);

  Future<void> updateAccount(AccountEntity account);

  Future<void> updateBalance(String id, BigInt newBalance);

  Future<void> deleteAccount(String id);
}
