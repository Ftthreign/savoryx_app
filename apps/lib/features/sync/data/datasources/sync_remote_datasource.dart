import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/daos/outbox_dao.dart';
import 'package:savoryx/core/error/exceptions.dart';
import 'package:savoryx/features/sync/data/models/sync_payload_models.dart';
import 'package:savoryx/features/sync/domain/usecases/push_mutations_usecase.dart';

/// Remote API contract for delta sync operations.
abstract interface class SyncRemoteDataSource {
  Future<SyncPushResponseModel> pushBatch(SyncPushRequestModel request);
  Future<SyncPullResponseModel> pullDelta(String lastPulledAtIso);
}

/// Dio-backed [SyncRemoteDataSource] communicating with Savoryx Go backend.
class DioSyncRemoteDataSource implements SyncRemoteDataSource {
  DioSyncRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<SyncPushResponseModel> pushBatch(SyncPushRequestModel request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/sync/push',
      data: request.toJson(),
    );
    final data = response.data ?? const <String, dynamic>{};
    return SyncPushResponseModel.fromJson(data);
  }

  @override
  Future<SyncPullResponseModel> pullDelta(String lastPulledAtIso) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/sync/pull',
      data: <String, dynamic>{'last_pulled_at': lastPulledAtIso},
    );
    final data = response.data ?? const <String, dynamic>{};
    return SyncPullResponseModel.fromJson(data);
  }
}

/// Signature for injectable async delay used by exponential backoff tests.
typedef AsyncDelayFn = Future<void> Function(Duration duration);

/// Pushes batches of up to 50 pending outbox mutations to `/api/v1/sync/push`
/// with exponential backoff + jitter and atomically clears acknowledged entries.
class SyncPushService implements SyncPushGateway {
  SyncPushService({
    required AppDatabase database,
    required SyncRemoteDataSource remoteDataSource,
    this.maxRetries = 3,
    this.baseRetryDelay = const Duration(milliseconds: 500),
    this.maxJitterMs = 250,
    Random? random,
    AsyncDelayFn? delayFn,
  })  : _database = database,
        _remoteDataSource = remoteDataSource,
        _random = random ?? Random(),
        _delayFn = delayFn ?? Future<void>.delayed;

  final AppDatabase _database;
  final SyncRemoteDataSource _remoteDataSource;
  final int maxRetries;
  final Duration baseRetryDelay;
  final int maxJitterMs;
  final Random _random;
  final AsyncDelayFn _delayFn;

  @override
  Future<SyncPushBatchResult> pushPendingMutations({int batchLimit = 50}) async {
    final pending =
        await _database.outboxDao.getPendingMutations(limit: batchLimit);
    if (pending.isEmpty) {
      return const SyncPushBatchResult(
        pushedMutationsCount: 0,
        accountsApplied: 0,
        categoriesApplied: 0,
        transactionsApplied: 0,
      );
    }

    final batchIds = <String>[];
    final accountIds = <String>[];
    final categoryIds = <String>[];
    final transactionIds = <String>[];

    final accounts = <SyncAccountPayloadModel>[];
    final categories = <SyncCategoryPayloadModel>[];
    final transactions = <SyncTransactionPayloadModel>[];

    for (final item in pending) {
      batchIds.add(item.id);
      final decoded = jsonDecode(item.payloadJson) as Map<String, dynamic>;

      switch (item.entityType) {
        case OutboxEntityType.account:
          accountIds.add(item.entityId);
          accounts.add(SyncAccountPayloadModel.fromOutboxJson(decoded));
          break;
        case OutboxEntityType.category:
          categoryIds.add(item.entityId);
          categories.add(SyncCategoryPayloadModel.fromOutboxJson(decoded));
          break;
        case OutboxEntityType.transaction:
          transactionIds.add(item.entityId);
          transactions.add(SyncTransactionPayloadModel.fromOutboxJson(decoded));
          break;
      }
    }

    final request = SyncPushRequestModel(
      accounts: accounts,
      categories: categories,
      transactions: transactions,
    );

    try {
      final response = await _executeWithBackoff(
        () => _remoteDataSource.pushBatch(request),
      );

      await _database.transaction(() async {
        await _database.outboxDao.deleteMutations(batchIds);

        if (accountIds.isNotEmpty) {
          await (_database.update(_database.localAccounts)
                ..where((t) => t.id.isIn(accountIds)))
              .write(const LocalAccountsCompanion(isSynced: Value(true)));
        }
        if (categoryIds.isNotEmpty) {
          await (_database.update(_database.localCategories)
                ..where((t) => t.id.isIn(categoryIds)))
              .write(const LocalCategoriesCompanion(isSynced: Value(true)));
        }
        if (transactionIds.isNotEmpty) {
          await (_database.update(_database.localTransactions)
                ..where((t) => t.id.isIn(transactionIds)))
              .write(const LocalTransactionsCompanion(isSynced: Value(true)));
        }
      });

      return SyncPushBatchResult(
        pushedMutationsCount: pending.length,
        accountsApplied: response.accountsApplied,
        categoriesApplied: response.categoriesApplied,
        transactionsApplied: response.transactionsApplied,
        syncedAt: response.syncedAt,
      );
    } catch (error) {
      final errorText = _summarizeError(error);
      await _database.transaction(() async {
        for (final id in batchIds) {
          await _database.outboxDao.incrementRetry(id, errorText);
        }
      });

      if (error is ServerException) {
        rethrow;
      }
      if (error is DioException) {
        throw ServerException(
          errorText,
          code: _extractServerCode(error) ?? 'SYNC_PUSH_FAILED',
        );
      }
      throw ServerException(errorText, code: 'SYNC_PUSH_FAILED');
    }
  }

  Future<T> _executeWithBackoff<T>(Future<T> Function() action) async {
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } on DioException catch (err) {
        if (!_isTransientError(err) || attempt >= maxRetries) {
          rethrow;
        }
        final delay = _computeBackoffDelay(attempt, err);
        attempt++;
        await _delayFn(delay);
      }
    }
  }

  bool _isTransientError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status == 429 || status >= 500;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return false;
    }
  }

  Duration _computeBackoffDelay(int attempt, DioException err) {
    final retryAfterRaw = err.response?.headers.value('Retry-After') ??
        err.response?.headers.value('retry-after');
    if (retryAfterRaw != null) {
      final retryAfterSec = int.tryParse(retryAfterRaw.trim());
      if (retryAfterSec != null && retryAfterSec > 0) {
        return Duration(seconds: retryAfterSec);
      }
    }

    final exponentialMs = baseRetryDelay.inMilliseconds * (1 << attempt);
    final jitterMs = maxJitterMs > 0 ? _random.nextInt(maxJitterMs + 1) : 0;
    return Duration(milliseconds: exponentialMs + jitterMs);
  }

  String? _extractServerCode(DioException err) {
    final data = err.response?.data;
    if (data is Map && data['error'] is Map) {
      return (data['error'] as Map)['code']?.toString();
    }
    return null;
  }

  String _summarizeError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final code = _extractServerCode(error);
      if (status != null) {
        return code != null ? 'HTTP $status ($code)' : 'HTTP $status';
      }
      return 'Network error: ${error.type.name}';
    }
    return error.toString();
  }
}
