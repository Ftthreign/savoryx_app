// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../../features/settings/presentation/bloc/theme_cubit.dart' as _i4;
import '../../features/transaction/data/datasources/transaction_local_datasource.dart'
    as _i5;
import '../../features/transaction/data/repositories/transaction_repository_impl.dart'
    as _i7;
import '../../features/transaction/domain/repositories/transaction_repository.dart'
    as _i6;
import '../../features/transaction/domain/usecases/create_transaction_usecase.dart'
    as _i8;
import '../../features/transaction/domain/usecases/delete_transaction_usecase.dart'
    as _i9;
import '../../features/transaction/domain/usecases/watch_recent_transactions_usecase.dart'
    as _i10;
import '../../features/transaction/presentation/bloc/transaction_bloc.dart'
    as _i11;
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
    gh.lazySingleton<_i8.CreateTransactionUseCase>(
        () => _i8.CreateTransactionUseCase(gh<_i6.TransactionRepository>()));
    gh.lazySingleton<_i9.DeleteTransactionUseCase>(
        () => _i9.DeleteTransactionUseCase(gh<_i6.TransactionRepository>()));
    gh.lazySingleton<_i10.WatchRecentTransactionsUseCase>(() =>
        _i10.WatchRecentTransactionsUseCase(gh<_i6.TransactionRepository>()));
    gh.lazySingleton<_i11.TransactionBloc>(() => _i11.TransactionBloc(
          createTransactionUseCase: gh<_i8.CreateTransactionUseCase>(),
          watchRecentTransactionsUseCase:
              gh<_i10.WatchRecentTransactionsUseCase>(),
          deleteTransactionUseCase: gh<_i9.DeleteTransactionUseCase>(),
        ));
    return this;
  }
}
