import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the DummyJSON access token in the platform secure store.
///
/// iOS and macOS use the Keychain. Android uses the Keystore with AES-GCM.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  Future<void> writeAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }
}
