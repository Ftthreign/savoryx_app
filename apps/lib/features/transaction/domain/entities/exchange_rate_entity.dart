import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_rate_entity.freezed.dart';

@freezed
class ExchangeRateEntity with _$ExchangeRateEntity {
  const ExchangeRateEntity._();

  const factory ExchangeRateEntity({
    required String baseCurrency,
    required String targetCurrency,
    required BigInt rateScaled,
    required DateTime effectiveDate,
    required DateTime updatedAt,
  }) = _ExchangeRateEntity;

  static final BigInt scale = BigInt.from(1000000);

  String get displayRate {
    final intRate = rateScaled ~/ scale;
    final fracRate = (rateScaled % scale).toInt();
    final fracStr = fracRate.toString().padLeft(6, '0').substring(0, 2);
    return '$intRate.$fracStr';
  }
}
