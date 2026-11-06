import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<AccountEntity>> getActiveAccounts() async {
    final rows = await _db.accountDao.getAllActiveAccounts();
    return rows.map(_mapToEntity).toList(growable: false);
  }

  @override
  Stream<List<AccountEntity>> watchActiveAccounts() {
    return _db.accountDao
        .watchAllActiveAccounts()
        .map((rows) => rows.map(_mapToEntity).toList(growable: false));
  }

  @override
  Future<AccountEntity?> getAccountById(String id) async {
    final row = await _db.accountDao.getAccountById(id);
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<void> createAccount(AccountEntity account) async {
    await _db.accountDao.insertAccount(
      LocalAccountsCompanion.insert(
        id: account.id,
        name: account.name,
        type: account.type.toDbString(),
        balance: Value(BigInt.from(account.balance)),
        currency: Value(account.currency),
        createdAt: account.createdAt,
        updatedAt: account.updatedAt,
        deletedAt: Value(account.deletedAt),
        isSynced: const Value(false),
      ),
    );
  }

  @override
  Future<void> updateAccount(AccountEntity account) async {
    await _db.accountDao.updateAccount(
      LocalAccountsCompanion(
        id: Value(account.id),
        name: Value(account.name),
        type: Value(account.type.toDbString()),
        currency: Value(account.currency),
        balance: Value(BigInt.from(account.balance)),
        updatedAt: Value(DateTime.now().toUtc()),
        deletedAt: Value(account.deletedAt),
        isSynced: const Value(false),
      ),
    );
  }

  @override
  Future<void> updateBalance(String id, BigInt newBalance) async {
    await _db.accountDao.updateBalance(id, newBalance);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _db.accountDao.softDeleteAccount(id);
  }

  AccountEntity _mapToEntity(LocalAccount row) {
    return AccountEntity(
      id: row.id,
      name: row.name,
      type: AccountType.fromString(row.type),
      currency: row.currency,
      balance: row.balance.toInt(),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
