/// Domain summary returned after pushing a pending outbox batch.
class SyncPushBatchResult {
  const SyncPushBatchResult({
    required this.pushedMutationsCount,
    required this.accountsApplied,
    required this.categoriesApplied,
    required this.transactionsApplied,
    this.syncedAt,
  });

  final int pushedMutationsCount;
  final int accountsApplied;
  final int categoriesApplied;
  final int transactionsApplied;
  final DateTime? syncedAt;
}

/// Domain boundary contract for pushing offline mutations to the remote ledger.
abstract interface class SyncPushGateway {
  Future<SyncPushBatchResult> pushPendingMutations({int batchLimit = 50});
}

/// Single-responsibility use case that uploads pending offline mutations.
class PushMutationsUseCase {
  const PushMutationsUseCase(this._gateway);

  final SyncPushGateway _gateway;

  Future<SyncPushBatchResult> call({int batchLimit = 50}) {
    if (batchLimit <= 0) {
      throw ArgumentError.value(batchLimit, 'batchLimit', 'Must be positive');
    }
    return _gateway.pushPendingMutations(batchLimit: batchLimit);
  }
}
