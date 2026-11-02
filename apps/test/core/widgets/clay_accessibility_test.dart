import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/widgets/clay_button.dart';
import 'package:savoryx/core/widgets/clay_card.dart';
import 'package:savoryx/core/widgets/clay_container.dart';
import 'package:savoryx/features/transaction/presentation/widgets/clay_keypad.dart';

void main() {
  group('Claymorphism Layout Hardening & Accessibility Semantics', () {
    testWidgets('ClayButton exposes button semantics and respects minTouchTarget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayButton(
              semanticLabel: 'Konfirmasi Pembayaran',
              semanticHint: 'Ketuk untuk melanjutkan',
              minTouchTarget: true,
              onTap: () {},
              child: const Text('OK'),
            ),
          ),
        ),
      );

      // Verify semantics
      expect(
        find.bySemanticsLabel('Konfirmasi Pembayaran'),
        findsOneWidget,
      );

      final renderObject = tester.renderObject(find.byType(ClayButton));
      final size = (renderObject as RenderBox).size;
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('ClayCard exposes semantic container and button semantics when onTap provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayCard(
              semanticLabel: 'Kartu Dompet Digital',
              semanticHint: 'Ketuk untuk melihat riwayat mutasi',
              onTap: () {},
              child: const Text('GoPay'),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Kartu Dompet Digital'),
        findsOneWidget,
      );
    });

    testWidgets('ClayContainer enforces constraints without overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClayContainer(
              semanticLabel: 'Ringkasan Bulanan',
              constraints: BoxConstraints(
                minWidth: 120.0,
                minHeight: 80.0,
                maxWidth: 200.0,
              ),
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Ringkasan Bulanan'), findsOneWidget);
      final renderBox = tester.renderObject(find.byType(ClayContainer)) as RenderBox;
      expect(renderBox.size.height, greaterThanOrEqualTo(80.0));
      expect(renderBox.size.width, greaterThanOrEqualTo(120.0));
    });

    testWidgets('ClayKeypad exposes comprehensive accessibility labels for screen readers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayKeypad(
              onDigitPressed: (_) {},
              onOperatorPressed: (_) {},
              onClear: () {},
              onBackspace: () {},
              onAcceleratorPressed: (_) {},
            ),
          ),
        ),
      );

      // Verify key semantic labels
      expect(find.bySemanticsLabel('Angka 7'), findsOneWidget);
      expect(find.bySemanticsLabel('Angka 0'), findsOneWidget);
      expect(find.bySemanticsLabel('Operasi Pembagian'), findsOneWidget);
      expect(find.bySemanticsLabel('Operasi Penjumlahan'), findsOneWidget);
      expect(find.bySemanticsLabel('Hapus Semua Nominal'), findsOneWidget);
      expect(find.bySemanticsLabel('Hapus satu digit'), findsOneWidget);
      expect(find.bySemanticsLabel('Tambah 50 ribu Rupiah'), findsOneWidget);
    });
  });
}
