import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/daos/outbox_dao.dart';
import 'package:savoryx/core/di/injection_container.dart';
import 'package:savoryx/core/network/dio_client.dart';
import 'package:savoryx/core/network/interceptors/sync_security_interceptor.dart';
import 'package:savoryx/core/security/device_credentials_storage.dart';
import 'package:savoryx/core/security/hmac_signer.dart';
import 'package:savoryx/features/sync/data/datasources/connectivity_sync_listener.dart';
import 'package:savoryx/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:savoryx/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:savoryx/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:savoryx/features/sync/domain/repositories/sync_repository.dart';
import 'package:savoryx/features/sync/domain/usecases/pull_delta_usecase.dart';
import 'package:savoryx/features/sync/domain/usecases/push_mutations_usecase.dart';
import 'package:savoryx/features/sync/domain/usecases/watch_pending_outbox_usecase.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_event.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_state.dart';
import 'package:uuid/uuid.dart';

class _InMemoryKeyValueStore implements KeyValueSecureStore {
  final Map<String, String> _storage = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => _storage[key];

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }
}

class _InMemoryCursorStorage implements SyncCursorStorage {
  String? cursor;

  @override
  Future<String?> readLastPulledAtIso() async => cursor;

  @override
  Future<void> saveLastPulledAtIso(String isoTimestamp) async {
    cursor = isoTimestamp;
  }
}

class _SimulatedConnectivityMonitor implements NetworkConnectivityMonitor {
  _SimulatedConnectivityMonitor({
    List<ConnectivityResult> initialResults = const <ConnectivityResult>[
      ConnectivityResult.none,
    ],
  }) : _currentResults = initialResults;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  List<ConnectivityResult> _currentResults;

  void setConnectivity(List<ConnectivityResult> results) {
    _currentResults = results;
    _controller.add(isOnlineConnectivityResults(results));
  }

  @override
  Stream<bool> get onOnlineChanged => _controller.stream;

  @override
  Future<bool> isConnected() async =>
      isOnlineConnectivityResults(_currentResults);

  Future<void> close() => _controller.close();
}

class _RecordedHttpRequest {
  const _RecordedHttpRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.bodyString,
  });

  final String method;
  final String path;
  final Map<String, dynamic> headers;
  final String bodyString;
}

class _MockSyncServerAdapter implements HttpClientAdapter {
  _MockSyncServerAdapter({
    required this.remoteDeltaTxId,
    required this.accountId,
    required this.categoryId,
  });

  final String remoteDeltaTxId;
  final String accountId;
  final String categoryId;

  final List<_RecordedHttpRequest> requests = <_RecordedHttpRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    final rawBody = utf8.decode(bytes);
    requests.add(
      _RecordedHttpRequest(
        method: options.method,
        path: options.uri.path,
        headers: Map<String, dynamic>.from(options.headers),
        bodyString: rawBody,
      ),
    );

