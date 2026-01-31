import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/domains/order/order_page.dart';
import 'package:edifly_pos/domains/product/product_service.dart';
import 'package:flutter/foundation.dart';
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
    if (kDebugMode && email.value == 'ikhsan') {
      await AuthStorage.saveAuth(
        token: "1926491632311449f9eafd0eaf2742bfcaebbff404a776666950544edfabe631",
        outletId: '1',
        userId: '1',
        role: "kasir",
        name: "Ikhsan",
        namaOutlet: "Bella Terra",
        email: email.value,
      );
      Get.put(ProductService());
      Get.offAll(() => const PosOrderPage());
      return;
    }
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
      print("token ${await AuthStorage.getToken()}");
      isLoading.value = true;

      final data = await AuthService.login(email: email.value, password: password.value);

      // Parse data and update state
      userId.value = int.tryParse(data['user_id'].toString()) ?? 0;
      outletId.value = int.tryParse(data['outlet_id'].toString()) ?? 0;
      role.value = data['role'] ?? '';
      token.value = data['token'] ?? '';

      final String name = data['name'] ?? '';
      final String namaOutlet = data['nama_outlet'] ?? '';

      // Get.snackbar('Sukses', 'Login berhasil');

      // Simpan token dan data user ke SharedPreferences
      await AuthStorage.saveAuth(
        token: token.value,
        outletId: data['outlet_id'].toString(),
        userId: data['user_id'].toString(),
        role: role.value,
        name: name,
        namaOutlet: namaOutlet,
        email: email.value,
      );

      // Redirect directly to Order Page
      Get.put(ProductService());
      Get.offAll(() => const PosOrderPage());
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
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;

      final savedToken = await AuthStorage.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        await AuthService.logout(savedToken);
      }

      // Clear local storage
      await AuthStorage.clearAuth();

      Get.snackbar('Sukses', 'Logout berhasil');

      // Navigate to login page
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Logout Gagal',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
