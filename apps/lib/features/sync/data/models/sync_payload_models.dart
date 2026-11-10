import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:savoryx/core/utils/currency_converter.dart';

/// Pure integer / BigInt fixed-point decimal serializer and parser (zero floating-point).
abstract final class FixedPointDecimalCodec {
  /// Returns decimal digit scale for [currency] (2 for IDR/USD/EUR, 0 for JPY/KRW).
  static int decimalDigitsForCurrency(String currency) {
    final normalized = currency.trim().toUpperCase();
    return CurrencyConverter.supportedCurrencies[normalized]?.decimalDigits ?? 2;
  }

  /// Formats integer minor units as a fixed-point decimal string (e.g. `15000000` -> `"150000.00"`).
  static String formatMinorUnits(
    BigInt minorUnits, {
    int decimalDigits = 2,
  }) {
    if (decimalDigits <= 0) {
      return minorUnits.toString();
    }

    final isNegative = minorUnits.isNegative;
    final absVal = minorUnits.abs();
    final scale = BigInt.from(10).pow(decimalDigits);
    final whole = absVal ~/ scale;
    final fraction = (absVal % scale).toString().padLeft(decimalDigits, '0');
    return '${isNegative ? '-' : ''}$whole.$fraction';
  }

  /// Formats monetary minor units using the currency's configured decimal precision.
  static String formatCurrencyMinorUnits(
    BigInt minorUnits, {
    required String currency,
  }) {
    return formatMinorUnits(
      minorUnits,
      decimalDigits: decimalDigitsForCurrency(currency),
    );
  }

  /// Parses a fixed-point decimal string (e.g. `"150000.00"`) into exact [BigInt] minor units.
  static BigInt parseToMinorUnits(
    String decimalStr, {
    int decimalDigits = 2,
  }) {
    final trimmed = decimalStr.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Decimal string cannot be empty');
    }

    final isNegative = trimmed.startsWith('-');
    final unsigned =
        (isNegative || trimmed.startsWith('+')) ? trimmed.substring(1) : trimmed;
    final parts = unsigned.split('.');
    if (parts.length > 2) {
      throw FormatException('Invalid decimal format: $decimalStr');
    }

    final wholePart = parts[0].isEmpty ? '0' : parts[0];
    final whole = BigInt.parse(wholePart);

    if (decimalDigits <= 0) {
      return isNegative ? -whole : whole;
    }

    final rawFrac = parts.length == 2 ? parts[1] : '';
    final paddedFrac = rawFrac.length >= decimalDigits
        ? rawFrac.substring(0, decimalDigits)
        : rawFrac.padRight(decimalDigits, '0');
    final frac = BigInt.parse(paddedFrac);
    final scale = BigInt.from(10).pow(decimalDigits);
    final combined = (whole * scale) + frac;
    return isNegative ? -combined : combined;
  }

  /// Parses a currency decimal string into minor units for [currency].
  static BigInt parseCurrencyToMinorUnits(
    String decimalStr, {
    required String currency,
  }) {
    return parseToMinorUnits(
      decimalStr,
      decimalDigits: decimalDigitsForCurrency(currency),
    );
  }
}

BigInt _parseBigIntField(Object? raw, {BigInt? fallback}) {
  if (raw is BigInt) return raw;
  if (raw is int) return BigInt.from(raw);
  if (raw is String && raw.trim().isNotEmpty) {
    return BigInt.parse(raw.trim());
  }
  if (fallback != null) return fallback;
  throw FormatException('Expected BigInt-compatible value, got: $raw');
}

