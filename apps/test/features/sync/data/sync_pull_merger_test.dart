import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:savoryx/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:savoryx/features/sync/data/models/sync_payload_models.dart';
import 'package:savoryx/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:savoryx/features/sync/domain/usecases/pull_delta_usecase.dart';
import 'package:uuid/uuid.dart';

class _InMemoryCursorStorage implements SyncCursorStorage {
  String? cursor;

  @override
  Future<String?> readLastPulledAtIso() async => cursor;

  @override
  Future<void> saveLastPulledAtIso(String isoTimestamp) async {
    cursor = isoTimestamp;
  }
}

class _FakePullRemoteDataSource implements SyncRemoteDataSource {
  _FakePullRemoteDataSource({required this.onPull});

  final Future<SyncPullResponseModel> Function(String sinceIso) onPull;

  @override
  Future<SyncPushResponseModel> pushBatch(SyncPushRequestModel request) {
    throw UnimplementedError();
  }

  @override
  Future<SyncPullResponseModel> pullDelta(String lastPulledAtIso) {
    return onPull(lastPulledAtIso);
  }
}

void main() {
  group('SyncLocalDataSource & PullDeltaUseCase (Task #50)', () {
    late AppDatabase db;
    late _InMemoryCursorStorage cursorStorage;
    late SyncLocalDataSource localDataSource;
    const uuid = Uuid();

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      cursorStorage = _InMemoryCursorStorage();
      localDataSource = SyncLocalDataSource(
        database: db,
        cursorStorage: cursorStorage,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'initial pull uses Unix epoch, inserts delta atomically without re-enqueuing outbox, and saves server cursor',
        () async {
      final accId = uuid.v7();
      final catId = uuid.v7();
      final txId = uuid.v7();
      final t1 = DateTime.utc(2026, 11, 10, 6, 0, 0);
      final serverTime = DateTime.utc(2026, 11, 10, 6, 5, 1, 234567);

      String? capturedSince;
      final remote = _FakePullRemoteDataSource(
        onPull: (sinceIso) async {
          capturedSince = sinceIso;
          return SyncPullResponseModel.fromJson(<String, dynamic>{
            'data': <String, dynamic>{
              'accounts': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': accId,
                  'name': 'Remote BCA',
                  'type': 'BANK',
                  'currency': 'IDR',
                  'balance': '1500000.00',
                  'created_at': t1.toIso8601String(),
                  'updated_at': t1.toIso8601String(),
                },
              ],
              'categories': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': catId,
                  'name': 'Remote Food',
                  'icon': 'utensils',
                  'color': '#8DB355',
                  'is_wants': false,
                  'created_at': t1.toIso8601String(),
                  'updated_at': t1.toIso8601String(),
                },
              ],
              'transactions': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': txId,
                  'account_id': accId,
                  'category_id': catId,
                  'type': 'EXPENSE',
                  'amount': '150000.00',
                  'currency': 'IDR',
                  'exchange_rate_to_base': '1.000000',
                  'base_amount': '150000.00',
                  'note': 'Dinner Synced',
                  'transaction_date': t1.toIso8601String(),
                  'created_at': t1.toIso8601String(),
                  'updated_at': t1.toIso8601String(),
                },
              ],
              'pulled_at': serverTime.toIso8601String(),
              'server_time': serverTime.toIso8601String(),
            },
          });
        },
      );

      final repo = SyncRepositoryImpl(
        pushService: SyncPushService(database: db, remoteDataSource: remote),
        remoteDataSource: remote,
        localDataSource: localDataSource,
      );
      final pullUseCase = PullDeltaUseCase(repo);

      final summary = await pullUseCase();

      expect(capturedSince, equals('1970-01-01T00:00:00Z'));
      expect(summary.accountsUpserted, equals(1));
      expect(summary.categoriesUpserted, equals(1));
      expect(summary.transactionsInserted, equals(1));
      expect(summary.transactionsTombstoned, equals(0));
      expect(
        cursorStorage.cursor,
        equals(serverTime.toUtc().toIso8601String()),
      );

      final acc = await db.accountDao.getAccountById(accId);
      expect(acc, isNotNull);
      expect(acc!.balance, equals(BigInt.from(150000000)));
      expect(acc.isSynced, isTrue);

      final tx = await db.transactionDao.getTransactionById(txId);
      expect(tx, isNotNull);
      expect(tx!.amount, equals(BigInt.from(15000000)));
      expect(tx.isSynced, isTrue);

      // Must NOT echo remote pulled rows back into outbox queue
      expect(await db.outboxDao.getPendingMutations(), isEmpty);
    });

    test(
        'enforces LWW on accounts & categories and protects pending unsynced local mutations',
        () async {
      final staleAccId = uuid.v7();
      final pendingAccId = uuid.v7();
      final catId = uuid.v7();

      final tLocalNewer = DateTime.utc(2026, 11, 10, 10, 0, 10);
      final tRemoteOlder = DateTime.utc(2026, 11, 10, 10, 0, 5);
      final tLocalOlder = DateTime.utc(2026, 11, 10, 10, 0, 0);
      final tRemoteNewer = DateTime.utc(2026, 11, 10, 10, 5, 0);

      // Seed already-synced local account with newer updated_at
      await db.into(db.localAccounts).insert(
            LocalAccountsCompanion.insert(
              id: staleAccId,
              name: 'Local Newer Name',
              type: 'BANK',
              balance: Value(BigInt.from(900000)),
              createdAt: tLocalNewer,
              updatedAt: tLocalNewer,
              isSynced: const Value(true),
            ),
          );

      // Seed local pending offline mutation via AccountDao (adds outbox entry)
      await db.accountDao.insertAccount(
        LocalAccountsCompanion.insert(
          id: pendingAccId,
          name: 'Local Unpushed Edit',
          type: 'CASH',
          balance: Value(BigInt.from(200000)),
          createdAt: tLocalOlder,
          updatedAt: tLocalOlder,
        ),
      );

      // Seed synced local category with older timestamp
      await db.into(db.localCategories).insert(
            LocalCategoriesCompanion.insert(
              id: catId,
              name: 'Old Category',
              icon: 'tag',
              color: '#000000',
              createdAt: tLocalOlder,
              updatedAt: tLocalOlder,
              isSynced: const Value(true),
            ),
          );

      final delta = SyncPullResponseModel(
        accounts: <SyncRemoteAccountModel>[
          SyncRemoteAccountModel(
            id: staleAccId,
            name: 'Stale Remote Name',
            type: 'BANK',
            currency: 'IDR',
            balanceMinor: BigInt.from(100),
            createdAt: tRemoteOlder,
            updatedAt: tRemoteOlder,
          ),
          SyncRemoteAccountModel(
            id: pendingAccId,
            name: 'Remote Clobber Attempt',
            type: 'CASH',
            currency: 'IDR',
            balanceMinor: BigInt.from(100),
            createdAt: tRemoteNewer,
            updatedAt: tRemoteNewer,
          ),
        ],
        categories: <SyncRemoteCategoryModel>[
          SyncRemoteCategoryModel(
            id: catId,
            name: 'Archived Remote Category',
            icon: 'archive',
            color: '#D90000',
            isWants: true,
            createdAt: tLocalOlder,
            updatedAt: tRemoteNewer,
            deletedAt: tRemoteNewer,
          ),
        ],
        transactions: const <SyncRemoteTransactionModel>[],
        pulledAt: tRemoteNewer,
      );

      final stats = await localDataSource.mergePullDelta(delta);
      expect(stats.accountsUpserted, equals(0));
      expect(stats.categoriesUpserted, equals(1));

      expect(
        (await db.accountDao.getAccountById(staleAccId))!.name,
        equals('Local Newer Name'),
      );
      expect(
        (await db.accountDao.getAccountById(pendingAccId))!.name,
        equals('Local Unpushed Edit'),
      );

      final updatedCat = await db.categoryDao.getCategoryById(catId);
      expect(updatedCat!.name, equals('Archived Remote Category'));
      expect(updatedCat.deletedAt, isNotNull);
      expect(updatedCat.isSynced, isTrue);
    });

    test(
        'enforces append-only ledger idempotency and propagates remote transaction tombstones',
        () async {
      final accId = uuid.v7();
      final txId = uuid.v7();
      final t1 = DateTime.utc(2026, 11, 10, 9, 0, 0);
      final tDelete = DateTime.utc(2026, 11, 10, 9, 10, 0);

      await db.into(db.localAccounts).insert(
            LocalAccountsCompanion.insert(
              id: accId,
              name: 'Vault',
              type: 'BANK',
              balance: Value(BigInt.from(5000000)),
              createdAt: t1,
              updatedAt: t1,
              isSynced: const Value(true),
            ),
          );
      await db.into(db.localTransactions).insert(
            LocalTransactionsCompanion.insert(
              id: txId,
              accountId: accId,
              amount: BigInt.from(7500000),
              baseAmount: BigInt.from(7500000),
              type: 'EXPENSE',
              transactionTime: t1,
              note: const Value('Original Note'),
              createdAt: t1,
              updatedAt: t1,
              isSynced: const Value(true),
            ),
          );

      // Step 1: Mutated duplicate without tombstone must be skipped (append-only)
      final dupStats = await localDataSource.mergePullDelta(
        SyncPullResponseModel(
          accounts: const <SyncRemoteAccountModel>[],
          categories: const <SyncRemoteCategoryModel>[],
          transactions: <SyncRemoteTransactionModel>[
            SyncRemoteTransactionModel(
              id: txId,
              accountId: accId,
              type: 'EXPENSE',
              amountMinor: BigInt.from(99999900),
              currency: 'IDR',
              exchangeRateToBase: BigInt.from(1000000),
              baseAmountMinor: BigInt.from(99999900),
              note: 'Tampered Note',
              transactionDate: t1,
              createdAt: t1,
              updatedAt: tDelete,
            ),
          ],
          pulledAt: tDelete,
        ),
      );
      expect(dupStats.transactionsInserted, equals(0));
      expect(dupStats.transactionsTombstoned, equals(0));

      var localTx = await db.transactionDao.getTransactionById(txId);
      expect(localTx!.amount, equals(BigInt.from(7500000)));
      expect(localTx.note, equals('Original Note'));
      expect(localTx.deletedAt, isNull);

      // Step 2: Remote tombstone propagates deletedAt locally
      final tombStats = await localDataSource.mergePullDelta(
        SyncPullResponseModel(
          accounts: const <SyncRemoteAccountModel>[],
          categories: const <SyncRemoteCategoryModel>[],
          transactions: <SyncRemoteTransactionModel>[
            SyncRemoteTransactionModel(
              id: txId,
              accountId: accId,
              type: 'EXPENSE',
              amountMinor: BigInt.from(7500000),
              currency: 'IDR',
              exchangeRateToBase: BigInt.from(1000000),
              baseAmountMinor: BigInt.from(7500000),
              transactionDate: t1,
              createdAt: t1,
              updatedAt: tDelete,
              deletedAt: tDelete,
            ),
          ],
          pulledAt: tDelete,
        ),
      );
      expect(tombStats.transactionsTombstoned, equals(1));

      localTx = await db.transactionDao.getTransactionById(txId);
      expect(localTx!.deletedAt, isNotNull);
      expect(localTx.isSynced, isTrue);
    });

    test('does not advance last_pulled_at cursor when pull fails', () async {
      cursorStorage.cursor = '2026-11-10T05:00:00Z';
      final failingRemote = _FakePullRemoteDataSource(
        onPull: (_) async => throw Exception('Network offline'),
      );

      final repo = SyncRepositoryImpl(
        pushService:
            SyncPushService(database: db, remoteDataSource: failingRemote),
        remoteDataSource: failingRemote,
        localDataSource: localDataSource,
      );

      await expectLater(() => repo.pullDelta(), throwsException);
      expect(cursorStorage.cursor, equals('2026-11-10T05:00:00Z'));
    });
  });
}
