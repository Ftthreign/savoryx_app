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
    as _i9;
import '../../features/account/domain/repositories/account_repository.dart'
    as _i8;
import '../../features/account/domain/usecases/create_account_usecase.dart'
    as _i10;
import '../../features/account/domain/usecases/delete_account_usecase.dart'
    as _i11;
import '../../features/account/domain/usecases/get_account_by_id_usecase.dart'
    as _i13;
import '../../features/account/domain/usecases/get_accounts_usecase.dart'
    as _i12;
import '../../features/account/domain/usecases/update_account_balance_usecase.dart'
    as _i14;
import '../../features/account/domain/usecases/update_account_usecase.dart'
    as _i15;
import '../../features/account/domain/usecases/watch_accounts_usecase.dart'
    as _i16;
import '../../features/category/data/repositories/category_repository_impl.dart'
    as _i19;
import '../../features/category/domain/repositories/category_repository.dart'
    as _i18;
import '../../features/category/domain/usecases/create_category_usecase.dart'
    as _i30;
import '../../features/category/domain/usecases/delete_category_usecase.dart'
    as _i31;
import '../../features/category/domain/usecases/get_categories_usecase.dart'
    as _i32;
import '../../features/category/domain/usecases/get_category_by_id_usecase.dart'
    as _i33;
import '../../features/category/domain/usecases/update_category_usecase.dart'
    as _i34;
import '../../features/category/domain/usecases/watch_categories_by_budget_usecase.dart'
    as _i35;
import '../../features/category/domain/usecases/watch_categories_usecase.dart'
    as _i36;
import '../../features/navigation/domain/usecases/calculate_safe_to_spend_usecase.dart'
    as _i5;
import '../../features/navigation/domain/usecases/stash_impulse_fund_usecase.dart'
    as _i38;
import '../../features/navigation/presentation/bloc/overview_bloc.dart' as _i39;
import '../../features/settings/presentation/bloc/theme_cubit.dart' as _i4;
import '../../features/transaction/data/datasources/transaction_local_datasource.dart'
    as _i17;
import '../../features/transaction/data/repositories/exchange_rate_repository_impl.dart'
    as _i7;
import '../../features/transaction/data/repositories/syncable_repository_impl.dart'
    as _i26;
import '../../features/transaction/data/repositories/transaction_repository_impl.dart'
    as _i22;
import '../../features/transaction/domain/repositories/exchange_rate_repository.dart'
    as _i6;
import '../../features/transaction/domain/repositories/syncable_repository.dart'
    as _i25;
import '../../features/transaction/domain/repositories/transaction_repository.dart'
    as _i21;
import '../../features/transaction/domain/usecases/convert_currency_usecase.dart'
    as _i23;
import '../../features/transaction/domain/usecases/create_transaction_usecase.dart'
    as _i27;
import '../../features/transaction/domain/usecases/delete_transaction_usecase.dart'
    as _i28;
import '../../features/transaction/domain/usecases/get_exchange_rates_usecase.dart'
    as _i20;
import '../../features/transaction/domain/usecases/watch_recent_transactions_usecase.dart'
    as _i29;
import '../../features/transaction/presentation/bloc/currency_bloc.dart'
    as _i24;
import '../../features/transaction/presentation/bloc/transaction_bloc.dart'
    as _i37;
