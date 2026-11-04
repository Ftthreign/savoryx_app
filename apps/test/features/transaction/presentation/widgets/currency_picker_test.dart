import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/transaction/presentation/widgets/currency_picker_sheet.dart';
import 'package:savoryx/features/transaction/presentation/widgets/rapid_input_modal.dart';

void main() {
  group('CurrencyPickerSheet Widget Tests (Task #33)', () {
    testWidgets('renders list of global currencies with code, name, and symbols', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyPickerSheet(
              selectedCurrency: 'IDR',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Pilih Mata Uang'), findsOneWidget);
      expect(find.byKey(const Key('currency_picker_search_field')), findsOneWidget);
      expect(find.text('IDR'), findsWidgets);
      expect(find.text('USD'), findsWidgets);
      expect(find.text('SGD'), findsWidgets);
      expect(find.text('EUR'), findsWidgets);
    });

    testWidgets('search field filters currency list by code or name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyPickerSheet(
              selectedCurrency: 'IDR',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      final searchField = find.byKey(const Key('currency_picker_search_field'));

      // Filter by 'Yen'
      await tester.enterText(searchField, 'Yen');
      await tester.pump();

      expect(find.text('JPY'), findsOneWidget);
      expect(find.text('Japanese Yen'), findsOneWidget);
      expect(find.text('EUR'), findsNothing);
    });

    testWidgets('tapping currency item invokes onSelected callback', (tester) async {
      String? selectedCode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyPickerSheet(
              selectedCurrency: 'IDR',
              onSelected: (code) {
                selectedCode = code;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('currency_item_USD')));
      await tester.pump();

      expect(selectedCode, equals('USD'));
    });
  });

  group('RapidInputModal Multi-Currency Integration Tests (Task #33)', () {
    testWidgets('renders currency selector button defaulting to Rp', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RapidInputModal(),
          ),
        ),
      );

      final currencyBtn = find.byKey(const Key('rapid_input_currency_selector_button'));
      expect(currencyBtn, findsOneWidget);
      expect(find.text('Rp'), findsOneWidget);

      // Initially no conversion preview (since currency is IDR)
      expect(find.byKey(const Key('currency_conversion_live_preview')), findsNothing);
    });

    testWidgets('selecting foreign currency displays live conversion preview', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RapidInputModal(),
          ),
        ),
      );

      // Tap currency selector to open picker sheet
      await tester.tap(find.byKey(const Key('rapid_input_currency_selector_button')));
      await tester.pumpAndSettle();

      // Tap USD in modal
      await tester.tap(find.byKey(const Key('currency_item_USD')));
      await tester.pumpAndSettle();

      // Currency selector should now show USD
      expect(find.textContaining('USD'), findsWidgets);

      // Live currency conversion banner is now visible
      final previewFinder = find.byKey(const Key('currency_conversion_live_preview'));
      expect(previewFinder, findsOneWidget);
      expect(find.textContaining('≈ Rp'), findsOneWidget);
      expect(find.textContaining('/USD'), findsOneWidget);
    });
  });
}
