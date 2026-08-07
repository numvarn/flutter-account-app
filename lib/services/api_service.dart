import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_app/services/token_service.dart';

class ApiService {
  static const String baseUrl = 'https://flutter-backend-iota.vercel.app/api';

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String fname,
    required String lname,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'fname': fname,
        'lname': lname,
        'email': email,
        'password': password,
      }),
    );

    debugPrint('================ [API RESPONSE LOG] ================');
    debugPrint('Endpoint: POST $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('====================================================');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['token'] != null) {
        await TokenService.saveToken(data['token']);
      }
      if (data['user'] != null) {
        await TokenService.saveUserData(data['user']);
      }
      return data;
    } else {
      final errorMessage = data['error'] ?? 'เกิดข้อผิดพลาดในการลงทะเบียน (${response.statusCode})';
      throw Exception(errorMessage);
    }
  }

  /// Login existing user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    debugPrint('================ [API RESPONSE LOG] ================');
    debugPrint('Endpoint: POST $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('====================================================');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Save Token and User Data to secure storage
      if (data['token'] != null) {
        await TokenService.saveToken(data['token']);
      }
      if (data['user'] != null) {
        await TokenService.saveUserData(data['user']);
      }
      return data;
    } else {
      final errorMessage = data['error'] ?? 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ (${response.statusCode})';
      throw Exception(errorMessage);
    }
  }

  /// Logout user and revoke token on server and delete local secure storage
  static Future<void> logout() async {
    final token = await TokenService.getToken();
    final url = Uri.parse('$baseUrl/auth/logout');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('================ [API LOGOUT LOG] ================');
      debugPrint('Endpoint: POST $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('==================================================');
    } catch (e) {
      debugPrint('Logout request error: $e');
    } finally {
      // Clear token from secure storage regardless of API result
      await TokenService.deleteToken();
    }
  }

  /// Get current user profile
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await TokenService.getToken();
    final url = Uri.parse('$baseUrl/auth/me');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (data['user'] != null) {
        await TokenService.saveUserData(data['user']);
      }
      return data;
    } else {
      throw Exception(data['error'] ?? 'ไม่สามารถดึงข้อมูลโปรไฟล์ได้');
    }
  }
}
