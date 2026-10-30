import 'package:intl/intl.dart';
import 'constants.dart';

/// Deterministic, zero-floating-point financial currency formatter.
/// Conforms strictly to AGENTS.md §1.1 (Zero IEEE-754 float calculations on balances).
abstract final class CurrencyFormatter {
  static final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Standard minor-unit formatting without any floating-point division.
  static String formatMinorUnit(int minorAmount, {String currency = 'IDR'}) {
    switch (currency.toUpperCase()) {
      case 'IDR':
        return _idrFormat.format(minorAmount);
      case 'USD':
        final int whole = minorAmount ~/ 100;
        final int cents = (minorAmount % 100).abs();
        final String centsStr = cents.toString().padLeft(2, '0');
        final String sign = minorAmount < 0 ? '-' : '';
        return '$sign\$${NumberFormat('#,##0', 'en_US').format(whole.abs())}.$centsStr';
      default:
        return '${currency.toUpperCase()} $minorAmount';
    }
  }

  /// Format minor unit with privacy shield masking.
  static String formatMasked(
    int minorAmount, {
    bool isMasked = false,
    String currency = 'IDR',
  }) {
    if (isMasked) {
      return AppConstants.privacyMask;
    }
    return formatMinorUnit(minorAmount, currency: currency);
  }

  /// Compact Indonesian Rupiah format for chips & buttons (e.g., 10000 -> "10k", 1500000 -> "1.5M").
  static String formatCompactRupiah(
    int minorAmount, {
    bool isMasked = false,
    String prefix = '',
  }) {
    if (isMasked) {
      return AppConstants.privacyMask;
    }

    final int absAmount = minorAmount.abs();
    final String sign = minorAmount < 0 ? '-' : '';

    if (absAmount >= 1000000000) {
      final int billions = absAmount ~/ 1000000000;
      final int decimal = (absAmount % 1000000000) ~/ 100000000;
      final String decStr = decimal > 0 ? '.$decimal' : '';
      return '$prefix$sign$billions${decStr}B';
    } else if (absAmount >= 1000000) {
      final int millions = absAmount ~/ 1000000;
      final int decimal = (absAmount % 1000000) ~/ 100000;
      final String decStr = decimal > 0 ? '.$decimal' : '';
      return '$prefix$sign$millions${decStr}M';
    } else if (absAmount >= 1000) {
      final int thousands = absAmount ~/ 1000;
      final int decimal = (absAmount % 1000) ~/ 100;
      final String decStr = decimal > 0 ? '.$decimal' : '';
      return '$prefix$sign$thousands${decStr}k';
    }

    return '$prefix$sign$absAmount';
  }

  /// Calculates working hours equivalence using deterministic integer math.
  /// (e.g. 85000 with 65000/hr -> "1.3")
  static String calculateWorkHours(int minorAmount, {int hourlyWage = 65000}) {
    if (hourlyWage <= 0) return '0.0';
    final int wholeHours = minorAmount ~/ hourlyWage;
    final int tenth = ((minorAmount % hourlyWage) * 10) ~/ hourlyWage;
    return '$wholeHours.$tenth';
  }

  /// Helper for BigInt minor amounts without float conversion.
  static String formatBigIntMinor(
    BigInt minorAmount, {
    String currency = 'IDR',
    bool isMasked = false,
  }) {
    if (isMasked) {
      return AppConstants.privacyMask;
    }
    if (minorAmount.isValidInt) {
      return formatMinorUnit(minorAmount.toInt(), currency: currency);
    }
    return '$currency ${minorAmount.toString()}';
  }
}
