import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/di/injection_container.dart';
import 'package:savoryx/core/typography/font_manager.dart';
import 'package:savoryx/features/navigation/presentation/widgets/overview_tab.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/usecases/create_transaction_usecase.dart';

void main() {
  late AppDatabase db;

  setUpAll(() {
    FontManager.useTestFallback = true;
    getIt.allowReassignment = true;
  });

  setUp(() async {
    if (!getIt.isRegistered<CreateTransactionUseCase>()) {
      await configureDependencies();
    }
    db = AppDatabase.executor(NativeDatabase.memory());
    getIt.registerSingleton<AppDatabase>(db);
  });

  tearDown(() async {
    await db.close();
    if (getIt.isRegistered<AppDatabase>()) {
      await getIt.unregister<AppDatabase>();
    }
  });

  Widget buildTestableOverview() {
    return const MaterialApp(
      home: Scaffold(
        body: OverviewTab(),
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

  Future<void> unmountAndFlush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('OverviewTab Reactive Integration Tests (Task #20)', () {
    testWidgets('renders reactive accounts carousel and default seeded accounts from Drift',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableOverview());
      await tester.pumpAndSettle();

      // Top bar & Hero Card
      expect(find.text('PULSESPEND // SAVORYX'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('SAFE-TO-SPEND RUNWAY'), findsOneWidget);

      // Seeded accounts from database onCreate
      expect(find.text('Pockets & Accounts'), findsOneWidget);
      expect(find.text('Kas Tunai'), findsOneWidget);
      expect(find.text('Rekening BCA'), findsOneWidget);

      // Section header
      expect(find.text('Recent Tactile Ledger'), findsOneWidget);

      await unmountAndFlush(tester);
    });

    testWidgets('toggles privacy mask on eye button tap',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableOverview());
      await tester.pumpAndSettle();

      // Initially eye icon is visibility
      final eyeButton = find.byIcon(Icons.visibility);
      expect(eyeButton, findsOneWidget);

      // Tap to mask
      await tester.tap(eyeButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.textContaining('••••••••'), findsWidgets);

      // Tap again to unmask
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await unmountAndFlush(tester);
    });

    testWidgets('Saya Batal Beli button deflects impulse and updates stashed fund',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableOverview());
      await tester.pumpAndSettle();

      expect(find.text('Saya Batal Beli'), findsOneWidget);
      expect(find.text('+45k Stashed'), findsOneWidget);

      await tester.tap(find.text('Saya Batal Beli'));
      await tester.pump();

      expect(find.text('+90k Stashed'), findsOneWidget);
      expect(find.textContaining('Impulse deflected!'), findsOneWidget);

      // Let SnackBar timer expire
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await unmountAndFlush(tester);
    });

    testWidgets('reactively displays new transactions inserted into database',
        (WidgetTester tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableOverview());
      await tester.pumpAndSettle();

      // Fetch first account ID from DB
      final accounts = await db.accountDao.watchAllAccounts().first;
      expect(accounts, isNotEmpty);
      final accountId = accounts.first.id;

      // Create a transaction directly via CreateTransactionUseCase or Data layer
      if (getIt.isRegistered<CreateTransactionUseCase>()) {
        final createUseCase = getIt<CreateTransactionUseCase>();
        await createUseCase(
          TransactionEntity(
            id: '0192e4a1-0000-7000-8000-000000000099',
            accountId: accountId,
            categoryId: 'cat-food',
            amount: 75000,
            type: TransactionType.expense,
            note: 'Makan Siang Sate Padang',
            transactionDate: DateTime.now().toUtc(),
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }

      // Re-pump widget to capture stream emission
      await tester.pumpAndSettle();

      // Verify the transaction appeared reactively on screen
      expect(find.text('Makan Siang Sate Padang'), findsOneWidget);

      await unmountAndFlush(tester);
    });
  });
}
