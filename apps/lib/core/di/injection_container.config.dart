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
    as _i7;
import '../../features/account/domain/repositories/account_repository.dart'
    as _i6;
import '../../features/account/domain/usecases/create_account_usecase.dart'
    as _i8;
import '../../features/account/domain/usecases/delete_account_usecase.dart'
    as _i9;
import '../../features/account/domain/usecases/get_account_by_id_usecase.dart'
    as _i11;
import '../../features/account/domain/usecases/get_accounts_usecase.dart'
    as _i10;
import '../../features/account/domain/usecases/update_account_balance_usecase.dart'
    as _i12;
import '../../features/account/domain/usecases/update_account_usecase.dart'
    as _i13;
import '../../features/account/domain/usecases/watch_accounts_usecase.dart'
    as _i14;
import '../../features/category/data/repositories/category_repository_impl.dart'
    as _i17;
import '../../features/category/domain/repositories/category_repository.dart'
    as _i16;
import '../../features/category/domain/usecases/create_category_usecase.dart'
    as _i25;
import '../../features/category/domain/usecases/delete_category_usecase.dart'
    as _i26;
import '../../features/category/domain/usecases/get_categories_usecase.dart'
    as _i27;
import '../../features/category/domain/usecases/get_category_by_id_usecase.dart'
    as _i28;
import '../../features/category/domain/usecases/update_category_usecase.dart'
    as _i29;
import '../../features/category/domain/usecases/watch_categories_by_budget_usecase.dart'
    as _i30;
import '../../features/category/domain/usecases/watch_categories_usecase.dart'
    as _i31;
import '../../features/navigation/domain/usecases/calculate_safe_to_spend_usecase.dart'
    as _i5;
import '../../features/navigation/domain/usecases/stash_impulse_fund_usecase.dart'
    as _i33;
import '../../features/navigation/presentation/bloc/overview_bloc.dart' as _i34;
import '../../features/settings/presentation/bloc/theme_cubit.dart' as _i4;
import '../../features/transaction/data/datasources/transaction_local_datasource.dart'
    as _i15;
import '../../features/transaction/data/repositories/syncable_repository_impl.dart'
    as _i21;
import '../../features/transaction/data/repositories/transaction_repository_impl.dart'
    as _i19;
import '../../features/transaction/domain/repositories/syncable_repository.dart'
    as _i20;
import '../../features/transaction/domain/repositories/transaction_repository.dart'
    as _i18;
import '../../features/transaction/domain/usecases/create_transaction_usecase.dart'
    as _i22;
import '../../features/transaction/domain/usecases/delete_transaction_usecase.dart'
    as _i23;
import '../../features/transaction/domain/usecases/watch_recent_transactions_usecase.dart'
    as _i24;
import '../../features/transaction/presentation/bloc/transaction_bloc.dart'
    as _i32;
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
    gh.lazySingleton<_i6.AccountRepository>(
        () => _i7.AccountRepositoryImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i8.CreateAccountUseCase>(
        () => _i8.CreateAccountUseCase(gh<_i6.AccountRepository>()));
    gh.lazySingleton<_i9.DeleteAccountUseCase>(
        () => _i9.DeleteAccountUseCase(gh<_i6.AccountRepository>()));
    gh.lazySingleton<_i10.GetAccountsUseCase>(
        () => _i10.GetAccountsUseCase(gh<_i6.AccountRepository>()));
    gh.lazySingleton<_i11.GetAccountByIdUseCase>(
        () => _i11.GetAccountByIdUseCase(gh<_i6.AccountRepository>()));
    gh.lazySingleton<_i12.UpdateAccountBalanceUseCase>(
        () => _i12.UpdateAccountBalanceUseCase(gh<_i6.AccountRepository>()));
    gh.lazySingleton<_i13.UpdateAccountUseCase>(
        () => _i13.UpdateAccountUseCase(gh<_i6.AccountRepository>()));
    gh.lazySingleton<_i14.WatchAccountsUseCase>(
        () => _i14.WatchAccountsUseCase(gh<_i6.AccountRepository>()));
    gh.lazySingleton<_i15.TransactionLocalDataSource>(
        () => _i15.TransactionLocalDataSourceImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i16.CategoryRepository>(
        () => _i17.CategoryRepositoryImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i18.TransactionRepository>(() =>
        _i19.TransactionRepositoryImpl(gh<_i15.TransactionLocalDataSource>()));
    gh.lazySingleton<_i20.TransactionSyncableRepository>(() =>
        _i21.TransactionSyncableRepositoryImpl(
            gh<_i15.TransactionLocalDataSource>()));
    gh.lazySingleton<_i22.CreateTransactionUseCase>(
        () => _i22.CreateTransactionUseCase(gh<_i18.TransactionRepository>()));
    gh.lazySingleton<_i23.DeleteTransactionUseCase>(
        () => _i23.DeleteTransactionUseCase(gh<_i18.TransactionRepository>()));
    gh.lazySingleton<_i24.WatchRecentTransactionsUseCase>(() =>
        _i24.WatchRecentTransactionsUseCase(gh<_i18.TransactionRepository>()));
    gh.lazySingleton<_i25.CreateCategoryUseCase>(
        () => _i25.CreateCategoryUseCase(gh<_i16.CategoryRepository>()));
    gh.lazySingleton<_i26.DeleteCategoryUseCase>(
        () => _i26.DeleteCategoryUseCase(gh<_i16.CategoryRepository>()));
    gh.lazySingleton<_i27.GetCategoriesUseCase>(
        () => _i27.GetCategoriesUseCase(gh<_i16.CategoryRepository>()));
    gh.lazySingleton<_i28.GetCategoryByIdUseCase>(
        () => _i28.GetCategoryByIdUseCase(gh<_i16.CategoryRepository>()));
    gh.lazySingleton<_i29.UpdateCategoryUseCase>(
        () => _i29.UpdateCategoryUseCase(gh<_i16.CategoryRepository>()));
    gh.lazySingleton<_i30.WatchCategoriesByBudgetUseCase>(() =>
        _i30.WatchCategoriesByBudgetUseCase(gh<_i16.CategoryRepository>()));
    gh.lazySingleton<_i31.WatchCategoriesUseCase>(
        () => _i31.WatchCategoriesUseCase(gh<_i16.CategoryRepository>()));
    gh.lazySingleton<_i32.TransactionBloc>(() => _i32.TransactionBloc(
          createTransactionUseCase: gh<_i22.CreateTransactionUseCase>(),
          watchRecentTransactionsUseCase:
              gh<_i24.WatchRecentTransactionsUseCase>(),
          deleteTransactionUseCase: gh<_i23.DeleteTransactionUseCase>(),
        ));
    gh.lazySingleton<_i33.StashImpulseFundUseCase>(
        () => _i33.StashImpulseFundUseCase(
              gh<_i6.AccountRepository>(),
              gh<_i18.TransactionRepository>(),
            ));
    gh.factory<_i34.OverviewBloc>(() => _i34.OverviewBloc(
          watchAccountsUseCase: gh<_i14.WatchAccountsUseCase>(),
          watchRecentTransactionsUseCase:
              gh<_i24.WatchRecentTransactionsUseCase>(),
          calculateSafeToSpendUseCase: gh<_i5.CalculateSafeToSpendUseCase>(),
          stashImpulseFundUseCase: gh<_i33.StashImpulseFundUseCase>(),
        ));
    return this;
  }
}
