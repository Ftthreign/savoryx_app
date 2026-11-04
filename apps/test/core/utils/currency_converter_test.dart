import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/utils/currency_converter.dart';
import 'package:savoryx/core/utils/financial_math.dart';

void main() {
  group('CurrencyConverter Deterministic Fixed-Point Tests (Task #30)', () {
    final rate16k = BigInt.from(16000000000); // 16,000.00 IDR per USD scaled by 10^6
    final rate1625075 = BigInt.from(16250750000); // 16,250.75 IDR per USD

    test('identity rate (1.0) converts foreign amount 1:1 to base amount', () {
      final foreign = BigInt.from(50000); // 500.00
      final base = CurrencyConverter.convertToBaseAmount(
        foreignAmount: foreign,
        rateScaled: CurrencyConverter.rateScale, // 1,000,000
      );
      expect(base, equals(foreign));
    });

    test('exact rate conversion converts cents to sen without precision drift', () {
      // 10.00 USD (1000 cents) @ 16,000 IDR/USD -> 160,000.00 IDR (16,000,000 sen)
      final foreignUSD = BigInt.from(1000);
      final baseIDR = CurrencyConverter.convertToBaseAmount(
        foreignAmount: foreignUSD,
        rateScaled: rate16k,
      );
      expect(baseIDR, equals(BigInt.from(16000000)));

      // Reverse conversion: 160,000.00 IDR -> 10.00 USD (1000 cents)
      final backUSD = CurrencyConverter.convertFromBaseAmount(
        baseAmount: baseIDR,
        rateScaled: rate16k,
      );
      expect(backUSD, equals(foreignUSD));
    });

    test('fractional conversion applies RoundingMode correctly', () {
      // 15.00 USD (1500 cents) @ 16,250.75 IDR/USD
      // Exact = 1500 * 16250750000 / 1000000 = 24,376,125 sen (Rp 243.761,25)
      final foreign = BigInt.from(1500);
      final base = CurrencyConverter.convertToBaseAmount(
        foreignAmount: foreign,
        rateScaled: rate1625075,
      );
      expect(base, equals(BigInt.from(24376125)));

      // Truncate vs HalfUp with odd fractions:
      // foreign = 1, rateScaled = 1,500,000 (1.5 IDR per unit)
      // product = 1,500,000 / 1,000,000 = 1 remainder 500,000 (tie 0.5)
      final oneUnit = BigInt.one;
      final rate1_5 = BigInt.from(1500000);

      final roundedHalfUp = CurrencyConverter.convertToBaseAmount(
        foreignAmount: oneUnit,
        rateScaled: rate1_5,
        mode: RoundingMode.halfUp,
      );
      expect(roundedHalfUp, equals(BigInt.two));

      final roundedDown = CurrencyConverter.convertToBaseAmount(
        foreignAmount: oneUnit,
        rateScaled: rate1_5,
        mode: RoundingMode.down,
      );
      expect(roundedDown, equals(BigInt.one));
    });

    test('zero and negative amounts are handled deterministically', () {
      expect(
        CurrencyConverter.convertToBaseAmount(
          foreignAmount: BigInt.zero,
          rateScaled: rate16k,
        ),
        equals(BigInt.zero),
      );

      // Refund adjustment of -5.00 USD (-500 cents)
      final refund = CurrencyConverter.convertToBaseAmount(
        foreignAmount: BigInt.from(-500),
        rateScaled: rate16k,
      );
      expect(refund, equals(BigInt.from(-8000000)));
    });

    test('rate less than or equal to zero throws ArgumentError', () {
      expect(
        () => CurrencyConverter.convertToBaseAmount(
          foreignAmount: BigInt.from(100),
          rateScaled: BigInt.zero,
        ),
        throwsArgumentError,
      );

      expect(
        () => CurrencyConverter.convertToBaseAmount(
          foreignAmount: BigInt.from(100),
          rateScaled: BigInt.from(-1000000),
        ),
        throwsArgumentError,
      );
    });

    group('Rate Parsing & Formatting Helpers', () {
      test('parseRateToScaled parses integer and decimal strings into scaled BigInt', () {
        expect(
          CurrencyConverter.parseRateToScaled('16000'),
          equals(BigInt.from(16000000000)),
        );
        expect(
          CurrencyConverter.parseRateToScaled('16250.75'),
          equals(BigInt.from(16250750000)),
        );
        expect(
          CurrencyConverter.parseRateToScaled('1.000000'),
          equals(BigInt.from(1000000)),
        );
        expect(
          CurrencyConverter.parseRateToScaled('0.5'),
          equals(BigInt.from(500000)),
        );
      });

      test('parseRateToScaled throws FormatException on invalid inputs', () {
        expect(() => CurrencyConverter.parseRateToScaled(''), throwsFormatException);
        expect(() => CurrencyConverter.parseRateToScaled('1.2.3'), throwsFormatException);
        expect(() => CurrencyConverter.parseRateToScaled('abc'), throwsFormatException);
      });

      test('formatScaledRate converts scaled BigInt to clean string', () {
        expect(
          CurrencyConverter.formatScaledRate(BigInt.from(16000000000)),
          equals('16000'),
        );
        expect(
          CurrencyConverter.formatScaledRate(BigInt.from(16250750000)),
          equals('16250.75'),
        );
        expect(
          CurrencyConverter.formatScaledRate(BigInt.from(1000000)),
          equals('1'),
        );
        expect(
          CurrencyConverter.formatScaledRate(BigInt.from(500000)),
          equals('0.5'),
        );
      });
    });

    group('Supported Currencies Metadata', () {
      test('contains 15+ global currencies with default base IDR', () {
        expect(CurrencyConverter.defaultBaseCurrency, equals('IDR'));
        expect(CurrencyConverter.supportedCurrencies.length, greaterThanOrEqualTo(15));
        expect(CurrencyConverter.supportedCurrencies.containsKey('IDR'), isTrue);
        expect(CurrencyConverter.supportedCurrencies.containsKey('USD'), isTrue);
        expect(CurrencyConverter.supportedCurrencies.containsKey('SGD'), isTrue);
        expect(CurrencyConverter.supportedCurrencies.containsKey('JPY'), isTrue);
        expect(CurrencyConverter.supportedCurrencies.containsKey('EUR'), isTrue);
      });

      test('minorUnitFactor correctly reflects decimalDigits', () {
        final idr = CurrencyConverter.supportedCurrencies['IDR']!;
        expect(idr.minorUnitFactor, equals(BigInt.from(100)));

        final jpy = CurrencyConverter.supportedCurrencies['JPY']!;
        expect(jpy.minorUnitFactor, equals(BigInt.one)); // 0 digits
      });
    });
  });
}
