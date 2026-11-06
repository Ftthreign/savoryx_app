import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_entity.freezed.dart';

enum TransactionType {
  expense,
  income,
  transfer;

  String get displayName {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'EXPENSE':
        return TransactionType.expense;
      case 'INCOME':
        return TransactionType.income;
      case 'TRANSFER':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  String toDbString() {
    switch (this) {
      case TransactionType.expense:
        return 'EXPENSE';
      case TransactionType.income:
        return 'INCOME';
      case TransactionType.transfer:
        return 'TRANSFER';
    }
  }
}

@freezed
class TransactionEntity with _$TransactionEntity {
  const TransactionEntity._();

  const factory TransactionEntity({
    required String id,
    required String accountId,
    String? destinationAccountId,
    String? categoryId,
    required int amount,
    required TransactionType type,
    @Default('') String note,
    @Default('IDR') String currency,
    BigInt? exchangeRateToBase,
    BigInt? baseAmount,
    required DateTime transactionDate,
    @Default(false) bool isSynced,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _TransactionEntity;

  bool get isDeleted => deletedAt != null;
}
