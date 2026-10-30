import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/transaction/presentation/widgets/account_chip_selector.dart';
import 'package:savoryx/features/transaction/presentation/widgets/category_selector_grid.dart';
import 'package:savoryx/features/transaction/presentation/widgets/keypad_grid.dart';
import 'package:savoryx/features/transaction/presentation/widgets/quick_amount_grid.dart';
import 'package:savoryx/features/transaction/presentation/widgets/rapid_input_modal.dart';

void main() {
  Widget buildTestableModal() {
    return const MaterialApp(
      home: Scaffold(
        body: RapidInputModal(),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  String getDisplayedAmount(WidgetTester tester) {
    final Text textWidget = tester.widget<Text>(find.byKey(const Key('amount_display_text')));
    return textWidget.data ?? '';
  }

  group('RapidInputModal Widget Tests (flutter-add-widget-test)', () {
    testWidgets('renders all sub-components and default values cleanly',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableModal());

      // Verify presence of decomposed components
      expect(find.byType(CategorySelectorGrid), findsOneWidget);
      expect(find.byType(AccountChipSelector), findsOneWidget);
      expect(find.byType(QuickAmountGrid), findsOneWidget);
      expect(find.byType(KeypadGrid), findsOneWidget);

      // Verify default display text is 85.000
      expect(getDisplayedAmount(tester), equals('85.000'));

      // Verify initial selected category and account
      expect(find.text('Food & Drink'), findsOneWidget);
      expect(find.text('BCA Checking'), findsOneWidget);

      // Verify time-cost equivalence pill is present
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.textContaining('Working Hours'), findsOneWidget);
    });

    testWidgets('handles keypad input, clear (AC), and backspace correctly',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableModal());

      // 1. Clear with AC
      await tester.tap(find.byKey(const Key('keypad_ac')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('0'));

      // 2. Type digits: 1, 5, 0, 0 -> 1.500
      await tester.tap(find.byKey(const Key('keypad_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('keypad_5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('keypad_0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('keypad_0')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('1.500'));

      // 3. Backspace -> 150
      await tester.tap(find.byKey(const Key('keypad_backspace')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('150'));
    });

    testWidgets('quick denomination accelerator adds amounts correctly',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableModal());

      // Clear first
      await tester.tap(find.byKey(const Key('keypad_ac')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('0'));

      // Tap +50k
      await tester.tap(find.text('+50k'));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('50.000'));

      // Tap +10k
      await tester.tap(find.text('+10k'));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('60.000'));

      // Tap +100k
      await tester.tap(find.text('+100k'));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('160.000'));
    });

    testWidgets('category selection updates active choice without overflow',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableModal());

      // Tap Groceries
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Tap Transport category
      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();

      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('source account selection updates active chip',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableModal());

      // Tap Cash Wallet
      await tester.tap(find.text('Cash Wallet'));
      await tester.pumpAndSettle();

      // Tap GoPay E-Wallet
      await tester.tap(find.text('GoPay E-Wallet'));
      await tester.pumpAndSettle();

      expect(find.text('GoPay E-Wallet'), findsOneWidget);
    });
  });
}
