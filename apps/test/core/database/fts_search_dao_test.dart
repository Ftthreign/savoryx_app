import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/daos/fts_search_dao.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('FtsSearchDao & SQLite FTS5 Trigger Sync Engine Tests (Task #29)', () {
    late AppDatabase database;
    late FtsSearchDao ftsDao;
    const uuid = Uuid();

    late String testAccountId;
    late String testCategoryId;

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      ftsDao = database.ftsSearchDao;

      // Seed account and category for foreign key references
      final now = DateTime.now().toUtc();
      testAccountId = uuid.v7();
      testCategoryId = uuid.v7();

      await database.accountDao.insertAccount(
        LocalAccountsCompanion.insert(
          id: testAccountId,
          name: 'Checking Account',
          type: 'BANK',
          balance: Value(BigInt.from(100000000)),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.categoryDao.insertCategory(
        LocalCategoriesCompanion.insert(
          id: testCategoryId,
          name: 'Food & Drink',
          icon: 'utensils',
          color: '#8DB355',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      await database.close();
    });

    group('FTS5 Query Sanitization Tests', () {
      test('sanitizes simple keywords and multi-word phrases safely', () {
        expect(FtsSearchDao.sanitizeQuery('kopi'), equals('"kopi"*'));
        expect(
            FtsSearchDao.sanitizeQuery('kopi susu'), equals('"kopi"* "susu"*'));
      });

      test(
          'strips special symbols, punctuation, and quotes that break FTS5 parser',
          () {
        expect(FtsSearchDao.sanitizeQuery('#coffee!'), equals('"coffee"*'));
        expect(FtsSearchDao.sanitizeQuery('Starbucks: "latte"'),
            equals('"Starbucks"* "latte"*'));
        expect(FtsSearchDao.sanitizeQuery('50% discount (promo)'),
            equals('"50"* "discount"* "promo"*'));
      });

      test('handles empty and whitespace strings gracefully', () {
        expect(FtsSearchDao.sanitizeQuery(''), equals(''));
        expect(FtsSearchDao.sanitizeQuery('   '), equals(''));
        expect(FtsSearchDao.sanitizeQuery('!@#\$%^&*()'), equals(''));
      });
    });

    group('Trigger Sync Lifecycle (Insert, Update, Delete)', () {
      test(
          'Insert Trigger: Inserting into local_transactions auto-indexes into transactions_fts',
          () async {
        final now = DateTime.now().toUtc();
        final txId = uuid.v7();

        await database.transactionDao.insertTransaction(
          LocalTransactionsCompanion.insert(
            id: txId,
            accountId: testAccountId,
            categoryId: Value(testCategoryId),
            amount: BigInt.from(3500000), // Rp 35.000,00
            type: 'EXPENSE',
            transactionTime: now,
            note: const Value('Ngopi pagi di Starbucks Senopati #coffee'),
            baseAmount: BigInt.from(3500000),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Verify FTS search by merchant name
        final merchantResults = await ftsDao.searchTransactions('Starbucks');
        expect(merchantResults.length, equals(1));
        expect(merchantResults.first.id, equals(txId));

        // Verify FTS search by hashtag
        final tagResults = await ftsDao.searchTransactions('#coffee');
        expect(tagResults.length, equals(1));
        expect(tagResults.first.id, equals(txId));

        // Verify FTS search by prefix
        final prefixResults = await ftsDao.searchTransactions('Seno');
        expect(prefixResults.length, equals(1));
        expect(prefixResults.first.id, equals(txId));
      });

      test('Update Trigger: Modifying transaction note auto-updates FTS index',
          () async {
        final now = DateTime.now().toUtc();
        final txId = uuid.v7();

        await database.transactionDao.insertTransaction(
          LocalTransactionsCompanion.insert(
            id: txId,
            accountId: testAccountId,
            categoryId: Value(testCategoryId),
            amount: BigInt.from(5000000),
            type: 'EXPENSE',
            transactionTime: now,
            note: const Value('Makan siang Nasi Padang Sederhana'),
            baseAmount: BigInt.from(5000000),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Before update: matches Padang
        var results = await ftsDao.searchTransactions('Padang');
        expect(results.length, equals(1));

        // Update note to Japanese Bento
        await (database.update(database.localTransactions)
              ..where((t) => t.id.equals(txId)))
            .write(
          LocalTransactionsCompanion(
            note: const Value('Makan siang HokBen Bento Special'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );

        // Old term returns 0
        final oldResults = await ftsDao.searchTransactions('Padang');
        expect(oldResults, isEmpty);

        // New term matches updated record
        final newResults = await ftsDao.searchTransactions('HokBen');
        expect(newResults.length, equals(1));
        expect(newResults.first.id, equals(txId));
      });

      test(
          'Soft Delete Isolation: Soft deleted transactions are excluded from search',
          () async {
        final now = DateTime.now().toUtc();
        final txId = uuid.v7();

        await database.transactionDao.insertTransaction(
          LocalTransactionsCompanion.insert(
            id: txId,
            accountId: testAccountId,
            categoryId: Value(testCategoryId),
            amount: BigInt.from(2500000),
            type: 'EXPENSE',
            transactionTime: now,
            note: const Value('Langganan Netflix Premium'),
            baseAmount: BigInt.from(2500000),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Active: found
        var results = await ftsDao.searchTransactions('Netflix');
        expect(results.length, equals(1));

        // Soft delete (tombstone)
        await (database.update(database.localTransactions)
              ..where((t) => t.id.equals(txId)))
            .write(
          LocalTransactionsCompanion(
            deletedAt: Value(DateTime.now().toUtc()),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );

        // Excluded from search
        results = await ftsDao.searchTransactions('Netflix');
        expect(results, isEmpty);
      });

      test(
          'Hard Delete Trigger: Hard deletion from table cleans up FTS virtual table',
          () async {
        final now = DateTime.now().toUtc();
        final txId = uuid.v7();

        await database.transactionDao.insertTransaction(
          LocalTransactionsCompanion.insert(
            id: txId,
            accountId: testAccountId,
            categoryId: Value(testCategoryId),
            amount: BigInt.from(1200000),
            type: 'EXPENSE',
            transactionTime: now,
            note: const Value('Beli pulsa Indosat'),
            baseAmount: BigInt.from(1200000),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Verify exists in FTS virtual table directly
        final rawFtsBefore = await database.customSelect(
          'SELECT COUNT(*) AS c FROM transactions_fts WHERE id = ?',
          variables: [Variable.withString(txId)],
        ).getSingle();
        expect(rawFtsBefore.read<int>('c'), equals(1));

        // Hard delete from local_transactions
        await (database.delete(database.localTransactions)
              ..where((t) => t.id.equals(txId)))
            .go();

        // Verify trigger removed row from transactions_fts
        final rawFtsAfter = await database.customSelect(
          'SELECT COUNT(*) AS c FROM transactions_fts WHERE id = ?',
          variables: [Variable.withString(txId)],
        ).getSingle();
        expect(rawFtsAfter.read<int>('c'), equals(0));
      });
    });

    group('BM25 Ranking & Reactive Stream Tests', () {
      test('searchWithRank returns results ordered by BM25 relevance score',
          () async {
        final now = DateTime.now().toUtc();

        // Insert two transactions with different keyword frequencies
        await database.transactionDao.insertTransaction(
          LocalTransactionsCompanion.insert(
            id: uuid.v7(),
            accountId: testAccountId,
            amount: BigInt.from(1000000),
            type: 'EXPENSE',
            transactionTime: now,
            note: const Value('Beli susu segar di supermarket'),
            baseAmount: BigInt.from(1000000),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await database.transactionDao.insertTransaction(
          LocalTransactionsCompanion.insert(
            id: uuid.v7(),
            accountId: testAccountId,
            amount: BigInt.from(2000000),
            type: 'EXPENSE',
            transactionTime: now,
            note: const Value('Kopi susu gula aren susu murni ekstra susu'),
            baseAmount: BigInt.from(2000000),
            createdAt: now,
            updatedAt: now,
          ),
        );

        final results = await ftsDao.searchWithRank('susu');
        expect(results.length, equals(2));
        // In BM25, lower/more negative score indicates higher term relevance
        expect(results.first.transaction.note, contains('Kopi susu gula aren'));
      });

      test(
          'watchSearchTransactions emits updated list when new matching record is added',
          () async {
        final stream = ftsDao.watchSearchTransactions('Spotify');

        final expectation = expectLater(
          stream,
          emitsInOrder([
            isEmpty, // Initially no matches
            hasLength(1), // After inserting matching transaction
          ]),
        );

        // Allow initial stream listener to register
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final now = DateTime.now().toUtc();
        await database.transactionDao.insertTransaction(
          LocalTransactionsCompanion.insert(
            id: uuid.v7(),
            accountId: testAccountId,
            amount: BigInt.from(5499000),
            type: 'EXPENSE',
            transactionTime: now,
            note: const Value('Langganan bulanan Spotify Duo'),
            baseAmount: BigInt.from(5499000),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await expectation;
      });

      test('Sub-10ms query execution speed verification', () async {
        final now = DateTime.now().toUtc();

        // Seed 100 sample transactions
        for (var i = 0; i < 100; i++) {
          await database.transactionDao.insertTransaction(
            LocalTransactionsCompanion.insert(
              id: uuid.v7(),
              accountId: testAccountId,
              amount: BigInt.from((i + 1) * 100000),
              type: 'EXPENSE',
              transactionTime: now,
              note: Value('Transaksi nomor $i ke merchant Superindo #belanja'),
              baseAmount: BigInt.from((i + 1) * 100000),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }

        // Measure execution latency
        final stopwatch = Stopwatch()..start();
        final results = await ftsDao.searchTransactions('Superindo');
        stopwatch.stop();

        expect(results.length, equals(50)); // Default limit
        // Query must execute in sub-10ms (< 10,000 microseconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });
  });
}
