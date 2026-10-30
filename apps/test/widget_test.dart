import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/di/injection_container.dart';
import 'package:savoryx/core/typography/font_manager.dart';
import 'package:savoryx/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:savoryx/main.dart';

void main() {
  setUpAll(() {
    FontManager.useTestFallback = true;
  });

  setUp(() async {
    if (!getIt.isRegistered<ThemeCubit>()) {
      await configureDependencies();
    }
  });

  testWidgets('SavoryxApp launches MainNavigationShell and navigates tabs and modals seamlessly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SavoryxApp());
    await tester.pumpAndSettle();

    // 1. Initial State: Overview Tab (Tab 0)
    expect(find.text('PULSESPEND // SAVORYX'), findsOneWidget);
    expect(find.text('SAFE-TO-SPEND RUNWAY'), findsOneWidget);
    expect(find.text('Saya Batal Beli'), findsOneWidget);
    expect(find.text('Pockets & Accounts'), findsOneWidget);
    expect(find.text('Recent Tactile Ledger'), findsOneWidget);

    // 2. Open Rapid Input Modal via Center Elevated FAB
    final fabFinder = find.byIcon(Icons.add);
    expect(fabFinder, findsOneWidget);
    await tester.tap(fabFinder);
    await tester.pumpAndSettle();

    // Verify modal contents
    expect(find.text('Log Transaction'), findsOneWidget);
    expect(find.textContaining('Log Expense'), findsOneWidget);

    // Tap +10k accelerator chip
    final chipFinder = find.text('+10k');
    expect(chipFinder, findsOneWidget);
    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    // Close modal via close button
    final closeBtnFinder = find.byIcon(Icons.close);
    expect(closeBtnFinder, findsOneWidget);
    await tester.tap(closeBtnFinder);
    await tester.pumpAndSettle();

    // Modal closed, back to Overview
    expect(find.text('Log Transaction'), findsNothing);

    // 3. Navigate to Tab 1: Vaults
    final vaultsTabFinder = find.byIcon(Icons.savings_outlined);
    expect(vaultsTabFinder, findsOneWidget);
    await tester.tap(vaultsTabFinder);
    await tester.pumpAndSettle();

    expect(find.text('VIRTUAL VAULTS'), findsOneWidget);
    expect(find.text('Sinking Funds'), findsOneWidget);

    // 4. Navigate to Tab 2: Health
    final healthTabFinder = find.byIcon(Icons.monitor_heart_outlined);
    expect(healthTabFinder, findsOneWidget);
    await tester.tap(healthTabFinder);
    await tester.pumpAndSettle();

    expect(find.text('EXECUTIVE REPORT'), findsOneWidget);
    expect(find.text('Financial Health Score'), findsOneWidget);

    // 5. Navigate to Tab 3: Settings
    final settingsTabFinder = find.byIcon(Icons.tune_outlined);
    expect(settingsTabFinder, findsOneWidget);
    await tester.tap(settingsTabFinder);
    await tester.pumpAndSettle();

    expect(find.text('PERSONALIZATION HUB'), findsOneWidget);
    expect(find.text('Surface Theme Mode'), findsOneWidget);

    // Switch theme mode to Clay Dark
    await tester.tap(find.text('Clay Dark'));
    await tester.pumpAndSettle();

    // Switch font to Inter
    await tester.tap(find.text('Inter'));
    await tester.pumpAndSettle();

    // Return to Overview Tab
    final overviewTabFinder = find.byIcon(Icons.account_balance_wallet_outlined);
    expect(overviewTabFinder, findsOneWidget);
    await tester.tap(overviewTabFinder);
    await tester.pumpAndSettle();

    expect(find.text('PULSESPEND // SAVORYX'), findsOneWidget);
  });
}
