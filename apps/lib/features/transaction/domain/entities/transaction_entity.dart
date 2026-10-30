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

class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.accountId,
    this.destinationAccountId,
    this.categoryId,
    required this.amount,
    required this.type,
    this.note = '',
    required this.transactionDate,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final int amount;
  final TransactionType type;
  final String note;
  final DateTime transactionDate;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  TransactionEntity copyWith({
    String? id,
    String? accountId,
    String? destinationAccountId,
    String? categoryId,
    int? amount,
    TransactionType? type,
    String? note,
    DateTime? transactionDate,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionEntity &&
        other.id == id &&
        other.accountId == accountId &&
        other.destinationAccountId == destinationAccountId &&
        other.categoryId == categoryId &&
        other.amount == amount &&
        other.type == type &&
        other.note == note &&
        other.transactionDate == transactionDate &&
        other.isSynced == isSynced &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        accountId,
        destinationAccountId,
        categoryId,
        amount,
        type,
        note,
        transactionDate,
        isSynced,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
