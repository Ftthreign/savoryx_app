import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/daos/outbox_dao.dart';
import 'package:savoryx/core/security/device_credentials_storage.dart';
import 'package:savoryx/features/sync/data/models/sync_payload_models.dart';

/// Persistence contract for the incremental delta pull cursor (`last_pulled_at`).
abstract interface class SyncCursorStorage {
  Future<String?> readLastPulledAtIso();
  Future<void> saveLastPulledAtIso(String isoTimestamp);
}

/// Default [SyncCursorStorage] backed by [KeyValueSecureStore].
class SecureSyncCursorStorage implements SyncCursorStorage {
  SecureSyncCursorStorage({KeyValueSecureStore? store})
      : _store = store ?? FlutterSecureStorageAdapter();

  static const String keyLastPulledAt = 'savoryx_last_pulled_at';

  final KeyValueSecureStore _store;

  @override
  Future<String?> readLastPulledAtIso() => _store.read(key: keyLastPulledAt);

  @override
  Future<void> saveLastPulledAtIso(String isoTimestamp) {
    return _store.write(key: keyLastPulledAt, value: isoTimestamp.trim());
  }
}

/// Counts of entities modified locally during a delta pull merge transaction.
class SyncMergeStats {
  const SyncMergeStats({
    required this.accountsUpserted,
    required this.categoriesUpserted,
    required this.transactionsInserted,
    required this.transactionsTombstoned,
  });

  final int accountsUpserted;
  final int categoriesUpserted;
  final int transactionsInserted;
  final int transactionsTombstoned;
}

/// Applies pulled server deltas atomically to Drift SQLite using LWW and Append-Only rules.
class SyncLocalDataSource {
  SyncLocalDataSource({
    required AppDatabase database,
    required SyncCursorStorage cursorStorage,
  })  : _database = database,
        _cursorStorage = cursorStorage;

  static const String defaultEpochCursorIso = '1970-01-01T00:00:00Z';

  final AppDatabase _database;
  final SyncCursorStorage _cursorStorage;

  /// Returns stored `last_pulled_at` watermark or Unix epoch if never synced.
  Future<String> getLastPulledAtIso() async {
    final stored = await _cursorStorage.readLastPulledAtIso();
    if (stored == null || stored.trim().isEmpty) {
      return defaultEpochCursorIso;
    }
    return stored.trim();
  }

  /// Persists the server's `pulled_at` watermark after a successful merge.
  Future<void> saveLastPulledAtIso(String isoTimestamp) {
    return _cursorStorage.saveLastPulledAtIso(isoTimestamp);
  }

  /// Atomically merges remote accounts, categories, and transactions into SQLite.
  Future<SyncMergeStats> mergePullDelta(SyncPullResponseModel delta) {
    return _database.transaction(() async {
      final pendingOutbox = await _database.select(_database.localOutboxMutations).get();
      final pendingAccounts = <String>{};
      final pendingCategories = <String>{};
      final pendingTransactions = <String>{};

      for (final row in pendingOutbox) {
        switch (row.entityType) {
          case OutboxEntityType.account:
            pendingAccounts.add(row.entityId);
            break;
          case OutboxEntityType.category:
            pendingCategories.add(row.entityId);
            break;
          case OutboxEntityType.transaction:
            pendingTransactions.add(row.entityId);
            break;
        }
      }

      var accountsUpserted = 0;
      var categoriesUpserted = 0;
      var transactionsInserted = 0;
      var transactionsTombstoned = 0;

      // 1. Categories (Last-Write-Wins based on microsecond comparison)
      for (final remoteCat in delta.categories) {
        if (await _mergeCategory(remoteCat, pendingCategories)) {
          categoriesUpserted++;
        }
      }

      // 2. Accounts (Last-Write-Wins based on microsecond comparison)
      for (final remoteAcc in delta.accounts) {
        if (await _mergeAccount(remoteAcc, pendingAccounts)) {
          accountsUpserted++;
        }
      }

      // 3. Transactions (Append-Only Ledger + Tombstone soft-delete propagation)
      for (final remoteTx in delta.transactions) {
        final outcome = await _mergeTransaction(remoteTx, pendingTransactions);
        if (outcome == _TxMergeOutcome.inserted) {
          transactionsInserted++;
        } else if (outcome == _TxMergeOutcome.tombstoned) {
          transactionsTombstoned++;
        }
      }

      return SyncMergeStats(
        accountsUpserted: accountsUpserted,
        categoriesUpserted: categoriesUpserted,
        transactionsInserted: transactionsInserted,
        transactionsTombstoned: transactionsTombstoned,
      );
    });
  }

