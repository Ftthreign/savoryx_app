import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Maintains calibrated UTC timestamps aligned with the Go backend's 60-second clock skew guard.
class UtcTimekeeper {
  UtcTimekeeper({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  Duration _clockOffset = Duration.zero;

  /// Current calibrated difference between server UTC clock and local device clock.
  Duration get clockOffset => _clockOffset;

  /// Returns current UTC time adjusted by [clockOffset].
  DateTime nowUtc() => _clock().toUtc().add(_clockOffset);

  /// Returns an RFC3339Nano-compatible UTC ISO-8601 timestamp string for `X-Timestamp`.
  String currentTimestampIso8601() => nowUtc().toIso8601String();

  /// Updates [clockOffset] so local UTC aligns with [serverTime].
  void calibrateWithServerTime(DateTime serverTime) {
    final rawLocalUtc = _clock().toUtc();
    _clockOffset = serverTime.toUtc().difference(rawLocalUtc);
  }

  /// Parses an `X-Server-Time` header (RFC3339 / RFC3339Nano UTC) and calibrates [clockOffset].
  ///
  /// Returns `true` when [serverTimeHeader] was valid and calibration succeeded.
  bool calibrateFromHeader(String? serverTimeHeader) {
    if (serverTimeHeader == null) return false;
    final trimmed = serverTimeHeader.trim();
    if (trimmed.isEmpty) return false;

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return false;

    calibrateWithServerTime(parsed);
    return true;
  }

  /// Resets the clock skew offset back to zero.
  void resetOffset() {
    _clockOffset = Duration.zero;
  }
}

/// Computes deterministic HMAC-SHA256 digests compatible with the Savoryx Go backend.
class HmacSigner {
  const HmacSigner();

  static const String pipeDelimiter = '|';
  static const String newlineDelimiter = '\n';

  /// Builds the canonical signing message:
  /// `<timestampUtc><delimiter><UPPER_METHOD><delimiter><path><delimiter><payloadJson>`.
  String computeCanonicalPayload({
    required String timestampUtc,
    required String method,
    required String path,
    String payloadJson = '',
    String delimiter = pipeDelimiter,
  }) {
    final normalizedMethod = method.trim().toUpperCase();
    return '$timestampUtc$delimiter$normalizedMethod$delimiter$path$delimiter$payloadJson';
  }

  /// Computes a lowercase hex-encoded HMAC-SHA256 digest for an HTTP mutation request.
  String signRequest({
    required String secret,
    required String timestampUtc,
    required String method,
    required String path,
    String payloadJson = '',
    String delimiter = pipeDelimiter,
  }) {
    final canonical = computeCanonicalPayload(
      timestampUtc: timestampUtc,
      method: method,
      path: path,
      payloadJson: payloadJson,
      delimiter: delimiter,
    );
    return computeRawDigestHex(
      keyBytes: utf8.encode(secret),
      messageBytes: utf8.encode(canonical),
    );
  }

  /// Computes raw lowercase hex-encoded HMAC-SHA256 digest over arbitrary byte slices.
  String computeRawDigestHex({
    required List<int> keyBytes,
    required List<int> messageBytes,
  }) {
    final mac = Hmac(sha256, keyBytes);
    return mac.convert(messageBytes).toString();
  }
}
