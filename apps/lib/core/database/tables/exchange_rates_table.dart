import 'package:drift/drift.dart';

@DataClassName('LocalExchangeRate')
@TableIndex(
  name: 'idx_local_fx_pair_date',
  columns: {#baseCurrency, #targetCurrency, #effectiveDate},
)
class LocalExchangeRates extends Table {
  /// Base currency ISO code (e.g., 'EUR', 'USD', 'IDR').
  TextColumn get baseCurrency => text().withLength(min: 3, max: 3)();

  /// Target currency ISO code (e.g., 'IDR', 'SGD', 'USD').
  TextColumn get targetCurrency => text().withLength(min: 3, max: 3)();

  /// Exchange rate represented as an integer scaled by 10^6 (1,000,000).
  ///
  /// Example:
  /// - A rate of 1.0 is stored as 1,000,000.
  /// - A rate of 16,250.75 IDR/USD is stored as 16,250,750,000.
  Int64Column get rate => int64()();

  /// Effective date of this exchange rate (normalized to UTC date).
  DateTimeColumn get effectiveDate => dateTime()();

  /// Timestamp when this record was stored locally.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => {
        baseCurrency,
        targetCurrency,
        effectiveDate,
      };
}
