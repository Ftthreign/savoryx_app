import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/daos/outbox_dao.dart';
import 'package:savoryx/core/di/injection_container.config.dart';
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

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();

@module
abstract class SyncModule {
  @lazySingleton
  OutboxDao outboxDao(AppDatabase database) => database.outboxDao;

  @lazySingleton
  HmacSigner get hmacSigner => const HmacSigner();

  @lazySingleton
  UtcTimekeeper utcTimekeeper() => UtcTimekeeper();

  @lazySingleton
  DeviceCredentialsStorage deviceCredentialsStorage() =>
      DeviceCredentialsStorage();

  @lazySingleton
  SyncCursorStorage syncCursorStorage() => SecureSyncCursorStorage();

  @lazySingleton
  SyncSecurityInterceptor syncSecurityInterceptor(
    DeviceCredentialsStorage credentialsStorage,
    HmacSigner hmacSigner,
    UtcTimekeeper timekeeper,
  ) {
    return SyncSecurityInterceptor(
      credentialsStorage: credentialsStorage,
      hmacSigner: hmacSigner,
      timekeeper: timekeeper,
    );
  }

  @lazySingleton
  DioClient dioClient(
    DeviceCredentialsStorage credentialsStorage,
    HmacSigner hmacSigner,
    UtcTimekeeper timekeeper,
    SyncSecurityInterceptor securityInterceptor,
  ) {
    return DioClient(
      baseUrl: const String.fromEnvironment(
        'SAVORYX_API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8080',
      ),
      credentialsStorage: credentialsStorage,
      hmacSigner: hmacSigner,
      timekeeper: timekeeper,
      securityInterceptor: securityInterceptor,
    );
  }

  @lazySingleton
  SyncRemoteDataSource syncRemoteDataSource(DioClient dioClient) =>
      DioSyncRemoteDataSource(dioClient.dio);

  @lazySingleton
  SyncLocalDataSource syncLocalDataSource(
    AppDatabase database,
    SyncCursorStorage cursorStorage,
  ) {
    return SyncLocalDataSource(
      database: database,
      cursorStorage: cursorStorage,
    );
  }

  @lazySingleton
  SyncPushService syncPushService(
    AppDatabase database,
    SyncRemoteDataSource remoteDataSource,
  ) {
    return SyncPushService(
      database: database,
      remoteDataSource: remoteDataSource,
    );
  }

  @lazySingleton
  SyncRepository syncRepository(
    SyncPushService pushService,
    SyncRemoteDataSource remoteDataSource,
    SyncLocalDataSource localDataSource,
  ) {
    return SyncRepositoryImpl(
      pushService: pushService,
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );
  }

  @lazySingleton
  PushMutationsUseCase pushMutationsUseCase(SyncRepository repository) =>
      PushMutationsUseCase(repository);

  @lazySingleton
  PullDeltaUseCase pullDeltaUseCase(SyncRepository repository) =>
      PullDeltaUseCase(repository);

  @lazySingleton
  WatchPendingOutboxUseCase watchPendingOutboxUseCase(
    SyncRepository repository,
  ) =>
      WatchPendingOutboxUseCase(repository);

  @lazySingleton
  NetworkConnectivityMonitor networkConnectivityMonitor() =>
      ConnectivityPlusMonitor();

  @lazySingleton
  ConnectivitySyncListener connectivitySyncListener(
    NetworkConnectivityMonitor monitor,
  ) {
    return ConnectivitySyncListener(
      monitor: monitor,
      onSyncRequested: () async {
        if (!getIt.isRegistered<SyncBloc>()) return;
        final syncBloc = getIt<SyncBloc>();
        if (syncBloc.isClosed) return;
        final completer = Completer<void>();
        syncBloc.add(
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
    );
  }

  @lazySingleton
  SyncBloc syncBloc(
    PushMutationsUseCase pushMutationsUseCase,
    PullDeltaUseCase pullDeltaUseCase,
    WatchPendingOutboxUseCase watchPendingOutboxUseCase,
    ConnectivitySyncListener connectivityListener,
  ) {
    return SyncBloc(
      pushMutationsUseCase: pushMutationsUseCase,
      pullDeltaUseCase: pullDeltaUseCase,
      watchPendingOutboxUseCase: watchPendingOutboxUseCase,
      onStartConnectivityMonitor: connectivityListener.start,
      onDisposeConnectivityMonitor: connectivityListener.dispose,
    );
  }
}
