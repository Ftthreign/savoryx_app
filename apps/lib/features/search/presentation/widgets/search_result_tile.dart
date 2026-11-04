import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/utils/currency_formatter.dart';
import 'package:savoryx/features/search/domain/entities/search_result_entity.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    this.transaction,
    this.transactionEntity,
    this.highlightQuery = '',
    this.accountName,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    this.onTap,
  }) : assert(
          transaction != null || transactionEntity != null,
          'Either transaction or transactionEntity must be provided',
        );

  factory SearchResultTile.fromEntity({
    Key? key,
    required SearchResultEntity result,
    String highlightQuery = '',
    String? accountName,
    String? categoryName,
    String? categoryColor,
    String? categoryIcon,
    VoidCallback? onTap,
  }) {
    return SearchResultTile(
      key: key,
      transactionEntity: result.transaction,
      highlightQuery: highlightQuery,
      accountName: accountName,
      categoryName: categoryName,
      categoryColor: categoryColor,
      categoryIcon: categoryIcon,
      onTap: onTap,
    );
  }

  final LocalTransaction? transaction;
  final TransactionEntity? transactionEntity;
  final String highlightQuery;
  final String? accountName;
  final String? categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final VoidCallback? onTap;

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
      case 'plane':
      case 'travel':
        return Icons.flight_takeoff_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  /// Builds a [TextSpan] tree highlighting all occurrences of [highlightQuery] case-insensitively.
  InlineSpan _buildHighlightedText(
      String text, String query, Color normalColor, Color highlightColor) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty || !text.toLowerCase().contains(cleanQuery)) {
      return TextSpan(
          text: text,
          style: ClayTypography.bodyMd(color: normalColor)
              .copyWith(fontWeight: FontWeight.w600));
    }

    final spans = <TextSpan>[];
    var start = 0;
    final lowerText = text.toLowerCase();

    while (start < text.length) {
      final index = lowerText.indexOf(cleanQuery, start);
      if (index == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: ClayTypography.bodyMd(color: normalColor)
              .copyWith(fontWeight: FontWeight.w600),
        ));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: ClayTypography.bodyMd(color: normalColor)
              .copyWith(fontWeight: FontWeight.w600),
        ));
      }

      // Highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + cleanQuery.length),
        style: ClayTypography.bodyMd(color: normalColor).copyWith(
          fontWeight: FontWeight.w800,
          backgroundColor: highlightColor.withOpacity(0.28),
          color: highlightColor,
        ),
      ));

      start = index + cleanQuery.length;
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? ClayColors.surfaceDark : ClayColors.surfaceContainerLowest;
    final textColor = isDark ? ClayColors.onSurfaceDark : ClayColors.onSurface;
    final subtitleColor =
        isDark ? ClayColors.onSurfaceVariantDark : ClayColors.outline;
    final accentHighlight =
        isDark ? ClayColors.primaryHighlight : ClayColors.primary;

    final typeStr = transaction?.type.toUpperCase() ??
        transactionEntity!.type.toDbString().toUpperCase();
    final isExpense = typeStr == 'EXPENSE';
    final isIncome = typeStr == 'INCOME';

    final Color amountColor;
    final String amountPrefix;
    if (isExpense) {
      amountColor = isDark ? ClayColors.primaryHighlight : ClayColors.primary;
      amountPrefix = '-';
    } else if (isIncome) {
      amountColor = ClayColors.tertiaryAccent;
      amountPrefix = '+';
    } else {
      amountColor = isDark ? ClayColors.secondaryFixed : ClayColors.secondary;
      amountPrefix = '';
    }

    // Minor unit integer formatting
    final int amountInt = transaction != null
        ? transaction!.amount.toInt()
        : transactionEntity!.amount;
    final currency = transaction?.currency ?? transactionEntity!.currency;
    final int baseAmountInt = transaction != null
        ? transaction!.baseAmount.toInt()
        : (transactionEntity!.baseAmount?.toInt() ??
            transactionEntity!.amount);

    final formattedAmount = CurrencyFormatter.formatMinorUnit(
      amountInt,
      currency: currency,
    );

    // Format transaction date
    final txDate =
        transaction?.transactionTime ?? transactionEntity!.transactionDate;
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(txDate.toLocal());
    final rawNote = transaction?.note ?? transactionEntity!.note;
    final displayNote =
        rawNote.isNotEmpty ? rawNote : (categoryName ?? 'Transaksi');

    return Semantics(
      button: true,
      label: 'Hasil pencarian $displayNote nominal $formattedAmount',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: ClayShadows.elevated(isDark: isDark, scale: 0.6),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(18.0),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Category Icon Container
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: _parseCategoryColor(isDark).withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _resolveCategoryIcon(),
                      color: _parseCategoryColor(isDark),
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // Title, Metadata & Note
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: _buildHighlightedText(
                            displayNote,
                            highlightQuery,
                            textColor,
                            accentHighlight,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            if (accountName != null) ...[
                              Flexible(
                                child: Text(
                                  accountName!,
                                  style: ClayTypography.labelSm(
                                      color: subtitleColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                ' • ',
                                style: ClayTypography.labelSm(
                                    color: subtitleColor),
                              ),
                            ],
                            Text(
                              dateStr,
                              style:
                                  ClayTypography.labelSm(color: subtitleColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Amount Display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$amountPrefix$formattedAmount',
                        style:
                            ClayTypography.bodyLg(color: amountColor).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (currency.toUpperCase() != 'IDR') ...[
                        const SizedBox(height: 2.0),
                        Text(
                          '≈ ${CurrencyFormatter.formatMinorUnit(baseAmountInt, currency: 'IDR')}',
                          style: ClayTypography.labelSm(color: subtitleColor),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
