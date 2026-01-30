import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/domains/order/closing_order.dart';
import 'package:edifly_pos/domains/order/order_page.dart';
import 'package:edifly_pos/domains/product/product_service.dart';
import 'package:edifly_pos/domains/shift/open_shift_page.dart';
import 'package:edifly_pos/domains/shift/shift_service.dart';
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

      // Parse data and update state
      userId.value = int.tryParse(data['user_id'].toString()) ?? 0;
      outletId.value = int.tryParse(data['outlet_id'].toString()) ?? 0;
      role.value = data['role'] ?? '';
      token.value = data['token'] ?? '';

      final String name = data['name'] ?? '';
      final String namaOutlet = data['nama_outlet'] ?? '';

      Get.snackbar('Sukses', 'Login berhasil');

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

      // Check Shift Status
      await _checkShiftAfterLogin();
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

  Future<void> _checkShiftAfterLogin() async {
    try {
      final response = await ShiftService.checkShiftStatus();

      if (response['status'] == true) {
        final data = response['data'];
        final openedAtStr = data['opened_at'];
        if (openedAtStr != null) {
          final openedAt = DateTime.parse(openedAtStr);
          final now = DateTime.now();

          // Check if same day
          if (openedAt.year == now.year && openedAt.month == now.month && openedAt.day == now.day) {
            Get.put(ProductService());
            Get.offAll(() => const PosOrderPage());
          } else {
            // Different day, must close previous shift first
            Get.snackbar(
              'Perhatian',
              'Anda memiliki shift aktif dari hari sebelumnya. Harap lakukan closing terlebih dahulu.',
            );
            Get.offAll(() => const ReconciliationPage());
          }
        }
      } else {
        // No active shift, go to open shift page
        Get.offAll(() => const OpenShiftPage());
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
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
