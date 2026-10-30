import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/clay_colors.dart';
import '../theme/clay_shadows.dart';
import '../theme/clay_typography.dart';
import 'clay_button.dart';

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
        : ClayColors.surfaceContainerLow;

    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
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
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0.0, 8.0),
                  blurRadius: 24.0,
                  color: isDark
                      ? const Color.fromRGBO(0, 0, 0, 0.70)
                      : const Color.fromRGBO(163, 177, 198, 0.60),
                ),
                BoxShadow(
                  offset: const Offset(-4.0, -4.0),
                  blurRadius: 16.0,
                  color: isDark
                      ? const Color.fromRGBO(45, 52, 68, 0.25)
                      : const Color.fromRGBO(255, 255, 255, 0.95),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left Tabs (Overview, Vaults)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTabItem(context, index: 0, item: leftTabs[0], isDark: isDark),
                      _buildTabItem(context, index: 1, item: leftTabs[1], isDark: isDark),
                    ],
                  ),
                ),
                // Center Gap for FAB
                const SizedBox(width: 72.0),
                // Right Tabs (Health, Settings)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTabItem(context, index: 2, item: rightTabs[0], isDark: isDark),
                      _buildTabItem(context, index: 3, item: rightTabs[1], isDark: isDark),
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
                  Icons.add,
                  size: 32.0,
                  color: Colors.white,
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
    final bool isActive = currentIndex == index;
    const Color activeColor = ClayColors.primary;
    final Color inactiveColor = isDark
        ? ClayColors.onSurfaceVariantDark
        : ClayColors.onSurfaceVariant;

    final Color tabBgColor = isActive
        ? (isDark ? ClayColors.surfaceContainerDarkHigh : ClayColors.surfaceContainerHigh)
        : Colors.transparent;

    final List<BoxShadow>? tabShadows = isActive
        ? ClayShadows.pressed(isDark: isDark, scale: 0.7)
        : null;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 58.0,
        height: 58.0,
        decoration: BoxDecoration(
          color: tabBgColor,
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: tabShadows,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              size: 22.0,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2.0),
            Text(
              item.label,
              style: ClayTypography.labelSm(
                color: isActive ? activeColor : inactiveColor,
              ).copyWith(
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
