import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/usecases/watch_accounts_usecase.dart';
import 'package:savoryx/features/navigation/domain/usecases/calculate_safe_to_spend_usecase.dart';
import 'package:savoryx/features/navigation/domain/usecases/stash_impulse_fund_usecase.dart';
import 'package:savoryx/features/navigation/presentation/bloc/overview_event.dart';
import 'package:savoryx/features/navigation/presentation/bloc/overview_state.dart';
import 'package:savoryx/features/transaction/domain/usecases/watch_recent_transactions_usecase.dart';

@injectable
class OverviewBloc extends Bloc<OverviewEvent, OverviewState> {
  OverviewBloc({
    required WatchAccountsUseCase watchAccountsUseCase,
    required WatchRecentTransactionsUseCase watchRecentTransactionsUseCase,
    required CalculateSafeToSpendUseCase calculateSafeToSpendUseCase,
    required StashImpulseFundUseCase stashImpulseFundUseCase,
  })  : _watchAccountsUseCase = watchAccountsUseCase,
        _watchRecentTransactionsUseCase = watchRecentTransactionsUseCase,
        _calculateSafeToSpendUseCase = calculateSafeToSpendUseCase,
        _stashImpulseFundUseCase = stashImpulseFundUseCase,
        super(OverviewState.initial()) {
    on<OverviewLoadStarted>(_onLoadStarted);
    on<OverviewAccountsUpdated>(_onAccountsUpdated);
    on<OverviewTransactionsUpdated>(_onTransactionsUpdated);
    on<OverviewSafeToSpendStashed>(_onSafeToSpendStashed);
    on<OverviewMaskToggled>(_onMaskToggled);
    on<OverviewCurrencyChanged>(_onCurrencyChanged);
  }

  final WatchAccountsUseCase _watchAccountsUseCase;
  final WatchRecentTransactionsUseCase _watchRecentTransactionsUseCase;
  final CalculateSafeToSpendUseCase _calculateSafeToSpendUseCase;
  final StashImpulseFundUseCase _stashImpulseFundUseCase;

  StreamSubscription<dynamic>? _accountsSub;
  StreamSubscription<dynamic>? _transactionsSub;

  Future<void> _onLoadStarted(
    OverviewLoadStarted event,
    Emitter<OverviewState> emit,
  ) async {
    emit(state.copyWith(status: OverviewStatus.loading));

    await _accountsSub?.cancel();
    _accountsSub = _watchAccountsUseCase().listen(
      (accounts) => add(OverviewAccountsUpdated(accounts)),
      onError: (Object error) => emit(
        state.copyWith(
          status: OverviewStatus.failure,
          errorMessage: error.toString(),
        ),
      ),
    );

    await _transactionsSub?.cancel();
    _transactionsSub = _watchRecentTransactionsUseCase(limit: 20).listen(
      (transactions) => add(OverviewTransactionsUpdated(transactions)),
      onError: (Object error) => emit(
        state.copyWith(
          status: OverviewStatus.failure,
          errorMessage: error.toString(),
        ),
      ),
    );
  }

  void _onAccountsUpdated(
    OverviewAccountsUpdated event,
    Emitter<OverviewState> emit,
  ) {
    // Total liquid balance: strictly compute sum of positive minor units across active non-credit accounts
    final BigInt totalLiquid = event.accounts
        .where((a) => a.type != AccountType.creditCard && a.balance > 0)
        .fold(
          BigInt.zero,
          (sum, a) => sum + BigInt.from(a.balance),
        );

    // Default 30-day runway calculation
    final now = DateTime.now();
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (daysInCurrentMonth - now.day) + 1;

    final safeToSpend = _calculateSafeToSpendUseCase(
      totalLiquidBalance: totalLiquid,
      monthlyFixedObligations: BigInt.zero,
      daysRemainingInMonth: remainingDays,
      currency: state.selectedCurrency,
    );

    // Compute active impulse stash vault balance
    final vaultAccount = event.accounts.cast<AccountEntity?>().firstWhere(
          (a) => a?.name == StashImpulseFundUseCase.impulseVaultName,
          orElse: () => null,
        );
    final int vaultBalance = vaultAccount?.balance ?? state.stashedImpulseFund;

    emit(
      state.copyWith(
        status: OverviewStatus.loaded,
        accounts: event.accounts,
        safeToSpend: safeToSpend,
        stashedImpulseFund: vaultBalance,
      ),
    );
  }

  void _onTransactionsUpdated(
    OverviewTransactionsUpdated event,
    Emitter<OverviewState> emit,
  ) {
    emit(state.copyWith(recentTransactions: event.transactions));
  }

  Future<void> _onSafeToSpendStashed(
    OverviewSafeToSpendStashed event,
    Emitter<OverviewState> emit,
  ) async {
    try {
      final updatedVault = await _stashImpulseFundUseCase(
        amountMinorUnits: event.amountMinorUnits,
      );
      emit(state.copyWith(stashedImpulseFund: updatedVault.toInt()));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onMaskToggled(
    OverviewMaskToggled event,
    Emitter<OverviewState> emit,
  ) {
    emit(state.copyWith(isMasked: !state.isMasked));
  }

  void _onCurrencyChanged(
    OverviewCurrencyChanged event,
    Emitter<OverviewState> emit,
  ) {
    final updatedSafeToSpend =
        state.safeToSpend.copyWith(currency: event.currencyCode);
    emit(
      state.copyWith(
        selectedCurrency: event.currencyCode,
        selectedCurrencySymbol: event.currencySymbol,
        safeToSpend: updatedSafeToSpend,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _accountsSub?.cancel();
    await _transactionsSub?.cancel();
    return super.close();
  }
}
