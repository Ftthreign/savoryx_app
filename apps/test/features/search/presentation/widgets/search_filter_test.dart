import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/category/domain/entities/category_entity.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/presentation/widgets/search_filter_bottom_sheet.dart';

void main() {
  group('SearchFilterEntity Unit Tests (Task #32)', () {
    test('empty filter reports hasActiveFilter as false', () {
      expect(SearchFilterEntity.empty.hasActiveFilter, isFalse);
    });

    test('active conditions report hasActiveFilter as true', () {
      expect(
        const SearchFilterEntity(datePreset: DateRangePreset.today).hasActiveFilter,
        isTrue,
      );
      expect(
        SearchFilterEntity(minAmount: BigInt.from(100000)).hasActiveFilter,
        isTrue,
      );
      expect(
        const SearchFilterEntity(categoryIds: {'cat-1'}).hasActiveFilter,
        isTrue,
      );
      expect(
        const SearchFilterEntity(accountIds: {'acc-1'}).hasActiveFilter,
        isTrue,
      );
      expect(
        const SearchFilterEntity(transactionTypes: {'EXPENSE'}).hasActiveFilter,
        isTrue,
      );
    });

    test('resolveEffectiveDateRange computes correct boundaries', () {
      const allFilter = SearchFilterEntity(datePreset: DateRangePreset.all);
      final (allStart, allEnd) = allFilter.resolveEffectiveDateRange();
      expect(allStart, isNull);
      expect(allEnd, isNull);

      const todayFilter = SearchFilterEntity(datePreset: DateRangePreset.today);
      final (todayStart, todayEnd) = todayFilter.resolveEffectiveDateRange();
      expect(todayStart, isNotNull);
      expect(todayEnd, isNotNull);
      expect(todayStart!.day, equals(todayEnd!.day));

      const last7Filter = SearchFilterEntity(datePreset: DateRangePreset.last7Days);
      final (last7Start, last7End) = last7Filter.resolveEffectiveDateRange();
      expect(last7Start, isNotNull);
      expect(last7End, isNotNull);
      expect(last7End!.difference(last7Start!).inDays, greaterThanOrEqualTo(6));

      const thisMonthFilter = SearchFilterEntity(datePreset: DateRangePreset.thisMonth);
      final (monthStart, monthEnd) = thisMonthFilter.resolveEffectiveDateRange();
      expect(monthStart!.day, equals(1));
      expect(monthEnd, isNotNull);
    });
  });

  group('SearchFilterBottomSheet Widget Tests (Task #32)', () {
    final now = DateTime.now();
    final sampleAccounts = [
      AccountEntity(
        id: 'acc-1',
        name: 'Rekening BCA',
        type: AccountType.bank,
        balance: 0,
        createdAt: now,
        updatedAt: now,
      ),
      AccountEntity(
        id: 'acc-2',
        name: 'Dompet Tunai',
        type: AccountType.cash,
        balance: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final sampleCategories = [
      CategoryEntity(
        id: 'cat-1',
        name: 'Makan & Minum',
        icon: 'utensils',
        color: '#8DB355',
        isWants: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    testWidgets('renders filter modal with sections and allows applying compound filters', (tester) async {
      SearchFilterEntity? appliedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterBottomSheet(
              initialFilter: SearchFilterEntity.empty,
              accounts: sampleAccounts,
              categories: sampleCategories,
              onApply: (filter) {
                appliedFilter = filter;
              },
            ),
          ),
        ),
      );

      // Verify sections are visible
      expect(find.text('Filter Transaksi'), findsOneWidget);
      expect(find.text('Rentang Tanggal'), findsOneWidget);
      expect(find.text('Rentang Nominal (Rp)'), findsOneWidget);
      expect(find.text('Tipe Transaksi'), findsOneWidget);
      expect(find.text('Akun & Dompet'), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);

      // Select '7 Hari' date preset
      await tester.tap(find.byKey(const Key('date_preset_chip_last7Days')));
      await tester.pump();

      // Enter nominal range (min: 25000, max: 150000)
      await tester.enterText(find.byKey(const Key('search_filter_min_amount_field')), '25000');
      await tester.enterText(find.byKey(const Key('search_filter_max_amount_field')), '150000');
      await tester.pump();

      // Select 'Pengeluaran' chip
      await tester.tap(find.byKey(const Key('filter_chip_EXPENSE')));
      await tester.pump();

      // Select 'Rekening BCA' chip
      await tester.tap(find.byKey(const Key('filter_chip_acc-1')));
      await tester.pump();

      // Select category chip
      await tester.tap(find.byKey(const Key('filter_chip_cat-1')));
      await tester.pump();

      // Tap Apply
      await tester.tap(find.byKey(const Key('search_filter_apply_button')));
      await tester.pump();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.datePreset, equals(DateRangePreset.last7Days));
      // 25,000 * 100 = 2,500,000 minor units
      expect(appliedFilter!.minAmount, equals(BigInt.from(2500000)));
      // 150,000 * 100 = 15,000,000 minor units
      expect(appliedFilter!.maxAmount, equals(BigInt.from(15000000)));
      expect(appliedFilter!.transactionTypes, contains('EXPENSE'));
      expect(appliedFilter!.accountIds, contains('acc-1'));
      expect(appliedFilter!.categoryIds, contains('cat-1'));
    });

    testWidgets('reset button clears all selected fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterBottomSheet(
              initialFilter: const SearchFilterEntity(
                datePreset: DateRangePreset.thisMonth,
                transactionTypes: {'EXPENSE'},
                accountIds: {'acc-1'},
              ),
              accounts: sampleAccounts,
              categories: sampleCategories,
              onApply: (_) {},
            ),
          ),
        ),
      );

      // Tap Reset
      await tester.tap(find.byKey(const Key('search_filter_reset_button')));
      await tester.pump();

      // Verify that chips are unselected
      final expenseChip = tester.widget<FilterChip>(find.byKey(const Key('filter_chip_EXPENSE')));
      expect(expenseChip.selected, isFalse);
    });
  });
}
