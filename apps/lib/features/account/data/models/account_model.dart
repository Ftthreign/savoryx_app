import 'package:savoryx/core/utils/financial_math.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';

class AccountModel {
  const AccountModel({
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

  AccountEntity toEntity() {
    return AccountEntity(
      id: id,
      name: name,
      type: type,
      currency: currency,
      balance: balance,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawBalance = json['balance'];
    final int parsedBalance;

    if (rawBalance is int) {
      parsedBalance = rawBalance;
    } else if (rawBalance is String) {
      final String currency = json['currency'] as String? ?? 'IDR';
      parsedBalance = FinancialMath.parseCurrencyToMinorUnits(
        rawBalance,
        decimalPlaces: currency.toUpperCase() == 'IDR' ? 0 : 2,
      );
    } else if (rawBalance is num) {
      parsedBalance = rawBalance.toInt();
    } else {
      parsedBalance = 0;
    }

    final String rawCreatedAt = json['created_at'] as String? ??
        DateTime.now().toUtc().toIso8601String();
    final String rawUpdatedAt = json['updated_at'] as String? ?? rawCreatedAt;
    final String? rawDeletedAt = json['deleted_at'] as String?;

    return AccountModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: AccountType.fromString(json['type'] as String? ?? 'CASH'),
      currency: json['currency'] as String? ?? 'IDR',
      balance: parsedBalance,
      createdAt: DateTime.parse(rawCreatedAt),
      updatedAt: DateTime.parse(rawUpdatedAt),
      deletedAt: rawDeletedAt != null ? DateTime.parse(rawDeletedAt) : null,
    );
  }

  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      currency: entity.currency,
      balance: entity.balance,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.toDbString(),
      'currency': currency,
      'balance': balance,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toUtc().toIso8601String(),
    };
  }

  AccountModel copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? currency,
    int? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return AccountModel(
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
    return other is AccountModel &&
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