  Future<bool> _mergeCategory(
    SyncRemoteCategoryModel remote,
    Set<String> pendingCategories,
  ) async {
    final local = await (_database.select(_database.localCategories)
          ..where((t) => t.id.equals(remote.id)))
        .getSingleOrNull();

    if (local == null) {
      await _database.into(_database.localCategories).insert(
            LocalCategoriesCompanion.insert(
              id: remote.id,
              name: remote.name,
              icon: remote.icon,
              color: remote.color,
              isWants: Value(remote.isWants),
              createdAt: remote.createdAt,
              updatedAt: remote.updatedAt,
              deletedAt: Value(remote.deletedAt),
              isSynced: const Value(true),
            ),
          );
      return true;
    }

    if (pendingCategories.contains(remote.id)) {
      return false;
    }

    final remoteMicros = remote.updatedAt.toUtc().microsecondsSinceEpoch;
    final localMicros = local.updatedAt.toUtc().microsecondsSinceEpoch;
    if (remoteMicros <= localMicros) {
      return false;
    }

    await (_database.update(_database.localCategories)
          ..where((t) => t.id.equals(remote.id)))
        .write(
      LocalCategoriesCompanion(
        name: Value(remote.name),
        icon: Value(remote.icon),
        color: Value(remote.color),
        isWants: Value(remote.isWants),
        updatedAt: Value(remote.updatedAt),
        deletedAt: Value(remote.deletedAt),
        isSynced: const Value(true),
      ),
    );
    return true;
  }

  Future<bool> _mergeAccount(
    SyncRemoteAccountModel remote,
    Set<String> pendingAccounts,
  ) async {
    final local = await (_database.select(_database.localAccounts)
          ..where((t) => t.id.equals(remote.id)))
        .getSingleOrNull();

    if (local == null) {
      await _database.into(_database.localAccounts).insert(
            LocalAccountsCompanion.insert(
              id: remote.id,
              name: remote.name,
              type: remote.type,
              balance: Value(remote.balanceMinor),
              currency: Value(remote.currency),
              createdAt: remote.createdAt,
              updatedAt: remote.updatedAt,
              deletedAt: Value(remote.deletedAt),
              isSynced: const Value(true),
            ),
          );
      return true;
    }

    if (pendingAccounts.contains(remote.id)) {
      return false;
    }

    final remoteMicros = remote.updatedAt.toUtc().microsecondsSinceEpoch;
    final localMicros = local.updatedAt.toUtc().microsecondsSinceEpoch;
    if (remoteMicros <= localMicros) {
      return false;
    }

    await (_database.update(_database.localAccounts)
          ..where((t) => t.id.equals(remote.id)))
        .write(
      LocalAccountsCompanion(
        name: Value(remote.name),
        type: Value(remote.type),
        balance: Value(remote.balanceMinor),
        currency: Value(remote.currency),
        updatedAt: Value(remote.updatedAt),
        deletedAt: Value(remote.deletedAt),
        isSynced: const Value(true),
      ),
    );
    return true;
  }

  Future<_TxMergeOutcome> _mergeTransaction(
    SyncRemoteTransactionModel remote,
    Set<String> pendingTransactions,
  ) async {
    final local = await (_database.select(_database.localTransactions)
          ..where((t) => t.id.equals(remote.id)))
        .getSingleOrNull();

    if (local == null) {
      await _database.into(_database.localTransactions).insert(
            LocalTransactionsCompanion.insert(
              id: remote.id,
              accountId: remote.accountId,
              categoryId: Value(remote.categoryId),
              amount: remote.amountMinor,
              currency: Value(remote.currency),
              exchangeRateToBase: Value(remote.exchangeRateToBase),
              baseAmount: remote.baseAmountMinor,
              type: remote.type,
              transactionTime: remote.transactionDate,
              note: Value(remote.note),
              createdAt: remote.createdAt,
              updatedAt: remote.updatedAt,
              deletedAt: Value(remote.deletedAt),
              isSynced: const Value(true),
            ),
          );
      return _TxMergeOutcome.inserted;
    }

    // Append-Only Ledger: existing transactions only transition to soft-delete tombstone.
    if (local.deletedAt == null &&
        remote.deletedAt != null &&
        !pendingTransactions.contains(remote.id)) {
      await (_database.update(_database.localTransactions)
            ..where((t) => t.id.equals(remote.id)))
          .write(
        LocalTransactionsCompanion(
          deletedAt: Value(remote.deletedAt),
          updatedAt: Value(remote.updatedAt),
          isSynced: const Value(true),
        ),
      );
      return _TxMergeOutcome.tombstoned;
    }

    return _TxMergeOutcome.skipped;
  }
}

enum _TxMergeOutcome { inserted, tombstoned, skipped }
