import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/error/exceptions.dart';
import 'package:savoryx/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:savoryx/features/sync/data/models/sync_payload_models.dart';
import 'package:savoryx/features/sync/domain/usecases/push_mutations_usecase.dart';
import 'package:uuid/uuid.dart';

class _FakeSyncRemoteDataSource implements SyncRemoteDataSource {
  _FakeSyncRemoteDataSource({required this.onPush});

  final Future<SyncPushResponseModel> Function(SyncPushRequestModel request)
      onPush;

  @override
  Future<SyncPushResponseModel> pushBatch(SyncPushRequestModel request) {
    return onPush(request);
  }
}

void main() {
  group('FixedPointDecimalCodec (Zero-Floating-Point)', () {
    test('formats and parses BigInt minor units without floating-point errors',
        () {
      expect(
        FixedPointDecimalCodec.formatCurrencyMinorUnits(
          BigInt.from(15000000),
          currency: 'IDR',
        ),
        equals('150000.00'),
      );
      expect(
        FixedPointDecimalCodec.formatCurrencyMinorUnits(
          BigInt.from(5),
          currency: 'USD',
        ),
        equals('0.05'),
      );
      expect(
        FixedPointDecimalCodec.formatCurrencyMinorUnits(
          BigInt.from(-3500050),
          currency: 'IDR',
        ),
        equals('-35000.50'),
      );
      expect(
        FixedPointDecimalCodec.formatCurrencyMinorUnits(
          BigInt.from(1200),
          currency: 'JPY',
        ),
        equals('1200'),
      );
      expect(
        FixedPointDecimalCodec.formatMinorUnits(
          BigInt.from(1000000),
          decimalDigits: 6,
        ),
        equals('1.000000'),
      );

      expect(
        FixedPointDecimalCodec.parseCurrencyToMinorUnits(
          '150000.00',
          currency: 'IDR',
        ),
        equals(BigInt.from(15000000)),
      );
      expect(
        FixedPointDecimalCodec.parseCurrencyToMinorUnits(
          '-35000.50',
          currency: 'USD',
        ),
        equals(BigInt.from(-3500050)),
      );
    });
  });

  group('SyncPushService & PushMutationsUseCase (Task #49)', () {
    late AppDatabase db;
    const uuid = Uuid();

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns zero summary immediately when outbox queue is empty',
        () async {
      var remoteCalled = false;
      final service = SyncPushService(
        database: db,
        remoteDataSource: _FakeSyncRemoteDataSource(
          onPush: (_) async {
            remoteCalled = true;
            return SyncPushResponseModel(
              accountsApplied: 0,
              categoriesApplied: 0,
              transactionsApplied: 0,
              syncedAt: DateTime.now().toUtc(),
            );
          },
        ),
      );
      final useCase = PushMutationsUseCase(service);

      final result = await useCase();
      expect(result.pushedMutationsCount, equals(0));
      expect(remoteCalled, isFalse);
    });

    test(
        'uploads outbox batch, formats decimals cleanly, clears outbox, and marks entities isSynced=true',
        () async {
      final now = DateTime.now().toUtc();
      final accId = uuid.v7();
      final catId = uuid.v7();
      final txId = uuid.v7();

      await db.categoryDao.insertCategory(
        LocalCategoriesCompanion.insert(
          id: catId,
          name: 'Kopi',
          icon: 'coffee',
          color: '#8DB355',
          isWants: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.accountDao.insertAccount(
        LocalAccountsCompanion.insert(
          id: accId,
          name: 'Dompet Sync',
          type: 'E_WALLET',
          balance: Value(BigInt.from(50000000)),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.transactionDao.createTransactionWithBalanceAdjustment(
        transactionCompanion: LocalTransactionsCompanion.insert(
          id: txId,
          accountId: accId,
          categoryId: Value(catId),
          amount: BigInt.from(15000000),
          baseAmount: BigInt.from(15000000),
          type: 'EXPENSE',
          transactionTime: now,
          note: const Value('Kopi Susu'),
          createdAt: now,
          updatedAt: now.add(const Duration(seconds: 1)),
        ),
        accountId: accId,
        balanceDelta: BigInt.from(-15000000),
      );

      late SyncPushRequestModel capturedRequest;
      final service = SyncPushService(
        database: db,
        remoteDataSource: _FakeSyncRemoteDataSource(
          onPush: (req) async {
            capturedRequest = req;
            return SyncPushResponseModel(
              accountsApplied: req.accounts.length,
              categoriesApplied: req.categories.length,
              transactionsApplied: req.transactions.length,
              syncedAt: DateTime.utc(2026, 11, 10, 7, 0, 0),
            );
          },
        ),
      );

      final useCase = PushMutationsUseCase(service);
      final result = await useCase(batchLimit: 50);

      expect(result.pushedMutationsCount, equals(3));
      expect(result.accountsApplied, equals(1));
      expect(result.categoriesApplied, equals(1));
      expect(result.transactionsApplied, equals(1));

      expect(capturedRequest.accounts.single.balance, equals('350000.00'));
      expect(capturedRequest.transactions.single.amount, equals('150000.00'));
      expect(
        capturedRequest.transactions.single.exchangeRateToBase,
        equals('1.000000'),
      );

      // Outbox cleared & local entities marked isSynced = true
      expect(await db.outboxDao.getPendingMutations(), isEmpty);
      expect((await db.accountDao.getAccountById(accId))!.isSynced, isTrue);
      expect((await db.categoryDao.getCategoryById(catId))!.isSynced, isTrue);
      expect(
        (await db.transactionDao.getTransactionById(txId))!.isSynced,
        isTrue,
      );
    });

    test('caps single batch at 50 mutations and leaves remaining queued',
        () async {
      final base = DateTime.utc(2026, 11, 10, 8, 0, 0);
      for (var i = 0; i < 55; i++) {
        await db.categoryDao.insertCategory(
          LocalCategoriesCompanion.insert(
            id: uuid.v7(),
            name: 'Cat $i',
            icon: 'tag',
            color: '#8DB355',
            createdAt: base.add(Duration(seconds: i)),
            updatedAt: base.add(Duration(seconds: i)),
          ),
        );
      }

      final service = SyncPushService(
        database: db,
        remoteDataSource: _FakeSyncRemoteDataSource(
          onPush: (req) async => SyncPushResponseModel(
            accountsApplied: 0,
            categoriesApplied: req.categories.length,
            transactionsApplied: 0,
            syncedAt: DateTime.now().toUtc(),
          ),
        ),
      );

      final firstBatch = await service.pushPendingMutations(batchLimit: 50);
      expect(firstBatch.pushedMutationsCount, equals(50));
      expect((await db.outboxDao.getPendingMutations(limit: 100)).length, equals(5));
    });

    test('applies exponential backoff with jitter on transient 503 and succeeds on retry',
        () async {
      final now = DateTime.now().toUtc();
      final catId = uuid.v7();
      await db.categoryDao.insertCategory(
        LocalCategoriesCompanion.insert(
          id: catId,
          name: 'Retry Cat',
          icon: 'refresh',
          color: '#FFEA93',
          createdAt: now,
          updatedAt: now,
        ),
      );

      var attempts = 0;
      final recordedDelays = <Duration>[];

      final service = SyncPushService(
        database: db,
        baseRetryDelay: const Duration(milliseconds: 100),
        maxJitterMs: 50,
        random: Random(42),
        delayFn: (d) async => recordedDelays.add(d),
        remoteDataSource: _FakeSyncRemoteDataSource(
          onPush: (req) async {
            attempts++;
            if (attempts < 3) {
              throw DioException(
                requestOptions: RequestOptions(path: '/api/v1/sync/push'),
                response: Response<dynamic>(
                  requestOptions: RequestOptions(path: '/api/v1/sync/push'),
                  statusCode: 503,
                ),
                type: DioExceptionType.badResponse,
              );
            }
            return SyncPushResponseModel(
              accountsApplied: 0,
              categoriesApplied: req.categories.length,
              transactionsApplied: 0,
              syncedAt: DateTime.now().toUtc(),
            );
          },
        ),
      );

      final result = await service.pushPendingMutations();
      expect(attempts, equals(3));
      expect(result.categoriesApplied, equals(1));
      expect(recordedDelays.length, equals(2));
      // Attempt 0: 100ms + [0..50]ms; Attempt 1: 200ms + [0..50]ms
      expect(recordedDelays[0].inMilliseconds, inInclusiveRange(100, 150));
      expect(recordedDelays[1].inMilliseconds, inInclusiveRange(200, 250));
      expect(await db.outboxDao.getPendingMutations(), isEmpty);
    });

    test('increments retryCount and preserves outbox rows on permanent failure',
        () async {
      final now = DateTime.now().toUtc();
      final catId = uuid.v7();
      await db.categoryDao.insertCategory(
        LocalCategoriesCompanion.insert(
          id: catId,
          name: 'Bad Payload',
          icon: 'alert',
          color: '#D90000',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final service = SyncPushService(
        database: db,
        maxRetries: 2,
        delayFn: (_) async {},
        remoteDataSource: _FakeSyncRemoteDataSource(
          onPush: (_) async {
            throw DioException(
              requestOptions: RequestOptions(path: '/api/v1/sync/push'),
              response: Response<dynamic>(
                requestOptions: RequestOptions(path: '/api/v1/sync/push'),
                statusCode: 400,
                data: <String, dynamic>{
                  'error': <String, dynamic>{'code': 'validation_error'},
                },
              ),
              type: DioExceptionType.badResponse,
            );
          },
        ),
      );

      await expectLater(
        () => service.pushPendingMutations(),
        throwsA(isA<ServerException>()),
      );

      final pending = await db.outboxDao.getPendingMutations();
      expect(pending.length, equals(1));
      expect(pending.single.retryCount, equals(1));
      expect(pending.single.lastError, equals('HTTP 400 (validation_error)'));
      expect((await db.categoryDao.getCategoryById(catId))!.isSynced, isFalse);
    });
  });
}
