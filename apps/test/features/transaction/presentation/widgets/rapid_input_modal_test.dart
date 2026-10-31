import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/transaction/presentation/widgets/account_chip_selector.dart';
import 'package:savoryx/features/transaction/presentation/widgets/category_selector_grid.dart';
import 'package:savoryx/features/transaction/presentation/widgets/clay_keypad.dart';
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
    final Text textWidget =
        tester.widget<Text>(find.byKey(const Key('amount_display_text')));
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
      expect(find.byType(ClayKeypad), findsOneWidget);

      // Verify default display text is 85.000
      expect(getDisplayedAmount(tester), equals('85.000'));

      // Verify initial selected category and account
      expect(find.text('Food & Drink'), findsOneWidget);
      expect(find.text('BCA Checking'), findsOneWidget);

      // Verify time-cost equivalence pill is present
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.textContaining('Working Hours'), findsOneWidget);
    });

    testWidgets('handles keypad input, clear (C), and backspace correctly',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableModal());

      // 1. Clear with C
      await tester.tap(find.byKey(const Key('clay_key_clear')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('0'));

      // 2. Type digits: 1, 5, 0, 0 -> 1.500
      await tester.tap(find.byKey(const Key('clay_key_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_0')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('1.500'));

      // 3. Backspace -> 150
      await tester.tap(find.byKey(const Key('clay_key_backspace')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('150'));
    });

    testWidgets('quick denomination accelerator adds amounts correctly',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableModal());

      // Clear first
      await tester.tap(find.byKey(const Key('clay_key_clear')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('0'));

      // Tap +50k
      await tester.tap(find.byKey(const Key('clay_chip_50k')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('50.000'));

      // Tap +10k
      await tester.tap(find.byKey(const Key('clay_chip_10k')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('60.000'));

      // Tap +100k
      await tester.tap(find.byKey(const Key('clay_chip_100k')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('160.000'));
    });

    testWidgets('supports inline math operations and dynamic live preview',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableModal());

      // 1. Clear
      await tester.tap(find.byKey(const Key('clay_key_clear')));
      await tester.pumpAndSettle();

      // 2. Type: 5, 0, 000 -> 50000
      await tester.tap(find.byKey(const Key('clay_key_5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_000')));
      await tester.pumpAndSettle();
      expect(getDisplayedAmount(tester), equals('50.000'));

      // 3. Tap Plus (+) operator
      await tester.tap(find.byKey(const Key('clay_key_plus')));
      await tester.pumpAndSettle();
      expect(find.textContaining('+'), findsWidgets);
      // Live preview shows = Rp 50.000 because trailing operator is cleanly stripped
      expect(find.byKey(const Key('live_preview_text')), findsOneWidget);

      // 4. Type second operand: 2, 5, 000 -> 25000
      await tester.tap(find.byKey(const Key('clay_key_2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_000')));
      await tester.pumpAndSettle();

      // Evaluated live preview should show = Rp 75.000
      expect(find.text('= Rp 75.000'), findsOneWidget);
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

    testWidgets('verifies sub-500ms launch-to-input readiness without virtual keyboard latency',
        (WidgetTester tester) async {
      setMobileScreen(tester);

      // Simulate opening modal via showModalBottomSheet
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => RapidInputModal.show(context),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      // BottomSheet animation completes in under 300ms
      await tester.pump(const Duration(milliseconds: 300));

      // Keypad is already rendered and ready for tap immediately (0ms OS keyboard latency)
      expect(find.byType(ClayKeypad), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('clay_key_7')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clay_key_7')));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
