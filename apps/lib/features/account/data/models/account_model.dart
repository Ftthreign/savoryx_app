import 'package:savoryx/core/utils/financial_math.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';

class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.name,
    required super.type,
    super.currency = 'IDR',
    required super.balance,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

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

  /// Factory to convert pure domain AccountEntity to AccountModel.
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

  /// Serializes AccountModel to JSON matching Go PostgreSQL schema.
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

  @override
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
}
