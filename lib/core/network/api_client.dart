import 'dart:convert';

import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:edifly_pos/core/network/api_config.dart';
import 'package:edifly_pos/core/network/inspector_http_client.dart';
import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$API_BASE_URL$endpoint');
    final headers = await _getHeaders();

    print("[GET] $url");
    final response = await InspectorHttpClient.get(url, headers: headers);
    await _handleResponse(response);
    return response;
  }

  static Future<http.Response> post(String endpoint, {Object? body}) async {
    final url = Uri.parse('$API_BASE_URL$endpoint');
    final headers = await _getHeaders();

    // Ensure body is JSON encoded if it's a Map
    final finalBody = (body is Map) ? jsonEncode(body) : body;

    print("[POST] $url");
    final response = await InspectorHttpClient.post(url, headers: headers, body: finalBody);
    await _handleResponse(response);
    return response;
  }

  static Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      print("Unauthorized (401) detected. Logging out...");
      await AuthStorage.clearAuth();
      Get.offAllNamed(Routes.login);
      // Optional: Throw exception to stop further execution in the calling service
      throw Exception("Session expired. Please login again.");
    }
  }
}
