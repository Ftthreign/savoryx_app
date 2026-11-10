import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savoryx/features/sync/domain/usecases/pull_delta_usecase.dart';
import 'package:savoryx/features/sync/domain/usecases/push_mutations_usecase.dart';
import 'package:savoryx/features/sync/domain/usecases/watch_pending_outbox_usecase.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_event.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    required PushMutationsUseCase pushMutationsUseCase,
    required PullDeltaUseCase pullDeltaUseCase,
    required WatchPendingOutboxUseCase watchPendingOutboxUseCase,
    Future<void> Function()? onStartConnectivityMonitor,
    Future<void> Function()? onDisposeConnectivityMonitor,
  })  : _pushMutationsUseCase = pushMutationsUseCase,
        _pullDeltaUseCase = pullDeltaUseCase,
        _watchPendingOutboxUseCase = watchPendingOutboxUseCase,
        _onStartConnectivityMonitor = onStartConnectivityMonitor,
        _onDisposeConnectivityMonitor = onDisposeConnectivityMonitor,
        super(const SyncState.idle()) {
    on<SyncStarted>(_onStarted);
    on<SyncManualRequested>(_onSyncTriggered);
    on<SyncConnectivityTriggered>(_onConnectivityTriggered);
    on<SyncPendingCountUpdated>(_onPendingCountUpdated);
  }

  static const int _batchSize = 50;
  static const int _maxBatchesPerCycle = 20;

  final PushMutationsUseCase _pushMutationsUseCase;
  final PullDeltaUseCase _pullDeltaUseCase;
  final WatchPendingOutboxUseCase _watchPendingOutboxUseCase;
  final Future<void> Function()? _onStartConnectivityMonitor;
  final Future<void> Function()? _onDisposeConnectivityMonitor;

  StreamSubscription<int>? _outboxCountSub;
  bool _isSyncInProgress = false;
  int _latestPendingCount = 0;
  DateTime? _lastSyncedAt;

  Future<void> _onStarted(
    SyncStarted event,
    Emitter<SyncState> emit,
  ) async {
    if (_outboxCountSub != null) {
      return;
    }
    _outboxCountSub = _watchPendingOutboxUseCase().listen(
      (count) {
        if (!isClosed) {
          add(SyncEvent.pendingCountUpdated(count));
        }
      },
    );
    await _onStartConnectivityMonitor?.call();
  }

  void _onPendingCountUpdated(
    SyncPendingCountUpdated event,
    Emitter<SyncState> emit,
  ) {
    _latestPendingCount = event.count;
    emit(
      state.when(
        idle: (_, lastSyncedAt) => SyncState.idle(
          pendingCount: event.count,
          lastSyncedAt: lastSyncedAt,
        ),
        syncing: (_) => SyncState.syncing(pendingCount: event.count),
        success: (lastSyncedAt, _) => SyncState.success(
          lastSyncedAt: lastSyncedAt,
          pendingCount: event.count,
        ),
        failure: (message, _, lastSyncedAt) => SyncState.failure(
          message: message,
          pendingCount: event.count,
          lastSyncedAt: lastSyncedAt,
        ),
      ),
    );
  }

  Future<void> _onConnectivityTriggered(
    SyncConnectivityTriggered event,
    Emitter<SyncState> emit,
  ) {
    return _runSyncCycle(emit);
  }

  Future<void> _onSyncTriggered(
    SyncManualRequested event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await _runSyncCycle(emit);
    } finally {
      event.onComplete?.call();
    }
  }

  Future<void> _runSyncCycle(Emitter<SyncState> emit) async {
    if (_isSyncInProgress) {
      return;
    }

    _isSyncInProgress = true;
    emit(SyncState.syncing(pendingCount: _latestPendingCount));

    try {
      // Drain outbox queue in bounded batches before pulling server deltas.
      for (var batch = 0; batch < _maxBatchesPerCycle; batch++) {
        final pushResult = await _pushMutationsUseCase(batchLimit: _batchSize);
        if (pushResult.pushedMutationsCount < _batchSize) {
          break;
        }
      }

      final pullSummary = await _pullDeltaUseCase();
      _lastSyncedAt = pullSummary.pulledAt;

      emit(
        SyncState.success(
          lastSyncedAt: pullSummary.pulledAt,
          pendingCount: _latestPendingCount,
        ),
      );
    } catch (error) {
      emit(
        SyncState.failure(
          message: _sanitizeErrorMessage(error),
          pendingCount: _latestPendingCount,
          lastSyncedAt: _lastSyncedAt,
        ),
      );
    } finally {
      _isSyncInProgress = false;
    }
  }

  String _sanitizeErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return 'Sinkronisasi gagal. Ketuk untuk mencoba lagi.';
    }
    return raw;
  }

  @override
  Future<void> close() async {
    await _outboxCountSub?.cancel();
    await _onDisposeConnectivityMonitor?.call();
    return super.close();
  }
}
