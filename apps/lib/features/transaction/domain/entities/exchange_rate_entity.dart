import 'package:savoryx/core/database/daos/exchange_rate_dao.dart';

class ExchangeRateEntity {
  const ExchangeRateEntity({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rateScaled,
    required this.effectiveDate,
    required this.updatedAt,
  });

  final String baseCurrency;
  final String targetCurrency;
  final BigInt rateScaled;
  final DateTime effectiveDate;
  final DateTime updatedAt;

  static final BigInt scale = ExchangeRateDao.rateScale;

  String get displayRate {
    final intRate = rateScaled ~/ scale;
    final fracRate = (rateScaled % scale).toInt();
    final fracStr = fracRate.toString().padLeft(6, '0').substring(0, 2);
    return '$intRate.$fracStr';
  }

  ExchangeRateEntity copyWith({
    String? baseCurrency,
    String? targetCurrency,
    BigInt? rateScaled,
    DateTime? effectiveDate,
    DateTime? updatedAt,
  }) {
    return ExchangeRateEntity(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      rateScaled: rateScaled ?? this.rateScaled,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRateEntity &&
          runtimeType == other.runtimeType &&
          baseCurrency == other.baseCurrency &&
          targetCurrency == other.targetCurrency &&
          rateScaled == other.rateScaled &&
          effectiveDate == other.effectiveDate;

  @override
  int get hashCode =>
      baseCurrency.hashCode ^
      targetCurrency.hashCode ^
      rateScaled.hashCode ^
      effectiveDate.hashCode;
}
