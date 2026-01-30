import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/domains/order/closing_order.dart';
import 'package:edifly_pos/domains/order/order_page.dart';
import 'package:edifly_pos/domains/product/product_service.dart';
import 'package:get/get.dart';

import 'shift_service.dart';

class ShiftController extends GetxController {
  final isLoading = false.obs;
  final openingCash = 0.obs;
  final selectedShift = 1.obs; // 1, 2, or 3 (Full Day)
  final userName = ''.obs;
  final outletName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    final name = await AuthStorage.getName();
    final outlet = await AuthStorage.getNamaOutlet();
    userName.value = name ?? '';
    outletName.value = outlet ?? '';
  }

  Future<void> openShift() async {
    if (openingCash.value < 0) {
      Get.snackbar('Error', 'Kas awal tidak boleh kurang dari 0');
      return;
    }

    try {
      isLoading.value = true;
      final response = await ShiftService.openShift(
        openingCash: openingCash.value,
        shiftNumber: selectedShift.value,
      );

      if (response['status'] == true) {
        Get.snackbar('Sukses', 'Shift berhasil dibuka');
        Get.put(ProductService());
        Get.offAll(() => const PosOrderPage());
      } else {
        if (response['message']?.toString().contains('Tutup shift sebelumnya') ?? false) {
          Get.snackbar('Perhatian', response['message']);
          Get.to(() => const ReconciliationPage());
        } else {
          throw response['message'] ?? 'Gagal membuka shift';
        }
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Future<void> checkInitialStatus() async {
  //   try {
  //     isLoading.value = true;
  //     final response = await ShiftService.checkShiftStatus();

  //     if (response['status'] == true) {
  //       final data = response['data'];
  //       final openedAtStr = data['opened_at'];
  //       if (openedAtStr != null) {
  //         final openedAt = DateTime.parse(openedAtStr);
  //         final now = DateTime.now();

  //         // Check if same day
  //         if (openedAt.year == now.year && openedAt.month == now.month && openedAt.day == now.day) {
  //           Get.put(ProductService());
  //           Get.offAll(() => const PosOrderPage());
  //         } else {
  //           // Different day, must close previous shift first
  //           Get.snackbar(
  //             'Perhatian',
  //             'Anda memiliki shift aktif dari hari sebelumnya. Harap lakukan closing terlebih dahulu.',
  //           );
  //           Get.offAll(() => const ReconciliationPage());
  //         }
  //       }
  //     } else {
  //       // No active shift, stay on open shift page or go to it
  //     }
  //   } catch (e) {
  //     print("Error checking shift status: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
}
