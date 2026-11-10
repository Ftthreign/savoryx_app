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
import 'package:savoryx/features/navigation/presentation/widgets/overview_tab.dart';
import 'package:savoryx/features/sync/domain/repositories/sync_repository.dart';
import 'package:savoryx/features/sync/domain/usecases/pull_delta_usecase.dart';
import 'package:savoryx/features/sync/domain/usecases/push_mutations_usecase.dart';
import 'package:savoryx/features/sync/domain/usecases/watch_pending_outbox_usecase.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_event.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_state.dart';
import 'package:savoryx/features/sync/presentation/widgets/sync_status_indicator.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:savoryx/features/transaction/domain/usecases/watch_recent_transactions_usecase.dart';

class _StubAccountRepository implements AccountRepository {
  final _controller = StreamController<List<AccountEntity>>.broadcast();

  @override
  Stream<List<AccountEntity>> watchActiveAccounts() => _controller.stream;

  @override
  Future<List<AccountEntity>> getActiveAccounts() async => const [];

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

  Future<void> dispose() => _controller.close();
}

class _StubTransactionRepository implements TransactionRepository {
  final _controller = StreamController<List<TransactionEntity>>.broadcast();

  @override
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 50}) =>
      _controller.stream;

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {}

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<TransactionEntity?> getTransactionById(String id) async => null;

  Future<void> dispose() => _controller.close();
}

class _StubSyncRepository implements SyncRepository {
  final _pendingController = StreamController<int>.broadcast();
  int pushCalls = 0;
  int pullCalls = 0;

  @override
  Future<SyncPushBatchResult> pushPendingMutations({int batchLimit = 50}) async {
    pushCalls++;
    return const SyncPushBatchResult(
      pushedMutationsCount: 0,
      accountsApplied: 0,
      categoriesApplied: 0,
      transactionsApplied: 0,
    );
  }

  @override
  Future<SyncPullSummary> pullDelta() async {
    pullCalls++;
    return SyncPullSummary(
      accountsUpserted: 0,
      categoriesUpserted: 0,
      transactionsInserted: 0,
      transactionsTombstoned: 0,
      pulledAt: DateTime.utc(2026, 11, 10, 8, 0, 0),
    );
  }

  @override
  Future<String> getLastPulledAtIso() async => '1970-01-01T00:00:00Z';

  @override
  Stream<int> watchPendingCount() => _pendingController.stream;

  Future<void> dispose() => _pendingController.close();
}

void main() {
  setUpAll(() {
    FontManager.useTestFallback = true;
  });
  group('SyncStatusIndicator Widget Tests (Task #51)', () {
    Widget wrapIndicator(SyncStatusIndicator indicator) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: indicator),
        ),
      );
    }

    testWidgets('renders idle state without pending badge when pendingCount is 0',
        (tester) async {
      await tester.pumpWidget(
        wrapIndicator(
          const SyncStatusIndicator(state: SyncState.idle()),
        ),
      );

      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
      expect(find.byKey(const Key('sync_pending_badge')), findsNothing);
    });

    testWidgets('renders pending badge with exact count and caps at 99+',
        (tester) async {
      await tester.pumpWidget(
        wrapIndicator(
          const SyncStatusIndicator(state: SyncState.idle(pendingCount: 4)),
        ),
      );

      expect(find.byIcon(Icons.cloud_upload_rounded), findsOneWidget);
      expect(find.byKey(const Key('sync_pending_badge')), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tester.pumpWidget(
        wrapIndicator(
          const SyncStatusIndicator(state: SyncState.idle(pendingCount: 142)),
        ),
      );
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('renders spinning RotationTransition during Syncing state',
        (tester) async {
      await tester.pumpWidget(
        wrapIndicator(
          const SyncStatusIndicator(state: SyncState.syncing(pendingCount: 3)),
        ),
      );

      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SyncStatusIndicator),
          matching: find.byType(RotationTransition),
        ),
        findsOneWidget,
      );
      expect(find.text('3'), findsOneWidget);

      // Pump several frames cleanly without pumpAndSettle timeout on infinite repeat
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('renders error icon on SyncFailure and triggers retry callback on tap',
        (tester) async {
      var retried = false;
      await tester.pumpWidget(
        wrapIndicator(
          SyncStatusIndicator(
            state: const SyncState.failure(
              message: 'Network unreachable',
              pendingCount: 2,
            ),
            onTap: () => retried = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.sync_problem_rounded), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byType(SyncStatusIndicator));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('renders synced check icon on SyncSuccess with zero pending',
        (tester) async {
      await tester.pumpWidget(
        wrapIndicator(
          SyncStatusIndicator(
            state: SyncState.success(
              lastSyncedAt: DateTime.utc(2026, 11, 10, 8, 0, 0),
              pendingCount: 0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
      expect(find.byKey(const Key('sync_pending_badge')), findsNothing);
    });

    testWidgets(
        'OverviewTab triggers SyncEvent.manualRequested on indicator tap and pull-to-refresh',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      final accountRepo = _StubAccountRepository();
      final txRepo = _StubTransactionRepository();
      final syncRepo = _StubSyncRepository();

      final overviewBloc = OverviewBloc(
        watchAccountsUseCase: WatchAccountsUseCase(accountRepo),
        watchRecentTransactionsUseCase: WatchRecentTransactionsUseCase(txRepo),
        calculateSafeToSpendUseCase: const CalculateSafeToSpendUseCase(),
        stashImpulseFundUseCase: StashImpulseFundUseCase(accountRepo, txRepo),
      );
      final syncBloc = SyncBloc(
        pushMutationsUseCase: PushMutationsUseCase(syncRepo),
        pullDeltaUseCase: PullDeltaUseCase(syncRepo),
        watchPendingOutboxUseCase: WatchPendingOutboxUseCase(syncRepo),
      )..add(const SyncEvent.started());

      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await overviewBloc.close();
        await syncBloc.close();
        await accountRepo.dispose();
        await txRepo.dispose();
        await syncRepo.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewTab(
              bloc: overviewBloc,
              syncBloc: syncBloc,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final indicator = find.byKey(const Key('overview_sync_indicator'));
      expect(indicator, findsOneWidget);

      await tester.tap(indicator);
      await tester.pumpAndSettle();
      expect(syncRepo.pushCalls, equals(1));
      expect(syncRepo.pullCalls, equals(1));

      await tester.fling(
        find.byKey(const PageStorageKey<String>('overview_scroll_view')),
        const Offset(0, 300),
        1000.0,
      );
      await tester.pumpAndSettle();
      expect(syncRepo.pushCalls, equals(2));
      expect(syncRepo.pullCalls, equals(2));
    });
  });
}
