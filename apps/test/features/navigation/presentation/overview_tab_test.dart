import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/typography/font_manager.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';
import 'package:savoryx/features/account/domain/usecases/watch_accounts_usecase.dart';
import 'package:savoryx/features/navigation/domain/usecases/calculate_safe_to_spend_usecase.dart';
import 'package:savoryx/features/navigation/domain/usecases/stash_impulse_fund_usecase.dart';
import 'package:savoryx/features/navigation/presentation/bloc/overview_bloc.dart';
import 'package:savoryx/features/navigation/presentation/bloc/overview_event.dart';
import 'package:savoryx/features/navigation/presentation/widgets/overview_tab.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:savoryx/features/transaction/domain/usecases/watch_recent_transactions_usecase.dart';

class _FakeAccountRepo implements AccountRepository {
  final _controller = StreamController<List<AccountEntity>>.broadcast();
  final List<AccountEntity> _items = [];

  void emit(List<AccountEntity> items) {
    _items.clear();
    _items.addAll(items);
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Stream<List<AccountEntity>> watchActiveAccounts() {
    // ignore: close_sinks
    late StreamController<List<AccountEntity>> controller;
    StreamSubscription<List<AccountEntity>>? sub;
    controller = StreamController<List<AccountEntity>>.broadcast(
      onListen: () {
        controller.add(List.unmodifiable(_items));
        sub = _controller.stream.listen(controller.add);
      },
      onCancel: () {
        sub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<List<AccountEntity>> getActiveAccounts() async =>
      List.unmodifiable(_items);

  @override
  Future<AccountEntity?> getAccountById(String id) async => _items
      .cast<AccountEntity?>()
      .firstWhere((a) => a?.id == id, orElse: () => null);

  @override
  Future<void> createAccount(AccountEntity account) async {
    _items.add(account);
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> updateAccount(AccountEntity account) async {
    final idx = _items.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      _items[idx] = account;
      _controller.add(List.unmodifiable(_items));
    }
  }

  @override
  Future<void> updateBalance(String id, BigInt newBalance) async {
    final idx = _items.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(balance: newBalance.toInt());
      _controller.add(List.unmodifiable(_items));
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    _items.removeWhere((a) => a.id == id);
    _controller.add(List.unmodifiable(_items));
  }

  void dispose() => _controller.close();
}

class _FakeTransactionRepo implements TransactionRepository {
  final _controller = StreamController<List<TransactionEntity>>.broadcast();
  final List<TransactionEntity> _items = [];

  void emit(List<TransactionEntity> items) {
    _items.clear();
    _items.addAll(items);
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 50}) {
    // ignore: close_sinks
    late StreamController<List<TransactionEntity>> controller;
    StreamSubscription<List<TransactionEntity>>? sub;
    controller = StreamController<List<TransactionEntity>>.broadcast(
      onListen: () {
        controller.add(List.unmodifiable(_items));
        sub = _controller.stream.listen(controller.add);
      },
      onCancel: () {
        sub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {
    _items.insert(0, transaction);
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _items.removeWhere((t) => t.id == id);
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async => _items
      .cast<TransactionEntity?>()
      .firstWhere((t) => t?.id == id, orElse: () => null);

  void dispose() => _controller.close();
}

void main() {
  late _FakeAccountRepo accountRepo;
  late _FakeTransactionRepo txRepo;
  late OverviewBloc bloc;

  final now = DateTime.parse('2026-11-01T10:00:00Z');
  final sampleAccounts = [
    AccountEntity(
      id: 'acc-1',
      name: 'Kas Tunai',
      type: AccountType.cash,
      balance: 4500000,
      createdAt: now,
      updatedAt: now,
    ),
    AccountEntity(
      id: 'acc-2',
      name: 'Rekening BCA',
      type: AccountType.bank,
      balance: 145000000,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  setUpAll(() {
    FontManager.useTestFallback = true;
  });

  setUp(() {
    accountRepo = _FakeAccountRepo();
    accountRepo.emit(sampleAccounts);
    txRepo = _FakeTransactionRepo();
    bloc = OverviewBloc(
      watchAccountsUseCase: WatchAccountsUseCase(accountRepo),
      watchRecentTransactionsUseCase: WatchRecentTransactionsUseCase(txRepo),
      calculateSafeToSpendUseCase: const CalculateSafeToSpendUseCase(),
      stashImpulseFundUseCase: StashImpulseFundUseCase(accountRepo, txRepo),
    )..add(const OverviewLoadStarted());
  });

  tearDown(() {
    bloc.close();
    accountRepo.dispose();
    txRepo.dispose();
  });

  Widget buildTestableOverview() {
    return MaterialApp(
      home: Scaffold(
        body: OverviewTab(bloc: bloc),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('OverviewTab Reactive Integration Tests (Task #20 & #166)', () {
    testWidgets(
        'renders reactive accounts carousel and default seeded accounts cleanly',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableOverview());
      await tester.pumpAndSettle();

      // Top bar & Hero Card
      expect(find.text('PULSESPEND // SAVORYX'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('SAFE-TO-SPEND RUNWAY'), findsOneWidget);

      // Section header
      expect(find.text('Pockets & Accounts'), findsOneWidget);
      expect(find.text('Recent Tactile Ledger'), findsOneWidget);

      expect(find.text('Kas Tunai'), findsOneWidget);
      expect(find.text('Rekening BCA'), findsOneWidget);
    });

    testWidgets('toggles privacy mask on eye button tap',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableOverview());
      await tester.pumpAndSettle();

      // Initially eye icon is visibility
      final eyeButton = find.byIcon(Icons.visibility);
      expect(eyeButton, findsOneWidget);

      // Tap to mask
      await tester.tap(eyeButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.textContaining('••••••••'), findsWidgets);

      // Tap again to unmask
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets(
        'Saya Batal Beli button deflects impulse and updates stashed fund persistently',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableOverview());
      await tester.pumpAndSettle();

      expect(find.text('Saya Batal Beli'), findsOneWidget);
      expect(find.text('+45k Stashed'), findsOneWidget);

      await tester.tap(find.text('Saya Batal Beli'));
      await tester.pumpAndSettle();

      expect(find.text('+90k Stashed'), findsOneWidget);
      expect(find.textContaining('Impulse deflected!'), findsOneWidget);

      // Advance SnackBar duration
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('reactively displays new transactions in recent ledger',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableOverview());
      await tester.pumpAndSettle();

      // Emit new transaction
      txRepo.emit([
        TransactionEntity(
          id: 'tx-001',
          accountId: 'acc-1',
          amount: 75000,
          type: TransactionType.expense,
          note: 'Makan Siang Sate Padang',
          transactionDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpAndSettle();

      expect(find.text('Makan Siang Sate Padang'), findsOneWidget);
    });
  });
}
