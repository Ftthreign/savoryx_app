import 'package:flutter/foundation.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/navigation/domain/entities/safe_to_spend_entity.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

enum OverviewStatus { initial, loading, loaded, failure }

class OverviewState {
  const OverviewState({
    this.status = OverviewStatus.initial,
    this.accounts = const [],
    required this.safeToSpend,
    this.recentTransactions = const [],
    this.stashedImpulseFund = 45000,
    this.isMasked = false,
    this.selectedCurrency = 'IDR',
    this.selectedCurrencySymbol = 'Rp',
    this.errorMessage,
  });

  final OverviewStatus status;
  final List<AccountEntity> accounts;
  final SafeToSpendEntity safeToSpend;
  final List<TransactionEntity> recentTransactions;
  final int stashedImpulseFund;
  final bool isMasked;
  final String selectedCurrency;
  final String selectedCurrencySymbol;
  final String? errorMessage;

  factory OverviewState.initial() {
    return OverviewState(
      status: OverviewStatus.initial,
      accounts: const [],
      safeToSpend: SafeToSpendEntity.initial,
      recentTransactions: const [],
      stashedImpulseFund: 45000,
      isMasked: false,
      selectedCurrency: 'IDR',
      selectedCurrencySymbol: 'Rp',
    );
  }

  OverviewState copyWith({
    OverviewStatus? status,
    List<AccountEntity>? accounts,
    SafeToSpendEntity? safeToSpend,
    List<TransactionEntity>? recentTransactions,
    int? stashedImpulseFund,
    bool? isMasked,
    String? selectedCurrency,
    String? selectedCurrencySymbol,
    String? errorMessage,
  }) {
    return OverviewState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      safeToSpend: safeToSpend ?? this.safeToSpend,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      stashedImpulseFund: stashedImpulseFund ?? this.stashedImpulseFund,
      isMasked: isMasked ?? this.isMasked,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      selectedCurrencySymbol:
          selectedCurrencySymbol ?? this.selectedCurrencySymbol,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OverviewState &&
        other.status == status &&
        listEquals(other.accounts, accounts) &&
        other.safeToSpend == safeToSpend &&
        listEquals(other.recentTransactions, recentTransactions) &&
        other.stashedImpulseFund == stashedImpulseFund &&
        other.isMasked == isMasked &&
        other.selectedCurrency == selectedCurrency &&
        other.selectedCurrencySymbol == selectedCurrencySymbol &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        status,
        Object.hashAll(accounts),
        safeToSpend,
        Object.hashAll(recentTransactions),
        stashedImpulseFund,
        isMasked,
        selectedCurrency,
        selectedCurrencySymbol,
        errorMessage,
      );
}
