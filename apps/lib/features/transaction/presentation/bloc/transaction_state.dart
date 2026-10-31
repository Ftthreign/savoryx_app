import 'package:equatable/equatable.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

sealed class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

final class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

final class TransactionLoaded extends TransactionState {
  const TransactionLoaded({required this.transactions});
  final List<TransactionEntity> transactions;

  @override
  List<Object?> get props => [transactions];
}

final class TransactionSuccess extends TransactionState {
  const TransactionSuccess({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

final class TransactionFailure extends TransactionState {
  const TransactionFailure({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
