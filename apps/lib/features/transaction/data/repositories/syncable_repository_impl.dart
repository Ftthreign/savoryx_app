import 'package:injectable/injectable.dart';
import 'package:savoryx/features/transaction/data/datasources/transaction_local_datasource.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/syncable_repository.dart';

@LazySingleton(as: TransactionSyncableRepository)
class TransactionSyncableRepositoryImpl
    implements TransactionSyncableRepository {
  final TransactionLocalDataSource _localDataSource;

  TransactionSyncableRepositoryImpl(this._localDataSource);

  @override
  Future<List<TransactionEntity>> getPendingSyncRecords() {
    if (_localDataSource is TransactionSyncLocalDataSource) {
      return (_localDataSource as TransactionSyncLocalDataSource)
          .getPendingSyncRecords();
    }
    return Future.value([]);
  }

  @override
  Future<void> markAsSynced(List<String> ids) {
    if (_localDataSource is TransactionSyncLocalDataSource) {
      return (_localDataSource as TransactionSyncLocalDataSource)
          .markAsSynced(ids);
    }
    return Future.value();
  }

  @override
  Future<void> reconcileRemoteTombstones(List<String> deletedIds) {
    if (_localDataSource is TransactionSyncLocalDataSource) {
      return (_localDataSource as TransactionSyncLocalDataSource)
          .reconcileRemoteTombstones(deletedIds);
    }
    return Future.value();
  }
}
