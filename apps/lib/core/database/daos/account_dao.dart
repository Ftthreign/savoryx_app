import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/daos/outbox_dao.dart';
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

  /// Inserts a new local account record and atomically enqueues an outbox mutation.
  Future<int> insertAccount(LocalAccountsCompanion companion) {
    return transaction<int>(() async {
      final rowId = await into(localAccounts).insert(companion);
      final inserted = await getAccountById(companion.id.value);
      if (inserted != null && !inserted.isSynced) {
        await db.outboxDao.enqueueAccountMutation(
          account: inserted,
          operation: OutboxOperation.create,
        );
      }
      return rowId;
    });
  }

  /// Updates an existing local account metadata and atomically enqueues an outbox mutation.
  Future<int> updateAccount(LocalAccountsCompanion companion) {
    return transaction<int>(() async {
      final targetId = companion.id.value;
      final effective = companion.copyWith(isSynced: const Value(false));
      final updatedCount = await (update(localAccounts)
            ..where((t) => t.id.equals(targetId)))
          .write(effective);
      if (updatedCount > 0) {
        final updated = await getAccountById(targetId);
        if (updated != null) {
          await db.outboxDao.enqueueAccountMutation(
            account: updated,
            operation: OutboxOperation.update,
          );
        }
      }
      return updatedCount;
    });
  }

  /// Updates the running balance of an account in minor units and atomically enqueues an outbox mutation.
  Future<int> updateBalance(String id, BigInt newBalance) {
    return transaction<int>(() async {
      final updatedCount =
          await (update(localAccounts)..where((t) => t.id.equals(id))).write(
        LocalAccountsCompanion(
          balance: Value(newBalance),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );
      if (updatedCount > 0) {
        final updated = await getAccountById(id);
        if (updated != null) {
          await db.outboxDao.enqueueAccountMutation(
            account: updated,
            operation: OutboxOperation.update,
          );
        }
      }
      return updatedCount;
    });
  }

  /// Soft deletes an account using the tombstone pattern and atomically enqueues an outbox mutation.
  Future<int> softDeleteAccount(String id) {
    return transaction<int>(() async {
      final now = DateTime.now().toUtc();
      final updatedCount =
          await (update(localAccounts)..where((t) => t.id.equals(id))).write(
        LocalAccountsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );
      if (updatedCount > 0) {
        final deleted = await getAccountById(id);
        if (deleted != null) {
          await db.outboxDao.enqueueAccountMutation(
            account: deleted,
            operation: OutboxOperation.delete,
          );
        }
      }
      return updatedCount;
    });
  }
}
