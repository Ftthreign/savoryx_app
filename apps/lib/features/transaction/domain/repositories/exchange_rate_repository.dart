import 'package:savoryx/features/transaction/domain/entities/exchange_rate_entity.dart';

abstract interface class ExchangeRateRepository {
  Future<ExchangeRateEntity?> getLatestRate({
    required String baseCurrency,
    required String targetCurrency,
  });

  Future<ExchangeRateEntity?> getHistoricalRate({
    required String baseCurrency,
    required String targetCurrency,
    required DateTime date,
  });

  Future<List<ExchangeRateEntity>> getAllRatesForBase({
    required String baseCurrency,
  });

  Future<void> saveRates(List<ExchangeRateEntity> rates);
}
