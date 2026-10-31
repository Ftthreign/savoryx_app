import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/tables/accounts_table.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [LocalAccounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  /// Emits a continuous, reactive stream of all active accounts ordered by name.
  Stream<List<LocalAccount>> watchAllActiveAccounts() {
    return (select(localAccounts)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Alias for watchAllActiveAccounts.
  Stream<List<LocalAccount>> watchAllAccounts() => watchAllActiveAccounts();

  /// Retrieves a snapshot of all active accounts ordered by name.
  Future<List<LocalAccount>> getAllActiveAccounts() {
    return (select(localAccounts)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Finds an active or tombstoned account by its unique UUID string.
  Future<LocalAccount?> getAccountById(String id) {
    return (select(localAccounts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts a new local account record.
  Future<int> insertAccount(LocalAccountsCompanion companion) {
    return into(localAccounts).insert(companion);
  }

  /// Updates an existing local account metadata.
  Future<int> updateAccount(LocalAccountsCompanion companion) {
    return (update(localAccounts)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
  }

  /// Updates the running balance of an account in minor units.
  Future<int> updateBalance(String id, BigInt newBalance) {
    return (update(localAccounts)..where((t) => t.id.equals(id))).write(
      LocalAccountsCompanion(
        balance: Value(newBalance),
        updatedAt: Value(DateTime.now().toUtc()),
        isSynced: const Value(false),
      ),
    );
  }

  /// Soft deletes an account using the tombstone pattern.
  Future<int> softDeleteAccount(String id) {
    final now = DateTime.now().toUtc();
    return (update(localAccounts)..where((t) => t.id.equals(id))).write(
      LocalAccountsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(false),
      ),
    );
  }
}
