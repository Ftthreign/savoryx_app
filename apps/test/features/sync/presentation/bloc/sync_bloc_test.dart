import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/sync/domain/repositories/sync_repository.dart';
import 'package:savoryx/features/sync/domain/usecases/pull_delta_usecase.dart';
import 'package:savoryx/features/sync/domain/usecases/push_mutations_usecase.dart';
import 'package:savoryx/features/sync/domain/usecases/watch_pending_outbox_usecase.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_event.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_state.dart';

class _FakeSyncRepository implements SyncRepository {
  _FakeSyncRepository({
    Future<SyncPushBatchResult> Function(int batchLimit)? onPush,
    Future<SyncPullSummary> Function()? onPull,
  })  : _onPush = onPush,
        _onPull = onPull;

  final Future<SyncPushBatchResult> Function(int batchLimit)? _onPush;
  final Future<SyncPullSummary> Function()? _onPull;
  final StreamController<int> pendingController =
      StreamController<int>.broadcast();

  int pushCalls = 0;
  int pullCalls = 0;

  @override
  Future<SyncPushBatchResult> pushPendingMutations({int batchLimit = 50}) async {
    pushCalls++;
    if (_onPush != null) {
      return _onPush(batchLimit);
    }
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
    if (_onPull != null) {
      return _onPull();
    }
    return SyncPullSummary(
      accountsUpserted: 0,
      categoriesUpserted: 0,
      transactionsInserted: 0,
      transactionsTombstoned: 0,
      pulledAt: DateTime.utc(2026, 11, 10, 7, 0, 0),
    );
  }

  @override
  Future<String> getLastPulledAtIso() async => '1970-01-01T00:00:00Z';

  @override
  Stream<int> watchPendingCount() => pendingController.stream;

  Future<void> dispose() => pendingController.close();
}

void main() {
  group('SyncBloc State Machine Tests (Task #51)', () {
    late _FakeSyncRepository fakeRepo;
    final syncedAt = DateTime.utc(2026, 11, 10, 7, 30, 0);

    setUp(() {
      fakeRepo = _FakeSyncRepository(
        onPush: (_) async => SyncPushBatchResult(
          pushedMutationsCount: 2,
          accountsApplied: 1,
          categoriesApplied: 0,
          transactionsApplied: 1,
          syncedAt: syncedAt,
        ),
        onPull: () async => SyncPullSummary(
          accountsUpserted: 1,
          categoriesUpserted: 0,
          transactionsInserted: 1,
          transactionsTombstoned: 0,
          pulledAt: syncedAt,
        ),
      );
    });

    tearDown(() async {
      await fakeRepo.dispose();
    });

    SyncBloc buildBloc({
      Future<void> Function()? onStartMonitor,
      Future<void> Function()? onDisposeMonitor,
    }) {
      return SyncBloc(
        pushMutationsUseCase: PushMutationsUseCase(fakeRepo),
        pullDeltaUseCase: PullDeltaUseCase(fakeRepo),
        watchPendingOutboxUseCase: WatchPendingOutboxUseCase(fakeRepo),
        onStartConnectivityMonitor: onStartMonitor,
        onDisposeConnectivityMonitor: onDisposeMonitor,
      );
    }

    blocTest<SyncBloc, SyncState>(
      'watches outbox pending count and runs Push -> Pull cleanly on manual request',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SyncEvent.started());
        await Future<void>.delayed(Duration.zero);
        fakeRepo.pendingController.add(2);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SyncEvent.manualRequested());
      },
      wait: const Duration(milliseconds: 20),
      expect: () => <SyncState>[
        const SyncState.idle(pendingCount: 2),
        const SyncState.syncing(pendingCount: 2),
        SyncState.success(lastSyncedAt: syncedAt, pendingCount: 2),
      ],
      verify: (_) {
        expect(fakeRepo.pushCalls, equals(1));
        expect(fakeRepo.pullCalls, equals(1));
      },
    );

    blocTest<SyncBloc, SyncState>(
      'drains multi-batch outbox queues (>50 items) before running pullDelta',
      build: () {
        var batchIndex = 0;
        fakeRepo = _FakeSyncRepository(
          onPush: (limit) async {
            batchIndex++;
            return SyncPushBatchResult(
              pushedMutationsCount: batchIndex == 1 ? 50 : 12,
              accountsApplied: 0,
              categoriesApplied: batchIndex == 1 ? 50 : 12,
              transactionsApplied: 0,
              syncedAt: syncedAt,
            );
          },
          onPull: () async => SyncPullSummary(
            accountsUpserted: 0,
            categoriesUpserted: 0,
            transactionsInserted: 0,
            transactionsTombstoned: 0,
            pulledAt: syncedAt,
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SyncEvent.connectivityTriggered()),
      expect: () => <SyncState>[
        const SyncState.syncing(pendingCount: 0),
        SyncState.success(lastSyncedAt: syncedAt, pendingCount: 0),
      ],
      verify: (_) {
        expect(fakeRepo.pushCalls, equals(2));
        expect(fakeRepo.pullCalls, equals(1));
      },
    );

    blocTest<SyncBloc, SyncState>(
      'emits SyncFailure with error message when push fails and allows retry',
      build: () {
        var attempts = 0;
        fakeRepo = _FakeSyncRepository(
          onPush: (_) async {
            attempts++;
            if (attempts == 1) {
              throw Exception('Server timeout');
            }
            return SyncPushBatchResult(
              pushedMutationsCount: 1,
              accountsApplied: 0,
              categoriesApplied: 1,
              transactionsApplied: 0,
              syncedAt: syncedAt,
            );
          },
          onPull: () async => SyncPullSummary(
            accountsUpserted: 0,
            categoriesUpserted: 0,
            transactionsInserted: 0,
            transactionsTombstoned: 0,
            pulledAt: syncedAt,
          ),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const SyncEvent.manualRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SyncEvent.manualRequested());
      },
      expect: () => <SyncState>[
        const SyncState.syncing(pendingCount: 0),
        const SyncState.failure(
          message: 'Exception: Server timeout',
          pendingCount: 0,
        ),
        const SyncState.syncing(pendingCount: 0),
        SyncState.success(lastSyncedAt: syncedAt, pendingCount: 0),
      ],
    );

    test('guards concurrent sync triggers while in-flight and disposes monitor on close',
        () async {
      final gate = Completer<void>();
      var monitorStarted = false;
      var monitorDisposed = false;

      fakeRepo = _FakeSyncRepository(
        onPush: (_) async {
          await gate.future;
          return const SyncPushBatchResult(
            pushedMutationsCount: 0,
            accountsApplied: 0,
            categoriesApplied: 0,
            transactionsApplied: 0,
          );
        },
      );

      final bloc = buildBloc(
        onStartMonitor: () async => monitorStarted = true,
        onDisposeMonitor: () async => monitorDisposed = true,
      );

      bloc.add(const SyncEvent.started());
      await Future<void>.delayed(Duration.zero);
      expect(monitorStarted, isTrue);

      bloc.add(const SyncEvent.manualRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<Syncing>());

      // Duplicate trigger while first sync is still awaiting gate must be ignored
      bloc.add(const SyncEvent.connectivityTriggered());
      await Future<void>.delayed(Duration.zero);
      expect(fakeRepo.pushCalls, equals(1));

      gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state, isA<SyncSuccess>());

      await bloc.close();
      expect(monitorDisposed, isTrue);
    });
  });
}
