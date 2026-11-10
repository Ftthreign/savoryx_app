import 'package:savoryx/features/sync/domain/repositories/sync_repository.dart';

/// Single-responsibility use case that observes the pending offline outbox queue count.
class WatchPendingOutboxUseCase {
  const WatchPendingOutboxUseCase(this._repository);

  final SyncRepository _repository;

  Stream<int> call() => _repository.watchPendingCount();
}
