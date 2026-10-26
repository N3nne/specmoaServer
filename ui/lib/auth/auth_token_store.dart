import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

abstract interface class AuthTokenStore {
  Future<String?> read();
  Future<void> write(String? refreshToken);
}

class SecureAuthTokenStore implements AuthTokenStore {
  const SecureAuthTokenStore();

  static const _storage = FlutterSecureStorage();
  static const _key = '${AppConfig.apiBaseUrl}:auth-refresh-v1';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String? refreshToken) => refreshToken == null
      ? _storage.delete(key: _key)
      : _storage.write(key: _key, value: refreshToken);
}
