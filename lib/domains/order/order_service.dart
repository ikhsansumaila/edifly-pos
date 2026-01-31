import 'dart:convert';

import 'package:edifly_pos/core/network/api_client.dart';

class OrderService {
  static Future<Map<String, dynamic>> checkout({
    required String clientUuid,
    required int closingId,
    required String paymentMethod,
    required String sumber,
    required int subTotal,
    required int totalBayar,
    required List<Map<String, dynamic>> items,
    required String customerName,
    required String queueNumber,
  }) async {
    final response = await ApiClient.post(
      '/orders/checkout',
      body: {
        "client_uuid": clientUuid,
        "closing_id": closingId,
        "payment_method": paymentMethod,
        "sumber": sumber,
        "sub_total": subTotal,
        "total_bayar": totalBayar,
        "items": items,
        "customer_name": customerName,
        "queue_number": queueNumber,
      },
    );
    // print("response checkout: ${response.body}");

    return jsonDecode(response.body);
  }
}
