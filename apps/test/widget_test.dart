import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/main.dart';

void main() {
  testWidgets('SavoryxApp smoke test initializes and renders Clay Showcase', (WidgetTester tester) async {
    await tester.pumpWidget(const SavoryxApp());
    await tester.pumpAndSettle();

    expect(find.text('Tactile Showcase'), findsOneWidget);
    expect(find.text('SAFE-TO-SPEND RUNWAY'), findsOneWidget);
    expect(find.text('Saya Batal Beli'), findsOneWidget);
    expect(find.text('Mark as Talangan'), findsOneWidget);
  });
}
