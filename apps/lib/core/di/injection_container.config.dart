// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../../features/account/data/repositories/account_repository_impl.dart'
    as _i16;
import '../../features/account/domain/repositories/account_repository.dart'
    as _i15;
import '../../features/account/domain/usecases/create_account_usecase.dart'
    as _i17;
import '../../features/account/domain/usecases/delete_account_usecase.dart'
    as _i18;
import '../../features/account/domain/usecases/get_account_by_id_usecase.dart'
    as _i20;
import '../../features/account/domain/usecases/get_accounts_usecase.dart'
    as _i19;
import '../../features/account/domain/usecases/update_account_balance_usecase.dart'
    as _i21;
import '../../features/account/domain/usecases/update_account_usecase.dart'
    as _i22;
import '../../features/account/domain/usecases/watch_accounts_usecase.dart'
    as _i23;
import '../../features/category/data/repositories/category_repository_impl.dart'
    as _i27;
import '../../features/category/domain/repositories/category_repository.dart'
    as _i26;
import '../../features/category/domain/usecases/create_category_usecase.dart'
    as _i39;
import '../../features/category/domain/usecases/delete_category_usecase.dart'
    as _i40;
import '../../features/category/domain/usecases/get_categories_usecase.dart'
    as _i41;
import '../../features/category/domain/usecases/get_category_by_id_usecase.dart'
    as _i42;
import '../../features/category/domain/usecases/update_category_usecase.dart'
    as _i43;
import '../../features/category/domain/usecases/watch_categories_by_budget_usecase.dart'
    as _i44;
import '../../features/category/domain/usecases/watch_categories_usecase.dart'
    as _i45;
import '../../features/navigation/domain/usecases/calculate_safe_to_spend_usecase.dart'
    as _i8;
import '../../features/navigation/domain/usecases/stash_impulse_fund_usecase.dart'
    as _i47;
import '../../features/navigation/presentation/bloc/overview_bloc.dart' as _i51;
import '../../features/settings/presentation/bloc/theme_cubit.dart' as _i9;
import '../../features/sync/data/datasources/connectivity_sync_listener.dart'
    as _i7;
import '../../features/sync/data/datasources/sync_local_datasource.dart' as _i6;
import '../../features/sync/data/datasources/sync_remote_datasource.dart'
    as _i24;
import '../../features/sync/domain/repositories/sync_repository.dart' as _i33;
import '../../features/sync/domain/usecases/pull_delta_usecase.dart' as _i49;
import '../../features/sync/domain/usecases/push_mutations_usecase.dart'
    as _i48;
import '../../features/sync/domain/usecases/watch_pending_outbox_usecase.dart'
    as _i50;
import '../../features/sync/presentation/bloc/sync_bloc.dart' as _i52;
import '../../features/transaction/data/datasources/transaction_local_datasource.dart'
    as _i25;
import '../../features/transaction/data/repositories/exchange_rate_repository_impl.dart'
    as _i13;
import '../../features/transaction/data/repositories/syncable_repository_impl.dart'
    as _i35;
import '../../features/transaction/data/repositories/transaction_repository_impl.dart'
    as _i30;
import '../../features/transaction/domain/repositories/exchange_rate_repository.dart'
    as _i12;
import '../../features/transaction/domain/repositories/syncable_repository.dart'
    as _i34;
import '../../features/transaction/domain/repositories/transaction_repository.dart'
    as _i29;
import '../../features/transaction/domain/usecases/convert_currency_usecase.dart'
    as _i31;
import '../../features/transaction/domain/usecases/create_transaction_usecase.dart'
    as _i36;
import '../../features/transaction/domain/usecases/delete_transaction_usecase.dart'
    as _i37;
import '../../features/transaction/domain/usecases/get_exchange_rates_usecase.dart'
    as _i28;
import '../../features/transaction/domain/usecases/watch_recent_transactions_usecase.dart'
    as _i38;
import '../../features/transaction/presentation/bloc/currency_bloc.dart'
    as _i32;
import '../../features/transaction/presentation/bloc/transaction_bloc.dart'
    as _i46;
