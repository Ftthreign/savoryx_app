import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/daos/outbox_dao.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('OutboxDao & Atomic Mutation Queue Hooks Tests (Task #45)', () {
    late AppDatabase db;
    const uuid = Uuid();

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('enqueueMutation, FIFO ordering, watchPendingCount, and deleteMutations',
        () async {
      final counts = <int>[];
      final sub = db.outboxDao.watchPendingCount().listen(counts.add);
      await pumpEventQueue();
      expect(counts.last, equals(0));

      final baseTime = DateTime.utc(2026, 11, 10, 10, 0, 0);
      final id1 = uuid.v7();
      final id2 = uuid.v7();

      await db.outboxDao.enqueueMutation(
        LocalOutboxMutationsCompanion.insert(
          id: id2,
          entityType: OutboxEntityType.category,
          entityId: uuid.v7(),
          operation: OutboxOperation.create,
          payloadJson: '{"name":"Second"}',
          createdAt: baseTime.add(const Duration(seconds: 10)),
        ),
      );
      await db.outboxDao.enqueueMutation(
        LocalOutboxMutationsCompanion.insert(
          id: id1,
          entityType: OutboxEntityType.category,
          entityId: uuid.v7(),
          operation: OutboxOperation.create,
          payloadJson: '{"name":"First"}',
          createdAt: baseTime,
        ),
      );
      await pumpEventQueue();
      expect(counts.last, equals(2));

      final pending = await db.outboxDao.getPendingMutations(limit: 50);
      expect(pending.length, equals(2));
      expect(pending.first.id, equals(id1));
      expect(pending.last.id, equals(id2));

      await db.outboxDao.deleteMutations([id1]);
      await pumpEventQueue();
      expect(counts.last, equals(1));

      final remaining = await db.outboxDao.getPendingMutations();
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals(id2));

      await sub.cancel();
    });

    test('smart coalescing merges consecutive updates and preserves CREATE before first sync',
        () async {
      final accId = uuid.v7();
      final now = DateTime.utc(2026, 11, 10, 10, 0, 0);

      await db.accountDao.insertAccount(
        LocalAccountsCompanion.insert(
          id: accId,
          name: 'Tabungan Awal',
          type: 'BANK',
          balance: Value(BigInt.from(1000000)),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.accountDao.updateBalance(accId, BigInt.from(2500000));

      var queue = await db.outboxDao.getPendingMutations();
      expect(queue.length, equals(1));
      expect(queue.first.entityType, equals(OutboxEntityType.account));
      expect(queue.first.entityId, equals(accId));
      expect(queue.first.operation, equals(OutboxOperation.create));

      final decodedUpdate =
          jsonDecode(queue.first.payloadJson) as Map<String, dynamic>;
      expect(decodedUpdate['balance_minor'], equals('2500000'));

      // Soft delete updates operation to DELETE with deleted_at set
      await db.accountDao.softDeleteAccount(accId);
      queue = await db.outboxDao.getPendingMutations();
      expect(queue.length, equals(1));
      expect(queue.first.operation, equals(OutboxOperation.delete));
      final decodedDelete =
          jsonDecode(queue.first.payloadJson) as Map<String, dynamic>;
      expect(decodedDelete['deleted_at'], isNotNull);
    });

    test('incrementRetry atomically increments retryCount and records lastError',
        () async {
      final entryId = uuid.v7();
      await db.outboxDao.enqueueMutation(
        LocalOutboxMutationsCompanion.insert(
          id: entryId,
          entityType: OutboxEntityType.transaction,
          entityId: uuid.v7(),
          operation: OutboxOperation.create,
          payloadJson: '{}',
          createdAt: DateTime.now().toUtc(),
        ),
      );

      await db.outboxDao.incrementRetry(entryId, 'SocketTimeoutException');
      await db.outboxDao.incrementRetry(entryId, 'HTTP 503 Unavailable');

      final pending = await db.outboxDao.getPendingMutations();
      expect(pending.length, equals(1));
      expect(pending.first.retryCount, equals(2));
      expect(pending.first.lastError, equals('HTTP 503 Unavailable'));
    });

    test('CategoryDao mutations atomically enqueue outbox records', () async {
      final catId = uuid.v7();
      final now = DateTime.now().toUtc();

      await db.categoryDao.insertCategory(
        LocalCategoriesCompanion.insert(
          id: catId,
          name: 'Hobi Kopi',
          icon: 'coffee',
          color: '#8DB355',
          isWants: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.categoryDao.updateCategory(
        LocalCategoriesCompanion(
          id: Value(catId),
          name: const Value('Kopi Spesial'),
          updatedAt: Value(now.add(const Duration(seconds: 5))),
        ),
      );

      var pending = await db.outboxDao.getPendingMutations();
      expect(pending.length, equals(1));
      expect(pending.first.entityType, equals(OutboxEntityType.category));
      expect(pending.first.operation, equals(OutboxOperation.create));
      expect(
        (jsonDecode(pending.first.payloadJson) as Map<String, dynamic>)['name'],
        equals('Kopi Spesial'),
      );

      await db.categoryDao.softDeleteCategory(catId);
      pending = await db.outboxDao.getPendingMutations();
      expect(pending.length, equals(1));
      expect(pending.first.operation, equals(OutboxOperation.delete));
    });

    test(
        'TransactionDao atomic ledger hooks enqueue TRANSACTION + ACCOUNT updates and roll back on error',
        () async {
      final accounts = await db.accountDao.getAllActiveAccounts();
      final categories = await db.categoryDao.getAllActiveCategories();
      final targetAcc = accounts.first;
      final targetCat = categories.first;
      final now = DateTime.now().toUtc();

      // Failing ledger mutation for unknown account must roll back BOTH tx and outbox
      final failedTxId = uuid.v7();
      await expectLater(
        () => db.transactionDao.createTransactionWithBalanceAdjustment(
          transactionCompanion: LocalTransactionsCompanion.insert(
            id: failedTxId,
            accountId: 'non-existent-account',
            categoryId: Value(targetCat.id),
            amount: BigInt.from(50000),
            baseAmount: BigInt.from(50000),
            type: 'EXPENSE',
            transactionTime: now,
            createdAt: now,
            updatedAt: now,
          ),
          accountId: 'non-existent-account',
          balanceDelta: BigInt.from(-50000),
        ),
        throwsA(isA<StateError>()),
      );
      expect(await db.outboxDao.getPendingMutations(), isEmpty);

      // Valid atomic transaction enqueues TRANSACTION CREATE + ACCOUNT UPDATE
      final validTxId = uuid.v7();
      await db.transactionDao.createTransactionWithBalanceAdjustment(
        transactionCompanion: LocalTransactionsCompanion.insert(
          id: validTxId,
          accountId: targetAcc.id,
          categoryId: Value(targetCat.id),
          amount: BigInt.from(75000),
          baseAmount: BigInt.from(75000),
          type: 'EXPENSE',
          transactionTime: now,
          note: const Value('Makan Siang'),
          createdAt: now,
          updatedAt: now,
        ),
        accountId: targetAcc.id,
        balanceDelta: BigInt.from(-75000),
      );

      var pending = await db.outboxDao.getPendingMutations();
      expect(pending.length, equals(2));
      expect(
        pending.map((m) => '${m.entityType}:${m.operation}').toSet(),
        equals({'TRANSACTION:CREATE', 'ACCOUNT:UPDATE'}),
      );

      final txOutbox = pending
          .firstWhere((m) => m.entityType == OutboxEntityType.transaction);
      final txPayload =
          jsonDecode(txOutbox.payloadJson) as Map<String, dynamic>;
      expect(txPayload['amount_minor'], equals('75000'));
      expect(txPayload['note'], equals('Makan Siang'));

      // Soft delete transaction with balance reversal updates outbox entries atomically
      await db.transactionDao.softDeleteTransactionWithBalanceReversal(
        transactionId: validTxId,
        accountId: targetAcc.id,
        balanceReversalDelta: BigInt.from(75000),
      );

      pending = await db.outboxDao.getPendingMutations();
      expect(pending.length, equals(2));
      expect(
        pending.map((m) => '${m.entityType}:${m.operation}').toSet(),
        equals({'TRANSACTION:DELETE', 'ACCOUNT:UPDATE'}),
      );
      final accOutbox =
          pending.firstWhere((m) => m.entityType == OutboxEntityType.account);
      final accPayload =
          jsonDecode(accOutbox.payloadJson) as Map<String, dynamic>;
      expect(accPayload['balance_minor'], equals('0'));
    });
  });
}
