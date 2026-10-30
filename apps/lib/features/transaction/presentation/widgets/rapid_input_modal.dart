import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/clay_colors.dart';
import '../../../../core/theme/clay_shadows.dart';
import '../../../../core/theme/clay_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/clay_button.dart';
import '../../../../core/widgets/clay_toggle_switch.dart';

/// Rapid Input & Calculator modal bottom sheet conforming to Stitch screen `1a425b51547f4a8bb8768df73fffcce0`.
class RapidInputModal extends StatefulWidget {
  const RapidInputModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RapidInputModal(),
    );
  }

  @override
  State<RapidInputModal> createState() => _RapidInputModalState();
}

class _RapidInputModalState extends State<RapidInputModal> {
  String _currentRaw = '85000';
  String _selectedCategory = 'Food & Drink';
  bool _isTalangan = false;
  static const int _wagePerHour = 65000;

  static const List<String> _categories = [
    'Food & Drink',
    'Groceries',
    'Transport',
    'Tech Gadget',
    'Bills & Utilities',
  ];

  static const List<int> _acceleratorDenoms = [10000, 50000, 100000, 500000];

  void _onDigitPressed(String digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentRaw == '0') {
        _currentRaw = digit;
      } else if (_currentRaw.length < 10) {
        _currentRaw += digit;
      }
    });
  }

  void _onAddAccelerator(int add) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = int.tryParse(_currentRaw) ?? 0;
      _currentRaw = (current + add).toString();
    });
  }

  void _onTripleZero() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentRaw != '0' && _currentRaw.length < 8) {
        _currentRaw += '000';
      }
    });
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentRaw.length > 1) {
        _currentRaw = _currentRaw.substring(0, _currentRaw.length - 1);
      } else {
        _currentRaw = '0';
      }
    });
  }

  void _onClear() {
    HapticFeedback.lightImpact();
    setState(() => _currentRaw = '0');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final int amount = int.tryParse(_currentRaw) ?? 0;
    final String workHours =
        CurrencyFormatter.calculateWorkHours(amount, hourlyWage: _wagePerHour);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ClayColors.surfaceDark : ClayColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
        boxShadow: ClayShadows.elevated(isDark: isDark, scale: 1.2),
      ),
      padding: EdgeInsets.only(
        top: 16.0,
        left: 20.0,
        right: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Modal Handle Bar
            Container(
              width: 48.0,
              height: 5.0,
              decoration: BoxDecoration(
                color: isDark
                    ? ClayColors.surfaceContainerDarkHigh
                    : ClayColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16.0),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Transaction',
                  style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                ClayButton(
                  width: 36.0,
                  height: 36.0,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(18.0),
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 18.0,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Horizontal Category Selector
            SizedBox(
              height: 42.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8.0),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;

                  return ClayButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    borderRadius: BorderRadius.circular(21.0),
                    color: isSelected
                        ? ClayColors.primary
                        : (isDark
                            ? ClayColors.surfaceContainerDark
                            : ClayColors.surfaceContainerLow),
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Center(
                      child: Text(
                        cat,
                        style: ClayTypography.labelMd(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18.0),

            // Giant Value Display Deck
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: isDark
                    ? ClayColors.surfaceContainerDarkLow
                    : ClayColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: ClayShadows.elevated(isDark: isDark, scale: 0.8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rp ',
                        style: ClayTypography.headlineMd(
                          color: ClayColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatMinorUnit(amount)
                            .replaceAll('Rp', '')
                            .trim(),
                        style: ClayTypography.headlineXl(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // Time-cost equivalence pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: ClayColors.secondaryContainer.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.hourglass_top,
                          size: 14.0,
                          color: ClayColors.secondary,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '≈ $workHours Working Hours at Rp 65k/hr',
                          style: ClayTypography.labelSm(
                            color: ClayColors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),

            // Quick Denomination Accelerator Pills
            Row(
              children: [
                ..._acceleratorDenoms.map(
                  (denom) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: ClayButton(
                        height: 38.0,
                        padding: EdgeInsets.zero,
                        color: ClayColors.tertiaryFixed,
                        borderRadius: BorderRadius.circular(19.0),
                        onTap: () => _onAddAccelerator(denom),
                        child: Center(
                          child: Text(
                            '+${denom ~/ 1000}k',
                            style: ClayTypography.labelMd(
                              color: ClayColors.onTertiaryFixed,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: ClayButton(
                      height: 38.0,
                      padding: EdgeInsets.zero,
                      color: isDark
                          ? ClayColors.surfaceContainerDark
                          : ClayColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(19.0),
                      onTap: _onTripleZero,
                      child: Center(
                        child: Text(
                          '000',
                          style: ClayTypography.labelMd(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),

            // 4x3 Clay Numeric Keypad
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 10.0,
              children: [
                ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(
                  (d) => ClayButton(
                    onTap: () => _onDigitPressed(d),
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(18.0),
                    child: Center(
                      child: Text(
                        d,
                        style: ClayTypography.headlineMd(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom Keypad Row: AC, 0, Backspace
                ClayButton(
                  color: ClayColors.errorContainer,
                  onTap: _onClear,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(18.0),
                  child: Center(
                    child: Text(
                      'AC',
                      style: ClayTypography.headlineSm(
                        color: ClayColors.onErrorContainer,
                      ),
                    ),
                  ),
                ),
                ClayButton(
                  onTap: () => _onDigitPressed('0'),
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(18.0),
                  child: Center(
                    child: Text(
                      '0',
                      style: ClayTypography.headlineMd(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                ClayButton(
                  onTap: _onBackspace,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(18.0),
                  child: Center(
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 22.0,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),

            // Talangan Toggle Card
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isDark
                    ? ClayColors.surfaceContainerDarkLow
                    : ClayColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32.0,
                        height: 32.0,
                        decoration: const BoxDecoration(
                          color: ClayColors.secondaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group,
                          size: 18.0,
                          color: ClayColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Text(
                        'Mark as Talangan',
                        style: ClayTypography.labelLg(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  ClayToggleSwitch(
                    value: _isTalangan,
                    onChanged: (val) => setState(() => _isTalangan = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Submit Button
            ClayButton(
              isPrimaryCta: true,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Logged: ${CurrencyFormatter.formatMinorUnit(amount)} ($_selectedCategory)',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Log Expense (${CurrencyFormatter.formatMinorUnit(amount)})',
                  style: ClayTypography.headlineSm(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
