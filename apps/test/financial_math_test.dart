import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/utils/currency_formatter.dart';
import 'package:savoryx/core/utils/financial_math.dart';

void main() {
  group('FinancialMath (Zero-Floating-Point)', () {
    test('deterministic integer division with rounding modes', () {
      // 10 / 3 = 3.333... -> halfUp: 3, up: 4, down: 3
      expect(FinancialMath.divide(10, 3, mode: RoundingMode.halfUp), equals(3));
      expect(FinancialMath.divide(10, 3, mode: RoundingMode.up), equals(4));
      expect(FinancialMath.divide(10, 3, mode: RoundingMode.down), equals(3));

      // 11 / 3 = 3.666... -> halfUp: 4, up: 4, down: 3
      expect(FinancialMath.divide(11, 3, mode: RoundingMode.halfUp), equals(4));
      expect(FinancialMath.divide(11, 3, mode: RoundingMode.up), equals(4));
      expect(FinancialMath.divide(11, 3, mode: RoundingMode.down), equals(3));

      // Exact division
      expect(FinancialMath.divide(100, 4), equals(25));

      // Division by zero throws ArgumentError
      expect(() => FinancialMath.divide(10, 0), throwsArgumentError);
    });

    test('multiplyAndDivide prevents intermediate overflow and loss of precision', () {
      // (100 * 3) / 2 = 150
      expect(FinancialMath.multiplyAndDivide(100, 3, 2), equals(150));

      // (10,000,000,000 * 2) / 5 = 4,000,000,000
      expect(
        FinancialMath.multiplyAndDivide(10000000000, 2, 5),
        equals(4000000000),
      );

      // Division by zero throws ArgumentError
      expect(() => FinancialMath.multiplyAndDivide(10, 2, 0), throwsArgumentError);
    });

    test('proportional allocation guarantees exact sum without single unit loss (Hare-Niemeyer)', () {
      // 100 Rupiah split 1:1:1 -> 34 + 33 + 33 = 100 exactly
      final alloc1 = FinancialMath.allocate(100, [1, 1, 1]);
      expect(alloc1, equals([34, 33, 33]));
      expect(alloc1.reduce((a, b) => a + b), equals(100));

      // 50,000 split 50/30/20 (5:3:2) -> 25,000 + 15,000 + 10,000 = 50,000
      final alloc2 = FinancialMath.allocate(50000, [5, 3, 2]);
      expect(alloc2, equals([25000, 15000, 10000]));
      expect(alloc2.reduce((a, b) => a + b), equals(50000));

      // Odd amounts: 1 split 1:1 -> [1, 0], sum = 1
      final alloc3 = FinancialMath.allocate(1, [1, 1]);
      expect(alloc3, equals([1, 0]));
      expect(alloc3.reduce((a, b) => a + b), equals(1));

      // Empty ratios
      expect(FinancialMath.allocate(100, []), isEmpty);

      // Negative or zero ratios throw ArgumentError
      expect(() => FinancialMath.allocate(100, [-1, 2]), throwsArgumentError);
      expect(() => FinancialMath.allocate(100, [0, 0]), throwsArgumentError);
    });

    test('calculates Basis Points (BPS) and scales accurately', () {
      // 50 out of 100 is 50.00% -> 5,000 bps
      expect(FinancialMath.toBasisPoints(50, 100), equals(5000));

      // 1 out of 8 is 12.50% -> 1,250 bps
      expect(FinancialMath.toBasisPoints(1, 8), equals(1250));

      // Amount from BPS: 2.50% (250 bps) of 1,000,000 -> 25,000
      expect(FinancialMath.fromBasisPoints(1000000, 250), equals(25000));

      // Zero whole returns 0 bps
      expect(FinancialMath.toBasisPoints(10, 0), equals(0));
    });

    test('formats percentage strings strictly via integer arithmetic', () {
      expect(FinancialMath.percentageString(1, 2), equals('50.00%'));
      expect(FinancialMath.percentageString(1, 3), equals('33.33%'));
      expect(FinancialMath.percentageString(2, 3, decimalPlaces: 1), equals('66.7%'));
      expect(FinancialMath.percentageString(2, 3, decimalPlaces: 0), equals('67%'));
      expect(FinancialMath.percentageString(1, 4, includeSymbol: false), equals('25.00'));
      expect(FinancialMath.percentageString(0, 100), equals('0.00%'));
      expect(FinancialMath.percentageString(10, 0), equals('0.00%'));
    });

    test('parses currency strings into minor units without floating-point conversion', () {
      // IDR (0 decimal places)
      expect(FinancialMath.parseCurrencyToMinorUnits('Rp 150.000'), equals(150000));
      expect(FinancialMath.parseCurrencyToMinorUnits('Rp 1.500.000,00'), equals(1500000));
      expect(FinancialMath.parseCurrencyToMinorUnits('50000'), equals(50000));
      expect(FinancialMath.parseCurrencyToMinorUnits('-Rp 25.000'), equals(-25000));
      expect(FinancialMath.parseCurrencyToMinorUnits(''), equals(0));

      // USD (2 decimal places)
      expect(
        FinancialMath.parseCurrencyToMinorUnits(r'$12.50', decimalPlaces: 2),
        equals(1250),
      );
      expect(
        FinancialMath.parseCurrencyToMinorUnits(r'$1,250.00', decimalPlaces: 2),
        equals(125000),
      );
      expect(
        FinancialMath.parseCurrencyToMinorUnits(r'0.99', decimalPlaces: 2),
        equals(99),
      );
    });

    test('CurrencyFormatter parses to minor unit and BigInt integration', () {
      expect(CurrencyFormatter.parseToMinorUnit('Rp 85.000'), equals(85000));
      expect(CurrencyFormatter.parseToMinorUnit(r'$15.75', currency: 'USD'), equals(1575));
      expect(CurrencyFormatter.parseToBigInt('Rp 500.000'), equals(BigInt.from(500000)));
    });
  });
}
