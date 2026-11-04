import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/features/account/data/repositories/account_repository_impl.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';

void main() {
  group('AccountRepositoryImpl Integration Tests', () {
    late AppDatabase database;
    late AccountRepositoryImpl repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = AccountRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('getActiveAccounts returns seeded accounts', () async {
      final accounts = await repository.getActiveAccounts();
      // AppDatabase seeds 4 initial default accounts
      expect(accounts.length, equals(4));
    });

    test('createAccount, getAccountById, and watchActiveAccounts', () async {
      final now = DateTime.now().toUtc();
      final newAcc = AccountEntity(
        id: 'acc-custom-01',
        name: 'Emergency Savings',
        type: AccountType.bank,
        currency: 'IDR',
        balance: 100000000,
        createdAt: now,
        updatedAt: now,
      );

      await repository.createAccount(newAcc);

      final retrieved = await repository.getAccountById('acc-custom-01');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Emergency Savings'));
      expect(retrieved.balance, equals(100000000));
      expect(retrieved.type, equals(AccountType.bank));

      final streamAccounts = await repository.watchActiveAccounts().first;
      expect(streamAccounts.any((a) => a.id == 'acc-custom-01'), isTrue);
    });

    test('updateAccount modifies account metadata', () async {
      final now = DateTime.now().toUtc();
      final acc = AccountEntity(
        id: 'acc-mod-01',
        name: 'Old Wallet Name',
        type: AccountType.eWallet,
        currency: 'IDR',
        balance: 5000000,
        createdAt: now,
        updatedAt: now,
      );

      await repository.createAccount(acc);
      await repository.updateAccount(acc.copyWith(name: 'GoPay Primary'));

      final retrieved = await repository.getAccountById('acc-mod-01');
      expect(retrieved!.name, equals('GoPay Primary'));
    });

    test('updateBalance updates integer minor units atomically', () async {
      final now = DateTime.now().toUtc();
      final acc = AccountEntity(
        id: 'acc-bal-01',
        name: 'Cash Pocket',
        type: AccountType.cash,
        currency: 'IDR',
        balance: 5000000,
        createdAt: now,
        updatedAt: now,
      );

      await repository.createAccount(acc);
      await repository.updateBalance('acc-bal-01', BigInt.from(12000000));

      final retrieved = await repository.getAccountById('acc-bal-01');
      expect(retrieved!.balance, equals(12000000));
    });

    test('deleteAccount marks account with tombstone and filters from active list', () async {
      final now = DateTime.now().toUtc();
      final acc = AccountEntity(
        id: 'acc-del-01',
        name: 'Old Deprecated Card',
        type: AccountType.creditCard,
        currency: 'IDR',
        balance: 0,
        createdAt: now,
        updatedAt: now,
      );

      await repository.createAccount(acc);
      await repository.deleteAccount('acc-del-01');

      final active = await repository.getActiveAccounts();
      expect(active.any((a) => a.id == 'acc-del-01'), isFalse);

      final directlyFetched = await repository.getAccountById('acc-del-01');
      expect(directlyFetched?.isDeleted, isTrue);
    });
  });
}
