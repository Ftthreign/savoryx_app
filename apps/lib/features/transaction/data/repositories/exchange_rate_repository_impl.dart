import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/daos/exchange_rate_dao.dart';
import 'package:savoryx/features/transaction/domain/entities/exchange_rate_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/exchange_rate_repository.dart';

class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  const ExchangeRateRepositoryImpl(this._exchangeRateDao);

  final ExchangeRateDao _exchangeRateDao;

  @override
  Future<ExchangeRateEntity?> getLatestRate({
    required String baseCurrency,
    required String targetCurrency,
  }) async {
    final record = await _exchangeRateDao.getLatestRate(
      base: baseCurrency,
      target: targetCurrency,
    );
    if (record == null) return null;
    return _mapToEntity(record);
  }

  @override
  Future<ExchangeRateEntity?> getHistoricalRate({
    required String baseCurrency,
    required String targetCurrency,
    required DateTime date,
  }) async {
    final record = await _exchangeRateDao.getRate(
      base: baseCurrency,
      target: targetCurrency,
      date: date,
    );
    if (record == null) return null;
    return _mapToEntity(record);
  }

  @override
  Future<List<ExchangeRateEntity>> getAllRatesForBase({
    required String baseCurrency,
  }) async {
    final records = await _exchangeRateDao.getLatestRatesForBase(base: baseCurrency);
    return records.map(_mapToEntity).toList();
  }

  @override
  Future<void> saveRates(List<ExchangeRateEntity> rates) async {
    final companions = rates.map((r) {
      return LocalExchangeRatesCompanion(
        baseCurrency: Value(r.baseCurrency.toUpperCase()),
        targetCurrency: Value(r.targetCurrency.toUpperCase()),
        rate: Value(r.rateScaled),
        effectiveDate: Value(ExchangeRateDao.normalizeDate(r.effectiveDate)),
        updatedAt: Value(r.updatedAt),
      );
    }).toList();

    await _exchangeRateDao.upsertRatesBatch(companions);
  }

  ExchangeRateEntity _mapToEntity(LocalExchangeRate record) {
    return ExchangeRateEntity(
      baseCurrency: record.baseCurrency,
      targetCurrency: record.targetCurrency,
      rateScaled: record.rate,
      effectiveDate: record.effectiveDate,
      updatedAt: record.updatedAt,
    );
  }
}
