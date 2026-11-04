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
    as _i6;
import '../../features/account/domain/repositories/account_repository.dart'
    as _i5;
import '../../features/account/domain/usecases/create_account_usecase.dart'
    as _i7;
import '../../features/account/domain/usecases/delete_account_usecase.dart'
    as _i8;
import '../../features/account/domain/usecases/get_account_by_id_usecase.dart'
    as _i10;
import '../../features/account/domain/usecases/get_accounts_usecase.dart'
    as _i9;
import '../../features/account/domain/usecases/update_account_balance_usecase.dart'
    as _i11;
import '../../features/account/domain/usecases/update_account_usecase.dart'
    as _i12;
import '../../features/account/domain/usecases/watch_accounts_usecase.dart'
    as _i13;
import '../../features/category/data/repositories/category_repository_impl.dart'
    as _i16;
import '../../features/category/domain/repositories/category_repository.dart'
    as _i15;
import '../../features/category/domain/usecases/create_category_usecase.dart'
    as _i24;
import '../../features/category/domain/usecases/delete_category_usecase.dart'
    as _i25;
import '../../features/category/domain/usecases/get_categories_usecase.dart'
    as _i26;
import '../../features/category/domain/usecases/get_category_by_id_usecase.dart'
    as _i27;
import '../../features/category/domain/usecases/update_category_usecase.dart'
    as _i28;
import '../../features/category/domain/usecases/watch_categories_by_budget_usecase.dart'
    as _i29;
import '../../features/category/domain/usecases/watch_categories_usecase.dart'
    as _i30;
import '../../features/settings/presentation/bloc/theme_cubit.dart' as _i4;
import '../../features/transaction/data/datasources/transaction_local_datasource.dart'
    as _i14;
import '../../features/transaction/data/repositories/syncable_repository_impl.dart'
    as _i20;
import '../../features/transaction/data/repositories/transaction_repository_impl.dart'
    as _i18;
import '../../features/transaction/domain/repositories/syncable_repository.dart'
    as _i19;
import '../../features/transaction/domain/repositories/transaction_repository.dart'
    as _i17;
import '../../features/transaction/domain/usecases/create_transaction_usecase.dart'
    as _i21;
import '../../features/transaction/domain/usecases/delete_transaction_usecase.dart'
    as _i22;
import '../../features/transaction/domain/usecases/watch_recent_transactions_usecase.dart'
    as _i23;
import '../../features/transaction/presentation/bloc/transaction_bloc.dart'
    as _i31;
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
    gh.lazySingleton<_i5.AccountRepository>(
        () => _i6.AccountRepositoryImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i7.CreateAccountUseCase>(
        () => _i7.CreateAccountUseCase(gh<_i5.AccountRepository>()));
    gh.lazySingleton<_i8.DeleteAccountUseCase>(
        () => _i8.DeleteAccountUseCase(gh<_i5.AccountRepository>()));
    gh.lazySingleton<_i9.GetAccountsUseCase>(
        () => _i9.GetAccountsUseCase(gh<_i5.AccountRepository>()));
    gh.lazySingleton<_i10.GetAccountByIdUseCase>(
        () => _i10.GetAccountByIdUseCase(gh<_i5.AccountRepository>()));
    gh.lazySingleton<_i11.UpdateAccountBalanceUseCase>(
        () => _i11.UpdateAccountBalanceUseCase(gh<_i5.AccountRepository>()));
    gh.lazySingleton<_i12.UpdateAccountUseCase>(
        () => _i12.UpdateAccountUseCase(gh<_i5.AccountRepository>()));
    gh.lazySingleton<_i13.WatchAccountsUseCase>(
        () => _i13.WatchAccountsUseCase(gh<_i5.AccountRepository>()));
    gh.lazySingleton<_i14.TransactionLocalDataSource>(
        () => _i14.TransactionLocalDataSourceImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i15.CategoryRepository>(
        () => _i16.CategoryRepositoryImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i17.TransactionRepository>(() =>
        _i18.TransactionRepositoryImpl(gh<_i14.TransactionLocalDataSource>()));
    gh.lazySingleton<_i19.TransactionSyncableRepository>(() =>
        _i20.TransactionSyncableRepositoryImpl(
            gh<_i14.TransactionLocalDataSource>()));
    gh.lazySingleton<_i21.CreateTransactionUseCase>(
        () => _i21.CreateTransactionUseCase(gh<_i17.TransactionRepository>()));
    gh.lazySingleton<_i22.DeleteTransactionUseCase>(
        () => _i22.DeleteTransactionUseCase(gh<_i17.TransactionRepository>()));
    gh.lazySingleton<_i23.WatchRecentTransactionsUseCase>(() =>
        _i23.WatchRecentTransactionsUseCase(gh<_i17.TransactionRepository>()));
    gh.lazySingleton<_i24.CreateCategoryUseCase>(
        () => _i24.CreateCategoryUseCase(gh<_i15.CategoryRepository>()));
    gh.lazySingleton<_i25.DeleteCategoryUseCase>(
        () => _i25.DeleteCategoryUseCase(gh<_i15.CategoryRepository>()));
    gh.lazySingleton<_i26.GetCategoriesUseCase>(
        () => _i26.GetCategoriesUseCase(gh<_i15.CategoryRepository>()));
    gh.lazySingleton<_i27.GetCategoryByIdUseCase>(
        () => _i27.GetCategoryByIdUseCase(gh<_i15.CategoryRepository>()));
    gh.lazySingleton<_i28.UpdateCategoryUseCase>(
        () => _i28.UpdateCategoryUseCase(gh<_i15.CategoryRepository>()));
    gh.lazySingleton<_i29.WatchCategoriesByBudgetUseCase>(() =>
        _i29.WatchCategoriesByBudgetUseCase(gh<_i15.CategoryRepository>()));
    gh.lazySingleton<_i30.WatchCategoriesUseCase>(
        () => _i30.WatchCategoriesUseCase(gh<_i15.CategoryRepository>()));
    gh.lazySingleton<_i31.TransactionBloc>(() => _i31.TransactionBloc(
          createTransactionUseCase: gh<_i21.CreateTransactionUseCase>(),
          watchRecentTransactionsUseCase:
              gh<_i23.WatchRecentTransactionsUseCase>(),
          deleteTransactionUseCase: gh<_i22.DeleteTransactionUseCase>(),
        ));
    return this;
  }
}
