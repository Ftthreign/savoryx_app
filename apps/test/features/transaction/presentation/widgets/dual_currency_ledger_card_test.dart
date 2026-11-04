import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/presentation/widgets/dual_currency_ledger_card.dart';

void main() {
  Widget buildCard(Widget card) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: card,
          ),
        ),
      ),
    );
  }

  group('DualCurrencyLedgerCard Widget Tests (Task #34)', () {
    testWidgets('renders single-currency IDR transaction cleanly without conversion badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildCard(
          const DualCurrencyLedgerCard(
            title: 'Kopi Kenangan Senopati',
            amount: 38000,
            currency: 'IDR',
            type: TransactionType.expense,
            time: '10:42 AM',
            pocketOrAccount: 'GoPay',
            categoryName: 'Ngopi',
            categoryIcon: 'coffee',
          ),
        ),
      );

      // Title & metadata
      expect(find.text('Kopi Kenangan Senopati'), findsOneWidget);
      expect(find.text('10:42 AM • GoPay'), findsOneWidget);

      // Primary amount in IDR
      expect(find.byKey(const Key('ledger_primary_amount')), findsOneWidget);
      expect(find.text('-Rp 38.000'), findsOneWidget);

      // No secondary foreign conversion or locked rate badge for IDR
      expect(find.byKey(const Key('ledger_secondary_base_amount')), findsNothing);
      expect(find.textContaining('@ Rp'), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    });

    testWidgets(
        'renders dual-currency USD transaction with foreign amount, converted base amount, and locked rate badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildCard(
          DualCurrencyLedgerCard(
            title: 'Figma Pro Subscription',
            amount: 15,
            currency: 'USD',
            baseAmount: 243750,
            exchangeRateToBase: BigInt.from(16250000000), // 16.250 * 10^6
            type: TransactionType.expense,
            time: '14:20',
            pocketOrAccount: 'Rekening BCA',
            categoryName: 'Tech',
            categoryIcon: 'shopping',
          ),
        ),
      );

      // Title & USD currency pill badge
      expect(find.text('Figma Pro Subscription'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('14:20 • Rekening BCA'), findsOneWidget);

      // Primary Foreign Amount
      expect(find.byKey(const Key('ledger_primary_amount')), findsOneWidget);
      expect(find.text('-\$15 USD'), findsOneWidget);

      // Secondary Base Converted Amount
      expect(find.byKey(const Key('ledger_secondary_base_amount')), findsOneWidget);
      expect(find.text('≈ Rp 243.750'), findsOneWidget);

      // Locked exchange rate badge
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('@ Rp 16.250 / USD'), findsOneWidget);
    });

    testWidgets('renders dual-currency income with sage green color and plus sign',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildCard(
          DualCurrencyLedgerCard(
            title: 'Upwork Payout',
            amount: 250,
            currency: 'USD',
            baseAmount: 4062500,
            exchangeRateToBase: BigInt.from(16250000000),
            type: TransactionType.income,
            time: 'Yesterday',
            pocketOrAccount: 'Wise Checking',
          ),
        ),
      );

      expect(find.text('Upwork Payout'), findsOneWidget);
      expect(find.text('+\$250 USD'), findsOneWidget);
      expect(find.text('≈ Rp 4.062.500'), findsOneWidget);
    });

    testWidgets('respects privacy masking by censoring primary and secondary amounts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildCard(
          DualCurrencyLedgerCard(
            title: 'DigitalOcean Cloud Server',
            amount: 48,
            currency: 'USD',
            baseAmount: 780000,
            exchangeRateToBase: BigInt.from(16250000000),
            type: TransactionType.expense,
            time: '09:00',
            pocketOrAccount: 'Rekening Mandiri',
            isMasked: true,
          ),
        ),
      );

      // Amounts masked
      expect(find.text('••••••'), findsOneWidget);
      expect(find.text('≈ ••••••'), findsOneWidget);

      // Sensitive numbers hidden
      expect(find.text('-\$48 USD'), findsNothing);
      expect(find.text('≈ Rp 780.000'), findsNothing);
    });

    testWidgets('factory fromLocal correctly maps Drift LocalTransaction',
        (WidgetTester tester) async {
      final now = DateTime.now().toUtc();
      final localTx = LocalTransaction(
        id: '0192e4a1-0000-7000-8000-000000000001',
        accountId: 'acc-1',
        amount: BigInt.from(85),
        currency: 'SGD',
        exchangeRateToBase: BigInt.from(12200000000), // 12.200 * 10^6
        baseAmount: BigInt.from(1037000),
        type: 'EXPENSE',
        transactionTime: now,
        note: 'Apple Store Marina Bay',
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      await tester.pumpWidget(
        buildCard(
          DualCurrencyLedgerCard.fromLocal(
            transaction: localTx,
            accountName: 'OCBC Bank',
            categoryName: 'Tech',
            categoryIcon: 'shopping',
          ),
        ),
      );

      expect(find.text('Apple Store Marina Bay'), findsOneWidget);
      expect(find.text('SGD'), findsOneWidget);
      expect(find.text('-S\$85 SGD'), findsOneWidget);
      expect(find.text('≈ Rp 1.037.000'), findsOneWidget);
      expect(find.text('@ Rp 12.200 / SGD'), findsOneWidget);
    });

    testWidgets('factory fromEntity correctly maps domain TransactionEntity',
        (WidgetTester tester) async {
      final now = DateTime.now().toUtc();
      final entity = TransactionEntity(
        id: '0192e4a1-0000-7000-8000-000000000002',
        accountId: 'acc-2',
        amount: 50,
        currency: 'EUR',
        exchangeRateToBase: BigInt.from(17500000000), // 17.500 * 10^6
        baseAmount: BigInt.from(875000),
        type: TransactionType.expense,
        transactionDate: now,
        note: 'Railway Hosting Frankfurt',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        buildCard(
          DualCurrencyLedgerCard.fromEntity(
            entity: entity,
            accountName: 'BCA Checking',
            categoryName: 'Hosting',
          ),
        ),
      );

      expect(find.text('Railway Hosting Frankfurt'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
      expect(find.text('-€50 EUR'), findsOneWidget);
      expect(find.text('≈ Rp 875.000'), findsOneWidget);
      expect(find.text('@ Rp 17.500 / EUR'), findsOneWidget);
    });

    testWidgets('tapping card invokes onTap callback',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildCard(
          DualCurrencyLedgerCard(
            title: 'Kopi Kenangan Senopati',
            amount: 38000,
            currency: 'IDR',
            type: TransactionType.expense,
            time: '10:42 AM',
            pocketOrAccount: 'GoPay',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Kopi Kenangan Senopati'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
