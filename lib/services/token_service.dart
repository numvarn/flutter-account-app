import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'jwt_token';
  static const _keyUser = 'user_data';

  /// Save JWT Token to secure storage
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Read JWT Token from secure storage
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Delete JWT Token & User Data from secure storage
  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }

  /// Check if a valid JWT Token exists
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }

  /// Save user profile info as JSON
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _keyUser, value: jsonEncode(userData));
  }

  /// Read user profile info
  static Future<Map<String, dynamic>?> getUserData() async {
    final dataStr = await _storage.read(key: _keyUser);
    if (dataStr != null && dataStr.isNotEmpty) {
      try {
        return jsonDecode(dataStr);
      } catch (_) {}
    }
    return null;
  }
}
