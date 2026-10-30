abstract final class FinancialMath {
  /// Basis points constant: 10,000 basis points equals 100.00%.
  static const int basisPointsScale = 10000;

  /// Deterministic division of two integers with specified [RoundingMode].
  ///
  /// Prevents IEEE-754 precision loss that occurs when using the `/` operator.
  static int divide(
    int dividend,
    int divisor, {
    RoundingMode mode = RoundingMode.halfUp,
  }) {
    if (divisor == 0) {
      throw ArgumentError('Divisor cannot be zero.');
    }

    final int quotient = dividend ~/ divisor;
    final int remainder = dividend % divisor;

    if (remainder == 0) {
      return quotient;
    }

    return _applyRounding(dividend, divisor, quotient, remainder, mode);
  }

  /// Multiply [value] by [multiplier] then divide by [divisor] in a single step
  /// to minimize intermediate precision loss without floating-point conversion.
  static int multiplyAndDivide(
    int value,
    int multiplier,
    int divisor, {
    RoundingMode mode = RoundingMode.halfUp,
  }) {
    if (divisor == 0) {
      throw ArgumentError('Divisor cannot be zero.');
    }

    // Use BigInt internally for intermediate multiplication to prevent 64-bit overflow
    final BigInt v = BigInt.from(value);
    final BigInt m = BigInt.from(multiplier);
    final BigInt d = BigInt.from(divisor);

    final BigInt product = v * m;
    final BigInt quotient = product ~/ d;
    final BigInt remainder = product % d;

    if (remainder == BigInt.zero) {
      return quotient.toInt();
    }

    return _applyRoundingBigInt(product, d, quotient, remainder, mode).toInt();
  }

  /// Proportional allocation using the Hare-Niemeyer (Largest Remainder) method.
  ///
  /// Guarantees that the sum of allocated parts exactly equals [totalAmount]
  /// without losing a single minor unit (cent/rupiah) due to integer truncation.
  ///
  /// Example:
  /// ```dart
  /// // Allocate 100 Rupiah with 1:1:1 ratio
  /// final result = FinancialMath.allocate(100, [1, 1, 1]); // [34, 33, 33] -> Sum = 100
  /// ```
  static List<int> allocate(int totalAmount, List<int> ratios) {
    if (ratios.isEmpty) {
      return <int>[];
    }

    int sumRatios = 0;
    for (final int r in ratios) {
      if (r < 0) {
        throw ArgumentError('Ratio weight cannot be negative: $r');
      }
      sumRatios += r;
    }

    if (sumRatios == 0) {
      throw ArgumentError('Sum of ratios must be greater than zero.');
    }

    final int n = ratios.length;
    final List<int> results = List<int>.filled(n, 0);
    final List<_AllocationRemainder> remainders = <_AllocationRemainder>[];

    int remainderSum = totalAmount;

    for (int i = 0; i < n; i++) {
      final int weight = ratios[i];
      final int allocated = (BigInt.from(totalAmount) *
              BigInt.from(weight) ~/
              BigInt.from(sumRatios))
          .toInt();
      results[i] = allocated;
      remainderSum -= allocated;

      final int rem = (BigInt.from(totalAmount) *
              BigInt.from(weight) %
              BigInt.from(sumRatios))
          .toInt();
      remainders.add(_AllocationRemainder(index: i, remainder: rem));
    }

    // Sort descending by remainder to distribute unallocated units
    remainders.sort((a, b) => b.remainder.compareTo(a.remainder));

    for (int i = 0; i < remainderSum; i++) {
      results[remainders[i].index]++;
    }

    return results;
  }

  /// Calculates the ratio of [part] to [whole] in Basis Points (BPS).
  ///
  /// 10,000 bps = 100.00%, 5,000 bps = 50.00%, 125 bps = 1.25%.
  static int toBasisPoints(int part, int whole) {
    if (whole == 0) {
      return 0;
    }
    return multiplyAndDivide(part, basisPointsScale, whole,
        mode: RoundingMode.halfUp);
  }

  /// Calculates amount from [whole] given [bps] (Basis Points).
  static int fromBasisPoints(
    int whole,
    int bps, {
    RoundingMode mode = RoundingMode.halfUp,
  }) {
    return multiplyAndDivide(whole, bps, basisPointsScale, mode: mode);
  }

  /// Formats percentage string strictly using integer math without `double`.
  ///
  /// Example:
  /// `percentageString(1, 3)` -> `"33.33%"`
  /// `percentageString(1, 2, decimalPlaces: 1)` -> `"50.0%"`
  static String percentageString(
    int part,
    int whole, {
    int decimalPlaces = 2,
    bool includeSymbol = true,
  }) {
    if (whole == 0) {
      return decimalPlaces > 0
          ? '0.${'0' * decimalPlaces}${includeSymbol ? '%' : ''}'
          : '0${includeSymbol ? '%' : ''}';
    }

    int scale = 100;
    for (int i = 0; i < decimalPlaces; i++) {
      scale *= 10;
    }

    final int scaled =
        multiplyAndDivide(part, scale, whole, mode: RoundingMode.halfUp);
    final String sign = scaled < 0 ? '-' : '';
    final int absScaled = scaled.abs();

    if (decimalPlaces == 0) {
      return '$sign$absScaled${includeSymbol ? '%' : ''}';
    }

    final int divisor = scale ~/ 100;
    final int integerPart = absScaled ~/ divisor;
    final int fractionPart = absScaled % divisor;

    final String fracStr = fractionPart.toString().padLeft(decimalPlaces, '0');
    return '$sign$integerPart.$fracStr${includeSymbol ? '%' : ''}';
  }

  /// Parses monetary string into integer minor units without calling `double.parse()`.
  ///
  /// Handles symbols (`Rp`, `$`), spaces, and thousand/decimal separators.
  /// [decimalPlaces] specifies minor unit precision (0 for IDR/JPY, 2 for USD/EUR).
  static int parseCurrencyToMinorUnits(
    String input, {
    int decimalPlaces = 0,
  }) {
    final String clean = input.trim();
    if (clean.isEmpty) {
      return 0;
    }

    final bool isNegative = clean.startsWith('-') || clean.startsWith('(');

    final String sanitized = clean.replaceAll(RegExp(r'[^\d.,]'), '');
    if (sanitized.isEmpty) {
      return 0;
    }

    String integerPart = sanitized;
    String fractionalPart = '';

    final int lastDot = sanitized.lastIndexOf('.');
    final int lastComma = sanitized.lastIndexOf(',');
    final int separatorIdx = lastDot > lastComma ? lastDot : lastComma;

    final bool hasTrailingFraction = separatorIdx != -1 &&
        (sanitized.length - separatorIdx - 1 <= 2) &&
        (sanitized.length - separatorIdx - 1 > 0);

    if (decimalPlaces > 0) {
      if (hasTrailingFraction) {
        integerPart = sanitized
            .substring(0, separatorIdx)
            .replaceAll(RegExp(r'[^\d]'), '');
        fractionalPart = sanitized
            .substring(separatorIdx + 1)
            .replaceAll(RegExp(r'[^\d]'), '');
      } else {
        integerPart = sanitized.replaceAll(RegExp(r'[^\d]'), '');
      }
    } else {
      // Currency has zero decimal places (IDR, JPY)
      if (hasTrailingFraction && (lastDot != -1 && lastComma != -1)) {
        integerPart = sanitized
            .substring(0, separatorIdx)
            .replaceAll(RegExp(r'[^\d]'), '');
      } else if (hasTrailingFraction &&
          (sanitized.endsWith(',00') || sanitized.endsWith('.00'))) {
        integerPart = sanitized
            .substring(0, separatorIdx)
            .replaceAll(RegExp(r'[^\d]'), '');
      } else {
        integerPart = sanitized.replaceAll(RegExp(r'[^\d]'), '');
      }
    }

    if (integerPart.isEmpty) {
      integerPart = '0';
    }

    // Pad or trim fractional part to exact decimalPlaces
    if (decimalPlaces > 0) {
      if (fractionalPart.length > decimalPlaces) {
        fractionalPart = fractionalPart.substring(0, decimalPlaces);
      } else {
        fractionalPart = fractionalPart.padRight(decimalPlaces, '0');
      }
    }

    final String combined = '$integerPart$fractionalPart';
    final int result = int.tryParse(combined) ?? 0;
    return isNegative ? -result : result;
  }

  static int _applyRounding(
    int dividend,
    int divisor,
    int quotient,
    int remainder,
    RoundingMode mode,
  ) {
    final bool isPositive = (dividend >= 0) == (divisor >= 0);
    final int absRemainder = remainder.abs();
    final int absDivisor = divisor.abs();

    switch (mode) {
      case RoundingMode.down:
        if (!isPositive && remainder != 0) {
          return quotient - 1;
        }
        return quotient;

      case RoundingMode.up:
        if (isPositive && remainder != 0) {
          return quotient + 1;
        }
        return quotient;

      case RoundingMode.halfUp:
        if (absRemainder * 2 >= absDivisor) {
          return isPositive ? quotient + 1 : quotient - 1;
        }
        return quotient;

      case RoundingMode.halfEven:
        if (absRemainder * 2 > absDivisor) {
          return isPositive ? quotient + 1 : quotient - 1;
        } else if (absRemainder * 2 == absDivisor) {
          // Halfway: round to nearest even number
          return quotient.isEven
              ? quotient
              : (isPositive ? quotient + 1 : quotient - 1);
        }
        return quotient;
    }
  }

  static BigInt _applyRoundingBigInt(
    BigInt dividend,
    BigInt divisor,
    BigInt quotient,
    BigInt remainder,
    RoundingMode mode,
  ) {
    final bool isPositive =
        (dividend >= BigInt.zero) == (divisor >= BigInt.zero);
    final BigInt absRemainder = remainder.abs();
    final BigInt absDivisor = divisor.abs();
    final BigInt two = BigInt.from(2);

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

enum RoundingMode {
  down,
  up,
  halfUp,
  halfEven,
}

class _AllocationRemainder {
  const _AllocationRemainder({required this.index, required this.remainder});
  final int index;
  final int remainder;
}
