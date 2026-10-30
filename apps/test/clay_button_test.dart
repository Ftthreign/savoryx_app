import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/widgets/clay_button.dart';
import 'package:savoryx/core/widgets/clay_card.dart';

void main() {
  group('ClayButton & ClayCard Widget Tests', () {
    testWidgets('ClayButton renders child and triggers onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ClayButton(
                onTap: () => tapped = true,
                child: const Text('Saya Batal Beli'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Saya Batal Beli'), findsOneWidget);

      await tester.tap(find.text('Saya Batal Beli'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('ClayButton compresses scale when tapped down', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ClayButton(
                onTap: () {},
                child: const Text('Compress Test'),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(ClayButton)));
      await tester.pump(); // Register Ticker start time
      await tester.pump(const Duration(milliseconds: 60)); // Advance 60ms into 120ms animation

      final ScaleTransition transition = tester.widget<ScaleTransition>(
        find.byKey(const ValueKey('clay_button_scale_transition')),
      );

      // Scale value must be compressing down towards 0.96 during 60ms into the 120ms animation
      expect(transition.scale.value, lessThan(1.0));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(transition.scale.value, equals(1.0));
    });

    testWidgets('ClayCard renders with Hero variant styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClayCard(
              isHero: true,
              child: Text('Safe-to-Spend Runway'),
            ),
          ),
        ),
      );

      expect(find.text('Safe-to-Spend Runway'), findsOneWidget);
    });
  });
}
