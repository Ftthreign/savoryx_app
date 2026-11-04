import 'package:savoryx/core/utils/currency_converter.dart';
import 'package:savoryx/core/utils/financial_math.dart';
import 'package:savoryx/features/transaction/domain/repositories/exchange_rate_repository.dart';

class ConvertCurrencyUseCase {
  const ConvertCurrencyUseCase(this._exchangeRateRepository);

  final ExchangeRateRepository _exchangeRateRepository;

  Future<BigInt> toBaseAmount({
    required BigInt amount,
    required String currency,
    required String baseCurrency,
    BigInt? customRateScaled,
    DateTime? effectiveDate,
    RoundingMode roundingMode = RoundingMode.halfUp,
  }) async {
    if (currency.toUpperCase() == baseCurrency.toUpperCase()) {
      return amount;
    }

    final BigInt rateScaled;
    if (customRateScaled != null && customRateScaled > BigInt.zero) {
      rateScaled = customRateScaled;
    } else {
      final rateEntity = effectiveDate != null
          ? await _exchangeRateRepository.getHistoricalRate(
              baseCurrency: baseCurrency,
              targetCurrency: currency,
              date: effectiveDate,
            )
          : await _exchangeRateRepository.getLatestRate(
              baseCurrency: baseCurrency,
              targetCurrency: currency,
            );

      if (rateEntity == null) {
        throw StateError(
          'Kurs valas untuk pasangan $baseCurrency/$currency tidak ditemukan di cache lokal.',
        );
      }
      rateScaled = rateEntity.rateScaled;
    }

    return CurrencyConverter.convertToBaseAmount(
      foreignAmount: amount,
      rateScaled: rateScaled,
      mode: roundingMode,
    );
  }

  Future<BigInt> fromBaseAmount({
    required BigInt baseAmount,
    required String targetCurrency,
    required String baseCurrency,
    BigInt? customRateScaled,
    DateTime? effectiveDate,
    RoundingMode roundingMode = RoundingMode.halfUp,
  }) async {
    if (targetCurrency.toUpperCase() == baseCurrency.toUpperCase()) {
      return baseAmount;
    }

    final BigInt rateScaled;
    if (customRateScaled != null && customRateScaled > BigInt.zero) {
      rateScaled = customRateScaled;
    } else {
      final rateEntity = effectiveDate != null
          ? await _exchangeRateRepository.getHistoricalRate(
              baseCurrency: baseCurrency,
              targetCurrency: targetCurrency,
              date: effectiveDate,
            )
          : await _exchangeRateRepository.getLatestRate(
              baseCurrency: baseCurrency,
              targetCurrency: targetCurrency,
            );

      if (rateEntity == null) {
        throw StateError(
          'Kurs valas untuk pasangan $baseCurrency/$targetCurrency tidak ditemukan di cache lokal.',
        );
      }
      rateScaled = rateEntity.rateScaled;
    }

    return CurrencyConverter.convertFromBaseAmount(
      baseAmount: baseAmount,
      rateScaled: rateScaled,
      mode: roundingMode,
    );
  }
}
