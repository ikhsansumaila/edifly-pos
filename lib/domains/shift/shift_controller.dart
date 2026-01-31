import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/domains/order/order_page.dart';
import 'package:edifly_pos/domains/product/product_service.dart';
import 'package:edifly_pos/domains/shift/closing_shift.dart';
import 'package:edifly_pos/domains/shift/open_shift_page.dart';
import 'package:get/get.dart';

import 'shift_service.dart';

class ShiftController extends GetxController {
  final isLoading = false.obs;
  final openingCash = 0.obs;
  final selectedShift = 1.obs; // 1, 2, or 3 (Full Day)
  final userName = ''.obs;
  final outletName = ''.obs;

  final currentShiftId = Rxn<int>();
  final activeShiftDate = ''.obs;

  final activeShiftName = ''.obs;

  final isShiftOpen = false.obs;

  // Financial Data from API
  final openingCashAmount = 0.0.obs;
  final totalSalesCash = 0.0.obs;
  final totalSalesNonCash = 0.0.obs;

  // Detailed breakdown from before_closing
  final totalQris = 0.0.obs;
  final totalTransfer = 0.0.obs;
  final expectedCashSystem = 0.0.obs;

  // User Input
  final userInputCash = 0.0.obs;

  double get systemTotalCash =>
      expectedCashSystem.value > 0
          ? expectedCashSystem.value
          : (openingCashAmount.value + totalSalesCash.value);

  double get cashDifference => userInputCash.value - systemTotalCash;

  bool get isBalance => cashDifference.abs() < 1; // Tolerance for float
  bool get isShort => cashDifference < -1;
  bool get isOver => cashDifference > 1;

  bool get isOldShift {
    if (activeShiftDate.value.isEmpty) return false;
    try {
      final date = DateTime.parse(activeShiftDate.value);
      final now = DateTime.now();
      return date.year != now.year || date.month != now.month || date.day != now.day;
    } catch (e) {
      return false;
    }
  }

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
        isShiftOpen.value = true;
        Get.snackbar('Sukses', 'Shift berhasil dibuka');
        Get.put(ProductService());
        Get.offAll(() => const PosOrderPage());
      } else {
        if (response['message']?.toString().contains('Tutup shift sebelumnya') ?? false) {
          Get.snackbar('Perhatian', response['message']);
          Get.to(() => const ClosingShiftPage());
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

  Future<void> getActiveShift() async {
    try {
      isLoading.value = true;
      final response = await ShiftService.checkShiftStatus();
      if (response['status'] == true) {
        final data = response['data'];
        if (data != null && data is Map) {
          currentShiftId.value =
              int.tryParse(data['id']?.toString() ?? '') ??
              int.tryParse(data['shift_id']?.toString() ?? '');

          // Dates
          activeShiftDate.value = data['opened_at'] ?? DateTime.now().toString();

          // Shift Name/Number
          final sNum = data['shift_number']?.toString() ?? '1';
          activeShiftName.value = "Shift $sNum";

          // If we are just checking status, we might not get full financial data yet
          // unless we call before_closing.
          // But let's populate what we can if available.
        }
      }
    } catch (e) {
      print("Error getting active shift: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadClosingData() async {
    await getActiveShift(); // Ensure we have ID

    if (currentShiftId.value == null) {
      Get.snackbar('Error', 'Tidak ada shift aktif ditemukan.');
      return;
    }

    try {
      isLoading.value = true;
      final response = await ShiftService.getBeforeClosingSummary(closingId: currentShiftId.value!);

      if (response['status'] == true) {
        final data = response['data'];
        if (data != null) {
          // "opening_cash": 500000
          openingCashAmount.value = double.tryParse(data['opening_cash']?.toString() ?? '0') ?? 0.0;

          // "total_cash": 250000 (Sales Cash)
          totalSalesCash.value = double.tryParse(data['total_cash']?.toString() ?? '0') ?? 0.0;

          // "total_qris": 150000
          totalQris.value = double.tryParse(data['total_qris']?.toString() ?? '0') ?? 0.0;

          // "total_transfer": 100000
          totalTransfer.value = double.tryParse(data['total_transfer']?.toString() ?? '0') ?? 0.0;

          // "expected_cash": 750000
          expectedCashSystem.value =
              double.tryParse(data['expected_cash']?.toString() ?? '0') ?? 0.0;

          // Non cash total
          totalSalesNonCash.value = totalQris.value + totalTransfer.value;
        }
      } else {
        Get.snackbar('Error', response['message'] ?? 'Gagal memuat data closing');
      }
    } catch (e) {
      print("Error loading closing data: $e");
      Get.snackbar('Error', 'Gagal memuat data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> closeShift({required int actualCash, required String notes}) async {
    if (currentShiftId.value == null) {
      Get.snackbar('Error', 'ID Shift tidak ditemukan. Pastikan data shift termuat.');
      return;
    }

    try {
      isLoading.value = true;
      final response = await ShiftService.closeShift(
        closingId: currentShiftId.value!,
        actualCash: actualCash,
        notes: notes,
      );

      if (response['status'] == true) {
        Get.snackbar('Sukses', response['message'] ?? 'Shift berhasil ditutup');
        Get.offAll(() => const OpenShiftPage());
      } else {
        Get.snackbar('Gagal', response['message'] ?? 'Gagal menutup shift');
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
  //           Get.offAll(() => const ClosingShiftPage());
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
