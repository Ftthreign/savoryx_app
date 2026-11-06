import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:savoryx/core/utils/currency_converter.dart';
import 'package:savoryx/features/transaction/domain/usecases/get_exchange_rates_usecase.dart';
import 'package:savoryx/features/transaction/presentation/bloc/currency_event.dart';
import 'package:savoryx/features/transaction/presentation/bloc/currency_state.dart';

@lazySingleton
class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  CurrencyBloc({required GetExchangeRatesUseCase getExchangeRatesUseCase})
      : _getExchangeRatesUseCase = getExchangeRatesUseCase,
        super(const CurrencyInitial()) {
    on<LoadExchangeRates>(_onLoadExchangeRates);
    on<CurrencySelected>(_onCurrencySelected);
    on<ExchangeRateRefreshed>(_onExchangeRateRefreshed);
  }

  final GetExchangeRatesUseCase _getExchangeRatesUseCase;

  static final Map<String, BigInt> _fallbackRatesScaled = {
    'IDR': CurrencyConverter.rateScale,
    'USD': BigInt.from(16250) * CurrencyConverter.rateScale,
    'SGD': BigInt.from(12050) * CurrencyConverter.rateScale,
    'EUR': BigInt.from(17400) * CurrencyConverter.rateScale,
    'JPY': BigInt.from(105) * CurrencyConverter.rateScale,
    'GBP': BigInt.from(20500) * CurrencyConverter.rateScale,
    'AUD': BigInt.from(10600) * CurrencyConverter.rateScale,
    'CNY': BigInt.from(2240) * CurrencyConverter.rateScale,
    'MYR': BigInt.from(3450) * CurrencyConverter.rateScale,
    'THB': BigInt.from(445) * CurrencyConverter.rateScale,
    'KRW': BigInt.from(12) * CurrencyConverter.rateScale,
  };

  Future<void> _onLoadExchangeRates(
    LoadExchangeRates event,
    Emitter<CurrencyState> emit,
  ) async {
    emit(const CurrencyLoading());
    try {
      final entities = await _getExchangeRatesUseCase.getAllForBase(
        baseCurrency: event.baseCurrency,
      );

      final Map<String, BigInt> rateMap = Map.from(_fallbackRatesScaled);
      for (final entity in entities) {
        rateMap[entity.targetCurrency.toUpperCase()] = entity.rateScaled;
      }
      rateMap[event.baseCurrency.toUpperCase()] = CurrencyConverter.rateScale;

      emit(CurrencyLoaded(
        baseCurrency: event.baseCurrency,
        selectedCurrency: event.baseCurrency,
        rates: rateMap,
        rateEntities: entities,
      ));
    } catch (e) {
      emit(CurrencyFailure(message: e.toString()));
    }
  }

  void _onCurrencySelected(
    CurrencySelected event,
    Emitter<CurrencyState> emit,
  ) {
    if (state is CurrencyLoaded) {
      final current = state as CurrencyLoaded;
      emit(current.copyWith(selectedCurrency: event.currency));
    } else {
      emit(CurrencyLoaded(
        baseCurrency: CurrencyConverter.defaultBaseCurrency,
        selectedCurrency: event.currency,
        rates: _fallbackRatesScaled,
      ));
    }
  }

  Future<void> _onExchangeRateRefreshed(
    ExchangeRateRefreshed event,
    Emitter<CurrencyState> emit,
  ) async {
    final base = state is CurrencyLoaded
        ? (state as CurrencyLoaded).baseCurrency
        : CurrencyConverter.defaultBaseCurrency;
    add(LoadExchangeRates(baseCurrency: base));
  }
}
