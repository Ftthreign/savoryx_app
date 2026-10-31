import 'package:savoryx/core/utils/currency_formatter.dart';

abstract final class MathEvaluator {
  static const int maxOperandDigits = 12;
  static final RegExp _operatorRegex = RegExp(r'[+\-*\/xX\u00D7\u00F7]');

  static bool hasOperator(String input) {
    return _operatorRegex.hasMatch(input);
  }

  static BigInt? evaluate(String expression) {
    final sanitized = _normalizeExpression(expression);
    if (sanitized.isEmpty) return null;

    try {
      final parser = _MathParser(sanitized);
      return parser.parse();
    } catch (_) {
      return null;
    }
  }

  static String? tryFormatLivePreview(
    String expression, {
    String currency = 'IDR',
  }) {
    if (expression.trim().isEmpty) return null;

    String target = expression.trim();

    while (target.isNotEmpty && _isOperatorChar(target[target.length - 1])) {
      target = target.substring(0, target.length - 1).trim();
    }

    if (target.isEmpty) return null;

    final result = evaluate(target);
    if (result == null) return null;

    if (result.isValidInt) {
      return CurrencyFormatter.formatMinorUnit(result.toInt(),
          currency: currency);
    } else {
      return '$currency $result';
    }
  }

  static String _normalizeExpression(String raw) {
    return raw
        .replaceAll(' ', '')
        .replaceAll('\u00D7', '*')
        .replaceAll('\u00F7', '/')
        .replaceAll('x', '*')
        .replaceAll('X', '*');
  }

  static bool _isOperatorChar(String char) {
    return char == '+' ||
        char == '-' ||
        char == '*' ||
        char == '/' ||
        char == 'x' ||
        char == 'X' ||
        char == '\u00D7' ||
        char == '\u00F7';
  }
}

class _MathParser {
  final String text;
  int pos = 0;

  _MathParser(this.text);

  BigInt? parse() {
    final result = _parseExpression();
    if (pos < text.length) {
      return null;
    }
    return result;
  }

  BigInt? _parseExpression() {
    var left = _parseTerm();
    if (left == null) return null;

    while (pos < text.length) {
      final char = text[pos];
      if (char == '+' || char == '-') {
        pos++;
        final right = _parseTerm();
        if (right == null) return null;

        if (char == '+') {
          left = left! + right;
        } else {
          left = left! - right;
        }
      } else {
        break;
      }
    }

    return left;
  }

  BigInt? _parseTerm() {
    var left = _parseFactor();
    if (left == null) return null;

    while (pos < text.length) {
      final char = text[pos];
      if (char == '*' || char == '/') {
        pos++;
        final right = _parseFactor();
        if (right == null) return null;

        if (char == '*') {
          left = left! * right;
        } else {
          // Zero division guard
          if (right == BigInt.zero) {
            return null;
          }
          left = left! ~/ right;
        }
      } else {
        break;
      }
    }

    return left;
  }

  BigInt? _parseFactor() {
    if (pos >= text.length) return null;

    final char = text[pos];

    // Unary plus or minus
    if (char == '+') {
      pos++;
      return _parseFactor();
    }
    if (char == '-') {
      pos++;
      final factor = _parseFactor();
      if (factor == null) return null;
      return -factor;
    }

    // Parentheses (if present)
    if (char == '(') {
      pos++;
      final expr = _parseExpression();
      if (pos >= text.length || text[pos] != ')') return null;
      pos++;
      return expr;
    }

    // Number
    final start = pos;
    while (pos < text.length && _isDigit(text[pos])) {
      pos++;
    }

    if (start == pos) {
      return null; // No digits found
    }

    final numberStr = text.substring(start, pos);
    if (numberStr.length > MathEvaluator.maxOperandDigits) {
      return null; // Operand exceeds 12-digit safety limit
    }

    return BigInt.tryParse(numberStr);
  }

  bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57; // '0'..'9'
  }
}
