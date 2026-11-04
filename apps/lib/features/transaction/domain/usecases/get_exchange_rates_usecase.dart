import 'package:savoryx/features/transaction/domain/entities/exchange_rate_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/exchange_rate_repository.dart';

class GetExchangeRatesUseCase {
  const GetExchangeRatesUseCase(this._repository);

  final ExchangeRateRepository _repository;

  Future<ExchangeRateEntity?> getRate({
    required String baseCurrency,
    required String targetCurrency,
    DateTime? effectiveDate,
  }) {
    if (effectiveDate != null) {
      return _repository.getHistoricalRate(
        baseCurrency: baseCurrency,
        targetCurrency: targetCurrency,
        date: effectiveDate,
      );
    }
    return _repository.getLatestRate(
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
    );
  }

  Future<List<ExchangeRateEntity>> getAllForBase({
    required String baseCurrency,
  }) {
    return _repository.getAllRatesForBase(baseCurrency: baseCurrency);
  }
}
