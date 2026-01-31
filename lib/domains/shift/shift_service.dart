import 'dart:convert';

import 'package:edifly_pos/core/network/api_client.dart';

class ShiftService {
  static Future<Map<String, dynamic>> checkShiftStatus() async {
    final response = await ApiClient.get('/shift/status');

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> openShift({
    required int openingCash,
    required int shiftNumber,
  }) async {
    final response = await ApiClient.post(
      '/shift/open',
      body: {'opening_cash': openingCash, 'shift_number': shiftNumber},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> closeShift({
    required int closingId,
    required int actualCash,
    String? notes,
  }) async {
    final response = await ApiClient.post(
      '/shift/close',
      body: {'closing_id': closingId, 'actual_cash': actualCash, 'notes': notes ?? ''},
    );

    return jsonDecode(response.body);
  }
}
