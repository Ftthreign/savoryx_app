import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/widgets/clay_button.dart';

/// Navigation item model for ClayBottomNavBar.
class ClayNavItem {
  const ClayNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class ClayBottomNavBar extends StatelessWidget {
  const ClayBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  static const List<ClayNavItem> leftTabs = [
    ClayNavItem(
      label: 'Overview',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
    ),
    ClayNavItem(
      label: 'Vaults',
      icon: Icons.savings_outlined,
      activeIcon: Icons.savings,
    ),
  ];

  static const List<ClayNavItem> rightTabs = [
    ClayNavItem(
      label: 'Health',
      icon: Icons.monitor_heart_outlined,
      activeIcon: Icons.monitor_heart,
    ),
    ClayNavItem(
      label: 'Settings',
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color barColor = isDark
        ? ClayColors.surfaceContainerDarkLow
        : ClayColors.surfaceContainerLowest;

    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        bottom: 12.0 + (bottomInset > 0 ? bottomInset - 4.0 : 0.0),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // --- Main Floating Pill Container ---
          Container(
            height: 76.0,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(38.0),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.85),
                width: 1.5,
              ),
              boxShadow: isDark
                  ? const [
                      BoxShadow(
                        offset: Offset(0.0, 8.0),
                        blurRadius: 24.0,
                        color: Color.fromRGBO(0, 0, 0, 0.70),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        offset: Offset(0.0, 8.0),
                        blurRadius: 20.0,
                        color: Color(0x3B475569),
                      ),
                      BoxShadow(
                        offset: Offset(0.0, 3.0),
                        blurRadius: 6.0,
                        color: Color(0x240F172A),
                      ),
                      BoxShadow(
                        offset: Offset(-4.0, -4.0),
                        blurRadius: 12.0,
                        color: Colors.white,
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Left Tabs (Overview, Vaults) with responsive flex bounds
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabItem(context, index: 0, item: leftTabs[0], isDark: isDark),
                      ),
                      Expanded(
                        child: _buildTabItem(context, index: 1, item: leftTabs[1], isDark: isDark),
                      ),
                    ],
                  ),
                ),
                // Center Gap for FAB
                const SizedBox(width: 58.0),
                // Right Tabs (Health, Settings) with responsive flex bounds
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabItem(context, index: 2, item: rightTabs[0], isDark: isDark),
                      ),
                      Expanded(
                        child: _buildTabItem(context, index: 3, item: rightTabs[1], isDark: isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Elevated Center Primary FAB ---
          Positioned(
            top: -18.0,
            child: ClayButton(
              width: 64.0,
              height: 64.0,
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(32.0),
              isPrimaryCta: true,
              onTap: onFabTap,
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 36.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required int index,
    required ClayNavItem item,
    required bool isDark,
  }) {
    final bool isSelected = currentIndex == index;
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color inactiveColor = isDark
        ? ClayColors.onSurfaceVariantDark
        : ClayColors.onSurfaceVariant;

    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            onTap(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          decoration: isSelected
              ? BoxDecoration(
                  color: isDark
                      ? ClayColors.surfaceContainerDarkHigh
                      : ClayColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18.0),
                  boxShadow: ClayShadows.pressed(isDark: isDark, scale: 0.8),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22.0,
              ),
              const SizedBox(height: 2.0),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: ClayTypography.labelSm(
                    color: isSelected ? activeColor : inactiveColor,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
