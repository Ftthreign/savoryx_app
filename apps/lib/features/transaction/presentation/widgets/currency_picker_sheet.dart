import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/utils/currency_converter.dart';

/// Tactile Claymorphism bottom sheet for selecting transaction currency.
class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({
    super.key,
    required this.selectedCurrency,
    required this.onSelected,
  });

  final String selectedCurrency;
  final ValueChanged<String> onSelected;

  static Future<String?> show(
    BuildContext context, {
    required String selectedCurrency,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CurrencyPickerSheet(
        selectedCurrency: selectedCurrency,
        onSelected: (code) => Navigator.of(ctx).pop(code),
      ),
    );
  }

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CurrencyInfo> get _filteredCurrencies {
    final all = CurrencyConverter.supportedCurrencies.values.toList();
    if (_searchQuery.trim().isEmpty) {
      return all;
    }
    final q = _searchQuery.trim().toLowerCase();
    return all.where((c) {
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? ClayColors.surfaceDark : ClayColors.surfaceContainerLowest;
    final textColor = isDark ? ClayColors.onSurfaceDark : ClayColors.onSurface;
    final subtitleColor = isDark ? ClayColors.onSurfaceVariantDark : ClayColors.outline;
    final activeCurrency = widget.selectedCurrency.toUpperCase();

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.75,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        boxShadow: ClayShadows.elevated(isDark: isDark, scale: 1.2),
      ),
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 14.0,
        bottom: 24.0 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44.0,
              height: 5.0,
              decoration: BoxDecoration(
                color: isDark ? ClayColors.surfaceContainerDark : ClayColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Header Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pilih Mata Uang',
                style: ClayTypography.headlineSm(color: textColor),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: subtitleColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Search Input
          Container(
            decoration: BoxDecoration(
              color: isDark ? ClayColors.surfaceContainerDark : ClayColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: TextField(
              key: const Key('currency_picker_search_field'),
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: ClayTypography.bodyMd(color: textColor),
              decoration: InputDecoration(
                hintText: 'Cari kode mata uang (USD, JPY, Dollar...)',
                hintStyle: ClayTypography.bodySm(color: subtitleColor),
                icon: Icon(Icons.search_rounded, size: 20.0, color: subtitleColor),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          const SizedBox(height: 14.0),

          // Currencies List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filteredCurrencies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8.0),
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == activeCurrency;

                return InkWell(
                  key: Key('currency_item_${currency.code}'),
                  borderRadius: BorderRadius.circular(16.0),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onSelected(currency.code);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? ClayColors.primaryContainer.withOpacity(0.25) : ClayColors.primaryContainer)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: isSelected ? ClayColors.primary : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Currency Code Badge
                        Container(
                          width: 46.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            color: isDark ? ClayColors.surfaceContainerDarkHigh : ClayColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            currency.code,
                            style: ClayTypography.labelMd(color: textColor).copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        // Currency Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currency.name,
                                style: ClayTypography.bodyMd(color: textColor).copyWith(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Simbol: ${currency.symbol}',
                                style: ClayTypography.labelSm(color: subtitleColor),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: ClayColors.primary,
                            size: 22.0,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
