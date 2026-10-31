import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/transaction/presentation/widgets/clay_keypad.dart';

void main() {
  group('ClayKeypad Widget Tests (flutter-add-widget-test)', () {
    testWidgets('renders complete 4x4 keypad grid with digits, operators, and clear button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayKeypad(
              onDigitPressed: (_) {},
              onOperatorPressed: (_) {},
              onClear: () {},
              onBackspace: () {},
            ),
          ),
        ),
      );

      // Verify 4x4 digits
      for (final digit in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '000']) {
        expect(find.byKey(Key('clay_key_$digit')), findsOneWidget);
        expect(find.text(digit), findsOneWidget);
      }

      // Verify 4 operators
      expect(find.byKey(const Key('clay_key_divide')), findsOneWidget);
      expect(find.text('÷'), findsOneWidget);

      expect(find.byKey(const Key('clay_key_multiply')), findsOneWidget);
      expect(find.text('×'), findsOneWidget);

      expect(find.byKey(const Key('clay_key_minus')), findsOneWidget);
      expect(find.text('-'), findsOneWidget);

      expect(find.byKey(const Key('clay_key_plus')), findsOneWidget);
      expect(find.text('+'), findsOneWidget);

      // Verify clear button
      expect(find.byKey(const Key('clay_key_clear')), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('renders accelerator chips row and backspace button by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayKeypad(
              onDigitPressed: (_) {},
              onOperatorPressed: (_) {},
              onClear: () {},
              onBackspace: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('clay_chip_10k')), findsOneWidget);
      expect(find.byKey(const Key('clay_chip_50k')), findsOneWidget);
      expect(find.byKey(const Key('clay_chip_100k')), findsOneWidget);
      expect(find.byKey(const Key('clay_chip_500k')), findsOneWidget);
      expect(find.byKey(const Key('clay_key_backspace')), findsOneWidget);
    });

    testWidgets('emits onDigitPressed with correct value when digit keys are tapped',
        (WidgetTester tester) async {
      final List<String> tappedDigits = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayKeypad(
              onDigitPressed: (digit) => tappedDigits.add(digit),
              onOperatorPressed: (_) {},
              onClear: () {},
              onBackspace: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('clay_key_7')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_000')));
      await tester.pump();

      expect(tappedDigits, equals(['7', '5', '000']));
    });

    testWidgets('emits onOperatorPressed when arithmetic operator keys are tapped',
        (WidgetTester tester) async {
      final List<String> tappedOperators = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayKeypad(
              onDigitPressed: (_) {},
              onOperatorPressed: (op) => tappedOperators.add(op),
              onClear: () {},
              onBackspace: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('clay_key_divide')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_multiply')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_minus')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_key_plus')));
      await tester.pump();

      expect(tappedOperators, equals(['÷', '×', '-', '+']));
    });

    testWidgets('emits onClear and onBackspace callbacks correctly',
        (WidgetTester tester) async {
      int clearCount = 0;
      int backspaceCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayKeypad(
              onDigitPressed: (_) {},
              onOperatorPressed: (_) {},
              onClear: () => clearCount++,
              onBackspace: () => backspaceCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('clay_key_clear')));
      await tester.pump();
      expect(clearCount, equals(1));

      await tester.tap(find.byKey(const Key('clay_key_backspace')));
      await tester.pump();
      expect(backspaceCount, equals(1));
    });

    testWidgets('emits onAcceleratorPressed when denomination chips are tapped',
        (WidgetTester tester) async {
      final List<int> tappedDenoms = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayKeypad(
              onDigitPressed: (_) {},
              onOperatorPressed: (_) {},
              onClear: () {},
              onBackspace: () {},
              onAcceleratorPressed: (val) => tappedDenoms.add(val),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('clay_chip_10k')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_chip_50k')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_chip_100k')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clay_chip_500k')));
      await tester.pump();

      expect(tappedDenoms, equals([10000, 50000, 100000, 500000]));
    });

    testWidgets('hides accelerator chips when showAccelerators is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayKeypad(
              showAccelerators: false,
              onDigitPressed: (_) {},
              onOperatorPressed: (_) {},
              onClear: () {},
              onBackspace: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('clay_chip_10k')), findsNothing);
      expect(find.byKey(const Key('clay_chip_50k')), findsNothing);
      expect(find.byKey(const Key('clay_key_backspace')), findsNothing);
      expect(find.byKey(const Key('clay_key_7')), findsOneWidget);
    });

    testWidgets('renders cleanly in dark mode without throwing errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: ClayKeypad(
              onDigitPressed: (_) {},
              onOperatorPressed: (_) {},
              onClear: () {},
              onBackspace: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ClayKeypad), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
    });

    testWidgets('handles tight constraints without rendering overflows',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340,
              child: ClayKeypad(
                onDigitPressed: (_) {},
                onOperatorPressed: (_) {},
                onClear: () {},
                onBackspace: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