/// DTO representing an account item inside `POST /api/v1/sync/push`.
@immutable
class SyncAccountPayloadModel {
  const SyncAccountPayloadModel({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String type;
  final String currency;
  final String balance;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  factory SyncAccountPayloadModel.fromOutboxJson(Map<String, dynamic> json) {
    final currency = (json['currency'] as String? ?? 'IDR').toUpperCase();
    final balanceMinor = _parseBigIntField(json['balance_minor']);
    return SyncAccountPayloadModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      currency: currency,
      balance: FixedPointDecimalCodec.formatCurrencyMinorUnits(
        balanceMinor,
        currency: currency,
      ),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type,
      'currency': currency,
      'balance': balance,
      'created_at': createdAt,
      'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    };
  }
}

/// DTO representing a category item inside `POST /api/v1/sync/push`.
@immutable
class SyncCategoryPayloadModel {
  const SyncCategoryPayloadModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isWants,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isWants;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  factory SyncCategoryPayloadModel.fromOutboxJson(Map<String, dynamic> json) {
    return SyncCategoryPayloadModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isWants: json['is_wants'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'is_wants': isWants,
      'created_at': createdAt,
      'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    };
  }
}

/// DTO representing a transaction item inside `POST /api/v1/sync/push`.
@immutable
class SyncTransactionPayloadModel {
  const SyncTransactionPayloadModel({
    required this.id,
    required this.accountId,
    this.categoryId,
    this.destinationAccountId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.exchangeRateToBase,
    required this.baseAmount,
    this.note,
    this.isTalangan = false,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String accountId;
  final String? categoryId;
  final String? destinationAccountId;
  final String type;
  final String amount;
  final String currency;
  final String exchangeRateToBase;
  final String baseAmount;
  final String? note;
  final bool isTalangan;
  final String transactionDate;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  factory SyncTransactionPayloadModel.fromOutboxJson(
    Map<String, dynamic> json,
  ) {
    final currency = (json['currency'] as String? ?? 'IDR').toUpperCase();
    final amountMinor = _parseBigIntField(json['amount_minor']);
    final rateScaled = _parseBigIntField(
      json['exchange_rate_to_base'],
      fallback: CurrencyConverter.rateScale,
    );
    final baseAmountMinor = _parseBigIntField(
      json['base_amount_minor'],
      fallback: amountMinor,
    );

    return SyncTransactionPayloadModel(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
      destinationAccountId: json['destination_account_id'] as String?,
      type: json['type'] as String,
      amount: FixedPointDecimalCodec.formatCurrencyMinorUnits(
        amountMinor,
        currency: currency,
      ),
      currency: currency,
      exchangeRateToBase: FixedPointDecimalCodec.formatMinorUnits(
        rateScaled,
        decimalDigits: 6,
      ),
      baseAmount: FixedPointDecimalCodec.formatCurrencyMinorUnits(
        baseAmountMinor,
        currency: CurrencyConverter.defaultBaseCurrency,
      ),
      note: json['note'] as String?,
      isTalangan: json['is_talangan'] as bool? ?? false,
      transactionDate: json['transaction_date'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'account_id': accountId,
      if (categoryId != null && categoryId!.isNotEmpty)
        'category_id': categoryId,
      if (destinationAccountId != null && destinationAccountId!.isNotEmpty)
        'destination_account_id': destinationAccountId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'exchange_rate_to_base': exchangeRateToBase,
      'base_amount': baseAmount,
      if (note != null) 'note': note,
      'is_talangan': isTalangan,
      'transaction_date': transactionDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    };
  }
}

/// Batch payload sent to `POST /api/v1/sync/push`.
@immutable
class SyncPushRequestModel {
  const SyncPushRequestModel({
    required this.accounts,
    required this.categories,
    required this.transactions,
  });

  final List<SyncAccountPayloadModel> accounts;
  final List<SyncCategoryPayloadModel> categories;
  final List<SyncTransactionPayloadModel> transactions;

  bool get isEmpty =>
      accounts.isEmpty && categories.isEmpty && transactions.isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accounts': accounts.map((a) => a.toJson()).toList(growable: false),
      'categories': categories.map((c) => c.toJson()).toList(growable: false),
      'transactions':
          transactions.map((t) => t.toJson()).toList(growable: false),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Response returned by `POST /api/v1/sync/push`.
@immutable
class SyncPushResponseModel {
  const SyncPushResponseModel({
    required this.accountsApplied,
    required this.categoriesApplied,
    required this.transactionsApplied,
    required this.syncedAt,
  });

  final int accountsApplied;
  final int categoriesApplied;
  final int transactionsApplied;
  final DateTime syncedAt;

  factory SyncPushResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return SyncPushResponseModel(
      accountsApplied: payload['accounts_applied'] as int? ?? 0,
      categoriesApplied: payload['categories_applied'] as int? ?? 0,
      transactionsApplied: payload['transactions_applied'] as int? ?? 0,
      syncedAt: DateTime.tryParse(payload['synced_at'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}

DateTime _parseRequiredUtcTimestamp(Object? raw, String fieldName) {
  if (raw is String && raw.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) {
      return parsed.toUtc();
    }
  }
  throw FormatException('Invalid timestamp for $fieldName: $raw');
}

DateTime? _parseNullableUtcTimestamp(Object? raw) {
  if (raw == null) return null;
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim())?.toUtc();
  }
  return null;
}

/// Remote account snapshot received from `POST /api/v1/sync/pull`.
@immutable
class SyncRemoteAccountModel {
  const SyncRemoteAccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balanceMinor,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String type;
  final String currency;
  final BigInt balanceMinor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory SyncRemoteAccountModel.fromJson(Map<String, dynamic> json) {
    final currency = (json['currency'] as String? ?? 'IDR').toUpperCase();
    final balanceStr = json['balance']?.toString() ?? '0';
    return SyncRemoteAccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      currency: currency,
      balanceMinor: FixedPointDecimalCodec.parseCurrencyToMinorUnits(
        balanceStr,
        currency: currency,
      ),
      createdAt: _parseRequiredUtcTimestamp(json['created_at'], 'created_at'),
      updatedAt: _parseRequiredUtcTimestamp(json['updated_at'], 'updated_at'),
      deletedAt: _parseNullableUtcTimestamp(json['deleted_at']),
    );
  }
}

/// Remote category snapshot received from `POST /api/v1/sync/pull`.
@immutable
class SyncRemoteCategoryModel {
  const SyncRemoteCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isWants,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isWants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory SyncRemoteCategoryModel.fromJson(Map<String, dynamic> json) {
    return SyncRemoteCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isWants: json['is_wants'] as bool? ?? false,
      createdAt: _parseRequiredUtcTimestamp(json['created_at'], 'created_at'),
      updatedAt: _parseRequiredUtcTimestamp(json['updated_at'], 'updated_at'),
      deletedAt: _parseNullableUtcTimestamp(json['deleted_at']),
    );
  }
}

/// Remote transaction snapshot received from `POST /api/v1/sync/pull`.
@immutable
class SyncRemoteTransactionModel {
  const SyncRemoteTransactionModel({
    required this.id,
    required this.accountId,
    this.categoryId,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.exchangeRateToBase,
    required this.baseAmountMinor,
    this.note,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String accountId;
  final String? categoryId;
  final String type;
  final BigInt amountMinor;
  final String currency;
  final BigInt exchangeRateToBase;
  final BigInt baseAmountMinor;
  final String? note;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory SyncRemoteTransactionModel.fromJson(Map<String, dynamic> json) {
    final currency = (json['currency'] as String? ?? 'IDR').toUpperCase();
    final amountMinor = FixedPointDecimalCodec.parseCurrencyToMinorUnits(
      json['amount']?.toString() ?? '0',
      currency: currency,
    );
    final rateRaw = json['exchange_rate_to_base']?.toString() ?? '1.000000';
    final rateScaled = FixedPointDecimalCodec.parseToMinorUnits(
      rateRaw,
      decimalDigits: 6,
    );
    final baseAmountRaw = json['base_amount']?.toString();
    final baseAmountMinor = baseAmountRaw != null && baseAmountRaw.isNotEmpty
        ? FixedPointDecimalCodec.parseCurrencyToMinorUnits(
            baseAmountRaw,
            currency: CurrencyConverter.defaultBaseCurrency,
          )
        : amountMinor;

    return SyncRemoteTransactionModel(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
      type: json['type'] as String,
      amountMinor: amountMinor,
      currency: currency,
      exchangeRateToBase: rateScaled,
      baseAmountMinor: baseAmountMinor,
      note: json['note'] as String?,
      transactionDate: _parseRequiredUtcTimestamp(
        json['transaction_date'],
        'transaction_date',
      ),
      createdAt: _parseRequiredUtcTimestamp(json['created_at'], 'created_at'),
      updatedAt: _parseRequiredUtcTimestamp(json['updated_at'], 'updated_at'),
      deletedAt: _parseNullableUtcTimestamp(json['deleted_at']),
    );
  }
}

/// Delta response returned by `POST /api/v1/sync/pull` or `GET /api/v1/sync/pull`.
@immutable
class SyncPullResponseModel {
  const SyncPullResponseModel({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.pulledAt,
  });

  final List<SyncRemoteAccountModel> accounts;
  final List<SyncRemoteCategoryModel> categories;
  final List<SyncRemoteTransactionModel> transactions;
  final DateTime pulledAt;

  factory SyncPullResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawAccounts = payload['accounts'] as List<dynamic>? ?? const [];
    final rawCategories = payload['categories'] as List<dynamic>? ?? const [];
    final rawTransactions =
        payload['transactions'] as List<dynamic>? ?? const [];

    final cursorRaw = payload['server_time'] ?? payload['pulled_at'];

    return SyncPullResponseModel(
      accounts: rawAccounts
          .cast<Map<String, dynamic>>()
          .map(SyncRemoteAccountModel.fromJson)
          .toList(growable: false),
      categories: rawCategories
          .cast<Map<String, dynamic>>()
          .map(SyncRemoteCategoryModel.fromJson)
          .toList(growable: false),
      transactions: rawTransactions
          .cast<Map<String, dynamic>>()
          .map(SyncRemoteTransactionModel.fromJson)
          .toList(growable: false),
      pulledAt: _parseNullableUtcTimestamp(cursorRaw) ?? DateTime.now().toUtc(),
    );
  }
}
