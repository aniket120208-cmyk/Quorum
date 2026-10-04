import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _refreshTokenKey = 'quorum_refresh_token';
  static const String _rolePendingKey = 'quorum_role_pending_user';

  final FlutterSecureStorage _storage;
  String? _accessToken;
  String? get accessToken => _accessToken;

  Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } on PlatformException {
      try {
        await _storage.delete(key: _refreshTokenKey);
      } catch (_) {}
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> readRolePendingUser() async {
    try {
      return await _storage.read(key: _rolePendingKey);
    } on PlatformException {
      return null;
    }
  }

  Future<void> markRolePending(String userId) async {
    await _storage.write(key: _rolePendingKey, value: userId);
  }

  Future<void> clearRolePending() async {
    try {
      await _storage.delete(key: _rolePendingKey);
    } catch (_) {}
  }

  Future<void> clear() async {
    _accessToken = null;
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {}
  }
}