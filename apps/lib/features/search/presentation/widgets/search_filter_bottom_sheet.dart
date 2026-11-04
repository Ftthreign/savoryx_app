import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';

/// Tactile Claymorphism bottom sheet modal for compound search filters.
class SearchFilterBottomSheet extends StatefulWidget {
  const SearchFilterBottomSheet({
    super.key,
    required this.initialFilter,
    this.accounts = const [],
    this.categories = const [],
    required this.onApply,
  });

  final SearchFilterEntity initialFilter;
  final List<LocalAccount> accounts;
  final List<LocalCategory> categories;
  final ValueChanged<SearchFilterEntity> onApply;

  static Future<SearchFilterEntity?> show(
    BuildContext context, {
    required SearchFilterEntity initialFilter,
    List<LocalAccount> accounts = const [],
    List<LocalCategory> categories = const [],
  }) {
    return showModalBottomSheet<SearchFilterEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchFilterBottomSheet(
        initialFilter: initialFilter,
        accounts: accounts,
        categories: categories,
        onApply: (filter) => Navigator.of(ctx).pop(filter),
      ),
    );
  }

  @override
  State<SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late DateRangePreset _datePreset;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;
  late final Set<String> _selectedTypes;
  late final Set<String> _selectedAccountIds;
  late final Set<String> _selectedCategoryIds;

  @override
  void initState() {
    super.initState();
    _datePreset = widget.initialFilter.datePreset;
    _customStartDate = widget.initialFilter.customStartDate;
    _customEndDate = widget.initialFilter.customEndDate;

    _minAmountController = TextEditingController(
      text: widget.initialFilter.minAmount != null
          ? (widget.initialFilter.minAmount! ~/ BigInt.from(100)).toString()
          : '',
    );
    _maxAmountController = TextEditingController(
      text: widget.initialFilter.maxAmount != null
          ? (widget.initialFilter.maxAmount! ~/ BigInt.from(100)).toString()
          : '',
    );

    _selectedTypes = Set.from(widget.initialFilter.transactionTypes);
    _selectedAccountIds = Set.from(widget.initialFilter.accountIds);
    _selectedCategoryIds = Set.from(widget.initialFilter.categoryIds);
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _handleReset() {
    HapticFeedback.lightImpact();
    setState(() {
      _datePreset = DateRangePreset.all;
      _customStartDate = null;
      _customEndDate = null;
      _minAmountController.clear();
      _maxAmountController.clear();
      _selectedTypes.clear();
      _selectedAccountIds.clear();
      _selectedCategoryIds.clear();
    });
  }

  void _handleApply() {
    HapticFeedback.mediumImpact();

    BigInt? minAmount;
    final minCleaned = _minAmountController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (minCleaned.isNotEmpty) {
      minAmount = BigInt.parse(minCleaned) * BigInt.from(100);
    }

    BigInt? maxAmount;
    final maxCleaned = _maxAmountController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (maxCleaned.isNotEmpty) {
      maxAmount = BigInt.parse(maxCleaned) * BigInt.from(100);
    }

    final filter = SearchFilterEntity(
      datePreset: _datePreset,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
      transactionTypes: Set.unmodifiable(_selectedTypes),
      accountIds: Set.unmodifiable(_selectedAccountIds),
      categoryIds: Set.unmodifiable(_selectedCategoryIds),
    );

    widget.onApply(filter);
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: (_customStartDate != null && _customEndDate != null)
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _datePreset = DateRangePreset.custom;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? ClayColors.surfaceDark : ClayColors.surfaceContainerLowest;
    final textColor = isDark ? ClayColors.onSurfaceDark : ClayColors.onSurface;
    final subtitleColor = isDark ? ClayColors.onSurfaceVariantDark : ClayColors.outline;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        boxShadow: ClayShadows.elevated(isDark: isDark, scale: 1.2),
      ),
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 14.0,
        bottom: 24.0 + bottomInset,
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
          const SizedBox(height: 14.0),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transaksi',
                style: ClayTypography.headlineSm(color: textColor),
              ),
              TextButton(
                key: const Key('search_filter_reset_button'),
                onPressed: _handleReset,
                child: Text(
                  'Reset',
                  style: ClayTypography.bodyMd(color: ClayColors.primary).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION 1: Rentang Tanggal ---
                  Text(
                    'Rentang Tanggal',
                    style: ClayTypography.labelLg(color: subtitleColor),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: DateRangePreset.values.map((preset) {
                      final isSelected = _datePreset == preset;
                      return ChoiceChip(
                        key: Key('date_preset_chip_${preset.name}'),
                        label: Text(preset.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            if (preset == DateRangePreset.custom) {
                              _pickCustomDateRange();
                            } else {
                              setState(() {
                                _datePreset = preset;
                                _customStartDate = null;
                                _customEndDate = null;
                              });
                            }
                          }
                        },
                        selectedColor: isDark ? ClayColors.primaryContainer.withOpacity(0.3) : ClayColors.primaryContainer,
                        labelStyle: ClayTypography.bodyMd(
                          color: isSelected ? ClayColors.primary : textColor,
                        ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                      );
                    }).toList(),
                  ),
                  if (_datePreset == DateRangePreset.custom && _customStartDate != null && _customEndDate != null) ...[
                    const SizedBox(height: 6.0),
                    Text(
                      'Periode: ${DateFormat('dd/MM/yyyy').format(_customStartDate!)} - ${DateFormat('dd/MM/yyyy').format(_customEndDate!)}',
                      style: ClayTypography.labelSm(color: ClayColors.primary),
                    ),
                  ],
                  const SizedBox(height: 16.0),

                  // --- SECTION 2: Rentang Nominal ---
                  Text(
                    'Rentang Nominal (Rp)',
                    style: ClayTypography.labelLg(color: subtitleColor),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('search_filter_min_amount_field'),
                          controller: _minAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: ClayTypography.bodyMd(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Minimum',
                            prefixText: 'Rp ',
                            labelStyle: ClayTypography.bodySm(color: subtitleColor),
                            filled: true,
                            fillColor: isDark ? ClayColors.surfaceContainerDark : ClayColors.surfaceContainerLow,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: BorderSide.none),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: TextField(
                          key: const Key('search_filter_max_amount_field'),
                          controller: _maxAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: ClayTypography.bodyMd(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Maksimum',
                            prefixText: 'Rp ',
                            labelStyle: ClayTypography.bodySm(color: subtitleColor),
                            filled: true,
                            fillColor: isDark ? ClayColors.surfaceContainerDark : ClayColors.surfaceContainerLow,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: BorderSide.none),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // --- SECTION 3: Tipe Transaksi ---
                  Text(
                    'Tipe Transaksi',
                    style: ClayTypography.labelLg(color: subtitleColor),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _buildFilterChip('Pengeluaran', 'EXPENSE', _selectedTypes, isDark, textColor),
                      _buildFilterChip('Pemasukan', 'INCOME', _selectedTypes, isDark, textColor),
                      _buildFilterChip('Transfer', 'TRANSFER', _selectedTypes, isDark, textColor),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // --- SECTION 4: Akun & Dompet ---
                  if (widget.accounts.isNotEmpty) ...[
                    Text(
                      'Akun & Dompet',
                      style: ClayTypography.labelLg(color: subtitleColor),
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 6.0,
                      children: widget.accounts.map((acc) {
                        return _buildFilterChip(acc.name, acc.id, _selectedAccountIds, isDark, textColor);
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                  ],

                  // --- SECTION 5: Kategori ---
                  if (widget.categories.isNotEmpty) ...[
                    Text(
                      'Kategori',
                      style: ClayTypography.labelLg(color: subtitleColor),
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 6.0,
                      children: widget.categories.map((cat) {
                        return _buildFilterChip(cat.name, cat.id, _selectedCategoryIds, isDark, textColor);
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12.0),

          // Primary CTA Button
          ElevatedButton(
            key: const Key('search_filter_apply_button'),
            onPressed: _handleApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
              ),
              elevation: 3.0,
            ),
            child: Text(
              'Terapkan Filter',
              style: ClayTypography.bodyLg(color: Colors.white).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    Set<String> selectedSet,
    bool isDark,
    Color textColor,
  ) {
    final isSelected = selectedSet.contains(value);
    return FilterChip(
      key: Key('filter_chip_$value'),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            selectedSet.add(value);
          } else {
            selectedSet.remove(value);
          }
        });
      },
      selectedColor: isDark ? ClayColors.primaryContainer.withOpacity(0.3) : ClayColors.primaryContainer,
      labelStyle: ClayTypography.bodySm(
        color: isSelected ? ClayColors.primary : textColor,
      ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
    );
  }
}
