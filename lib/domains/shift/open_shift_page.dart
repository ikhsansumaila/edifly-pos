import 'dart:ui';

import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'shift_controller.dart';

class OpenShiftPage extends StatelessWidget {
  const OpenShiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShiftController());

    return Scaffold(
      backgroundColor: Colors.white.withAlpha(240),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_cafe.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.35)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Container(
                width: 360,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.85,
                        ), // Slightly more opaque for form readability
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// HEADER
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: const BoxDecoration(
                              color: Color(0xFF5B4028),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(40),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.key, color: Colors.white, size: 29),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'BUKA SHIFT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Siapkan kas awal untuk operasional hari ini',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// BODY
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// USER CARD
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF5B4028).withAlpha(40),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.person, color: Colors.blueGrey),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Obx(
                                            () => Text(
                                              controller.userName.value,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF5B4028),
                                              ),
                                            ),
                                          ),
                                          Obx(
                                            () => Text(
                                              controller.outletName.value.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                const Text(
                                  'Pilih Periode Shift',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: _shiftButton(controller, 1, 'Shift 1')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _shiftButton(controller, 2, 'Shift 2')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _shiftButton(controller, 3, 'Full Day')),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                const Text(
                                  'Kas Awal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                RupiahInput(
                                  hint: 'Rp 0',
                                  onChanged: (val) {
                                    controller.openingCash.value = val;
                                  },
                                ),

                                const SizedBox(height: 20),

                                /// ACTION BUTTONS
                                Obx(
                                  () => SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed:
                                          controller.isLoading.value
                                              ? null
                                              : () => controller.openShift(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF5B4028),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                      child:
                                          controller.isLoading.value
                                              ? const CircularProgressIndicator(color: Colors.white)
                                              : const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'MULAI OPERASIONAL',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Icon(Icons.play_arrow_rounded, size: 20),
                                                ],
                                              ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: () => Get.offAllNamed(Routes.login),
                                    child: Text(
                                      'BATAL',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shiftButton(ShiftController controller, int shift, String label) {
    return Obx(() {
      final isSelected = controller.selectedShift.value == shift;
      return InkWell(
        onTap: () => controller.selectedShift.value = shift,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5B4028) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF5B4028) : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ),
        ),
      );
    });
  }
}
