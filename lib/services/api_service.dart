import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://flutter-backend-iota.vercel.app/api';

  /// Register a new user
  /// [fname] - First Name
  /// [lname] - Last Name
  /// [email] - User Email
  /// [password] - User Password
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

    // Print backend response logs to console
    debugPrint('================ [API RESPONSE LOG] ================');
    debugPrint('Endpoint: POST $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('====================================================');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      final errorMessage = data['error'] ?? 'เกิดข้อผิดพลาดในการลงทะเบียน (${response.statusCode})';
      throw Exception(errorMessage);
    }
  }
}
