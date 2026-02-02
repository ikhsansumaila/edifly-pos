import 'dart:convert';

import 'package:edifly_pos/core/network/api_client.dart';
import 'package:edifly_pos/domains/order/models/checkout_response_model.dart';
import 'package:edifly_pos/domains/order/models/order_detail_model.dart';
import 'package:edifly_pos/domains/order/models/order_list_model.dart';

class OrderService {
  /// Get list of orders
  static Future<List<OrderListItemModel>> getOrders() async {
    final response = await ApiClient.get('/orders');
    final json = jsonDecode(response.body);

    if (json['status'] == true && json['data'] != null) {
      return (json['data'] as List).map((e) => OrderListItemModel.fromJson(e)).toList();
    }
    return [];
  }

  /// Get order detail by ID
  static Future<OrderDetailModel?> getOrderDetail(int orderId) async {
    final response = await ApiClient.get('/orders?id=$orderId');
    final json = jsonDecode(response.body);

    if (json['status'] == true && json['data'] != null) {
      return OrderDetailModel.fromJson(json['data']);
    }
    return null;
  }

  /// Delete order by ID
  static Future<bool> deleteOrder(int orderId) async {
    final response = await ApiClient.post('/orders/delete', body: {'order_id': orderId});
    final json = jsonDecode(response.body);
    return json['status'] == true;
  }

  static Future<CheckoutResponseModel> checkout({
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

    return CheckoutResponseModel.fromJson(jsonDecode(response.body));
  }
}
