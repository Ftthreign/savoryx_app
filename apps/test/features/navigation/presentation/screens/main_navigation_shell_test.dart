import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/di/injection_container.dart';
import 'package:savoryx/core/typography/font_manager.dart';
import 'package:savoryx/core/utils/constants.dart';
import 'package:savoryx/features/navigation/presentation/screens/main_navigation_shell.dart';
import 'package:savoryx/features/navigation/presentation/widgets/overview_tab.dart';
import 'package:savoryx/features/settings/domain/entities/app_theme_mode.dart';
import 'package:savoryx/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:savoryx/features/settings/presentation/bloc/theme_state.dart';

void main() {
  setUpAll(() {
    FontManager.useTestFallback = true;
  });

  setUp(() async {
    if (!getIt.isRegistered<ThemeCubit>()) {
      await configureDependencies();
    }
  });

  Widget buildTestableShell({int initialIndex = 0}) {
    return BlocProvider<ThemeCubit>.value(
      value: getIt<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final loadedState =
              state is ThemeLoaded ? state : const ThemeLoaded();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: loadedState.themeData,
            home: MainNavigationShell(initialIndex: initialIndex),
          );
        },
      ),
    );
  }

  group('MainNavigationShell Widget Tests (flutter-add-widget-test)', () {
    testWidgets('renders Overview tab and bottom navigation bar by default',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableShell());
      await tester.pumpAndSettle();

      // Verify overview tab contents
      expect(find.text('PULSESPEND // SAVORYX'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(OverviewTab),
          matching: find.text('Overview'),
        ),
        findsOneWidget,
      );
      expect(find.text('SAFE-TO-SPEND RUNWAY'), findsOneWidget);
      expect(find.text('Saya Batal Beli'), findsOneWidget);
      expect(find.text('Pockets & Accounts'), findsOneWidget);
      expect(find.text('Recent Tactile Ledger'), findsOneWidget);

      // Verify bottom nav items
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsNothing);
      expect(
          find.byIcon(Icons.account_balance_wallet), findsOneWidget); // active
      expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.monitor_heart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets(
        'switches seamlessly across all 4 tabs via bottom navigation bar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableShell());
      await tester.pumpAndSettle();

      // 1. Initial: Overview
      expect(
        find.descendant(
          of: find.byType(OverviewTab),
          matching: find.text('Overview'),
        ),
        findsOneWidget,
      );

      // 2. Switch to Vaults Tab
      await tester.tap(find.byIcon(Icons.savings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('VIRTUAL VAULTS'), findsOneWidget);
      expect(find.text('Sinking Funds'), findsOneWidget);
      expect(find.text('Emergency Fund (6 Months)'), findsOneWidget);

      // 3. Switch to Health Tab
      await tester.tap(find.byIcon(Icons.monitor_heart_outlined));
      await tester.pumpAndSettle();
      expect(find.text('EXECUTIVE REPORT'), findsOneWidget);
      expect(find.text('Financial Health Score'), findsOneWidget);
      expect(find.text('94 / 100'), findsOneWidget);

      // 4. Switch to Settings Tab
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      expect(find.text('PERSONALIZATION HUB'), findsOneWidget);
      expect(find.text('Settings & Themes'), findsOneWidget);
      expect(find.text('Surface Theme Mode'), findsOneWidget);

      // 5. Switch back to Overview Tab
      await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
      await tester.pumpAndSettle();
      expect(find.text('PULSESPEND // SAVORYX'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(OverviewTab),
          matching: find.text('Overview'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'preserves tab state and inputs across IndexedStack navigation switches',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableShell());
      await tester.pumpAndSettle();

      // Verify initial unmasked value
      expect(find.text('Rp 145.000'), findsOneWidget);
      expect(find.text('+45k Stashed'), findsOneWidget);

      // 1. Mutate Overview State: Tap Mask Button
      final maskBtnFinder = find.byIcon(Icons.visibility);
      expect(maskBtnFinder, findsOneWidget);
      await tester.tap(maskBtnFinder);
      await tester.pumpAndSettle();

      // Balance masked
      expect(find.text(AppConstants.privacyMask), findsWidgets);
      expect(find.text('Rp 145.000'), findsNothing);

      // 2. Mutate Overview State: Tap "Saya Batal Beli" fast action
      final stashBtnFinder = find.text('Saya Batal Beli');
      expect(stashBtnFinder, findsOneWidget);
      await tester.tap(stashBtnFinder);
      await tester.pumpAndSettle();

      // Stashed count increased from 45k to 90k
      expect(find.text('+90k Stashed'), findsOneWidget);

      // 3. Navigate away to Vaults Tab
      await tester.tap(find.byIcon(Icons.savings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('VIRTUAL VAULTS'), findsOneWidget);

      // 4. Navigate away to Health Tab
      await tester.tap(find.byIcon(Icons.monitor_heart_outlined));
      await tester.pumpAndSettle();
      expect(find.text('EXECUTIVE REPORT'), findsOneWidget);

      // 5. Navigate back to Overview Tab
      await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
      await tester.pumpAndSettle();

      // 6. Assert State Preservation:
      // Both masked state and stashed fund count are strictly retained!
      expect(find.text(AppConstants.privacyMask), findsWidgets);
      expect(find.text('Rp 145.000'), findsNothing);
      expect(find.text('+90k Stashed'), findsOneWidget);
    });

    testWidgets(
        'opens RapidInputModal via elevated center FAB without interrupting active tab',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableShell());
      await tester.pumpAndSettle();

      // Tap center FAB (+)
      final fabFinder = find.byIcon(Icons.add);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Modal bottom sheet should be presented
      expect(find.text('Log Transaction'), findsOneWidget);
      expect(find.textContaining('Log Expense'), findsOneWidget);

      // Tap +10k accelerator chip inside modal
      await tester.tap(find.text('+10k'));
      await tester.pumpAndSettle();

      // Close modal
      final closeFinder = find.byIcon(Icons.close);
      expect(closeFinder, findsOneWidget);
      await tester.tap(closeFinder);
      await tester.pumpAndSettle();

      // Modal dismissed, active tab remains intact
      expect(find.text('Log Transaction'), findsNothing);
      expect(find.text('PULSESPEND // SAVORYX'), findsOneWidget);
    });

    testWidgets(
        'interacts with Settings tab theme switcher and typography engine',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableShell(initialIndex: 3));
      await tester.pumpAndSettle();

      // Verify Settings Tab is active
      expect(find.text('PERSONALIZATION HUB'), findsOneWidget);
      expect(find.text('Surface Theme Mode'), findsOneWidget);

      // Select Clay Dark theme mode
      final darkThemeButton = find.text('Clay Dark');
      expect(darkThemeButton, findsOneWidget);
      await tester.tap(darkThemeButton);
      await tester.pumpAndSettle();

      // Select Inter font
      final interFontCard = find.text('Inter');
      expect(interFontCard, findsOneWidget);
      await tester.tap(interFontCard);
      await tester.pumpAndSettle();

      // Reset to Clay Light theme mode
      final lightThemeButton = find.text('Clay Light');
      expect(lightThemeButton, findsOneWidget);
      await tester.tap(lightThemeButton);
      await tester.pumpAndSettle();

      final themeState = getIt<ThemeCubit>().state as ThemeLoaded;
      expect(themeState.mode, AppThemeMode.clayLight);
    });
  });
}
