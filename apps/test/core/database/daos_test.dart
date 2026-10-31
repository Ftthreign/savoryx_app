import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Reactive DAOs & Atomic Ledger Tests (Task #15)', () {
    late AppDatabase database;
    const uuid = Uuid();

    setUp(() {
      // In-memory database with onCreate lifecycle triggering seedDefaultData
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    group('AccountDao Tests', () {
      test('watchAllActiveAccounts emits stream and updates reactively', () async {
        final dao = database.accountDao;

        // Expect initial stream emission (4 default seeded accounts)
        final initialAccounts = await dao.watchAllActiveAccounts().first;
        expect(initialAccounts.length, equals(4));

        // Insert a 5th account
        final now = DateTime.now().toUtc();
        final newAccountId = uuid.v7();
        await dao.insertAccount(
          LocalAccountsCompanion.insert(
            id: newAccountId,
            name: 'Celengan Koin',
            type: 'CASH',
            balance: Value(BigInt.from(5000000)), // Rp 50.000,00
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Verify account retrieved by ID
        final retrieved = await dao.getAccountById(newAccountId);
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Celengan Koin'));
        expect(retrieved.balance, equals(BigInt.from(5000000)));

        // Update balance
        await dao.updateBalance(newAccountId, BigInt.from(7500000));
        final afterUpdate = await dao.getAccountById(newAccountId);
        expect(afterUpdate!.balance, equals(BigInt.from(7500000)));

        // Soft delete removes from active list
        await dao.softDeleteAccount(newAccountId);
        final activeAccounts = await dao.getAllActiveAccounts();
        expect(activeAccounts.any((a) => a.id == newAccountId), isFalse);

        // But raw get by ID confirms tombstone
        final tombstoned = await dao.getAccountById(newAccountId);
        expect(tombstoned!.deletedAt, isNotNull);
      });
    });

    group('CategoryDao Tests', () {
      test('watchCategoriesByBudget filters Needs vs Wants reactively', () async {
        final dao = database.categoryDao;

        // 4 Needs categories seeded by default
        final needs = await dao.watchCategoriesByBudget(isWants: false).first;
        expect(needs.length, equals(4));
        expect(needs.every((c) => !c.isWants), isTrue);

        // 4 Wants categories seeded by default
        final wants = await dao.watchCategoriesByBudget(isWants: true).first;
        expect(wants.length, equals(4));
        expect(wants.every((c) => c.isWants), isTrue);

        // Soft delete a category
        final targetCategory = wants.first;
        await dao.softDeleteCategory(targetCategory.id);

        final updatedWants = await dao.watchCategoriesByBudget(isWants: true).first;
        expect(updatedWants.length, equals(3));
        expect(updatedWants.any((c) => c.id == targetCategory.id), isFalse);
      });
    });

    group('TransactionDao Atomic Ledger Tests', () {
      test('createTransactionWithBalanceAdjustment executes atomically', () async {
        final txDao = database.transactionDao;
        final accDao = database.accountDao;
        final catDao = database.categoryDao;

        // Get an active account and category
        final accounts = await accDao.getAllActiveAccounts();
        final targetAccount = accounts.firstWhere((a) => a.name == 'Kas Tunai');
        final categories = await catDao.getAllActiveCategories();
        final targetCategory = categories.firstWhere((c) => c.name == 'Makan Pokok');

        expect(targetAccount.balance, equals(BigInt.zero));

        final now = DateTime.now().toUtc();
        final txId = uuid.v7();
        final expenseAmount = BigInt.from(3500000); // Rp 35.000,00

        // Execute atomic transaction: Expense of Rp 35.000 (delta: -3500000)
        await txDao.createTransactionWithBalanceAdjustment(
          transactionCompanion: LocalTransactionsCompanion.insert(
            id: txId,
            accountId: targetAccount.id,
            categoryId: Value(targetCategory.id),
            amount: expenseAmount,
            baseAmount: expenseAmount,
            type: 'EXPENSE',
            transactionTime: now,
            note: const Value('Nasi Padang Siang'),
            createdAt: now,
            updatedAt: now,
          ),
          accountId: targetAccount.id,
          balanceDelta: -expenseAmount,
        );

        // Verify transaction inserted
        final insertedTx = await txDao.getTransactionById(txId);
        expect(insertedTx, isNotNull);
        expect(insertedTx!.amount, equals(expenseAmount));
        expect(insertedTx.note, equals('Nasi Padang Siang'));

        // Verify account balance updated atomically
        final updatedAccount = await accDao.getAccountById(targetAccount.id);
        expect(updatedAccount!.balance, equals(-expenseAmount));

        // Verify recent transactions stream emits the new transaction
        final recentTxs = await txDao.watchRecentTransactions().first;
        expect(recentTxs.any((t) => t.id == txId), isTrue);

        // Test Soft Delete with Balance Reversal
        await txDao.softDeleteTransactionWithBalanceReversal(
          transactionId: txId,
          accountId: targetAccount.id,
          balanceReversalDelta: expenseAmount, // Reversing the expense
        );

        // Transaction should no longer be in active stream
        final recentAfterDelete = await txDao.watchRecentTransactions().first;
        expect(recentAfterDelete.any((t) => t.id == txId), isFalse);

        // Account balance should be restored to zero
        final restoredAccount = await accDao.getAccountById(targetAccount.id);
        expect(restoredAccount!.balance, equals(BigInt.zero));
      });

      test('createTransactionWithBalanceAdjustment rolls back cleanly on error', () async {
        final txDao = database.transactionDao;
        final now = DateTime.now().toUtc();
        final txId = uuid.v7();
        final nonExistentAccountId = uuid.v7();

        // Attempt to create transaction for non-existent account
        expect(
          () => txDao.createTransactionWithBalanceAdjustment(
            transactionCompanion: LocalTransactionsCompanion.insert(
              id: txId,
              accountId: nonExistentAccountId,
              amount: BigInt.from(1000000),
              baseAmount: BigInt.from(1000000),
              type: 'EXPENSE',
              transactionTime: now,
              createdAt: now,
              updatedAt: now,
            ),
            accountId: nonExistentAccountId,
            balanceDelta: BigInt.from(-1000000),
          ),
          throwsA(isA<StateError>()),
        );

        // Verify transaction was rolled back and NOT persisted
        final failedTx = await txDao.getTransactionById(txId);
        expect(failedTx, isNull);
      });
    });
  });
}
