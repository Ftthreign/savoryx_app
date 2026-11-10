import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_state.freezed.dart';

/// Sealed UI states representing the real-time offline-to-online sync lifecycle.
@freezed
sealed class SyncState with _$SyncState {
  const SyncState._();

  const factory SyncState.idle({
    @Default(0) int pendingCount,
    DateTime? lastSyncedAt,
  }) = SyncIdle;

  const factory SyncState.syncing({
    required int pendingCount,
  }) = Syncing;

  const factory SyncState.success({
    required DateTime lastSyncedAt,
    @Default(0) int pendingCount,
  }) = SyncSuccess;

  const factory SyncState.failure({
    required String message,
    @Default(0) int pendingCount,
    DateTime? lastSyncedAt,
  }) = SyncFailure;

  /// Extracts [pendingCount] uniformly across all sealed variants.
  int get currentPendingCount => switch (this) {
        SyncIdle(:final pendingCount) => pendingCount,
        Syncing(:final pendingCount) => pendingCount,
        SyncSuccess(:final pendingCount) => pendingCount,
        SyncFailure(:final pendingCount) => pendingCount,
      };
}
