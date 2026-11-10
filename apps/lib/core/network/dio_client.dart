import 'package:dio/dio.dart';
import 'package:savoryx/core/network/interceptors/sync_security_interceptor.dart';
import 'package:savoryx/core/security/device_credentials_storage.dart';
import 'package:savoryx/core/security/hmac_signer.dart';

class DioClient {
  DioClient({
    required String baseUrl,
    required DeviceCredentialsStorage credentialsStorage,
    HmacSigner? hmacSigner,
    UtcTimekeeper? timekeeper,
    HttpClientAdapter? httpClientAdapter,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
    Duration sendTimeout = const Duration(seconds: 15),
  }) {
    final securityInterceptor = SyncSecurityInterceptor(
      credentialsStorage: credentialsStorage,
      hmacSigner: hmacSigner ?? const HmacSigner(),
      timekeeper: timekeeper ?? UtcTimekeeper(),
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: const <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (httpClientAdapter != null) {
      _dio.httpClientAdapter = httpClientAdapter;
    }

    securityInterceptor.retryExecutor =
        (options) => _dio.fetch<dynamic>(options);
    _dio.interceptors.add(securityInterceptor);
  }

  late final Dio _dio;

  /// Underlying configured [Dio] instance.
  Dio get dio => _dio;
}
