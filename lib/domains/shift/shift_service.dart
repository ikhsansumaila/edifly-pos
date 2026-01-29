import 'dart:convert';

import 'package:edifly_pos/core/network/api_config.dart';
import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:http/http.dart' as http;

class ShiftService {
  static Future<Map<String, dynamic>> checkShiftStatus() async {
    final token = await AuthStorage.getToken();
    final url = Uri.parse('${API_BASE_URL}shift/status');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> openShift({
    required int openingCash,
    required int shiftNumber,
  }) async {
    final token = await AuthStorage.getToken();
    final url = Uri.parse('${API_BASE_URL}shift/open');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'opening_cash': openingCash, 'shift_number': shiftNumber}),
    );

    return jsonDecode(response.body);
  }
}
