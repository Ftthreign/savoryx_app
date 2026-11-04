import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:savoryx/core/utils/financial_math.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

/// Top-level parser function for background isolate execution via compute().
/// Safely parses large JSON arrays of transaction payloads without freezing the UI thread.
List<TransactionModel> parseTransactionsJsonList(String jsonString) {
  final dynamic decoded = jsonDecode(jsonString);
  if (decoded is! List<dynamic>) {
    return const <TransactionModel>[];
  }
  return decoded
      .map<TransactionModel>((dynamic item) =>
          TransactionModel.fromJson(item as Map<String, dynamic>))
      .toList();
}

/// Data Transfer Object (DTO) for Transaction entity.
/// Handles type-safe JSON serialization/deserialization matching Go backend contracts.
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.accountId,
    super.destinationAccountId,
    super.categoryId,
    required super.amount,
    required super.type,
    super.note = '',
    super.currency = 'IDR',
    super.exchangeRateToBase,
    super.baseAmount,
    required super.transactionDate,
    super.isSynced = false,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON into TransactionModel.
  /// Handles numeric, string Decimal, and timestamp parsing deterministically.
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawAmount = json['amount'];
    final int parsedAmount;

    if (rawAmount is int) {
      parsedAmount = rawAmount;
    } else if (rawAmount is String) {
      parsedAmount = FinancialMath.parseCurrencyToMinorUnits(rawAmount);
    } else if (rawAmount is num) {
      parsedAmount = rawAmount.toInt();
    } else {
      parsedAmount = 0;
    }

    final String rawTxDate = json['transaction_date'] as String? ??
        json['created_at'] as String? ??
        DateTime.now().toUtc().toIso8601String();
    final String rawCreatedAt = json['created_at'] as String? ?? rawTxDate;
    final String rawUpdatedAt = json['updated_at'] as String? ?? rawCreatedAt;
    final String? rawDeletedAt = json['deleted_at'] as String?;

    final String currency = json['currency'] as String? ?? 'IDR';
    final dynamic rawRate = json['exchange_rate_to_base'];
    final BigInt? rate = rawRate != null ? BigInt.parse(rawRate.toString()) : null;
    final dynamic rawBase = json['base_amount'];
    final BigInt? base = rawBase != null ? BigInt.parse(rawBase.toString()) : null;

    return TransactionModel(
      id: json['id'] as String? ?? '',
      accountId: json['account_id'] as String? ?? '',
      destinationAccountId: json['destination_account_id'] as String?,
      categoryId: json['category_id'] as String?,
      amount: parsedAmount,
      type: TransactionType.fromString(json['type'] as String? ?? 'EXPENSE'),
      note: json['note'] as String? ?? '',
      currency: currency,
      exchangeRateToBase: rate,
      baseAmount: base,
      transactionDate: DateTime.parse(rawTxDate),
      isSynced: json['is_synced'] as bool? ?? false,
      createdAt: DateTime.parse(rawCreatedAt),
      updatedAt: DateTime.parse(rawUpdatedAt),
      deletedAt: rawDeletedAt != null ? DateTime.parse(rawDeletedAt) : null,
    );
  }

  /// Factory to convert pure domain TransactionEntity to TransactionModel.
  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      accountId: entity.accountId,
      destinationAccountId: entity.destinationAccountId,
      categoryId: entity.categoryId,
      amount: entity.amount,
      type: entity.type,
      note: entity.note,
      currency: entity.currency,
      exchangeRateToBase: entity.exchangeRateToBase,
      baseAmount: entity.baseAmount,
      transactionDate: entity.transactionDate,
      isSynced: entity.isSynced,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  /// Serializes TransactionModel to JSON matching Go PostgreSQL schema.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'account_id': accountId,
      if (destinationAccountId != null)
        'destination_account_id': destinationAccountId,
      if (categoryId != null) 'category_id': categoryId,
      'amount': amount,
      'type': type.toDbString(),
      'note': note,
      'currency': currency,
      if (exchangeRateToBase != null)
        'exchange_rate_to_base': exchangeRateToBase.toString(),
      if (baseAmount != null) 'base_amount': baseAmount.toString(),
      'transaction_date': transactionDate.toUtc().toIso8601String(),
      'is_synced': isSynced,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toUtc().toIso8601String(),
    };
  }

  /// Helper to parse a bulk JSON string in a background isolate if payload is large.
  static Future<List<TransactionModel>> computeFromRawJson(String rawJson) {
    return compute(parseTransactionsJsonList, rawJson);
  }

  @override
  TransactionModel copyWith({
    String? id,
    String? accountId,
    String? destinationAccountId,
    String? categoryId,
    int? amount,
    TransactionType? type,
    String? note,
    String? currency,
    BigInt? exchangeRateToBase,
    BigInt? baseAmount,
    DateTime? transactionDate,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      destinationAccountId:
          destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      currency: currency ?? this.currency,
      exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
      baseAmount: baseAmount ?? this.baseAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
