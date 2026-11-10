import 'package:savoryx/features/sync/domain/repositories/sync_repository.dart';

/// Single-responsibility use case that fetches and merges remote delta changes locally.
class PullDeltaUseCase {
  const PullDeltaUseCase(this._repository);

  final SyncRepository _repository;

  Future<SyncPullSummary> call() => _repository.pullDelta();
}
