import 'package:dio/dio.dart';
import 'package:savoryx/core/error/exceptions.dart';
import 'package:savoryx/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:savoryx/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:savoryx/features/sync/domain/repositories/sync_repository.dart';
import 'package:savoryx/features/sync/domain/usecases/push_mutations_usecase.dart';

/// Concrete [SyncRepository] coordinating offline push batches and delta pull merges.
class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required SyncPushService pushService,
    required SyncRemoteDataSource remoteDataSource,
    required SyncLocalDataSource localDataSource,
  })  : _pushService = pushService,
        _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final SyncPushService _pushService;
  final SyncRemoteDataSource _remoteDataSource;
  final SyncLocalDataSource _localDataSource;

  @override
  Future<SyncPushBatchResult> pushPendingMutations({int batchLimit = 50}) {
    return _pushService.pushPendingMutations(batchLimit: batchLimit);
  }

  @override
  Future<String> getLastPulledAtIso() => _localDataSource.getLastPulledAtIso();

  @override
  Stream<int> watchPendingCount() => _localDataSource.watchPendingCount();

  @override
  Future<SyncPullSummary> pullDelta() async {
    try {
      final sinceIso = await _localDataSource.getLastPulledAtIso();
      final delta = await _remoteDataSource.pullDelta(sinceIso);
      final stats = await _localDataSource.mergePullDelta(delta);

      final nextCursorIso = delta.pulledAt.toUtc().toIso8601String();
      await _localDataSource.saveLastPulledAtIso(nextCursorIso);

      return SyncPullSummary(
        accountsUpserted: stats.accountsUpserted,
        categoriesUpserted: stats.categoriesUpserted,
        transactionsInserted: stats.transactionsInserted,
        transactionsTombstoned: stats.transactionsTombstoned,
        pulledAt: delta.pulledAt,
      );
    } on ServerException {
      rethrow;
    } on DioException catch (err) {
      final status = err.response?.statusCode;
      String? code;
      final data = err.response?.data;
      if (data is Map && data['error'] is Map) {
        code = (data['error'] as Map)['code']?.toString();
      }
      throw ServerException(
        status != null ? 'HTTP $status' : 'Network error: ${err.type.name}',
        code: code ?? 'SYNC_PULL_FAILED',
      );
    }
  }
}
