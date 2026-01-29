import 'dart:convert';

import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:edifly_pos/core/network/api_config.dart';
import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'product_model.dart';

class ProductService extends GetxService {
  Future<List<ProductModel>> fetchProducts() async {
    final token = await AuthStorage.getToken();

    if (token == null) {
      await AuthStorage.clearAuth();
      Get.offAllNamed(Routes.login);
      return [];
    }

    final url = Uri.parse('${API_BASE_URL}products');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

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