import '../database/app_database.dart' as _i3;
import '../database/daos/outbox_dao.dart' as _i10;
import '../network/dio_client.dart' as _i14;
import '../network/interceptors/sync_security_interceptor.dart' as _i11;
import '../security/device_credentials_storage.dart' as _i5;
import '../security/hmac_signer.dart' as _i4;
import 'injection_container.dart' as _i53;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final syncModule = _$SyncModule();
    gh.lazySingleton<_i3.AppDatabase>(() => _i3.AppDatabase());
    gh.lazySingleton<_i4.HmacSigner>(() => syncModule.hmacSigner);
    gh.lazySingleton<_i4.UtcTimekeeper>(() => syncModule.utcTimekeeper());
    gh.lazySingleton<_i5.DeviceCredentialsStorage>(
        () => syncModule.deviceCredentialsStorage());
    gh.lazySingleton<_i6.SyncCursorStorage>(
        () => syncModule.syncCursorStorage());
    gh.lazySingleton<_i7.NetworkConnectivityMonitor>(
        () => syncModule.networkConnectivityMonitor());
    gh.lazySingleton<_i8.CalculateSafeToSpendUseCase>(
        () => const _i8.CalculateSafeToSpendUseCase());
    gh.lazySingleton<_i9.ThemeCubit>(() => _i9.ThemeCubit());
    gh.lazySingleton<_i6.SyncLocalDataSource>(
        () => syncModule.syncLocalDataSource(
              gh<_i3.AppDatabase>(),
              gh<_i6.SyncCursorStorage>(),
            ));
    gh.lazySingleton<_i10.OutboxDao>(
        () => syncModule.outboxDao(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i11.SyncSecurityInterceptor>(
        () => syncModule.syncSecurityInterceptor(
              gh<_i5.DeviceCredentialsStorage>(),
              gh<_i4.HmacSigner>(),
              gh<_i4.UtcTimekeeper>(),
            ));
    gh.lazySingleton<_i12.ExchangeRateRepository>(() =>
        _i13.ExchangeRateRepositoryImpl.fromDatabase(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i14.DioClient>(() => syncModule.dioClient(
          gh<_i5.DeviceCredentialsStorage>(),
          gh<_i4.HmacSigner>(),
          gh<_i4.UtcTimekeeper>(),
          gh<_i11.SyncSecurityInterceptor>(),
        ));
    gh.lazySingleton<_i15.AccountRepository>(
        () => _i16.AccountRepositoryImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i17.CreateAccountUseCase>(
        () => _i17.CreateAccountUseCase(gh<_i15.AccountRepository>()));
    gh.lazySingleton<_i18.DeleteAccountUseCase>(
        () => _i18.DeleteAccountUseCase(gh<_i15.AccountRepository>()));
    gh.lazySingleton<_i19.GetAccountsUseCase>(
        () => _i19.GetAccountsUseCase(gh<_i15.AccountRepository>()));
    gh.lazySingleton<_i20.GetAccountByIdUseCase>(
        () => _i20.GetAccountByIdUseCase(gh<_i15.AccountRepository>()));
    gh.lazySingleton<_i21.UpdateAccountBalanceUseCase>(
        () => _i21.UpdateAccountBalanceUseCase(gh<_i15.AccountRepository>()));
    gh.lazySingleton<_i22.UpdateAccountUseCase>(
        () => _i22.UpdateAccountUseCase(gh<_i15.AccountRepository>()));
    gh.lazySingleton<_i23.WatchAccountsUseCase>(
        () => _i23.WatchAccountsUseCase(gh<_i15.AccountRepository>()));
    gh.lazySingleton<_i24.SyncRemoteDataSource>(
        () => syncModule.syncRemoteDataSource(gh<_i14.DioClient>()));
    gh.lazySingleton<_i7.ConnectivitySyncListener>(() => syncModule
        .connectivitySyncListener(gh<_i7.NetworkConnectivityMonitor>()));
    gh.lazySingleton<_i25.TransactionLocalDataSource>(
        () => _i25.TransactionLocalDataSourceImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i26.CategoryRepository>(
        () => _i27.CategoryRepositoryImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i28.GetExchangeRatesUseCase>(
        () => _i28.GetExchangeRatesUseCase(gh<_i12.ExchangeRateRepository>()));
    gh.lazySingleton<_i24.SyncPushService>(() => syncModule.syncPushService(
          gh<_i3.AppDatabase>(),
          gh<_i24.SyncRemoteDataSource>(),
        ));
    gh.lazySingleton<_i29.TransactionRepository>(() =>
        _i30.TransactionRepositoryImpl(gh<_i25.TransactionLocalDataSource>()));
    gh.lazySingleton<_i31.ConvertCurrencyUseCase>(
        () => _i31.ConvertCurrencyUseCase(gh<_i12.ExchangeRateRepository>()));
    gh.lazySingleton<_i32.CurrencyBloc>(() => _i32.CurrencyBloc(
        getExchangeRatesUseCase: gh<_i28.GetExchangeRatesUseCase>()));
    gh.lazySingleton<_i33.SyncRepository>(() => syncModule.syncRepository(
          gh<_i24.SyncPushService>(),
          gh<_i24.SyncRemoteDataSource>(),
          gh<_i6.SyncLocalDataSource>(),
        ));
    gh.lazySingleton<_i34.TransactionSyncableRepository>(() =>
        _i35.TransactionSyncableRepositoryImpl(
            gh<_i25.TransactionLocalDataSource>()));
    gh.lazySingleton<_i36.CreateTransactionUseCase>(
        () => _i36.CreateTransactionUseCase(gh<_i29.TransactionRepository>()));
    gh.lazySingleton<_i37.DeleteTransactionUseCase>(
        () => _i37.DeleteTransactionUseCase(gh<_i29.TransactionRepository>()));
    gh.lazySingleton<_i38.WatchRecentTransactionsUseCase>(() =>
        _i38.WatchRecentTransactionsUseCase(gh<_i29.TransactionRepository>()));
    gh.lazySingleton<_i39.CreateCategoryUseCase>(
        () => _i39.CreateCategoryUseCase(gh<_i26.CategoryRepository>()));
    gh.lazySingleton<_i40.DeleteCategoryUseCase>(
        () => _i40.DeleteCategoryUseCase(gh<_i26.CategoryRepository>()));
    gh.lazySingleton<_i41.GetCategoriesUseCase>(
        () => _i41.GetCategoriesUseCase(gh<_i26.CategoryRepository>()));
    gh.lazySingleton<_i42.GetCategoryByIdUseCase>(
        () => _i42.GetCategoryByIdUseCase(gh<_i26.CategoryRepository>()));
    gh.lazySingleton<_i43.UpdateCategoryUseCase>(
        () => _i43.UpdateCategoryUseCase(gh<_i26.CategoryRepository>()));
    gh.lazySingleton<_i44.WatchCategoriesByBudgetUseCase>(() =>
        _i44.WatchCategoriesByBudgetUseCase(gh<_i26.CategoryRepository>()));
    gh.lazySingleton<_i45.WatchCategoriesUseCase>(
        () => _i45.WatchCategoriesUseCase(gh<_i26.CategoryRepository>()));
    gh.lazySingleton<_i46.TransactionBloc>(() => _i46.TransactionBloc(
          createTransactionUseCase: gh<_i36.CreateTransactionUseCase>(),
          watchRecentTransactionsUseCase:
              gh<_i38.WatchRecentTransactionsUseCase>(),
          deleteTransactionUseCase: gh<_i37.DeleteTransactionUseCase>(),
        ));
    gh.lazySingleton<_i47.StashImpulseFundUseCase>(
        () => _i47.StashImpulseFundUseCase(
              gh<_i15.AccountRepository>(),
              gh<_i29.TransactionRepository>(),
            ));
    gh.lazySingleton<_i48.PushMutationsUseCase>(
        () => syncModule.pushMutationsUseCase(gh<_i33.SyncRepository>()));
    gh.lazySingleton<_i49.PullDeltaUseCase>(
        () => syncModule.pullDeltaUseCase(gh<_i33.SyncRepository>()));
    gh.lazySingleton<_i50.WatchPendingOutboxUseCase>(
        () => syncModule.watchPendingOutboxUseCase(gh<_i33.SyncRepository>()));
    gh.factory<_i51.OverviewBloc>(() => _i51.OverviewBloc(
          watchAccountsUseCase: gh<_i23.WatchAccountsUseCase>(),
          watchRecentTransactionsUseCase:
              gh<_i38.WatchRecentTransactionsUseCase>(),
          calculateSafeToSpendUseCase: gh<_i8.CalculateSafeToSpendUseCase>(),
          stashImpulseFundUseCase: gh<_i47.StashImpulseFundUseCase>(),
        ));
    gh.lazySingleton<_i52.SyncBloc>(() => syncModule.syncBloc(
          gh<_i48.PushMutationsUseCase>(),
          gh<_i49.PullDeltaUseCase>(),
          gh<_i50.WatchPendingOutboxUseCase>(),
          gh<_i7.ConnectivitySyncListener>(),
        ));
    return this;
  }
}

class _$SyncModule extends _i53.SyncModule {}
