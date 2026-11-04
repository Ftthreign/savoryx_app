import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/daos/exchange_rate_dao.dart';
import 'package:savoryx/features/transaction/domain/entities/exchange_rate_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/exchange_rate_repository.dart';
import 'package:savoryx/features/transaction/domain/usecases/convert_currency_usecase.dart';

class MockExchangeRateRepository implements ExchangeRateRepository {
  final Map<String, ExchangeRateEntity> rateStore = {};

  @override
  Future<List<ExchangeRateEntity>> getAllRatesForBase({
    required String baseCurrency,
  }) async {
    return rateStore.values.where((r) => r.baseCurrency == baseCurrency).toList();
  }

  @override
  Future<ExchangeRateEntity?> getHistoricalRate({
    required String baseCurrency,
    required String targetCurrency,
    required DateTime date,
  }) async {
    return rateStore['$baseCurrency-$targetCurrency'];
  }

  @override
  Future<ExchangeRateEntity?> getLatestRate({
    required String baseCurrency,
    required String targetCurrency,
  }) async {
    return rateStore['$baseCurrency-$targetCurrency'];
  }

  @override
  Future<void> saveRates(List<ExchangeRateEntity> rates) async {
    for (final rate in rates) {
      rateStore['${rate.baseCurrency}-${rate.targetCurrency}'] = rate;
    }
  }
}

void main() {
  group('ConvertCurrencyUseCase (Task #35 Zero Floating-Point Currency Conversion)', () {
    late MockExchangeRateRepository mockRepository;
    late ConvertCurrencyUseCase convertUseCase;

    setUp(() {
      mockRepository = MockExchangeRateRepository();
      convertUseCase = ConvertCurrencyUseCase(mockRepository);

      // 1 USD = 16,250.75 IDR -> rate scaled by 10^6 = 16,250,750,000
      mockRepository.saveRates([
        ExchangeRateEntity(
          baseCurrency: 'IDR',
          targetCurrency: 'USD',
          rateScaled: BigInt.from(16250750000),
          effectiveDate: DateTime.utc(2026, 11, 4),
          updatedAt: DateTime.utc(2026, 11, 4),
        ),
      ]);
    });

    test('returns exact amount without conversion when currency matches base', () async {
      final result = await convertUseCase.toBaseAmount(
        amount: BigInt.from(150000),
        currency: 'IDR',
        baseCurrency: 'IDR',
      );
      expect(result, equals(BigInt.from(150000)));
    });

    test('converts foreign currency amount to base amount with integer arithmetic', () async {
      // 15 USD = 15 * 16,250.75 = 243,761.25 -> half-up rounds to 243,761 IDR
      final result = await convertUseCase.toBaseAmount(
        amount: BigInt.from(15),
        currency: 'USD',
        baseCurrency: 'IDR',
      );
      expect(result, equals(BigInt.from(243761)));
    });

    test('converts base amount to foreign currency amount with custom rate', () async {
      // 160,000 IDR at custom rate 16,000 IDR/USD -> 10 USD
      final customRate = BigInt.from(16000) * ExchangeRateDao.rateScale;
      final result = await convertUseCase.fromBaseAmount(
        baseAmount: BigInt.from(160000),
        targetCurrency: 'USD',
        baseCurrency: 'IDR',
        customRateScaled: customRate,
      );
      expect(result, equals(BigInt.from(10)));
    });

    test('throws StateError when exchange rate is not found in cache', () async {
      expect(
        () => convertUseCase.toBaseAmount(
          amount: BigInt.from(100),
          currency: 'EUR',
          baseCurrency: 'IDR',
        ),
        throwsStateError,
      );
    });
  });
}
