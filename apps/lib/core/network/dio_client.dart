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
    SyncSecurityInterceptor? securityInterceptor,
    HttpClientAdapter? httpClientAdapter,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
    Duration sendTimeout = const Duration(seconds: 15),
  }) {
    final effectiveSecurityInterceptor = securityInterceptor ??
        SyncSecurityInterceptor(
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

    effectiveSecurityInterceptor.retryExecutor =
        (options) => _dio.fetch<dynamic>(options);
    _dio.interceptors.add(effectiveSecurityInterceptor);
  }

  late final Dio _dio;

  Dio get dio => _dio;
}
