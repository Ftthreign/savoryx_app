import 'package:flutter/material.dart';
import 'package:savoryx/core/widgets/clay_bottom_nav_bar.dart';
import 'package:savoryx/features/transaction/presentation/widgets/rapid_input_modal.dart';
import 'package:savoryx/features/navigation/presentation/widgets/health_tab.dart';
import 'package:savoryx/features/navigation/presentation/widgets/overview_tab.dart';
import 'package:savoryx/features/navigation/presentation/widgets/settings_tab.dart';
import 'package:savoryx/features/navigation/presentation/widgets/vaults_tab.dart';

/// Main navigation shell housing the four primary tabs within an IndexedStack.
/// Tab state and scroll offsets are completely preserved across tab switches.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  void _openRapidInput() {
    RapidInputModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // IndexedStack preserves tab states cleanly without rebuilding
          IndexedStack(
            index: _currentIndex,
            children: const [
              OverviewTab(),
              VaultsTab(),
              HealthTab(),
              SettingsTab(),
            ],
          ),

          // Floating Pill Bottom Navigation Bar
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: ClayBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              onFabTap: _openRapidInput,
            ),
          ),
        ],
      ),
    );
  }
}
