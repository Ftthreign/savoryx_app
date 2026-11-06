import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';
import 'package:savoryx/features/navigation/domain/usecases/stash_impulse_fund_usecase.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/transaction_repository.dart';

class FakeAccountRepo implements AccountRepository {
  final List<AccountEntity> accounts = [];

  @override
  Future<List<AccountEntity>> getActiveAccounts() async =>
      accounts.where((a) => a.deletedAt == null).toList();

  @override
  Stream<List<AccountEntity>> watchActiveAccounts() =>
      Stream.value(accounts.where((a) => a.deletedAt == null).toList());

  @override
  Future<AccountEntity?> getAccountById(String id) async =>
      accounts.cast<AccountEntity?>().firstWhere((a) => a?.id == id, orElse: () => null);

  @override
  Future<void> createAccount(AccountEntity account) async {
    accounts.add(account);
  }

  @override
  Future<void> updateAccount(AccountEntity account) async {
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) accounts[idx] = account;
  }

  @override
  Future<void> updateBalance(String id, BigInt newBalance) async {
    final idx = accounts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      accounts[idx] = accounts[idx].copyWith(balance: newBalance.toInt());
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    final idx = accounts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      accounts[idx] = accounts[idx].copyWith(deletedAt: DateTime.now().toUtc());
    }
  }
}

class FakeTransactionRepo implements TransactionRepository {
  final List<TransactionEntity> transactions = [];

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {
    transactions.add(transaction);
  }

  @override
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 50}) =>
      Stream.value(transactions);

  @override
  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async =>
      transactions.cast<TransactionEntity?>().firstWhere((t) => t?.id == id, orElse: () => null);
}

void main() {
  group('StashImpulseFundUseCase Integration Tests', () {
    late FakeAccountRepo accountRepo;
    late FakeTransactionRepo transactionRepo;
    late StashImpulseFundUseCase useCase;

    setUp(() {
      accountRepo = FakeAccountRepo();
      transactionRepo = FakeTransactionRepo();
      useCase = StashImpulseFundUseCase(accountRepo, transactionRepo);
    });

    test('creates Celengan Impuls account on first stash and records ledger transaction', () async {
      final updatedBalance = await useCase(amountMinorUnits: 45000);

      expect(updatedBalance, equals(BigInt.from(45000)));
      expect(accountRepo.accounts.length, equals(1));
      expect(accountRepo.accounts.first.name, equals('Celengan Impuls'));
      expect(accountRepo.accounts.first.balance, equals(45000));

      expect(transactionRepo.transactions.length, equals(1));
      expect(transactionRepo.transactions.first.amount, equals(45000));
      expect(transactionRepo.transactions.first.note, contains('Batal Beli'));
    });

    test('increments existing Celengan Impuls balance atomically on subsequent stashes', () async {
      await useCase(amountMinorUnits: 45000);
      final secondStash = await useCase(amountMinorUnits: 45000);

      expect(secondStash, equals(BigInt.from(90000)));
      expect(accountRepo.accounts.length, equals(1));
      expect(accountRepo.accounts.first.balance, equals(90000));
      expect(transactionRepo.transactions.length, equals(2));
    });

    test('throws ArgumentError on zero or negative stash amount', () async {
      expect(() => useCase(amountMinorUnits: 0), throwsA(isA<ArgumentError>()));
      expect(() => useCase(amountMinorUnits: -100), throwsA(isA<ArgumentError>()));
    });
  });
}
