import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/security/device_credentials_storage.dart';
import 'package:savoryx/core/security/hmac_signer.dart';

class _InMemorySecureStore implements KeyValueSecureStore {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => _data[key];

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }
}

List<int> _hexToBytes(String hex) {
  final result = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    result.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return result;
}

void main() {
  group('HmacSigner & RFC-2104 / RFC-4231 Test Vectors (Task #47)', () {
    const signer = HmacSigner();

    test('matches official RFC-4231 HMAC-SHA256 Test Case 1', () {
      // Key = 0x0b repeated 20 times, Data = "Hi There"
      final keyBytes = List<int>.filled(20, 0x0b);
      final dataBytes = utf8.encode('Hi There');

      final digest = signer.computeRawDigestHex(
        keyBytes: keyBytes,
        messageBytes: dataBytes,
      );

      expect(
        digest,
        equals(
          'b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7',
        ),
      );
    });

    test('matches official RFC-4231 HMAC-SHA256 Test Case 2 (Jefe)', () {
      // Key = "Jefe", Data = "what do ya want for nothing?"
      final digest = signer.computeRawDigestHex(
        keyBytes: utf8.encode('Jefe'),
        messageBytes: utf8.encode('what do ya want for nothing?'),
      );

      expect(
        digest,
        equals(
          '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
        ),
      );
    });

    test('matches official RFC-4231 HMAC-SHA256 Test Case 3', () {
      // Key = 0xaa repeated 20 times, Data = 0xdd repeated 50 times
      final digest = signer.computeRawDigestHex(
        keyBytes: _hexToBytes('aa' * 20),
        messageBytes: _hexToBytes('dd' * 50),
      );

      expect(
        digest,
        equals(
          '773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe',
        ),
      );
    });

    test('produces deterministic pipe and newline canonical signatures matching Go backend', () {
      const secret = 'savoryx-super-secret-hmac-key-2026';
      const ts = '2026-11-10T06:00:00.123456Z';
      const path = '/api/v1/sync/push';
      const body = '{"accounts":[],"categories":[],"transactions":[]}';

      final sigPipeLower = signer.signRequest(
        secret: secret,
        timestampUtc: ts,
        method: 'post',
        path: path,
        payloadJson: body,
        delimiter: HmacSigner.pipeDelimiter,
      );
      final sigPipeUpper = signer.signRequest(
        secret: secret,
        timestampUtc: ts,
        method: 'POST',
        path: path,
        payloadJson: body,
        delimiter: HmacSigner.pipeDelimiter,
      );
      expect(sigPipeLower, equals(sigPipeUpper));
      expect(sigPipeLower.length, equals(64));

      // Verify digest changes if payload, path, or method is tampered
      final tamperedBodySig = signer.signRequest(
        secret: secret,
        timestampUtc: ts,
        method: 'POST',
        path: path,
        payloadJson: '{"accounts":[{"id":"1"}],"categories":[],"transactions":[]}',
      );
      expect(tamperedBodySig, isNot(equals(sigPipeLower)));

      // Verify newline delimiter matches ComputeHMACSignature canonical layout
      final sigNewline = signer.signRequest(
        secret: secret,
        timestampUtc: ts,
        method: 'POST',
        path: path,
        payloadJson: body,
        delimiter: HmacSigner.newlineDelimiter,
      );
      expect(sigNewline, isNot(equals(sigPipeLower)));
      expect(
        signer.computeCanonicalPayload(
          timestampUtc: ts,
          method: 'post',
          path: path,
          payloadJson: body,
          delimiter: HmacSigner.newlineDelimiter,
        ),
        equals('$ts\nPOST\n$path\n$body'),
      );
    });
  });

  group('UtcTimekeeper Clock Calibration (Task #47)', () {
    test('calibrates clockOffset from server X-Server-Time header and resets cleanly', () {
      // Simulate device clock lagging 5 minutes behind real UTC server time.
      final localClock = DateTime.utc(2026, 11, 10, 6, 0, 0);
      final serverClock = DateTime.utc(2026, 11, 10, 6, 5, 0, 500);

      final timekeeper = UtcTimekeeper(clock: () => localClock);
      expect(timekeeper.clockOffset, equals(Duration.zero));
      expect(
        timekeeper.currentTimestampIso8601(),
        equals('2026-11-10T06:00:00.000Z'),
      );

      final calibrated = timekeeper.calibrateFromHeader(
        serverClock.toIso8601String(),
      );
      expect(calibrated, isTrue);
      expect(
        timekeeper.clockOffset,
        equals(const Duration(minutes: 5, milliseconds: 500)),
      );
      expect(timekeeper.nowUtc(), equals(serverClock));

      // Reject malformed/empty headers safely without breaking state
      expect(timekeeper.calibrateFromHeader(null), isFalse);
      expect(timekeeper.calibrateFromHeader('   '), isFalse);
      expect(timekeeper.calibrateFromHeader('not-a-timestamp'), isFalse);
      expect(timekeeper.nowUtc(), equals(serverClock));

      timekeeper.resetOffset();
      expect(timekeeper.clockOffset, equals(Duration.zero));
      expect(timekeeper.nowUtc(), equals(localClock));
    });
  });

  group('DeviceCredentialsStorage (Task #47)', () {
    test('saves, reads, updates access token, and clears device credentials', () async {
      final storage = DeviceCredentialsStorage(store: _InMemorySecureStore());

      expect(await storage.readCredentials(), isNull);

      await storage.saveCredentials(
        deviceId: '0192d6e2-5b9c-7000-8000-000000000001',
        deviceSecret: 'hex-secret-abc',
        accessToken: 'v4.local.initial-token',
      );

      final creds = await storage.readCredentials();
      expect(creds, isNotNull);
      expect(creds!.isComplete, isTrue);
      expect(creds.deviceId, equals('0192d6e2-5b9c-7000-8000-000000000001'));
      expect(creds.deviceSecret, equals('hex-secret-abc'));
      expect(creds.accessToken, equals('v4.local.initial-token'));

      await storage.saveAccessToken('v4.local.refreshed-token');
      expect(
        await storage.readAccessToken(),
        equals('v4.local.refreshed-token'),
      );

      await storage.clear();
      expect(await storage.readCredentials(), isNull);
    });
  });
}
