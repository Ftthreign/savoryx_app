import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/utils/constants.dart';
import 'package:savoryx/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter (Zero-Floating-Point)', () {
    test('formats IDR integer minor units correctly without float conversion', () {
      final formatted = CurrencyFormatter.formatMinorUnit(50000, currency: 'IDR');
      expect(formatted.replaceAll(RegExp(r'\s+'), ' '), contains('Rp 50.000'));
    });

    test('formats large IDR BigInt amounts without overflow', () {
      final bigAmount = BigInt.from(1500000000);
      final formatted = CurrencyFormatter.formatBigIntMinor(bigAmount, currency: 'IDR');
      expect(formatted.replaceAll(RegExp(r'\s+'), ' '), contains('Rp 1.500.000.000'));
    });

    test('formats USD minor units (cents) deterministically without float division', () {
      final formatted = CurrencyFormatter.formatMinorUnit(1250, currency: 'USD');
      expect(formatted, contains(r'$12.50'));
    });

    test('masks balance with privacy shield dots when isMasked is true', () {
      final masked = CurrencyFormatter.formatMasked(145000, isMasked: true);
      expect(masked, equals(AppConstants.privacyMask));

      final unmasked = CurrencyFormatter.formatMasked(145000, isMasked: false);
      expect(unmasked.replaceAll(RegExp(r'\s+'), ' '), contains('Rp 145.000'));
    });

    test('formats compact Rupiah for denomination chips & buttons', () {
      expect(CurrencyFormatter.formatCompactRupiah(10000, prefix: '+'), equals('+10k'));
      expect(CurrencyFormatter.formatCompactRupiah(50000, prefix: '+'), equals('+50k'));
      expect(CurrencyFormatter.formatCompactRupiah(100000, prefix: '+'), equals('+100k'));
      expect(CurrencyFormatter.formatCompactRupiah(500000, prefix: '+'), equals('+500k'));
      expect(CurrencyFormatter.formatCompactRupiah(1500000), equals('1.5M'));
      expect(CurrencyFormatter.formatCompactRupiah(10000, isMasked: true), equals(AppConstants.privacyMask));
    });

    test('calculates work hours equivalence using deterministic integer math', () {
      // 85.000 with 65.000/hr wage -> 1.3 hours
      expect(CurrencyFormatter.calculateWorkHours(85000, hourlyWage: 65000), equals('1.3'));
      // 145.000 with 65.000/hr wage -> 2.2 hours
      expect(CurrencyFormatter.calculateWorkHours(145000, hourlyWage: 65000), equals('2.2'));
    });
  });
}
