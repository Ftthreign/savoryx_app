import 'package:equatable/equatable.dart';

sealed class CurrencyEvent extends Equatable {
  const CurrencyEvent();

  @override
  List<Object?> get props => [];
}

final class LoadExchangeRates extends CurrencyEvent {
  const LoadExchangeRates({this.baseCurrency = 'IDR'});

  final String baseCurrency;

  @override
  List<Object?> get props => [baseCurrency];
}

final class CurrencySelected extends CurrencyEvent {
  const CurrencySelected(this.currency);

  final String currency;

  @override
  List<Object?> get props => [currency];
}

final class ExchangeRateRefreshed extends CurrencyEvent {
  const ExchangeRateRefreshed();
}
