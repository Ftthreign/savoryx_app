// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../../features/search/data/repositories/search_repository_impl.dart' as _i14;
import '../../features/search/domain/repositories/search_repository.dart' as _i15;
import '../../features/search/domain/usecases/search_transactions_usecase.dart' as _i16;
import '../../features/search/presentation/bloc/search_bloc.dart' as _i17;
import '../../features/settings/presentation/bloc/theme_cubit.dart' as _i4;
import '../../features/transaction/data/datasources/transaction_local_datasource.dart'
    as _i5;
import '../../features/transaction/data/repositories/exchange_rate_repository_impl.dart'
    as _i18;
import '../../features/transaction/data/repositories/syncable_repository_impl.dart'
    as _i9;
import '../../features/transaction/data/repositories/transaction_repository_impl.dart'
    as _i7;
import '../../features/transaction/domain/repositories/exchange_rate_repository.dart'
    as _i19;
import '../../features/transaction/domain/repositories/syncable_repository.dart'
    as _i8;
import '../../features/transaction/domain/repositories/transaction_repository.dart'
    as _i6;
import '../../features/transaction/domain/usecases/convert_currency_usecase.dart'
    as _i20;
import '../../features/transaction/domain/usecases/create_transaction_usecase.dart'
    as _i10;
import '../../features/transaction/domain/usecases/delete_transaction_usecase.dart'
    as _i11;
import '../../features/transaction/domain/usecases/get_exchange_rates_usecase.dart'
    as _i21;
import '../../features/transaction/domain/usecases/watch_recent_transactions_usecase.dart'
    as _i12;
import '../../features/transaction/presentation/bloc/currency_bloc.dart' as _i22;
import '../../features/transaction/presentation/bloc/transaction_bloc.dart'
    as _i13;
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
    gh.lazySingleton<_i5.TransactionLocalDataSource>(
        () => _i5.TransactionLocalDataSourceImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i6.TransactionRepository>(() =>
        _i7.TransactionRepositoryImpl(gh<_i5.TransactionLocalDataSource>()));
    gh.lazySingleton<_i8.TransactionSyncableRepository>(() =>
        _i9.TransactionSyncableRepositoryImpl(
            gh<_i5.TransactionLocalDataSource>()));
    gh.lazySingleton<_i10.CreateTransactionUseCase>(
        () => _i10.CreateTransactionUseCase(gh<_i6.TransactionRepository>()));
    gh.lazySingleton<_i11.DeleteTransactionUseCase>(
        () => _i11.DeleteTransactionUseCase(gh<_i6.TransactionRepository>()));
    gh.lazySingleton<_i12.WatchRecentTransactionsUseCase>(() =>
        _i12.WatchRecentTransactionsUseCase(gh<_i6.TransactionRepository>()));
    gh.lazySingleton<_i13.TransactionBloc>(() => _i13.TransactionBloc(
          createTransactionUseCase: gh<_i10.CreateTransactionUseCase>(),
          watchRecentTransactionsUseCase:
              gh<_i12.WatchRecentTransactionsUseCase>(),
          deleteTransactionUseCase: gh<_i11.DeleteTransactionUseCase>(),
        ));

    // Sprint 3: Search Clean Architecture
    gh.lazySingleton<_i15.SearchRepository>(
        () => _i14.SearchRepositoryImpl(gh<_i3.AppDatabase>()));
    gh.lazySingleton<_i16.SearchTransactionsUseCase>(
        () => _i16.SearchTransactionsUseCase(gh<_i15.SearchRepository>()));
    gh.lazySingleton<_i17.SearchBloc>(() => _i17.SearchBloc(
          searchTransactionsUseCase: gh<_i16.SearchTransactionsUseCase>(),
        ));

    // Sprint 3: Multi-Currency Clean Architecture
    gh.lazySingleton<_i19.ExchangeRateRepository>(() =>
        _i18.ExchangeRateRepositoryImpl(gh<_i3.AppDatabase>().exchangeRateDao));
    gh.lazySingleton<_i21.GetExchangeRatesUseCase>(() =>
        _i21.GetExchangeRatesUseCase(gh<_i19.ExchangeRateRepository>()));
    gh.lazySingleton<_i20.ConvertCurrencyUseCase>(() =>
        _i20.ConvertCurrencyUseCase(gh<_i19.ExchangeRateRepository>()));
    gh.lazySingleton<_i22.CurrencyBloc>(() => _i22.CurrencyBloc(
          getExchangeRatesUseCase: gh<_i21.GetExchangeRatesUseCase>(),
        ));

    return this;
  }
}
