import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key-value secure storage abstraction enabling hermetic unit testing without platform channels.
abstract interface class KeyValueSecureStore {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

/// Production [KeyValueSecureStore] backed by [FlutterSecureStorage] (Android Keystore / iOS Keychain).
class FlutterSecureStorageAdapter implements KeyValueSecureStore {
  FlutterSecureStorageAdapter({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }
}

/// Immutable bundle of registered device authentication credentials.
@immutable
class DeviceCredentials {
  const DeviceCredentials({
    required this.deviceId,
    required this.deviceSecret,
    required this.accessToken,
  });

  final String deviceId;
  final String deviceSecret;
  final String accessToken;

  bool get isComplete =>
      deviceId.isNotEmpty && deviceSecret.isNotEmpty && accessToken.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeviceCredentials &&
            runtimeType == other.runtimeType &&
            deviceId == other.deviceId &&
            deviceSecret == other.deviceSecret &&
            accessToken == other.accessToken;
  }

  @override
  int get hashCode => Object.hash(deviceId, deviceSecret, accessToken);
}

/// Persists and retrieves `device_id`, `device_secret`, and `paseto_token` from secure hardware storage.
class DeviceCredentialsStorage {
  DeviceCredentialsStorage({KeyValueSecureStore? store})
      : _store = store ?? FlutterSecureStorageAdapter();

  static const String keyDeviceId = 'savoryx_device_id';
  static const String keyDeviceSecret = 'savoryx_device_secret';
  static const String keyAccessToken = 'savoryx_paseto_token';

  final KeyValueSecureStore _store;

  Future<void> saveCredentials({
    required String deviceId,
    required String deviceSecret,
    required String accessToken,
  }) async {
    await Future.wait([
      _store.write(key: keyDeviceId, value: deviceId.trim()),
      _store.write(key: keyDeviceSecret, value: deviceSecret.trim()),
      _store.write(key: keyAccessToken, value: accessToken.trim()),
    ]);
  }

  Future<void> saveAccessToken(String accessToken) {
    return _store.write(key: keyAccessToken, value: accessToken.trim());
  }

  Future<String?> readDeviceId() => _store.read(key: keyDeviceId);

  Future<String?> readDeviceSecret() => _store.read(key: keyDeviceSecret);

  Future<String?> readAccessToken() => _store.read(key: keyAccessToken);

  Future<DeviceCredentials?> readCredentials() async {
    final values = await Future.wait([
      _store.read(key: keyDeviceId),
      _store.read(key: keyDeviceSecret),
      _store.read(key: keyAccessToken),
    ]);

    final deviceId = values[0]?.trim() ?? '';
    final deviceSecret = values[1]?.trim() ?? '';
    final accessToken = values[2]?.trim() ?? '';

    if (deviceId.isEmpty && deviceSecret.isEmpty && accessToken.isEmpty) {
      return null;
    }

    return DeviceCredentials(
      deviceId: deviceId,
      deviceSecret: deviceSecret,
      accessToken: accessToken,
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _store.delete(key: keyDeviceId),
      _store.delete(key: keyDeviceSecret),
      _store.delete(key: keyAccessToken),
    ]);
  }
}
