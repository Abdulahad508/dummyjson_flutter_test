import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dummyjson_flutter_test/core/storage/token_storage.dart';

/// Stores the session in the platform secure store.
///
/// Android uses the Keystore, iOS and macOS use Keychain, Windows uses
/// DPAPI, and web uses the plugin's encrypted web storage.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'access_token';
  static const _userKey = 'user_json';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() {
    return _guard(() => _storage.read(key: _tokenKey));
  }

  @override
  Future<String?> readUserJson() {
    return _guard(() => _storage.read(key: _userKey));
  }

  @override
  Future<void> writeSession({
    required String accessToken,
    required String userJson,
  }) {
    return _guard(() async {
      // Write the profile first. A token without a profile is avoided if
      // the second write fails; restore still works from the token alone.
      await _storage.write(key: _userKey, value: userJson);
      await _storage.write(key: _tokenKey, value: accessToken);
    });
  }

  @override
  Future<void> clear() {
    return _guard(() async {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error) {
      throw StorageException(
        error.message ?? 'Secure storage is unavailable on this device.',
      );
    }
  }
}
