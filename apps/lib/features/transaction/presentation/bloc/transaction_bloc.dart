import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/usecases/create_transaction_usecase.dart';
import 'package:savoryx/features/transaction/domain/usecases/delete_transaction_usecase.dart';
import 'package:savoryx/features/transaction/domain/usecases/watch_recent_transactions_usecase.dart';
import 'package:savoryx/features/transaction/presentation/bloc/transaction_event.dart';
import 'package:savoryx/features/transaction/presentation/bloc/transaction_state.dart';

/// Feature-First Clean Architecture BLoC managing transaction state transitions.
@lazySingleton
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final CreateTransactionUseCase _createTransactionUseCase;
  final WatchRecentTransactionsUseCase _watchRecentTransactionsUseCase;
  final DeleteTransactionUseCase _deleteTransactionUseCase;

  TransactionBloc({
    required CreateTransactionUseCase createTransactionUseCase,
    required WatchRecentTransactionsUseCase watchRecentTransactionsUseCase,
    required DeleteTransactionUseCase deleteTransactionUseCase,
  })  : _createTransactionUseCase = createTransactionUseCase,
        _watchRecentTransactionsUseCase = watchRecentTransactionsUseCase,
        _deleteTransactionUseCase = deleteTransactionUseCase,
        super(const TransactionInitial()) {
    on<WatchTransactionsStarted>(_onWatchTransactionsStarted);
    on<TransactionsUpdated>(_onTransactionsUpdated);
    on<TransactionSubmitted>(_onTransactionSubmitted);
    on<TransactionDeleted>(_onTransactionDeleted);
  }

  Future<void> _onWatchTransactionsStarted(
    WatchTransactionsStarted event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    await emit.forEach<List<TransactionEntity>>(
      _watchRecentTransactionsUseCase(limit: event.limit),
      onData: (transactions) => TransactionLoaded(transactions: transactions),
      onError: (error, stackTrace) => TransactionFailure(message: error.toString()),
    );
  }

  void _onTransactionsUpdated(
    TransactionsUpdated event,
    Emitter<TransactionState> emit,
  ) {
    emit(TransactionLoaded(transactions: event.transactions));
  }

  Future<void> _onTransactionSubmitted(
    TransactionSubmitted event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      await _createTransactionUseCase(event.transaction);
      emit(const TransactionSuccess(message: 'Transaction saved successfully'));
    } catch (e) {
      emit(TransactionFailure(message: e.toString()));
    }
  }

  Future<void> _onTransactionDeleted(
    TransactionDeleted event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      await _deleteTransactionUseCase(event.id);
      emit(const TransactionSuccess(message: 'Transaction deleted successfully'));
    } catch (e) {
      emit(TransactionFailure(message: e.toString()));
    }
  }
}
