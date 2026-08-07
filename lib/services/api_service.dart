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
      final errorMessage =
          data['error'] ??
          'เกิดข้อผิดพลาดในการลงทะเบียน (${response.statusCode})';
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
      body: jsonEncode({'email': email, 'password': password}),
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
      final errorMessage =
          data['error'] ??
          'เกิดข้อผิดพลาดในการเข้าสู่ระบบ (${response.statusCode})';
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

  /// Create a new transaction (POST /api/transactions)
  static Future<Map<String, dynamic>> createTransaction({
    required String type, // 'income' or 'expense'
    required double amount,
    required String category,
    String? description,
    String? date, // YYYY-MM-DD
  }) async {
    final token = await TokenService.getToken();
    final url = Uri.parse('$baseUrl/transactions');

    final payload = {
      'type': type,
      'amount': amount,
      'category': category,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (date != null && date.trim().isNotEmpty) 'date': date.trim(),
    };

    debugPrint('================ [CREATE TRANSACTION REQUEST] ================');
    debugPrint('Endpoint: POST $url');
    debugPrint('Payload: ${jsonEncode(payload)}');
    debugPrint('Token Present: ${token != null}');
    debugPrint('==============================================================');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    debugPrint('================ [CREATE TRANSACTION RESPONSE] ================');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('===============================================================');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      final errorMessage =
          data['error'] ??
          'เกิดข้อผิดพลาดในการบันทึกรายการ (${response.statusCode})';
      throw Exception(errorMessage);
    }
  }

  /// Get list of transactions & summary (GET /api/transactions)
  static Future<Map<String, dynamic>> getTransactions({
    String? type,
    String? category,
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
  }) async {
    final token = await TokenService.getToken();
    final queryParams = <String, String>{};
    if (type != null && type.isNotEmpty && type != 'all') {
      queryParams['type'] = type;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['endDate'] = endDate;
    }
    if (page != null && page > 0) {
      queryParams['page'] = page.toString();
    }
    if (limit != null && limit > 0) {
      queryParams['limit'] = limit.toString();
    }

    final uri = Uri.parse('$baseUrl/transactions').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    debugPrint('================ [GET TRANSACTIONS REQUEST] ================');
    debugPrint('Endpoint: GET $uri');
    debugPrint('===========================================================');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    debugPrint('================ [GET TRANSACTIONS RESPONSE] ================');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('============================================================');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      final errorMessage =
          data['error'] ??
          'เกิดข้อผิดพลาดในการดึงรายการ (${response.statusCode})';
      throw Exception(errorMessage);
    }
  }

  /// Delete transaction by ID (DELETE /api/transactions/:id)
  static Future<Map<String, dynamic>> deleteTransaction(String id) async {
    final token = await TokenService.getToken();
    final url = Uri.parse('$baseUrl/transactions/$id');

    debugPrint('================ [DELETE TRANSACTION REQUEST] ================');
    debugPrint('Endpoint: DELETE $url');
    debugPrint('=============================================================');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    debugPrint('================ [DELETE TRANSACTION RESPONSE] ================');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('==============================================================');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      final errorMessage =
          data['error'] ??
          'เกิดข้อผิดพลาดในการลบรายการ (${response.statusCode})';
      throw Exception(errorMessage);
    }
  }
}


