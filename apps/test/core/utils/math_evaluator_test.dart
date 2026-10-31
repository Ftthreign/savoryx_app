import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/utils/math_evaluator.dart';

void main() {
  group('MathEvaluator (Pure Dart Integer Math Engine)', () {
    group('Basic Operations & Precedence', () {
      test('evaluates simple single-operator expressions', () {
        expect(MathEvaluator.evaluate('50000 + 25000'), equals(BigInt.from(75000)));
        expect(MathEvaluator.evaluate('100000 - 35000'), equals(BigInt.from(65000)));
        expect(MathEvaluator.evaluate('15000 * 3'), equals(BigInt.from(45000)));
        expect(MathEvaluator.evaluate('100000 / 4'), equals(BigInt.from(25000)));
      });

      test('supports visual operator aliases: ×, ÷, x, X', () {
        expect(MathEvaluator.evaluate('20000 × 3'), equals(BigInt.from(60000)));
        expect(MathEvaluator.evaluate('90000 ÷ 3'), equals(BigInt.from(30000)));
        expect(MathEvaluator.evaluate('12000 x 4'), equals(BigInt.from(48000)));
        expect(MathEvaluator.evaluate('15000 X 2'), equals(BigInt.from(30000)));
      });

      test('strictly respects operator precedence (* and / over + and -)', () {
        // 50000 + (20000 * 2) = 90000, NOT (50000 + 20000) * 2 = 140000
        expect(MathEvaluator.evaluate('50000 + 20000 * 2'), equals(BigInt.from(90000)));
        expect(MathEvaluator.evaluate('100000 - 30000 / 3'), equals(BigInt.from(90000)));
        expect(MathEvaluator.evaluate('2 * 50000 + 30000'), equals(BigInt.from(130000)));
      });

      test('evaluates left-to-right for same precedence operators', () {
        // 100 - 30 - 20 = 50, NOT 100 - (30 - 20) = 90
        expect(MathEvaluator.evaluate('100 - 30 - 20'), equals(BigInt.from(50)));
        // 100 / 2 / 2 = 25, NOT 100 / (2 / 2) = 100
        expect(MathEvaluator.evaluate('100 / 2 / 2'), equals(BigInt.from(25)));
      });

      test('handles integer division truncation without IEEE-754 floating point', () {
        expect(MathEvaluator.evaluate('100 / 3'), equals(BigInt.from(33)));
        expect(MathEvaluator.evaluate('10 / 4'), equals(BigInt.from(2)));
        expect(MathEvaluator.evaluate('7 / 2'), equals(BigInt.from(3)));
      });

      test('supports parenthesized expressions and nested parentheses', () {
        expect(MathEvaluator.evaluate('(50000 + 20000) * 2'), equals(BigInt.from(140000)));
        expect(MathEvaluator.evaluate('2 * (100000 - 35000)'), equals(BigInt.from(130000)));
        expect(MathEvaluator.evaluate('((10000 + 20000) * 2) - 5000'), equals(BigInt.from(55000)));
      });

      test('supports unary positive and negative numbers', () {
        expect(MathEvaluator.evaluate('-5000 + 10000'), equals(BigInt.from(5000)));
        expect(MathEvaluator.evaluate('+25000'), equals(BigInt.from(25000)));
        expect(MathEvaluator.evaluate('50000 + -20000'), equals(BigInt.from(30000)));
        expect(MathEvaluator.evaluate('--5000'), equals(BigInt.from(5000)));
      });

      test('handles complex multi-operator chained expressions', () {
        // 15000 + (25000 * 3) - (5000 / 2) = 15000 + 75000 - 2500 = 87500
        expect(
          MathEvaluator.evaluate('15000 + 25000 * 3 - 5000 / 2'),
          equals(BigInt.from(87500)),
        );
      });
    });

    group('Safety Guards & Validation', () {
      test('division by zero returns null safely without throwing', () {
        expect(MathEvaluator.evaluate('100000 / 0'), isNull);
        expect(MathEvaluator.evaluate('50000 + 100 / 0'), isNull);
        expect(MathEvaluator.evaluate('100 ÷ 0'), isNull);
      });

      test('enforces max 12-digit operand limit to prevent overflow attacks', () {
        // 12 digits: exactly 999,999,999,999 -> valid
        expect(MathEvaluator.evaluate('999999999999'), equals(BigInt.parse('999999999999')));
        // 13 digits: 1,000,000,000,000 -> exceeds limit, returns null
        expect(MathEvaluator.evaluate('1000000000000'), isNull);
        expect(MathEvaluator.evaluate('50000 + 1000000000000'), isNull);
      });

      test('handles large numbers well beyond 32-bit integer limits', () {
        final result = MathEvaluator.evaluate('5000000000 + 7000000000');
        expect(result, equals(BigInt.parse('12000000000')));
      });

      test('returns null on incomplete expressions with trailing operators', () {
        expect(MathEvaluator.evaluate('50000 +'), isNull);
        expect(MathEvaluator.evaluate('10000 *'), isNull);
        expect(MathEvaluator.evaluate('25000 -'), isNull);
        expect(MathEvaluator.evaluate('100 /'), isNull);
      });

      test('returns null on empty, blank, or whitespace-only inputs', () {
        expect(MathEvaluator.evaluate(''), isNull);
        expect(MathEvaluator.evaluate('   '), isNull);
        expect(MathEvaluator.evaluate('\t\n'), isNull);
      });

      test('returns null on invalid syntax or non-numeric characters', () {
        expect(MathEvaluator.evaluate('50000abc'), isNull);
        expect(MathEvaluator.evaluate('hello'), isNull);
        expect(MathEvaluator.evaluate('+ +'), isNull);
        expect(MathEvaluator.evaluate('* 5000'), isNull);
        expect(MathEvaluator.evaluate('/ 100'), isNull);
      });

      test('returns null on unbalanced or mismatched parentheses', () {
        expect(MathEvaluator.evaluate('(50000 + 20000'), isNull);
        expect(MathEvaluator.evaluate('50000 + 20000)'), isNull);
        expect(MathEvaluator.evaluate(')(50000)('), isNull);
      });
    });

    group('hasOperator Detection', () {
      test('identifies expressions containing valid operators', () {
        expect(MathEvaluator.hasOperator('50000 + 2000'), isTrue);
        expect(MathEvaluator.hasOperator('50000-2000'), isTrue);
        expect(MathEvaluator.hasOperator('10000 * 2'), isTrue);
        expect(MathEvaluator.hasOperator('10000 / 2'), isTrue);
        expect(MathEvaluator.hasOperator('10000 × 2'), isTrue);
        expect(MathEvaluator.hasOperator('10000 ÷ 2'), isTrue);
        expect(MathEvaluator.hasOperator('10000 x 2'), isTrue);
        expect(MathEvaluator.hasOperator('10000 X 2'), isTrue);
      });

      test('returns false when no operator is present', () {
        expect(MathEvaluator.hasOperator('50000'), isFalse);
        expect(MathEvaluator.hasOperator('0'), isFalse);
        expect(MathEvaluator.hasOperator('999999'), isFalse);
        expect(MathEvaluator.hasOperator(''), isFalse);
      });
    });

    group('tryFormatLivePreview', () {
      test('formats complete single number into currency preview', () {
        expect(MathEvaluator.tryFormatLivePreview('50000'), equals('Rp 50.000'));
        expect(MathEvaluator.tryFormatLivePreview('1500000'), equals('Rp 1.500.000'));
      });

      test('strips trailing operator to provide preview of evaluated prefix', () {
        expect(MathEvaluator.tryFormatLivePreview('50000 + '), equals('Rp 50.000'));
        expect(MathEvaluator.tryFormatLivePreview('75000 -'), equals('Rp 75.000'));
        expect(MathEvaluator.tryFormatLivePreview('10000 × '), equals('Rp 10.000'));
        expect(MathEvaluator.tryFormatLivePreview('20000 ÷'), equals('Rp 20.000'));
        expect(MathEvaluator.tryFormatLivePreview('12000 x '), equals('Rp 12.000'));
      });

      test('evaluates live intermediate expressions while typing second operand', () {
        expect(MathEvaluator.tryFormatLivePreview('50000 + 25000'), equals('Rp 75.000'));
        expect(MathEvaluator.tryFormatLivePreview('50000 + 25000 * 2'), equals('Rp 100.000'));
      });

      test('strips trailing operator on multi-term expression', () {
        // "50000 + 25000 +" -> evaluates "50000 + 25000" = 75000
        expect(MathEvaluator.tryFormatLivePreview('50000 + 25000 +'), equals('Rp 75.000'));
        expect(MathEvaluator.tryFormatLivePreview('50000 + 25000 *'), equals('Rp 75.000'));
      });

      test('returns null for isolated operators or invalid expressions', () {
        expect(MathEvaluator.tryFormatLivePreview('+'), isNull);
        expect(MathEvaluator.tryFormatLivePreview('-'), isNull);
        expect(MathEvaluator.tryFormatLivePreview('*'), isNull);
        expect(MathEvaluator.tryFormatLivePreview(''), isNull);
        expect(MathEvaluator.tryFormatLivePreview('   '), isNull);
        expect(MathEvaluator.tryFormatLivePreview('invalid'), isNull);
      });

      test('supports foreign currency formatting (e.g. USD)', () {
        // 1250 cents = $12.50
        expect(
          MathEvaluator.tryFormatLivePreview('1000 + 250', currency: 'USD'),
          equals(r'$12.50'),
        );
      });

      test('handles zero operands and arithmetic identity properly', () {
        expect(MathEvaluator.evaluate('0 + 50000'), equals(BigInt.from(50000)));
        expect(MathEvaluator.evaluate('50000 * 0'), equals(BigInt.zero));
        expect(MathEvaluator.evaluate('0 / 50000'), equals(BigInt.zero));
        expect(MathEvaluator.evaluate('50000 * 1'), equals(BigInt.from(50000)));
      });

      test('handles double negation inside parentheses', () {
        expect(MathEvaluator.evaluate('10000 - (-5000)'), equals(BigInt.from(15000)));
      });

      test('ignores arbitrary spaces and tabs within expressions', () {
        expect(MathEvaluator.evaluate('  50000   +   25000  '), equals(BigInt.from(75000)));
        expect(MathEvaluator.tryFormatLivePreview(' 50000 + 20000 × '), equals('Rp 70.000'));
      });
    });
  });
}
