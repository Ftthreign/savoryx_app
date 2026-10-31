import 'package:equatable/equatable.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

sealed class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

final class WatchTransactionsStarted extends TransactionEvent {
  const WatchTransactionsStarted({this.limit = 50});
  final int limit;

  @override
  List<Object?> get props => [limit];
}

final class TransactionsUpdated extends TransactionEvent {
  const TransactionsUpdated(this.transactions);
  final List<TransactionEntity> transactions;

  @override
  List<Object?> get props => [transactions];
}

final class TransactionSubmitted extends TransactionEvent {
  const TransactionSubmitted(this.transaction);
  final TransactionEntity transaction;

  @override
  List<Object?> get props => [transaction];
}

final class TransactionDeleted extends TransactionEvent {
  const TransactionDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
