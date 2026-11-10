import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_event.freezed.dart';

/// Events accepted by [SyncBloc].
@freezed
sealed class SyncEvent with _$SyncEvent {
  /// Starts listening to reactive outbox count and connectivity events.
  const factory SyncEvent.started() = SyncStarted;

  /// Triggers an immediate two-way Push -> Pull cycle (e.g. pull-to-refresh or indicator tap).
  const factory SyncEvent.manualRequested({
    void Function()? onComplete,
  }) = SyncManualRequested;

  /// Fired internally when the device connectivity transitions or refreshes.
  const factory SyncEvent.connectivityTriggered() = SyncConnectivityTriggered;

  /// Fired internally whenever the local outbox pending count changes.
  const factory SyncEvent.pendingCountUpdated(int count) =
      SyncPendingCountUpdated;
}
