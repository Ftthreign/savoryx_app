import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:savoryx/features/transaction/domain/entities/exchange_rate_entity.dart';

part 'currency_state.freezed.dart';

@freezed
class CurrencyState with _$CurrencyState {
  const factory CurrencyState.initial() = CurrencyInitial;
  const factory CurrencyState.loading() = CurrencyLoading;
  const factory CurrencyState.loaded({
    required String baseCurrency,
    required String selectedCurrency,
    required Map<String, BigInt> rates,
    @Default([]) List<ExchangeRateEntity> rateEntities,
  }) = CurrencyLoaded;
  const factory CurrencyState.failure({
    required String message,
  }) = CurrencyFailure;
}

extension CurrencyLoadedX on CurrencyLoaded {
  BigInt? get activeRateScaled => rates[selectedCurrency.toUpperCase()];
}
