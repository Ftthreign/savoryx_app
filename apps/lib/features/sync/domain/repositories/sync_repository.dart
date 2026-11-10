import 'package:savoryx/features/sync/domain/usecases/push_mutations_usecase.dart';

/// Domain summary returned after merging incremental server delta changes locally.
class SyncPullSummary {
  const SyncPullSummary({
    required this.accountsUpserted,
    required this.categoriesUpserted,
    required this.transactionsInserted,
    required this.transactionsTombstoned,
    required this.pulledAt,
  });

  final int accountsUpserted;
  final int categoriesUpserted;
  final int transactionsInserted;
  final int transactionsTombstoned;
  final DateTime pulledAt;

  int get totalChangesApplied =>
      accountsUpserted +
      categoriesUpserted +
      transactionsInserted +
      transactionsTombstoned;
}

/// Domain repository contract for two-way delta synchronization.
abstract interface class SyncRepository implements SyncPushGateway {
  Future<SyncPullSummary> pullDelta();

  Future<String> getLastPulledAtIso();
}
