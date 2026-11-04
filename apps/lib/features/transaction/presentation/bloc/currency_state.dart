import 'package:equatable/equatable.dart';
import 'package:savoryx/features/transaction/domain/entities/exchange_rate_entity.dart';

sealed class CurrencyState extends Equatable {
  const CurrencyState();

  @override
  List<Object?> get props => [];
}

final class CurrencyInitial extends CurrencyState {
  const CurrencyInitial();
}

final class CurrencyLoading extends CurrencyState {
  const CurrencyLoading();
}

final class CurrencyLoaded extends CurrencyState {
  const CurrencyLoaded({
    required this.baseCurrency,
    required this.selectedCurrency,
    required this.rates,
    this.rateEntities = const [],
  });

  /// The active base accounting currency (e.g., 'IDR').
  final String baseCurrency;

  /// The currently selected currency for transaction entry (e.g., 'USD', 'SGD').
  final String selectedCurrency;

  /// Map of target currency codes to scaled exchange rates (scaled by 10^6).
  final Map<String, BigInt> rates;

  /// Full entity list of exchange rate records.
  final List<ExchangeRateEntity> rateEntities;

  /// Retrieves the scaled rate for the currently selected currency relative to baseCurrency.
  BigInt? get activeRateScaled => rates[selectedCurrency.toUpperCase()];

  CurrencyLoaded copyWith({
    String? baseCurrency,
    String? selectedCurrency,
    Map<String, BigInt>? rates,
    List<ExchangeRateEntity>? rateEntities,
  }) {
    return CurrencyLoaded(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      rates: rates ?? this.rates,
      rateEntities: rateEntities ?? this.rateEntities,
    );
  }

  @override
  List<Object?> get props => [baseCurrency, selectedCurrency, rates, rateEntities];
}

final class CurrencyFailure extends CurrencyState {
  const CurrencyFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
