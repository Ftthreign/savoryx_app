import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/tables/exchange_rates_table.dart';

part 'exchange_rate_dao.g.dart';

@DriftAccessor(tables: [LocalExchangeRates])
class ExchangeRateDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRateDaoMixin {
  ExchangeRateDao(super.db);

  static final BigInt rateScale = BigInt.from(1000000);

  static DateTime normalizeDate(DateTime date) {
    final utc = date.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  Future<int> upsertRate(LocalExchangeRatesCompanion companion) {
    return into(localExchangeRates).insertOnConflictUpdate(companion);
  }

  Future<void> upsertRatesBatch(List<LocalExchangeRatesCompanion> companions) {
    return batch((b) {
      b.insertAllOnConflictUpdate(localExchangeRates, companions);
    });
  }

  Future<LocalExchangeRate?> getRate({
    required String base,
    required String target,
    required DateTime date,
  }) async {
    final baseUpper = base.toUpperCase();
    final targetUpper = target.toUpperCase();
    final normalized = normalizeDate(date);

    if (baseUpper == targetUpper) {
      return LocalExchangeRate(
        baseCurrency: baseUpper,
        targetCurrency: targetUpper,
        rate: rateScale,
        effectiveDate: normalized,
        updatedAt: normalized,
      );
    }

    return (select(localExchangeRates)
          ..where((t) =>
              t.baseCurrency.equals(baseUpper) &
              t.targetCurrency.equals(targetUpper) &
              t.effectiveDate.equals(normalized)))
        .getSingleOrNull();
  }

  Future<LocalExchangeRate?> getLatestRate({
    required String base,
    required String target,
  }) async {
    final baseUpper = base.toUpperCase();
    final targetUpper = target.toUpperCase();

    if (baseUpper == targetUpper) {
      final now = DateTime.now().toUtc();
      return LocalExchangeRate(
        baseCurrency: baseUpper,
        targetCurrency: targetUpper,
        rate: rateScale,
        effectiveDate: normalizeDate(now),
        updatedAt: now,
      );
    }

    return (select(localExchangeRates)
          ..where((t) =>
              t.baseCurrency.equals(baseUpper) &
              t.targetCurrency.equals(targetUpper))
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<LocalExchangeRate?> watchLatestRate({
    required String base,
    required String target,
  }) {
    final baseUpper = base.toUpperCase();
    final targetUpper = target.toUpperCase();

    if (baseUpper == targetUpper) {
      final now = DateTime.now().toUtc();
      return Stream.value(
        LocalExchangeRate(
          baseCurrency: baseUpper,
          targetCurrency: targetUpper,
          rate: rateScale,
          effectiveDate: normalizeDate(now),
          updatedAt: now,
        ),
      );
    }

    return (select(localExchangeRates)
          ..where((t) =>
              t.baseCurrency.equals(baseUpper) &
              t.targetCurrency.equals(targetUpper))
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<List<LocalExchangeRate>> getAllRatesForDate(
    DateTime date, {
    String base = 'EUR',
  }) {
    final normalized = normalizeDate(date);
    return (select(localExchangeRates)
          ..where((t) =>
              t.baseCurrency.equals(base.toUpperCase()) &
              t.effectiveDate.equals(normalized)))
        .get();
  }

  Future<List<LocalExchangeRate>> getLatestRatesForBase({
    required String base,
  }) {
    final baseUpper = base.toUpperCase();
    return (select(localExchangeRates)
          ..where((t) => t.baseCurrency.equals(baseUpper))
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)]))
        .get();
  }
}
