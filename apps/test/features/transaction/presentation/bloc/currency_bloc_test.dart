import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/daos/exchange_rate_dao.dart';
import 'package:savoryx/features/transaction/domain/entities/exchange_rate_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/exchange_rate_repository.dart';
import 'package:savoryx/features/transaction/domain/usecases/get_exchange_rates_usecase.dart';
import 'package:savoryx/features/transaction/presentation/bloc/currency_bloc.dart';
import 'package:savoryx/features/transaction/presentation/bloc/currency_event.dart';
import 'package:savoryx/features/transaction/presentation/bloc/currency_state.dart';

class FakeExchangeRateRepository implements ExchangeRateRepository {
  List<ExchangeRateEntity> ratesToReturn = [];
  bool shouldThrow = false;

  @override
  Future<List<ExchangeRateEntity>> getAllRatesForBase({
    required String baseCurrency,
  }) async {
    if (shouldThrow) {
      throw Exception('FX database read error');
    }
    return ratesToReturn;
  }

  @override
  Future<ExchangeRateEntity?> getHistoricalRate({
    required String baseCurrency,
    required String targetCurrency,
    required DateTime date,
  }) async {
    if (shouldThrow) throw Exception('FX database read error');
    return ratesToReturn.cast<ExchangeRateEntity?>().firstWhere(
          (r) =>
              r?.baseCurrency == baseCurrency &&
              r?.targetCurrency == targetCurrency,
          orElse: () => null,
        );
  }

  @override
  Future<ExchangeRateEntity?> getLatestRate({
    required String baseCurrency,
    required String targetCurrency,
  }) async {
    if (shouldThrow) throw Exception('FX database read error');
    return ratesToReturn.cast<ExchangeRateEntity?>().firstWhere(
          (r) =>
              r?.baseCurrency == baseCurrency &&
              r?.targetCurrency == targetCurrency,
          orElse: () => null,
        );
  }

  @override
  Future<void> saveRates(List<ExchangeRateEntity> rates) async {
    ratesToReturn.addAll(rates);
  }
}

void main() {
  group('CurrencyBloc (Task #35 Multi-Currency & Search BLoC Domain Clean Architecture)', () {
    late FakeExchangeRateRepository fakeRepo;
    late GetExchangeRatesUseCase getExchangeRatesUseCase;

    final usdRateEntity = ExchangeRateEntity(
      baseCurrency: 'IDR',
      targetCurrency: 'USD',
      rateScaled: BigInt.from(16300) * ExchangeRateDao.rateScale,
      effectiveDate: DateTime.utc(2026, 11, 4),
      updatedAt: DateTime.utc(2026, 11, 4),
    );

    setUp(() {
      fakeRepo = FakeExchangeRateRepository();
      getExchangeRatesUseCase = GetExchangeRatesUseCase(fakeRepo);
    });

    test('initial state is CurrencyInitial', () {
      final bloc = CurrencyBloc(getExchangeRatesUseCase: getExchangeRatesUseCase);
      expect(bloc.state, equals(const CurrencyInitial()));
      bloc.close();
    });

    blocTest<CurrencyBloc, CurrencyState>(
      'emits [CurrencyLoading, CurrencyLoaded] on LoadExchangeRates with cached rates merged',
      build: () {
        fakeRepo.ratesToReturn = [usdRateEntity];
        return CurrencyBloc(getExchangeRatesUseCase: getExchangeRatesUseCase);
      },
      act: (bloc) => bloc.add(const LoadExchangeRates(baseCurrency: 'IDR')),
      expect: () => [
        const CurrencyLoading(),
        isA<CurrencyLoaded>()
            .having((s) => s.baseCurrency, 'baseCurrency', 'IDR')
            .having((s) => s.selectedCurrency, 'selectedCurrency', 'IDR')
            .having(
              (s) => s.rates['USD'],
              'USD scaled rate',
              BigInt.from(16300) * ExchangeRateDao.rateScale,
            ),
      ],
    );

    blocTest<CurrencyBloc, CurrencyState>(
      'updates selectedCurrency when CurrencySelected event is added',
      build: () {
        return CurrencyBloc(getExchangeRatesUseCase: getExchangeRatesUseCase);
      },
      seed: () => CurrencyLoaded(
        baseCurrency: 'IDR',
        selectedCurrency: 'IDR',
        rates: {
          'USD': BigInt.from(16250) * ExchangeRateDao.rateScale,
        },
      ),
      act: (bloc) => bloc.add(const CurrencySelected('USD')),
      expect: () => [
        isA<CurrencyLoaded>().having((s) => s.selectedCurrency, 'selectedCurrency', 'USD'),
      ],
    );

    blocTest<CurrencyBloc, CurrencyState>(
      'emits [CurrencyLoading, CurrencyFailure] when repository fails',
      build: () {
        fakeRepo.shouldThrow = true;
        return CurrencyBloc(getExchangeRatesUseCase: getExchangeRatesUseCase);
      },
      act: (bloc) => bloc.add(const LoadExchangeRates()),
      expect: () => [
        const CurrencyLoading(),
        isA<CurrencyFailure>().having(
          (s) => s.message,
          'message',
          contains('FX database read error'),
        ),
      ],
    );
  });
}
