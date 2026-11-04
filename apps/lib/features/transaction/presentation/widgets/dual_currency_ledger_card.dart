import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/utils/currency_converter.dart';
import 'package:savoryx/core/utils/currency_formatter.dart';
import 'package:savoryx/core/widgets/clay_card.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

/// with locked FX exchange rate pill badges and deterministic integer conversions.
class DualCurrencyLedgerCard extends StatelessWidget {
  const DualCurrencyLedgerCard({
    super.key,
    required this.title,
    required this.amount,
    this.currency = 'IDR',
    this.baseAmount,
    this.exchangeRateToBase,
    this.type = TransactionType.expense,
    required this.time,
    required this.pocketOrAccount,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    this.isMasked = false,
    this.onTap,
  });

  /// Factory constructor for domain `TransactionEntity`.
  factory DualCurrencyLedgerCard.fromEntity({
    Key? key,
    required TransactionEntity entity,
    required String accountName,
    String? categoryName,
    String? categoryColor,
    String? categoryIcon,
    bool isMasked = false,
    VoidCallback? onTap,
  }) {
    final timeStr = DateFormat('HH:mm').format(entity.transactionDate);
    final titleText = entity.note.trim().isNotEmpty
        ? entity.note.trim()
        : (categoryName ?? 'Pengeluaran');

    return DualCurrencyLedgerCard(
      key: key,
      title: titleText,
      amount: entity.amount,
      currency: entity.currency,
      baseAmount: entity.baseAmount,
      exchangeRateToBase: entity.exchangeRateToBase,
      type: entity.type,
      time: timeStr,
      pocketOrAccount: accountName,
      categoryName: categoryName,
      categoryColor: categoryColor,
      categoryIcon: categoryIcon,
      isMasked: isMasked,
      onTap: onTap,
    );
  }

  /// Factory constructor for Drift SQLite `LocalTransaction`.
  factory DualCurrencyLedgerCard.fromLocal({
    Key? key,
    required LocalTransaction transaction,
    required String accountName,
    String? categoryName,
    String? categoryColor,
    String? categoryIcon,
    bool isMasked = false,
    VoidCallback? onTap,
  }) {
    final timeStr = DateFormat('HH:mm').format(transaction.transactionTime);
    final titleText = (transaction.note?.trim().isNotEmpty == true)
        ? transaction.note!.trim()
        : (categoryName ?? 'Pengeluaran');

    return DualCurrencyLedgerCard(
      key: key,
      title: titleText,
      amount: transaction.amount.toInt(),
      currency: transaction.currency,
      baseAmount: transaction.baseAmount.toInt(),
      exchangeRateToBase: transaction.exchangeRateToBase,
      type: TransactionType.fromString(transaction.type),
      time: timeStr,
      pocketOrAccount: accountName,
      categoryName: categoryName,
      categoryColor: categoryColor,
      categoryIcon: categoryIcon,
      isMasked: isMasked,
      onTap: onTap,
    );
  }

  final String title;
  final dynamic amount; // int or BigInt
  final String currency;
  final dynamic baseAmount; // int or BigInt
  final BigInt? exchangeRateToBase;
  final TransactionType type;
  final String time;
  final String pocketOrAccount;
  final String? categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final bool isMasked;
  final VoidCallback? onTap;

  int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is BigInt) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  Color _parseCategoryColor(bool isDark) {
    if (categoryColor != null && categoryColor!.isNotEmpty) {
      final hex = categoryColor!.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      }
    }
    return isDark
        ? ClayColors.surfaceContainerDarkHigh
        : ClayColors.surfaceContainerHigh;
  }

  IconData _resolveCategoryIcon() {
    switch (categoryIcon?.toLowerCase()) {
      case 'utensils':
      case 'food':
        return Icons.restaurant_rounded;
      case 'bus':
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'receipt':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'heart-pulse':
      case 'health':
        return Icons.favorite_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'film':
      case 'entertainment':
        return Icons.movie_rounded;
      case 'bag-shopping':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int foreignAmountInt = _toInt(amount);
    final isForeign = currency.toUpperCase() != 'IDR';
    final int effectiveBaseAmountInt = baseAmount != null
        ? _toInt(baseAmount)
        : (isForeign && exchangeRateToBase != null
            ? CurrencyConverter.convertToBaseAmount(
                foreignAmount: BigInt.from(foreignAmountInt),
                rateScaled: exchangeRateToBase!,
              ).toInt()
            : foreignAmountInt);

    final bool isIncome = type == TransactionType.income;
    final String sign = isIncome ? '+' : '-';
    final Color amountColor =
        isIncome ? ClayColors.tertiary : ClayColors.primary;
    final Color subtitleColor =
        isDark ? ClayColors.onSurfaceVariantDark : ClayColors.outline;

    final catColor = _parseCategoryColor(isDark);
    final catIcon = _resolveCategoryIcon();

    final currencyInfo =
        CurrencyConverter.supportedCurrencies[currency.toUpperCase()];
    final currencySymbol = currencyInfo?.symbol ?? currency;

    // Locked rate string calculation
    String? lockedRateFormatted;
    if (isForeign && exchangeRateToBase != null) {
      final rateScaled = exchangeRateToBase!;
      final rateWhole = (rateScaled ~/ CurrencyConverter.rateScale).toInt();
      lockedRateFormatted = NumberFormat('#,##0', 'id_ID').format(rateWhole);
    }

    final String primaryAmountFormatted = isMasked
        ? '••••••'
        : isForeign
            ? '$sign$currencySymbol${NumberFormat('#,##0').format(foreignAmountInt)} $currency'
            : '$sign${CurrencyFormatter.formatMinorUnit(foreignAmountInt)}';

    final String secondaryBaseFormatted = isMasked
        ? '≈ ••••••'
        : '≈ ${CurrencyFormatter.formatMinorUnit(effectiveBaseAmountInt)}';

    return Semantics(
      label:
          'Transaksi $title, nominal $primaryAmountFormatted${isForeign ? ', setara $secondaryBaseFormatted' : ''}',
      button: onTap != null,
      child: ClayCard(
        borderRadius: BorderRadius.circular(20.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category Icon with pastel clay bubble background
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(catIcon, size: 22.0, color: catColor),
            ),
            const SizedBox(width: 12.0),

            // Middle Column: Title, Metadata, Locked FX Pill Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClayTypography.bodyLg(
                            color: Theme.of(context).colorScheme.onSurface,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (isForeign) ...[
                        const SizedBox(width: 6.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? ClayColors.surfaceContainerDarkHigh
                                : ClayColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            currency.toUpperCase(),
                            style: ClayTypography.labelSm(
                              color: Theme.of(context).colorScheme.primary,
                            ).copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    '$time • $pocketOrAccount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClayTypography.bodySm(color: subtitleColor),
                  ),
                  if (isForeign && lockedRateFormatted != null) ...[
                    const SizedBox(height: 4.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7.0, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? ClayColors.surfaceContainerDarkHigh
                                : ClayColors.surfaceContainerLowest)
                            .withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: ClayColors.outline.withOpacity(0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 10.0,
                            color: subtitleColor,
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            '@ Rp $lockedRateFormatted / $currency',
                            style: ClayTypography.labelSm(color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10.0),

            // Right Column: Dual-Currency Amounts Display
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  primaryAmountFormatted,
                  key: const Key('ledger_primary_amount'),
                  style: ClayTypography.headlineSm(color: amountColor).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isForeign) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    secondaryBaseFormatted,
                    key: const Key('ledger_secondary_base_amount'),
                    style: ClayTypography.bodySm(color: subtitleColor).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
