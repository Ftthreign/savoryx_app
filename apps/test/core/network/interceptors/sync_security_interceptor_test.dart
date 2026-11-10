import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/network/dio_client.dart';
import 'package:savoryx/core/network/interceptors/sync_security_interceptor.dart';
import 'package:savoryx/core/security/device_credentials_storage.dart';
import 'package:savoryx/core/security/hmac_signer.dart';

class _InMemorySecureStore implements KeyValueSecureStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> delete({required String key}) async => _values.remove(key);
}

typedef _MockAdapterHandler = Future<ResponseBody> Function(
  RequestOptions options,
  Stream<Uint8List>? requestStream,
);

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final _MockAdapterHandler _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(
  int statusCode,
  Map<String, dynamic> body, {
  Map<String, List<String>> headers = const <String, List<String>>{},
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['application/json'],
      ...headers,
    },
  );
}

void main() {
  group('SyncSecurityInterceptor & DioClient (Task #48)', () {
    const testDeviceId = '0192d6e2-5b9c-7000-8000-000000000001';
    const testSecret = 'savoryx-device-hmac-secret-2026';
    const testToken = 'v4.local.test-paseto-token';

    late DeviceCredentialsStorage credentialsStorage;
    late HmacSigner hmacSigner;

    setUp(() async {
      credentialsStorage =
          DeviceCredentialsStorage(store: _InMemorySecureStore());
      await credentialsStorage.saveCredentials(
        deviceId: testDeviceId,
        deviceSecret: testSecret,
        accessToken: testToken,
      );
      hmacSigner = const HmacSigner();
    });

    test('injects 4 security headers on POST mutation matching Go HMAC contract',
        () async {
      final fixedTime = DateTime.utc(2026, 11, 10, 6, 30, 0);
      final timekeeper = UtcTimekeeper(clock: () => fixedTime);

      late RequestOptions capturedOptions;
      late String capturedBody;

      final adapter = _FakeHttpClientAdapter((options, stream) async {
        capturedOptions = options;
        if (stream != null) {
          final bytes = await stream.expand((chunk) => chunk).toList();
          capturedBody = utf8.decode(bytes);
        } else {
          capturedBody = options.data?.toString() ?? '';
        }
        return _jsonResponse(200, <String, dynamic>{
          'data': <String, dynamic>{'accounts_applied': 1},
        });
      });

      final client = DioClient(
        baseUrl: 'https://api.savoryx.local',
        credentialsStorage: credentialsStorage,
        hmacSigner: hmacSigner,
        timekeeper: timekeeper,
        httpClientAdapter: adapter,
      );

      final payload = <String, dynamic>{
        'accounts': <Map<String, dynamic>>[],
        'categories': <Map<String, dynamic>>[],
        'transactions': <Map<String, dynamic>>[],
      };

      final response = await client.dio.post<Map<String, dynamic>>(
        '/api/v1/sync/push',
        data: payload,
      );

      expect(response.statusCode, equals(200));
      expect(
        capturedOptions.headers['Authorization'],
        equals('Bearer $testToken'),
      );
      expect(capturedOptions.headers['X-Device-ID'], equals(testDeviceId));
      expect(
        capturedOptions.headers['X-Timestamp'],
        equals(fixedTime.toIso8601String()),
      );

      final expectedSig = hmacSigner.signRequest(
        secret: testSecret,
        timestampUtc: fixedTime.toIso8601String(),
        method: 'POST',
        path: '/api/v1/sync/push',
        payloadJson: jsonEncode(payload),
      );
      expect(capturedOptions.headers['X-Signature'], equals(expectedSig));
      expect(capturedBody, equals(jsonEncode(payload)));
    });

    test('injects Authorization and X-Device-ID on GET without X-Signature and honors skip flag',
        () async {
      final capturedRequests = <RequestOptions>[];
      final adapter = _FakeHttpClientAdapter((options, _) async {
        capturedRequests.add(options);
        return _jsonResponse(200, <String, dynamic>{'data': <String, dynamic>{}});
      });

      final client = DioClient(
        baseUrl: 'https://api.savoryx.local',
        credentialsStorage: credentialsStorage,
        httpClientAdapter: adapter,
      );

      await client.dio.get<Map<String, dynamic>>('/api/v1/sync/pull');
      await client.dio.post<Map<String, dynamic>>(
        '/api/v1/auth/register-device',
        data: <String, dynamic>{'device_id': testDeviceId},
        options: Options(
          extra: const <String, dynamic>{
            SyncSecurityInterceptor.skipSecurityExtraKey: true,
          },
        ),
      );

      final getHeaders = capturedRequests[0].headers;
      expect(getHeaders['Authorization'], equals('Bearer $testToken'));
      expect(getHeaders['X-Device-ID'], equals(testDeviceId));
      expect(getHeaders.containsKey('X-Signature'), isFalse);

      final registerHeaders = capturedRequests[1].headers;
      expect(registerHeaders.containsKey('Authorization'), isFalse);
      expect(registerHeaders.containsKey('X-Signature'), isFalse);
    });

    test('calibrates clock skew from X-Server-Time on 401 and executes one-time signed retry',
        () async {
      final skewedLocalClock = DateTime.utc(2026, 11, 10, 6, 0, 0);
      final authoritativeServerClock = DateTime.utc(2026, 11, 10, 6, 5, 0);
      final timekeeper = UtcTimekeeper(clock: () => skewedLocalClock);

      final attemptTimestamps = <String>[];
      final attemptSignatures = <String>[];

      final adapter = _FakeHttpClientAdapter((options, _) async {
        attemptTimestamps.add(options.headers['X-Timestamp'] as String);
        attemptSignatures.add(options.headers['X-Signature'] as String);

        if (attemptTimestamps.length == 1) {
          return _jsonResponse(
            401,
            <String, dynamic>{
              'error': <String, dynamic>{
                'code': 'clock_skew_exceeded',
                'message': 'Request timestamp exceeds 60-second clock skew tolerance',
              },
            },
            headers: <String, List<String>>{
              'X-Server-Time': <String>[
                authoritativeServerClock.toIso8601String(),
              ],
            },
          );
        }

        return _jsonResponse(200, <String, dynamic>{
          'data': <String, dynamic>{'transactions_applied': 2},
        });
      });

      final client = DioClient(
        baseUrl: 'https://api.savoryx.local',
        credentialsStorage: credentialsStorage,
        hmacSigner: hmacSigner,
        timekeeper: timekeeper,
        httpClientAdapter: adapter,
      );

      final response = await client.dio.post<Map<String, dynamic>>(
        '/api/v1/sync/push',
        data: const <String, dynamic>{'transactions': <dynamic>[]},
      );

      expect(response.statusCode, equals(200));
      expect(attemptTimestamps.length, equals(2));
      expect(
        attemptTimestamps[0],
        equals(skewedLocalClock.toIso8601String()),
      );
      expect(
        attemptTimestamps[1],
        equals(authoritativeServerClock.toIso8601String()),
      );
      expect(attemptSignatures[1], isNot(equals(attemptSignatures[0])));
      expect(
        timekeeper.clockOffset,
        equals(const Duration(minutes: 5)),
      );
    });

    test('stops after one-time retry if clock_skew_exceeded persists', () async {
      final localClock = DateTime.utc(2026, 11, 10, 6, 0, 0);
      final serverClock = DateTime.utc(2026, 11, 10, 6, 5, 0);
      final timekeeper = UtcTimekeeper(clock: () => localClock);

      var calls = 0;
      final adapter = _FakeHttpClientAdapter((options, _) async {
        calls++;
        return _jsonResponse(
          401,
          <String, dynamic>{
            'error': <String, dynamic>{'code': 'clock_skew_exceeded'},
          },
          headers: <String, List<String>>{
            'X-Server-Time': <String>[serverClock.toIso8601String()],
          },
        );
      });

      final client = DioClient(
        baseUrl: 'https://api.savoryx.local',
        credentialsStorage: credentialsStorage,
        timekeeper: timekeeper,
        httpClientAdapter: adapter,
      );

      await expectLater(
        () => client.dio.post<Map<String, dynamic>>(
          '/api/v1/sync/push',
          data: const <String, dynamic>{},
        ),
        throwsA(isA<DioException>()),
      );
      expect(calls, equals(2), reason: 'initial attempt + single retry max');
    });
  });
}
