import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';
import 'package:savoryx/features/account/domain/usecases/watch_accounts_usecase.dart';
import 'package:savoryx/features/navigation/domain/usecases/calculate_safe_to_spend_usecase.dart';
import 'package:savoryx/features/navigation/domain/usecases/stash_impulse_fund_usecase.dart';
import 'package:savoryx/features/navigation/presentation/bloc/overview_bloc.dart';
import 'package:savoryx/features/navigation/presentation/bloc/overview_event.dart';
import 'package:savoryx/features/navigation/presentation/bloc/overview_state.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:savoryx/features/transaction/domain/usecases/watch_recent_transactions_usecase.dart';

class MockAccountRepo implements AccountRepository {
  final _controller = StreamController<List<AccountEntity>>.broadcast();

  void emit(List<AccountEntity> items) => _controller.add(items);

  @override
  Stream<List<AccountEntity>> watchActiveAccounts() => _controller.stream;

  @override
  Future<List<AccountEntity>> getActiveAccounts() async => [];

  @override
  Future<AccountEntity?> getAccountById(String id) async => null;

  @override
  Future<void> createAccount(AccountEntity account) async {}

  @override
  Future<void> updateAccount(AccountEntity account) async {}

  @override
  Future<void> updateBalance(String id, BigInt newBalance) async {}

  @override
  Future<void> deleteAccount(String id) async {}

  void dispose() => _controller.close();
}

class MockTransactionRepo implements TransactionRepository {
  final _controller = StreamController<List<TransactionEntity>>.broadcast();

  void emit(List<TransactionEntity> items) => _controller.add(items);

  @override
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 50}) =>
      _controller.stream;

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {}

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<TransactionEntity?> getTransactionById(String id) async => null;

  void dispose() => _controller.close();
}

void main() {
  group('OverviewBloc Tests', () {
    late MockAccountRepo accountRepo;
    late MockTransactionRepo txRepo;
    late WatchAccountsUseCase watchAccountsUseCase;
    late WatchRecentTransactionsUseCase watchRecentTransactionsUseCase;
    late CalculateSafeToSpendUseCase calculateSafeToSpendUseCase;
    late StashImpulseFundUseCase stashImpulseFundUseCase;

    final now = DateTime.parse('2026-11-01T10:00:00Z');
    final sampleAccounts = [
      AccountEntity(
        id: 'acc-1',
        name: 'BCA Main',
        type: AccountType.bank,
        balance: 15000000,
        createdAt: now,
        updatedAt: now,
      ),
      AccountEntity(
        id: 'acc-2',
        name: 'GoPay',
        type: AccountType.eWallet,
        balance: 500000,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    setUp(() {
      accountRepo = MockAccountRepo();
      txRepo = MockTransactionRepo();
      watchAccountsUseCase = WatchAccountsUseCase(accountRepo);
      watchRecentTransactionsUseCase = WatchRecentTransactionsUseCase(txRepo);
      calculateSafeToSpendUseCase = const CalculateSafeToSpendUseCase();
      stashImpulseFundUseCase = StashImpulseFundUseCase(accountRepo, txRepo);
    });

    tearDown(() {
      accountRepo.dispose();
      txRepo.dispose();
    });

    OverviewBloc buildBloc() => OverviewBloc(
          watchAccountsUseCase: watchAccountsUseCase,
          watchRecentTransactionsUseCase: watchRecentTransactionsUseCase,
          calculateSafeToSpendUseCase: calculateSafeToSpendUseCase,
          stashImpulseFundUseCase: stashImpulseFundUseCase,
        );

    test('initial state is correct', () {
      final bloc = buildBloc();
      expect(bloc.state.status, equals(OverviewStatus.initial));
      expect(bloc.state.isMasked, isFalse);
      expect(bloc.state.selectedCurrency, equals('IDR'));
      expect(bloc.state.stashedImpulseFund, equals(45000));
      bloc.close();
    });

    blocTest<OverviewBloc, OverviewState>(
      'OverviewMaskToggled flips isMasked flag',
      build: buildBloc,
      act: (bloc) => bloc.add(const OverviewMaskToggled()),
      expect: () => [
        predicate<OverviewState>((s) => s.isMasked == true),
      ],
    );

    blocTest<OverviewBloc, OverviewState>(
      'OverviewCurrencyChanged updates currency code and symbol',
      build: buildBloc,
      act: (bloc) => bloc.add(const OverviewCurrencyChanged('USD', r'$')),
      expect: () => [
        predicate<OverviewState>(
          (s) =>
              s.selectedCurrency == 'USD' && s.selectedCurrencySymbol == r'$',
        ),
      ],
    );

    blocTest<OverviewBloc, OverviewState>(
      'OverviewAccountsUpdated computes safe-to-spend and emits loaded state',
      build: buildBloc,
      act: (bloc) => bloc.add(OverviewAccountsUpdated(sampleAccounts)),
      expect: () => [
        predicate<OverviewState>((s) {
          return s.status == OverviewStatus.loaded &&
              s.accounts.length == 2 &&
              s.safeToSpend.dailySafeToSpend > BigInt.zero;
        }),
      ],
    );

    blocTest<OverviewBloc, OverviewState>(
      'OverviewTransactionsUpdated updates recentTransactions list',
      build: buildBloc,
      act: (bloc) => bloc.add(
        OverviewTransactionsUpdated([
          TransactionEntity(
            id: 'tx-1',
            accountId: 'acc-1',
            amount: 50000,
            type: TransactionType.expense,
            note: 'Lunch',
            transactionDate: now,
            createdAt: now,
            updatedAt: now,
          ),
        ]),
      ),
      expect: () => [
        predicate<OverviewState>((s) => s.recentTransactions.length == 1),
      ],
    );
  });
}
