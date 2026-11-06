import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';
import 'package:savoryx/features/account/domain/usecases/create_account_usecase.dart';
import 'package:savoryx/features/account/domain/usecases/delete_account_usecase.dart';
import 'package:savoryx/features/account/domain/usecases/get_account_by_id_usecase.dart';
import 'package:savoryx/features/account/domain/usecases/get_accounts_usecase.dart';
import 'package:savoryx/features/account/domain/usecases/update_account_balance_usecase.dart';
import 'package:savoryx/features/account/domain/usecases/update_account_usecase.dart';
import 'package:savoryx/features/account/domain/usecases/watch_accounts_usecase.dart';

class FakeAccountRepository implements AccountRepository {
  final List<AccountEntity> _accounts = [];

  @override
  Future<List<AccountEntity>> getActiveAccounts() async {
    return _accounts.where((a) => a.deletedAt == null).toList();
  }

  @override
  Stream<List<AccountEntity>> watchActiveAccounts() {
    return Stream.value(_accounts.where((a) => a.deletedAt == null).toList());
  }

  @override
  Future<AccountEntity?> getAccountById(String id) async {
    return _accounts.cast<AccountEntity?>().firstWhere(
          (a) => a?.id == id,
          orElse: () => null,
        );
  }

  @override
  Future<void> createAccount(AccountEntity account) async {
    _accounts.add(account);
  }

  @override
  Future<void> updateAccount(AccountEntity account) async {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      _accounts[index] = account;
    }
  }

  @override
  Future<void> updateBalance(String id, BigInt newBalance) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _accounts[index] = _accounts[index].copyWith(balance: newBalance.toInt());
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _accounts[index] = _accounts[index].copyWith(deletedAt: DateTime.now().toUtc());
    }
  }
}

void main() {
  group('Account Domain Use Cases & SRP Tests', () {
    late FakeAccountRepository fakeRepo;
    late GetAccountsUseCase getAccountsUseCase;
    late WatchAccountsUseCase watchAccountsUseCase;
    late GetAccountByIdUseCase getAccountByIdUseCase;
    late CreateAccountUseCase createAccountUseCase;
    late UpdateAccountUseCase updateAccountUseCase;
    late UpdateAccountBalanceUseCase updateAccountBalanceUseCase;
    late DeleteAccountUseCase deleteAccountUseCase;

    final now = DateTime.parse('2026-11-01T10:00:00Z');
    final sampleAccount = AccountEntity(
      id: 'acc-uuid-001',
      name: 'BCA Main Pocket',
      type: AccountType.bank,
      currency: 'IDR',
      balance: 150000000,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      fakeRepo = FakeAccountRepository();
      getAccountsUseCase = GetAccountsUseCase(fakeRepo);
      watchAccountsUseCase = WatchAccountsUseCase(fakeRepo);
      getAccountByIdUseCase = GetAccountByIdUseCase(fakeRepo);
      createAccountUseCase = CreateAccountUseCase(fakeRepo);
      updateAccountUseCase = UpdateAccountUseCase(fakeRepo);
      updateAccountBalanceUseCase = UpdateAccountBalanceUseCase(fakeRepo);
      deleteAccountUseCase = DeleteAccountUseCase(fakeRepo);
    });

    test('CreateAccountUseCase and GetAccountsUseCase happy path', () async {
      await createAccountUseCase(sampleAccount);
      final active = await getAccountsUseCase();

      expect(active.length, equals(1));
      expect(active.first.id, equals('acc-uuid-001'));
      expect(active.first.name, equals('BCA Main Pocket'));
      expect(active.first.type, equals(AccountType.bank));
      expect(active.first.balance, equals(150000000));
    });

    test('CreateAccountUseCase throws ArgumentError on empty id or name', () async {
      expect(
        () => createAccountUseCase(sampleAccount.copyWith(id: '  ')),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => createAccountUseCase(sampleAccount.copyWith(name: '')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('WatchAccountsUseCase emits active accounts stream', () async {
      await createAccountUseCase(sampleAccount);
      final streamResult = await watchAccountsUseCase().first;
      expect(streamResult.length, equals(1));
      expect(streamResult.first.id, equals('acc-uuid-001'));
    });

    test('GetAccountByIdUseCase returns account or null if not found', () async {
      await createAccountUseCase(sampleAccount);

      final found = await getAccountByIdUseCase('acc-uuid-001');
      expect(found, isNotNull);
      expect(found!.id, equals('acc-uuid-001'));

      final notFound = await getAccountByIdUseCase('non-existent');
      expect(notFound, isNull);

      expect(() => getAccountByIdUseCase(''), throwsA(isA<ArgumentError>()));
    });

    test('UpdateAccountUseCase modifies existing account attributes', () async {
      await createAccountUseCase(sampleAccount);

      final updated = sampleAccount.copyWith(name: 'BCA Premier Pocket');
      await updateAccountUseCase(updated);

      final result = await getAccountByIdUseCase('acc-uuid-001');
      expect(result!.name, equals('BCA Premier Pocket'));
    });

    test('UpdateAccountBalanceUseCase modifies running balance in minor units', () async {
      await createAccountUseCase(sampleAccount);

      await updateAccountBalanceUseCase('acc-uuid-001', BigInt.from(200000000));
      final result = await getAccountByIdUseCase('acc-uuid-001');
      expect(result!.balance, equals(200000000));
    });

    test('DeleteAccountUseCase soft-deletes account and excludes from active list', () async {
      await createAccountUseCase(sampleAccount);
      expect((await getAccountsUseCase()).length, equals(1));

      await deleteAccountUseCase('acc-uuid-001');

      final active = await getAccountsUseCase();
      expect(active, isEmpty);

      final retrieved = await getAccountByIdUseCase('acc-uuid-001');
      expect(retrieved?.isDeleted, isTrue);
    });
  });
}
