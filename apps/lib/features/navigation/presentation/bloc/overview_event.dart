import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

abstract class OverviewEvent {
  const OverviewEvent();
}

class OverviewLoadStarted extends OverviewEvent {
  const OverviewLoadStarted();
}

class OverviewAccountsUpdated extends OverviewEvent {
  const OverviewAccountsUpdated(this.accounts);

  final List<AccountEntity> accounts;
}

class OverviewTransactionsUpdated extends OverviewEvent {
  const OverviewTransactionsUpdated(this.transactions);

  final List<TransactionEntity> transactions;
}

class OverviewSafeToSpendStashed extends OverviewEvent {
  const OverviewSafeToSpendStashed({this.amountMinorUnits = 45000});

  final int amountMinorUnits;
}

class OverviewMaskToggled extends OverviewEvent {
  const OverviewMaskToggled();
}

class OverviewCurrencyChanged extends OverviewEvent {
  const OverviewCurrencyChanged(this.currencyCode, this.currencySymbol);

  final String currencyCode;
  final String currencySymbol;
}
