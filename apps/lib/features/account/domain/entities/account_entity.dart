enum AccountType {
  cash,
  bank,
  eWallet,
  creditCard,
  investment,
  asset;

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash Pocket';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.eWallet:
        return 'E-Wallet';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.investment:
        return 'Investment';
      case AccountType.asset:
        return 'Fixed Asset';
    }
  }

  static AccountType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CASH':
        return AccountType.cash;
      case 'BANK':
        return AccountType.bank;
      case 'E_WALLET':
      case 'EWALLET':
        return AccountType.eWallet;
      case 'CREDIT_CARD':
      case 'CREDITCARD':
        return AccountType.creditCard;
      case 'INVESTMENT':
        return AccountType.investment;
      case 'ASSET':
        return AccountType.asset;
      default:
        return AccountType.cash;
    }
  }

  String toDbString() {
    switch (this) {
      case AccountType.cash:
        return 'CASH';
      case AccountType.bank:
        return 'BANK';
      case AccountType.eWallet:
        return 'E_WALLET';
      case AccountType.creditCard:
        return 'CREDIT_CARD';
      case AccountType.investment:
        return 'INVESTMENT';
      case AccountType.asset:
        return 'ASSET';
    }
  }
}

/// Pure Dart domain entity for financial account/pocket.
/// Zero-floating-point: balance is strictly stored as integer minor units.
class AccountEntity {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    this.currency = 'IDR',
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final AccountType type;
  final String currency;
  final int balance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  AccountEntity copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? currency,
    int? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountEntity &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.currency == currency &&
        other.balance == balance &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        currency,
        balance,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
