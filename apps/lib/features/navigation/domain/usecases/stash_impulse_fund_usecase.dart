import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/transaction_repository.dart';

/// Single-responsibility usecase to deflect impulse spending into a persistent SQLite Sinking Fund.
/// Automatically creates or updates the 'Celengan Impuls' vault account and records the audit transaction.
@lazySingleton
class StashImpulseFundUseCase {
  const StashImpulseFundUseCase(
    this._accountRepository,
    this._transactionRepository,
  );

  final AccountRepository _accountRepository;
  final TransactionRepository _transactionRepository;

  static const String impulseVaultName = 'Celengan Impuls';
  static const Uuid _uuid = Uuid();

  Future<BigInt> call({int amountMinorUnits = 45000}) async {
    if (amountMinorUnits <= 0) {
      throw ArgumentError('Stash amount must be strictly greater than zero minor units');
    }

    final activeAccounts = await _accountRepository.getActiveAccounts();
    AccountEntity? vaultAccount = activeAccounts.cast<AccountEntity?>().firstWhere(
          (a) => a?.name == impulseVaultName,
          orElse: () => null,
        );

    final now = DateTime.now().toUtc();
    final BigInt updatedBalance;

    if (vaultAccount == null) {
      final newId = _uuid.v7();
      vaultAccount = AccountEntity(
        id: newId,
        name: impulseVaultName,
        type: AccountType.cash,
        currency: 'IDR',
        balance: amountMinorUnits,
        createdAt: now,
        updatedAt: now,
      );
      await _accountRepository.createAccount(vaultAccount);
      updatedBalance = BigInt.from(amountMinorUnits);
    } else {
      updatedBalance = BigInt.from(vaultAccount.balance + amountMinorUnits);
      await _accountRepository.updateBalance(vaultAccount.id, updatedBalance);
    }

    // Persist audit trail transaction in ledger
    final tx = TransactionEntity(
      id: _uuid.v7(),
      accountId: vaultAccount.id,
      amount: amountMinorUnits,
      type: TransactionType.income,
      note: 'Impulse Deflection Stash (Batal Beli)',
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
    );
    await _transactionRepository.createTransaction(tx);

    return updatedBalance;
  }
}
