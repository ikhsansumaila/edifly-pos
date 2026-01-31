import 'dart:convert';

import 'package:edifly_pos/core/network/api_client.dart';
import 'package:get/get.dart';

import 'product_model.dart';

class ProductService extends GetxService {
  Future<List<ProductModel>> fetchProducts() async {
    // Token and handling checks are now inside ApiClient
    final response = await ApiClient.get('/products');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json['status'] == true) {
        if (json['data'] != null) {
          final List<dynamic> data = json['data'];
          return data.map((e) => ProductModel.fromJson(e)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(json['message'] ?? 'Failed to load products');
      }
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}
