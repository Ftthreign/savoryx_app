import 'package:flutter/material.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/widgets/clay_button.dart';

class AccountChipSelector extends StatelessWidget {
  const AccountChipSelector({
    super.key,
    required this.accounts,
    required this.selectedAccount,
    required this.onAccountSelected,
    this.accountBalances,
  });

  final List<String> accounts;
  final String selectedAccount;
  final ValueChanged<String> onAccountSelected;
  final Map<String, String>? accountBalances;

  static const List<BoxShadow> _chipShadowsLight = [
    BoxShadow(
      offset: Offset(1.5, 2.5),
      blurRadius: 4.0,
      color: Color.fromRGBO(163, 177, 198, 0.45),
    ),
    BoxShadow(
      offset: Offset(-1.0, -1.0),
      blurRadius: 3.0,
      color: Color.fromRGBO(255, 255, 255, 0.95),
    ),
  ];

  static const List<BoxShadow> _chipShadowsDark = [
    BoxShadow(
      offset: Offset(1.5, 2.5),
      blurRadius: 4.0,
      color: Color.fromRGBO(0, 0, 0, 0.50),
    ),
    BoxShadow(
      offset: Offset(-1.0, -1.0),
      blurRadius: 3.0,
      color: Color.fromRGBO(255, 255, 255, 0.08),
    ),
  ];

  static const List<BoxShadow> _chipSelectedShadows = [
    BoxShadow(
      offset: Offset(0.0, 3.0),
      blurRadius: 6.0,
      color: ClayColors.chipSecondaryShadow,
    ),
    BoxShadow(
      offset: Offset(-1.0, -1.0),
      blurRadius: 2.0,
      color: Color.fromRGBO(255, 255, 255, 0.35),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 42.0,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final String account = accounts[index];
          final bool isSelected = account == selectedAccount;

          final shadows = isSelected
              ? _chipSelectedShadows
              : (isDark ? _chipShadowsDark : _chipShadowsLight);

          return ClayButton(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            borderRadius: BorderRadius.circular(20.0),
            customShadows: shadows,
            color: isSelected
                ? ClayColors.secondary
                : (isDark
                    ? ClayColors.surfaceContainerDark
                    : Colors.white),
            onTap: () => onAccountSelected(account),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 14.0,
                  color: isSelected
                      ? Colors.white
                      : ClayColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6.0),
                Text(
                  accountBalances != null && accountBalances![account] != null
                      ? '$account (${accountBalances![account]})'
                      : account,
                  style: ClayTypography.labelSm(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
