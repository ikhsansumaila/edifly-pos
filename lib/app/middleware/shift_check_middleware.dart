import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:edifly_pos/domains/shift/closing_shift.dart';
import 'package:edifly_pos/domains/shift/shift_controller.dart';
import 'package:edifly_pos/domains/shift/shift_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShiftCheckMiddleware extends GetMiddleware {
  @override
  Widget onPageBuilt(Widget page) {
    _checkShift();
    return page;
  }

  Future<void> _checkShift() async {
    final shiftController =
        Get.isRegistered<ShiftController>()
            ? Get.find<ShiftController>()
            : Get.put(ShiftController());

    if (!shiftController.isShiftOpen.value) {
      try {
        final response = await ShiftService.checkShiftStatus();
        if (response['status'] == true) {
          final data = response['data'];
          final openedAtStr = data['opened_at'];
          if (openedAtStr != null) {
            final openedAt = DateTime.parse(openedAtStr);
            final now = DateTime.now();

            // Check if same day
            if (!(openedAt.year == now.year &&
                openedAt.month == now.month &&
                openedAt.day == now.day)) {
              // Different day, must close previous shift first
              Get.defaultDialog(
                title: 'Perhatian',
                middleText:
                    'Anda memiliki shift aktif dari hari sebelumnya. Harap lakukan closing terlebih dahulu.',
                textConfirm: 'OK',
                onConfirm: () {
                  Get.back(); // close dialog
                  Get.offAll(() => const ClosingShiftPage());
                },
                barrierDismissible: false,
                confirmTextColor: Colors.white,
              );
            }
          }
        } else if (response['status'] == false && response['data'] == null) {
          Get.offAllNamed(Routes.openingShift);
        }
      } catch (e) {
        // Silent error or log
        debugPrint("Shift check error: $e");
      }
    }
  }
}
