import 'package:edifly_pos/domains/order/order_page.dart';
import 'package:edifly_pos/domains/product/product_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth_service.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;

  final email = ''.obs;
  final password = ''.obs;

  final token = ''.obs;
  final outletId = 0.obs;
  final userId = 0.obs;
  final role = ''.obs;

  Future<void> login() async {
    print("email.isEmpty ${email.isEmpty}");

    print("password.isEmpty ${password.isEmpty}");
    if (email.value.trim().isEmpty || password.value.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Email dan password wajib diisi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      final data = await AuthService.login(email: email.value, password: password.value);
      print("data login $data");
      userId.value = data['user_id'];
      role.value = data['role'];
      outletId.value = data['outlet_id'];
      token.value = data['token'];

      Get.snackbar('Sukses', 'Login berhasil');

      // TODO: simpan token (GetStorage/Hive)
      // TODO: Get.offAllNamed('/dashboard');
      // Get.offAll(() => const PosOrderPage());
      // Get.put(ProductService());
    } catch (e) {
      print("login error $e");
      Get.snackbar(
        'Login Gagal',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      // isLoading.value = false;
      Get.put(ProductService());
      Get.offAll(() => const PosOrderPage());
    }
  }
}
