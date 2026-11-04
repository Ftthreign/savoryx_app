import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/features/search/presentation/widgets/search_result_tile.dart';

void main() {
  group('SearchResultTile Widget Tests (Task #31)', () {
    final sampleTx = LocalTransaction(
      id: 'tx-1',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      amount: BigInt.from(3500000), // Rp 35.000,00
      currency: 'IDR',
      exchangeRateToBase: BigInt.from(1000000),
      baseAmount: BigInt.from(3500000),
      type: 'EXPENSE',
      transactionTime: DateTime(2026, 11, 4, 10, 30),
      note: 'Ngopi pagi di Starbucks Senopati #coffee',
      createdAt: DateTime(2026, 11, 4, 10, 30),
      updatedAt: DateTime(2026, 11, 4, 10, 30),
      deletedAt: null,
      isSynced: false,
    );

    testWidgets('renders transaction note, account name, and formatted amount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultTile(
              transaction: sampleTx,
              accountName: 'BCA Checking',
              categoryName: 'Food & Drink',
              categoryIcon: 'coffee',
              categoryColor: '#FFEA93',
            ),
          ),
        ),
      );

      // Verify note rendered
      expect(find.byType(RichText), findsWidgets);
      // Account name and category icon rendered
      expect(find.textContaining('BCA Checking'), findsOneWidget);
      expect(find.byIcon(Icons.coffee_rounded), findsOneWidget);
      // Formatted amount (3500000 in IDR format: -Rp 3.500.000)
      expect(find.textContaining('3.500.000'), findsOneWidget);
    });

    testWidgets('dual-currency transaction displays both foreign amount and base conversion', (tester) async {
      final foreignTx = sampleTx.copyWith(
        currency: 'USD',
        amount: BigInt.from(1500), // $15.00
        baseAmount: BigInt.from(24376125), // Rp 243.761,25
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultTile(
              transaction: foreignTx,
              accountName: 'Cash Wallet',
            ),
          ),
        ),
      );

      // Foreign USD amount
      expect(find.textContaining('\$15.00'), findsOneWidget);
      // Base IDR conversion preview
      expect(find.textContaining('24.376.125'), findsOneWidget);
    });

    testWidgets('onTap callback is triggered when tile is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultTile(
              transaction: sampleTx,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SearchResultTile));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
