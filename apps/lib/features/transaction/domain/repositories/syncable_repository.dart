import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

/// Segregated repository contract dedicated strictly to offline delta synchronization
/// and tombstone lifecycle management, adhering to the Interface Segregation Principle (ISP).
abstract interface class TransactionSyncableRepository {
  /// Retrieves all local transaction records that have not been pushed to the remote backend.
  Future<List<TransactionEntity>> getPendingSyncRecords();

  /// Marks a batch of transaction records as synchronized upon remote push acknowledgement.
  Future<void> markAsSynced(List<String> ids);

  /// Reconciles remote tombstones by applying soft deletion locally with tombstone timestamps.
  Future<void> reconcileRemoteTombstones(List<String> deletedIds);
}
