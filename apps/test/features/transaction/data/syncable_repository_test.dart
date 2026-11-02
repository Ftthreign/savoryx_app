import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/features/transaction/data/datasources/transaction_local_datasource.dart';
import 'package:savoryx/features/transaction/data/repositories/syncable_repository_impl.dart';
import 'package:savoryx/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/syncable_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('TransactionSyncableRepository ISP & Tombstone Tests (Task #156)', () {
    late AppDatabase db;
    late TransactionLocalDataSource localDataSource;
    late TransactionSyncableRepository syncRepository;
    late TransactionRepositoryImpl txRepositoryImpl;
    const uuid = Uuid();

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      localDataSource = TransactionLocalDataSourceImpl(db);
      syncRepository = TransactionSyncableRepositoryImpl(localDataSource);
      txRepositoryImpl = TransactionRepositoryImpl(localDataSource);
    });

    tearDown(() async {
      await db.close();
    });

    test('getPendingSyncRecords returns records with isSynced = false',
        () async {
      final now = DateTime.now().toUtc();
      final tx1Id = uuid.v7();
      final tx2Id = uuid.v7();

      // Seed 2 transactions (one unsynced, one synced)
      await db.transactionDao.insertTransaction(
        LocalTransactionsCompanion.insert(
          id: tx1Id,
          accountId: 'dummy-acc-1',
          categoryId: const Value('dummy-cat-1'),
          amount: BigInt.from(5000000),
          currency: const Value('IDR'),
          exchangeRateToBase: Value(BigInt.from(1000000)),
          baseAmount: BigInt.from(5000000),
          type: 'EXPENSE',
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
          isSynced: const Value(false),
        ),
      );

      await db.transactionDao.insertTransaction(
        LocalTransactionsCompanion.insert(
          id: tx2Id,
          accountId: 'dummy-acc-1',
          categoryId: const Value('dummy-cat-1'),
          amount: BigInt.from(2500000),
          currency: const Value('IDR'),
          exchangeRateToBase: Value(BigInt.from(1000000)),
          baseAmount: BigInt.from(2500000),
          type: 'EXPENSE',
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
          isSynced: const Value(true),
        ),
      );

      final pending = await syncRepository.getPendingSyncRecords();
      expect(pending.length, equals(1));
      expect(pending.first.id, equals(tx1Id));
      expect(pending.first.isSynced, isFalse);

      // Verify TransactionRepositoryImpl also satisfies the contract
      final pendingViaImpl = await txRepositoryImpl.getPendingSyncRecords();
      expect(pendingViaImpl.length, equals(1));
      expect(pendingViaImpl.first.id, equals(tx1Id));
    });

    test('markAsSynced updates isSynced flag to true for acknowledged IDs',
        () async {
      final now = DateTime.now().toUtc();
      final txId = uuid.v7();

      await db.transactionDao.insertTransaction(
        LocalTransactionsCompanion.insert(
          id: txId,
          accountId: 'dummy-acc-1',
          categoryId: const Value('dummy-cat-1'),
          amount: BigInt.from(10000000),
          currency: const Value('IDR'),
          exchangeRateToBase: Value(BigInt.from(1000000)),
          baseAmount: BigInt.from(10000000),
          type: 'EXPENSE',
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
          isSynced: const Value(false),
        ),
      );

      // Verify pending
      expect((await syncRepository.getPendingSyncRecords()).length, equals(1));

      // Acknowledge sync
      await syncRepository.markAsSynced([txId]);

      // Verify no longer pending
      final pendingAfter = await syncRepository.getPendingSyncRecords();
      expect(pendingAfter, isEmpty);

      // Verify raw database row has isSynced = true
      final record = await db.transactionDao.getTransactionById(txId);
      expect(record!.isSynced, isTrue);
    });

    test(
        'reconcileRemoteTombstones marks local matching records as deleted and synced',
        () async {
      final now = DateTime.now().toUtc();
      final txId = uuid.v7();

      await db.transactionDao.insertTransaction(
        LocalTransactionsCompanion.insert(
          id: txId,
          accountId: 'dummy-acc-1',
          categoryId: const Value('dummy-cat-1'),
          amount: BigInt.from(3000000),
          currency: const Value('IDR'),
          exchangeRateToBase: Value(BigInt.from(1000000)),
          baseAmount: BigInt.from(3000000),
          type: 'EXPENSE',
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
          isSynced: const Value(false),
        ),
      );

      // Remote server indicates txId has been deleted on another client
      await syncRepository.reconcileRemoteTombstones([txId]);

      final record = await db.transactionDao.getTransactionById(txId);
      expect(record, isNotNull);
      expect(record!.deletedAt, isNotNull);
      expect(record.isSynced, isTrue);
    });

    test(
        'soft delete locally flags record as isSynced = false for sync engine propagation',
        () async {
      final now = DateTime.now().toUtc();
      final txId = uuid.v7();
      final accountId = uuid.v7();

      // Seed account
      await db.accountDao.insertAccount(
        LocalAccountsCompanion.insert(
          id: accountId,
          name: 'Kas',
          type: 'CASH',
          balance: Value(BigInt.from(50000000)),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Create transaction via CRUD
      final tx = TransactionEntity(
        id: txId,
        accountId: accountId,
        categoryId: 'cat-1',
        amount: 10000,
        type: TransactionType.expense,
        note: 'Beli kopi',
        transactionDate: now,
        isSynced: true,
        createdAt: now,
        updatedAt: now,
      );
      await txRepositoryImpl.createTransaction(tx);

      // Mark synced initially
      await syncRepository.markAsSynced([txId]);
      expect(await syncRepository.getPendingSyncRecords(), isEmpty);

      // Delete locally
      await txRepositoryImpl.deleteTransaction(txId);

      // The tombstone record must now appear in pending sync to be propagated to server!
      final pendingAfterDelete = await syncRepository.getPendingSyncRecords();
      expect(pendingAfterDelete.length, equals(1));
      expect(pendingAfterDelete.first.id, equals(txId));
      expect(pendingAfterDelete.first.deletedAt, isNotNull);
      expect(pendingAfterDelete.first.isSynced, isFalse);
    });
  });
}
