import 'dart:convert';

import 'package:edifly_pos/core/network/api_config.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$API_BASE_URL/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded['status'] == true) {
        return decoded['data'];
        /*
          {
            user_id,
            role,
            outlet_id,
            token
          }
        */
      } else {
        throw decoded['message'] ?? 'Login gagal';
      }
    } else {
      throw 'Server error (${response.statusCode})';
    }
  }

  static Future<void> logout(String token) async {
    final url = Uri.parse('$API_BASE_URL/auth/logout');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['status'] != true) {
        throw decoded['message'] ?? 'Logout gagal';
      }
    } else {
      throw 'Server error (${response.statusCode})';
    }
  }
}