import '../database/app_database.dart' as _i3;

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
    gh.lazySingleton<_i3.AppDatabase>(() => _i3.AppDatabase());
    gh.lazySingleton<_i4.ThemeCubit>(() => _i4.ThemeCubit());
    gh.lazySingleton<_i5.CalculateSafeToSpendUseCase>(
        () => const _i5.CalculateSafeToSpendUseCase());
    gh.lazySingleton<_i6.ExchangeRateRepository>(() =>
        _i7.ExchangeRateRepositoryImpl.fromDatabase(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i8.AccountRepository>(
        () => _i9.AccountRepositoryImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i10.CreateAccountUseCase>(
        () => _i10.CreateAccountUseCase(gh<_i8.AccountRepository>()));
    gh.lazySingleton<_i11.DeleteAccountUseCase>(
        () => _i11.DeleteAccountUseCase(gh<_i8.AccountRepository>()));
    gh.lazySingleton<_i12.GetAccountsUseCase>(
        () => _i12.GetAccountsUseCase(gh<_i8.AccountRepository>()));
    gh.lazySingleton<_i13.GetAccountByIdUseCase>(
        () => _i13.GetAccountByIdUseCase(gh<_i8.AccountRepository>()));
    gh.lazySingleton<_i14.UpdateAccountBalanceUseCase>(
        () => _i14.UpdateAccountBalanceUseCase(gh<_i8.AccountRepository>()));
    gh.lazySingleton<_i15.UpdateAccountUseCase>(
        () => _i15.UpdateAccountUseCase(gh<_i8.AccountRepository>()));
    gh.lazySingleton<_i16.WatchAccountsUseCase>(
        () => _i16.WatchAccountsUseCase(gh<_i8.AccountRepository>()));
    gh.lazySingleton<_i17.TransactionLocalDataSource>(
        () => _i17.TransactionLocalDataSourceImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i18.CategoryRepository>(
        () => _i19.CategoryRepositoryImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i20.GetExchangeRatesUseCase>(
        () => _i20.GetExchangeRatesUseCase(gh<_i6.ExchangeRateRepository>()));
    gh.lazySingleton<_i21.TransactionRepository>(() =>
        _i22.TransactionRepositoryImpl(gh<_i17.TransactionLocalDataSource>()));
    gh.lazySingleton<_i23.ConvertCurrencyUseCase>(
        () => _i23.ConvertCurrencyUseCase(gh<_i6.ExchangeRateRepository>()));
    gh.lazySingleton<_i24.CurrencyBloc>(() => _i24.CurrencyBloc(
        getExchangeRatesUseCase: gh<_i20.GetExchangeRatesUseCase>()));
    gh.lazySingleton<_i25.TransactionSyncableRepository>(() =>
        _i26.TransactionSyncableRepositoryImpl(
            gh<_i17.TransactionLocalDataSource>()));
    gh.lazySingleton<_i27.CreateTransactionUseCase>(
        () => _i27.CreateTransactionUseCase(gh<_i21.TransactionRepository>()));
    gh.lazySingleton<_i28.DeleteTransactionUseCase>(
        () => _i28.DeleteTransactionUseCase(gh<_i21.TransactionRepository>()));
    gh.lazySingleton<_i29.WatchRecentTransactionsUseCase>(() =>
        _i29.WatchRecentTransactionsUseCase(gh<_i21.TransactionRepository>()));
    gh.lazySingleton<_i30.CreateCategoryUseCase>(
        () => _i30.CreateCategoryUseCase(gh<_i18.CategoryRepository>()));
    gh.lazySingleton<_i31.DeleteCategoryUseCase>(
        () => _i31.DeleteCategoryUseCase(gh<_i18.CategoryRepository>()));
    gh.lazySingleton<_i32.GetCategoriesUseCase>(
        () => _i32.GetCategoriesUseCase(gh<_i18.CategoryRepository>()));
    gh.lazySingleton<_i33.GetCategoryByIdUseCase>(
        () => _i33.GetCategoryByIdUseCase(gh<_i18.CategoryRepository>()));
    gh.lazySingleton<_i34.UpdateCategoryUseCase>(
        () => _i34.UpdateCategoryUseCase(gh<_i18.CategoryRepository>()));
    gh.lazySingleton<_i35.WatchCategoriesByBudgetUseCase>(() =>
        _i35.WatchCategoriesByBudgetUseCase(gh<_i18.CategoryRepository>()));
    gh.lazySingleton<_i36.WatchCategoriesUseCase>(
        () => _i36.WatchCategoriesUseCase(gh<_i18.CategoryRepository>()));
    gh.lazySingleton<_i37.TransactionBloc>(() => _i37.TransactionBloc(
          createTransactionUseCase: gh<_i27.CreateTransactionUseCase>(),
          watchRecentTransactionsUseCase:
              gh<_i29.WatchRecentTransactionsUseCase>(),
          deleteTransactionUseCase: gh<_i28.DeleteTransactionUseCase>(),
        ));
    gh.lazySingleton<_i38.StashImpulseFundUseCase>(
        () => _i38.StashImpulseFundUseCase(
              gh<_i8.AccountRepository>(),
              gh<_i21.TransactionRepository>(),
            ));
    gh.factory<_i39.OverviewBloc>(() => _i39.OverviewBloc(
          watchAccountsUseCase: gh<_i16.WatchAccountsUseCase>(),
          watchRecentTransactionsUseCase:
              gh<_i29.WatchRecentTransactionsUseCase>(),
          calculateSafeToSpendUseCase: gh<_i5.CalculateSafeToSpendUseCase>(),
          stashImpulseFundUseCase: gh<_i38.StashImpulseFundUseCase>(),
        ));
    return this;
  }
}
