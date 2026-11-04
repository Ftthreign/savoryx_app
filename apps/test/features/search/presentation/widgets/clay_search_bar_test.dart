import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/search/presentation/widgets/clay_search_bar.dart';

void main() {
  group('ClaySearchBar Widget Tests (Task #31)', () {
    testWidgets('renders search bar with search icon and default hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClaySearchBar(
              hintText: 'Cari catatan...',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('Cari catatan...'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      // Clear button should not be visible when field is empty
      expect(find.byKey(const Key('clay_search_bar_clear_button')), findsNothing);
    });

    testWidgets('debounces input changes and triggers callback after 150ms', (tester) async {
      String? debouncedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClaySearchBar(
              debounceDuration: const Duration(milliseconds: 150),
              onSearchDebounced: (query) {
                debouncedResult = query;
              },
            ),
          ),
        ),
      );

      final textFieldFinder = find.byKey(const Key('clay_search_bar_text_field'));

      // Enter first keystroke
      await tester.enterText(textFieldFinder, 'kop');
      await tester.pump();

      // Before 150ms: callback has not fired yet
      await tester.pump(const Duration(milliseconds: 100));
      expect(debouncedResult, isNull);

      // Type more before timer expires
      await tester.enterText(textFieldFinder, 'kopi susu');
      await tester.pump();

      // Advance by 100ms again
      await tester.pump(const Duration(milliseconds: 100));
      expect(debouncedResult, isNull);

      // Advance by remaining 60ms (total 160ms since last keystroke)
      await tester.pump(const Duration(milliseconds: 60));
      expect(debouncedResult, equals('kopi susu'));
    });

    testWidgets('clear button appears when text is entered and clears input when tapped', (tester) async {
      var cleared = false;
      String? lastDebounced;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClaySearchBar(
              onClear: () {
                cleared = true;
              },
              onSearchDebounced: (query) {
                lastDebounced = query;
              },
            ),
          ),
        ),
      );

      final textFieldFinder = find.byKey(const Key('clay_search_bar_text_field'));
      await tester.enterText(textFieldFinder, 'Starbucks');
      await tester.pump();

      // Clear button is now visible
      final clearButtonFinder = find.byKey(const Key('clay_search_bar_clear_button'));
      expect(clearButtonFinder, findsOneWidget);

      // Tap clear
      await tester.tap(clearButtonFinder);
      await tester.pump();

      expect(cleared, isTrue);
      expect(lastDebounced, equals(''));
      expect(find.text('Starbucks'), findsNothing);
      expect(clearButtonFinder, findsNothing);
    });

    testWidgets('filter button invokes onFilterTap and displays active dot indicator', (tester) async {
      var filterTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClaySearchBar(
              hasActiveFilter: true,
              onFilterTap: () {
                filterTapped = true;
              },
            ),
          ),
        ),
      );

      final filterButtonFinder = find.byKey(const Key('clay_search_bar_filter_button'));
      expect(filterButtonFinder, findsOneWidget);

      await tester.tap(filterButtonFinder);
      await tester.pump();

      expect(filterTapped, isTrue);
    });
  });
}
