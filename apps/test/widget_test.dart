import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/di/injection_container.dart';
import 'package:savoryx/core/typography/font_manager.dart';
import 'package:savoryx/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:savoryx/main.dart';

void main() {
  setUpAll(() {
    FontManager.useTestFallback = true;
  });

  setUp(() async {
    if (!getIt.isRegistered<ThemeCubit>()) {
      await configureDependencies();
    }
  });

  testWidgets('SavoryxApp initializes and dynamically switches themes and fonts', (WidgetTester tester) async {
    await tester.pumpWidget(const SavoryxApp());
    await tester.pumpAndSettle();

    expect(find.text('Dynamic Engine Showcase'), findsOneWidget);
    expect(find.text('SAFE-TO-SPEND RUNWAY'), findsOneWidget);
    expect(find.text('Saya Batal Beli'), findsOneWidget);
    expect(find.text('Mark as Talangan'), findsOneWidget);

    // Verify Theme Mode Selector Chips
    expect(find.text('Clay Light'), findsOneWidget);
    expect(find.text('Clay Dark'), findsOneWidget);
    expect(find.text('OLED Pure Black'), findsOneWidget);

    // Switch to Clay Dark via chip tap
    await tester.tap(find.text('Clay Dark'));
    await tester.pumpAndSettle();

    // Switch font to Inter via chip tap
    await tester.tap(find.text('Inter'));
    await tester.pumpAndSettle();
  });
}
