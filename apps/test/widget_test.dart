import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/main.dart';

void main() {
  testWidgets('SavoryxApp smoke test initializes and renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const SavoryxApp());

    expect(find.text('Savoryx Clean Architecture Initialized'), findsOneWidget);
  });
}
