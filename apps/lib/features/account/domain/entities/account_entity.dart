import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_entity.freezed.dart';

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
@freezed
class AccountEntity with _$AccountEntity {
  const AccountEntity._();

  const factory AccountEntity({
    required String id,
    required String name,
    required AccountType type,
    @Default('IDR') String currency,
    required int balance,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _AccountEntity;

  bool get isDeleted => deletedAt != null;
}
