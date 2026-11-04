import 'package:savoryx/core/utils/financial_math.dart';

class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    this.decimalDigits = 2,
  });

  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;

  BigInt get minorUnitFactor {
    var factor = BigInt.one;
    for (var i = 0; i < decimalDigits; i++) {
      factor *= BigInt.from(10);
    }
    return factor;
  }
}

abstract final class CurrencyConverter {
  static const String defaultBaseCurrency = 'IDR';

  static const int rateScaleInt = 1000000;
  static final BigInt rateScale = BigInt.from(rateScaleInt);

  static const Map<String, CurrencyInfo> supportedCurrencies = {
    'IDR': CurrencyInfo(
        code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah', decimalDigits: 2),
    'USD': CurrencyInfo(
        code: 'USD', symbol: '\$', name: 'US Dollar', decimalDigits: 2),
    'SGD': CurrencyInfo(
        code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', decimalDigits: 2),
    'EUR':
        CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', decimalDigits: 2),
    'JPY': CurrencyInfo(
        code: 'JPY', symbol: '¥', name: 'Japanese Yen', decimalDigits: 0),
    'GBP': CurrencyInfo(
        code: 'GBP', symbol: '£', name: 'British Pound', decimalDigits: 2),
    'AUD': CurrencyInfo(
        code: 'AUD',
        symbol: 'A\$',
        name: 'Australian Dollar',
        decimalDigits: 2),
    'CNY': CurrencyInfo(
        code: 'CNY', symbol: '¥', name: 'Chinese Yuan', decimalDigits: 2),
    'MYR': CurrencyInfo(
        code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit', decimalDigits: 2),
    'THB': CurrencyInfo(
        code: 'THB', symbol: '฿', name: 'Thai Baht', decimalDigits: 2),
    'KRW': CurrencyInfo(
        code: 'KRW', symbol: '₩', name: 'South Korean Won', decimalDigits: 0),
    'CAD': CurrencyInfo(
        code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar', decimalDigits: 2),
    'CHF': CurrencyInfo(
        code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', decimalDigits: 2),
    'HKD': CurrencyInfo(
        code: 'HKD',
        symbol: 'HK\$',
        name: 'Hong Kong Dollar',
        decimalDigits: 2),
    'NZD': CurrencyInfo(
        code: 'NZD',
        symbol: 'NZ\$',
        name: 'New Zealand Dollar',
        decimalDigits: 2),
    'PHP': CurrencyInfo(
        code: 'PHP', symbol: '₱', name: 'Philippine Peso', decimalDigits: 2),
    'VND': CurrencyInfo(
        code: 'VND', symbol: '₫', name: 'Vietnamese Dong', decimalDigits: 0),
  };

  static BigInt convertToBaseAmount({
    required BigInt foreignAmount,
    required BigInt rateScaled,
    RoundingMode mode = RoundingMode.halfUp,
  }) {
    if (rateScaled <= BigInt.zero) {
      throw ArgumentError.value(
          rateScaled, 'rateScaled', 'Exchange rate must be strictly positive');
    }

    final product = foreignAmount * rateScaled;
    final quotient = product ~/ rateScale;
    final remainder = product % rateScale;

    if (remainder == BigInt.zero) {
      return quotient;
    }

    return _applyRounding(product, rateScale, quotient, remainder, mode);
  }

  static BigInt convertFromBaseAmount({
    required BigInt baseAmount,
    required BigInt rateScaled,
    RoundingMode mode = RoundingMode.halfUp,
  }) {
    if (rateScaled <= BigInt.zero) {
      throw ArgumentError.value(
          rateScaled, 'rateScaled', 'Exchange rate must be strictly positive');
    }

    final product = baseAmount * rateScale;
    final quotient = product ~/ rateScaled;
    final remainder = product % rateScaled;

    if (remainder == BigInt.zero) {
      return quotient;
    }

    return _applyRounding(product, rateScaled, quotient, remainder, mode);
  }

  /// Helper to convert integer rate strings (e.g., "16250.75") into scaled integer BigInt (16250750000).
  static BigInt parseRateToScaled(String rateStr) {
    final cleaned = rateStr.trim();
    if (cleaned.isEmpty) {
      throw const FormatException('Rate string cannot be empty');
    }

    final parts = cleaned.split('.');
    final whole = BigInt.parse(parts[0]);

    if (parts.length == 1) {
      return whole * rateScale;
    }

    if (parts.length > 2) {
      throw FormatException('Invalid rate format: $rateStr');
    }

    var decStr = parts[1];
    if (decStr.length > 6) {
      decStr = decStr.substring(0, 6);
    } else {
      decStr = decStr.padRight(6, '0');
    }

    final decimals = BigInt.parse(decStr);
    return (whole * rateScale) + (whole < BigInt.zero ? -decimals : decimals);
  }

  /// Formats scaled BigInt rate back to a human-readable string with up to 6 decimal digits.
  static String formatScaledRate(BigInt rateScaled) {
    final isNegative = rateScaled < BigInt.zero;
    final absRate = rateScaled.abs();
    final whole = absRate ~/ rateScale;
    final remainder = absRate % rateScale;

    if (remainder == BigInt.zero) {
      return '${isNegative ? '-' : ''}$whole';
    }

    final decStr =
        remainder.toString().padLeft(6, '0').replaceAll(RegExp(r'0+$'), '');
    return '${isNegative ? '-' : ''}$whole.$decStr';
  }

  static BigInt _applyRounding(
    BigInt product,
    BigInt divisor,
    BigInt quotient,
    BigInt remainder,
    RoundingMode mode,
  ) {
    final absRemainder = remainder.abs();
    final absDivisor = divisor.abs();
    final isPositive = (product >= BigInt.zero) == (divisor >= BigInt.zero);
    final two = BigInt.two;

    switch (mode) {
      case RoundingMode.down:
        if (!isPositive && remainder != BigInt.zero) {
          return quotient - BigInt.one;
        }
        return quotient;

      case RoundingMode.up:
        if (isPositive && remainder != BigInt.zero) {
          return quotient + BigInt.one;
        }
        return quotient;

      case RoundingMode.halfUp:
        if (absRemainder * two >= absDivisor) {
          return isPositive ? quotient + BigInt.one : quotient - BigInt.one;
        }
        return quotient;

      case RoundingMode.halfEven:
        if (absRemainder * two > absDivisor) {
          return isPositive ? quotient + BigInt.one : quotient - BigInt.one;
        } else if (absRemainder * two == absDivisor) {
          return (quotient % two == BigInt.zero)
              ? quotient
              : (isPositive ? quotient + BigInt.one : quotient - BigInt.one);
        }
        return quotient;
    }
  }
}
