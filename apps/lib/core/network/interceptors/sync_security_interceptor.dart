import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:savoryx/core/security/device_credentials_storage.dart';
import 'package:savoryx/core/security/hmac_signer.dart';

/// Callback executing a single retried request through the configured HTTP client.
typedef DioRetryExecutor = Future<Response<dynamic>> Function(
  RequestOptions options,
);

/// Injects PASETO Bearer tokens, `X-Device-ID`, and canonical `X-Timestamp` + `X-Signature`
/// headers on mutation requests, and calibrates UTC clock skew on `401 clock_skew_exceeded`.
class SyncSecurityInterceptor extends Interceptor {
  SyncSecurityInterceptor({
    required DeviceCredentialsStorage credentialsStorage,
    required HmacSigner hmacSigner,
    required UtcTimekeeper timekeeper,
    DioRetryExecutor? retryExecutor,
  })  : _credentialsStorage = credentialsStorage,
        _hmacSigner = hmacSigner,
        _timekeeper = timekeeper,
        _retryExecutor = retryExecutor;

  static const String skipSecurityExtraKey = '_skipSyncSecurity';
  static const String retriedSkewExtraKey = '_hmacRetried';

  static const Set<String> _mutationMethods = <String>{
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
  };

  final DeviceCredentialsStorage _credentialsStorage;
  final HmacSigner _hmacSigner;
  final UtcTimekeeper _timekeeper;
  DioRetryExecutor? _retryExecutor;

  /// Binds the retry executor after [Dio] construction to break circular references cleanly.
  set retryExecutor(DioRetryExecutor? executor) {
    _retryExecutor = executor;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipSecurityExtraKey] == true) {
      handler.next(options);
      return;
    }

    final credentials = await _credentialsStorage.readCredentials();
    if (credentials != null) {
      if (credentials.accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer ${credentials.accessToken}';
      }
      if (credentials.deviceId.isNotEmpty) {
        options.headers['X-Device-ID'] = credentials.deviceId;
      }
    }

    final method = options.method.trim().toUpperCase();
    if (_mutationMethods.contains(method)) {
      final canonicalBody = _canonicalizeBody(options);
      final timestampUtc = _timekeeper.currentTimestampIso8601();

      options.headers['X-Timestamp'] = timestampUtc;

      if (credentials != null && credentials.deviceSecret.isNotEmpty) {
        final signature = _hmacSigner.signRequest(
          secret: credentials.deviceSecret,
          timestampUtc: timestampUtc,
          method: method,
          path: options.uri.path,
          payloadJson: canonicalBody,
          delimiter: HmacSigner.pipeDelimiter,
        );
        options.headers['X-Signature'] = signature;
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    if (response?.statusCode == 401 &&
        requestOptions.extra[retriedSkewExtraKey] != true &&
        _isClockSkewExceeded(response?.data)) {
      final calibrated = _calibrateTimekeeper(response!);
      if (calibrated && _retryExecutor != null) {
        requestOptions.extra[retriedSkewExtraKey] = true;
        requestOptions.headers.remove('X-Timestamp');
        requestOptions.headers.remove('X-Signature');

        try {
          final retriedResponse = await _retryExecutor!(requestOptions);
          handler.resolve(retriedResponse);
          return;
        } on DioException catch (retryErr) {
          handler.next(retryErr);
          return;
        }
      }
    }

    handler.next(err);
  }

  String _canonicalizeBody(RequestOptions options) {
    final data = options.data;
    if (data == null) {
      return '';
    }
    if (data is String) {
      return data;
    }
    final encoded = jsonEncode(data);
    // Keep the exact encoded JSON string so the wire body matches the HMAC digest.
    options.data = encoded;
    return encoded;
  }

  bool _isClockSkewExceeded(dynamic responseData) {
    if (responseData is! Map) {
      return false;
    }
    final errorObj = responseData['error'];
    if (errorObj is Map) {
      return errorObj['code'] == 'clock_skew_exceeded';
    }
    return responseData['code'] == 'clock_skew_exceeded';
  }

  bool _calibrateTimekeeper(Response<dynamic> response) {
    final xServerTime = response.headers.value('X-Server-Time') ??
        response.headers.value('x-server-time');
    if (_timekeeper.calibrateFromHeader(xServerTime)) {
      return true;
    }

    final dateHeader =
        response.headers.value('Date') ?? response.headers.value('date');
    return _timekeeper.calibrateFromHeader(dateHeader);
  }
}