    final serverTime = DateTime.utc(2026, 11, 10, 7, 15, 0);
    if (options.uri.path == '/api/v1/sync/push') {
      final decoded = jsonDecode(rawBody) as Map<String, dynamic>;
      final accounts = (decoded['accounts'] as List<dynamic>? ?? const []);
      final categories = (decoded['categories'] as List<dynamic>? ?? const []);
      final transactions =
          (decoded['transactions'] as List<dynamic>? ?? const []);
      final payload = jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{
          'accounts_applied': accounts.length,
          'categories_applied': categories.length,
          'transactions_applied': transactions.length,
          'synced_at': serverTime.toIso8601String(),
        },
      });
      return ResponseBody.fromString(
        payload,
        200,
        headers: const <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }

    if (options.uri.path == '/api/v1/sync/pull') {
      final payload = jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{
          'accounts': const <Map<String, dynamic>>[],
          'categories': const <Map<String, dynamic>>[],
          'transactions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': remoteDeltaTxId,
              'account_id': accountId,
              'category_id': categoryId,
              'type': 'EXPENSE',
              'amount': '55000.00',
              'currency': 'IDR',
              'exchange_rate_to_base': '1.000000',
              'base_amount': '55000.00',
              'note': 'Remote Companion Device Entry',
              'transaction_date': serverTime.toIso8601String(),
              'created_at': serverTime.toIso8601String(),
              'updated_at': serverTime.toIso8601String(),
            },
          ],
          'pulled_at': serverTime.toIso8601String(),
          'server_time': serverTime.toIso8601String(),
        },
      });
      return ResponseBody.fromString(
        payload,
        200,
        headers: const <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'error': 'not_found'}),
      404,
      headers: const <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const uuid = Uuid();

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    if (getIt.isRegistered<SyncBloc>()) {
      await getIt<SyncBloc>().close();
    }
    if (getIt.isRegistered<AppDatabase>()) {
      await getIt<AppDatabase>().close();
    }
    await getIt.reset();
  });

  group('Sync DI Container & Airplane Mode E2E Verification (Task #52)', () {
    test('configureDependencies registers complete sync dependency graph',
        () async {
      await configureDependencies();

      expect(getIt.isRegistered<OutboxDao>(), isTrue);
      expect(getIt.isRegistered<HmacSigner>(), isTrue);
      expect(getIt.isRegistered<UtcTimekeeper>(), isTrue);
      expect(getIt.isRegistered<DeviceCredentialsStorage>(), isTrue);
      expect(getIt.isRegistered<SyncCursorStorage>(), isTrue);
      expect(getIt.isRegistered<SyncSecurityInterceptor>(), isTrue);
      expect(getIt.isRegistered<DioClient>(), isTrue);
      expect(getIt.isRegistered<SyncRemoteDataSource>(), isTrue);
      expect(getIt.isRegistered<SyncLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<SyncPushService>(), isTrue);
      expect(getIt.isRegistered<SyncRepository>(), isTrue);
      expect(getIt.isRegistered<PushMutationsUseCase>(), isTrue);
      expect(getIt.isRegistered<PullDeltaUseCase>(), isTrue);
      expect(getIt.isRegistered<WatchPendingOutboxUseCase>(), isTrue);
      expect(getIt.isRegistered<NetworkConnectivityMonitor>(), isTrue);
      expect(getIt.isRegistered<ConnectivitySyncListener>(), isTrue);
      expect(getIt.isRegistered<SyncBloc>(), isTrue);

      // Smoke check graph resolution without throwing
      expect(getIt<SyncBloc>(), isA<SyncBloc>());
    });

    test(
        'simulates Airplane Mode offline mutations -> online recovery -> debounced signed push + delta pull',
        () async {
      await configureDependencies();

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final secureStore = _InMemoryKeyValueStore();
      final credentialsStorage = DeviceCredentialsStorage(store: secureStore);
      const deviceId = '01937d9a-1000-7000-8000-000000000042';
      const deviceSecret = 'super-secret-device-key-task-52';
      const accessToken = 'v4.local.test-paseto-token';
      await credentialsStorage.saveCredentials(
        deviceId: deviceId,
        deviceSecret: deviceSecret,
        accessToken: accessToken,
      );

      final cursorStorage = _InMemoryCursorStorage();
      final connectivityMonitor = _SimulatedConnectivityMonitor(
        initialResults: const <ConnectivityResult>[ConnectivityResult.none],
      );
      addTearDown(connectivityMonitor.close);

      // Rewire test doubles into real getIt graph
      getIt.unregister<AppDatabase>();
      getIt.registerSingleton<AppDatabase>(db);
      getIt.unregister<OutboxDao>();
      getIt.registerSingleton<OutboxDao>(db.outboxDao);
      getIt.unregister<DeviceCredentialsStorage>();
      getIt.registerSingleton<DeviceCredentialsStorage>(credentialsStorage);
      getIt.unregister<SyncCursorStorage>();
      getIt.registerSingleton<SyncCursorStorage>(cursorStorage);
      getIt.unregister<NetworkConnectivityMonitor>();
      getIt.registerSingleton<NetworkConnectivityMonitor>(connectivityMonitor);

      // Seed accounts & categories by touching DB so FKs exist for offline ledger entries
      final accounts = await db.accountDao.getAllActiveAccounts();
      final categories = await db.categoryDao.getAllActiveCategories();
      expect(accounts, isNotEmpty);
      expect(categories, isNotEmpty);
      final targetAccount = accounts.first;
      final targetCategory = categories.first;
      final remoteDeltaTxId = uuid.v7();

      final serverAdapter = _MockSyncServerAdapter(
        remoteDeltaTxId: remoteDeltaTxId,
        accountId: targetAccount.id,
        categoryId: targetCategory.id,
      );

      getIt.unregister<SyncSecurityInterceptor>();
      final securityInterceptor = SyncSecurityInterceptor(
        credentialsStorage: credentialsStorage,
        hmacSigner: getIt<HmacSigner>(),
        timekeeper: getIt<UtcTimekeeper>(),
      );
      getIt.registerSingleton<SyncSecurityInterceptor>(securityInterceptor);

      getIt.unregister<DioClient>();
      final dioClient = DioClient(
        baseUrl: 'https://sync.savoryx.local',
        credentialsStorage: credentialsStorage,
        hmacSigner: getIt<HmacSigner>(),
        timekeeper: getIt<UtcTimekeeper>(),
        securityInterceptor: securityInterceptor,
        httpClientAdapter: serverAdapter,
      );
      getIt.registerSingleton<DioClient>(dioClient);

      getIt.unregister<SyncRemoteDataSource>();
      getIt.registerSingleton<SyncRemoteDataSource>(
        DioSyncRemoteDataSource(dioClient.dio),
      );
      getIt.unregister<SyncLocalDataSource>();
      getIt.registerSingleton<SyncLocalDataSource>(
        SyncLocalDataSource(database: db, cursorStorage: cursorStorage),
      );
      getIt.unregister<SyncPushService>();
      getIt.registerSingleton<SyncPushService>(
        SyncPushService(
          database: db,
          remoteDataSource: getIt<SyncRemoteDataSource>(),
        ),
      );
      getIt.unregister<SyncRepository>();
      getIt.registerSingleton<SyncRepository>(
        SyncRepositoryImpl(
          pushService: getIt<SyncPushService>(),
          remoteDataSource: getIt<SyncRemoteDataSource>(),
          localDataSource: getIt<SyncLocalDataSource>(),
        ),
      );
      getIt.unregister<PushMutationsUseCase>();
      getIt.registerSingleton<PushMutationsUseCase>(
        PushMutationsUseCase(getIt<SyncRepository>()),
      );
      getIt.unregister<PullDeltaUseCase>();
      getIt.registerSingleton<PullDeltaUseCase>(
        PullDeltaUseCase(getIt<SyncRepository>()),
      );
      getIt.unregister<WatchPendingOutboxUseCase>();
      getIt.registerSingleton<WatchPendingOutboxUseCase>(
        WatchPendingOutboxUseCase(getIt<SyncRepository>()),
      );
      getIt.unregister<ConnectivitySyncListener>();
      getIt.registerSingleton<ConnectivitySyncListener>(
        ConnectivitySyncListener(
          monitor: connectivityMonitor,
          onSyncRequested: () async {
            final bloc = getIt<SyncBloc>();
            if (bloc.isClosed) return;
            final completer = Completer<void>();
            bloc.add(
              SyncEvent.manualRequested(
                onComplete: () {
                  if (!completer.isCompleted) {
                    completer.complete();
                  }
                },
              ),
            );
            await completer.future;
          },
        ),
      );
      getIt.unregister<SyncBloc>();
      final syncBloc = SyncBloc(
        pushMutationsUseCase: getIt<PushMutationsUseCase>(),
        pullDeltaUseCase: getIt<PullDeltaUseCase>(),
        watchPendingOutboxUseCase: getIt<WatchPendingOutboxUseCase>(),
        onStartConnectivityMonitor: getIt<ConnectivitySyncListener>().start,
        onDisposeConnectivityMonitor:
            getIt<ConnectivitySyncListener>().dispose,
      );
      getIt.registerSingleton<SyncBloc>(syncBloc);

      syncBloc.add(const SyncEvent.started());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Step 1: Airplane Mode ON (Offline) — create 3 transactions + 1 category update
      final baseTime = DateTime.utc(2026, 11, 10, 7, 0, 0);
      await db.categoryDao.updateCategory(
        LocalCategoriesCompanion(
          id: Value(targetCategory.id),
          name: const Value('Makan Harian Offline'),
          updatedAt: Value(baseTime.add(const Duration(seconds: 1))),
        ),
      );

      final offlineTxIds = <String>[uuid.v7(), uuid.v7(), uuid.v7()];
      for (var i = 0; i < offlineTxIds.length; i++) {
        final txTime = baseTime.add(Duration(seconds: 2 + i));
        await db.transactionDao.insertTransaction(
          LocalTransactionsCompanion.insert(
            id: offlineTxIds[i],
            accountId: targetAccount.id,
            categoryId: Value(targetCategory.id),
            amount: BigInt.from((i + 1) * 1500000),
            baseAmount: BigInt.from((i + 1) * 1500000),
            type: 'EXPENSE',
            transactionTime: txTime,
            note: Value('Offline Tx #${i + 1}'),
            createdAt: txTime,
            updatedAt: txTime,
            isSynced: const Value(false),
          ),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Step 2: Verify local queue has 4 sequential pending mutations & isSynced == false
      final pendingOutbox = await db.outboxDao.getPendingMutations();
      expect(pendingOutbox, hasLength(4));
      expect(pendingOutbox.first.entityType, equals(OutboxEntityType.category));
      expect(pendingOutbox.first.operation, equals(OutboxOperation.update));
      for (var i = 1; i < 4; i++) {
        expect(pendingOutbox[i].entityType, equals(OutboxEntityType.transaction));
        expect(pendingOutbox[i].operation, equals(OutboxOperation.create));
        expect(pendingOutbox[i].entityId, equals(offlineTxIds[i - 1]));
      }

      final offlineCategory = await db.categoryDao.getCategoryById(targetCategory.id);
      expect(offlineCategory?.isSynced, isFalse);
      for (final txId in offlineTxIds) {
        final txRow = await db.transactionDao.getTransactionById(txId);
        expect(txRow?.isSynced, isFalse);
      }

      expect(syncBloc.state.currentPendingCount, equals(4));
      expect(serverAdapter.requests, isEmpty);

      // Step 3: Airplane Mode OFF -> Wi-Fi connected -> verify 1.5s debounce before auto Push -> Pull
      connectivityMonitor.setConnectivity(
        const <ConnectivityResult>[ConnectivityResult.wifi],
      );

      // Before debounce window expires, no HTTP requests must have fired yet.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(serverAdapter.requests, isEmpty);

      // Wait until SyncBloc finishes Push -> Pull and transitions to SyncSuccess.
      await expectLater(
        syncBloc.stream,
        emitsThrough(
          isA<SyncSuccess>().having((s) => s.pendingCount, 'pendingCount', 0),
        ),
      ).timeout(const Duration(seconds: 5));

      // Verify Push happened first, then Pull, with valid HMAC-SHA256 signatures
      expect(serverAdapter.requests, hasLength(2));
      final pushReq = serverAdapter.requests[0];
      final pullReq = serverAdapter.requests[1];
      expect(pushReq.path, equals('/api/v1/sync/push'));
      expect(pullReq.path, equals('/api/v1/sync/pull'));

      final hmacSigner = getIt<HmacSigner>();
      for (final req in serverAdapter.requests) {
        expect(req.headers['Authorization'], equals('Bearer $accessToken'));
        expect(req.headers['X-Device-ID'], equals(deviceId));
        final timestamp = req.headers['X-Timestamp'] as String?;
        final signature = req.headers['X-Signature'] as String?;
        expect(timestamp, isNotNull);
        expect(signature, isNotNull);

        final expectedSignature = hmacSigner.signRequest(
          secret: deviceSecret,
          timestampUtc: timestamp!,
          method: req.method,
          path: req.path,
          payloadJson: req.bodyString,
          delimiter: HmacSigner.pipeDelimiter,
        );
        expect(signature, equals(expectedSignature));
      }

      // Verify push payload carried all 4 offline mutations
      final pushJson = jsonDecode(pushReq.bodyString) as Map<String, dynamic>;
      expect((pushJson['categories'] as List<dynamic>), hasLength(1));
      expect((pushJson['transactions'] as List<dynamic>), hasLength(3));

      // Step 4: Verify post-sync state (empty outbox, isSynced == true, SyncSuccess, remote delta applied)
      expect(await db.outboxDao.getPendingMutations(), isEmpty);

      final syncedCategory = await db.categoryDao.getCategoryById(targetCategory.id);
      expect(syncedCategory?.isSynced, isTrue);
      expect(syncedCategory?.name, equals('Makan Harian Offline'));

      for (final txId in offlineTxIds) {
        final txRow = await db.transactionDao.getTransactionById(txId);
        expect(txRow?.isSynced, isTrue);
      }

      final remoteTxRow = await db.transactionDao.getTransactionById(remoteDeltaTxId);
      expect(remoteTxRow, isNotNull);
      expect(remoteTxRow?.isSynced, isTrue);
      expect(remoteTxRow?.amount, equals(BigInt.from(5500000)));
      expect(remoteTxRow?.note, equals('Remote Companion Device Entry'));

      expect(syncBloc.state, isA<SyncSuccess>());
      expect(syncBloc.state.currentPendingCount, equals(0));
    });
  });
}
