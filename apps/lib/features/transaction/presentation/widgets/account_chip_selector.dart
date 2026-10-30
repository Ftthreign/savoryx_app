import 'package:flutter/material.dart';
import '../../../../core/theme/clay_colors.dart';
import '../../../../core/theme/clay_typography.dart';
import '../../../../core/widgets/clay_button.dart';

/// Account source selector chip row with Claymorphism styling.
/// Prevents layout overflows via horizontal scroll view.
class AccountChipSelector extends StatelessWidget {
  const AccountChipSelector({
    super.key,
    required this.accounts,
    required this.selectedAccount,
    required this.onAccountSelected,
  });

  final List<String> accounts;
  final String selectedAccount;
  final ValueChanged<String> onAccountSelected;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final String account = accounts[index];
          final bool isSelected = account == selectedAccount;

          return ClayButton(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            borderRadius: BorderRadius.circular(18.0),
            color: isSelected
                ? ClayColors.secondary
                : (isDark
                    ? ClayColors.surfaceContainerDarkLow
                    : ClayColors.surfaceContainerLow),
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
                  account,
                  style: ClayTypography.labelSm(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
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
