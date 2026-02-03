import 'dart:ui';

import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:edifly_pos/core/utils/terbilang.dart';
import 'package:edifly_pos/domains/auth/auth_controller.dart';
import 'package:edifly_pos/domains/shift/shift_controller.dart';
import 'package:edifly_pos/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ClosingShiftPage extends StatefulWidget {
  const ClosingShiftPage({super.key});

  @override
  State<ClosingShiftPage> createState() => _ClosingShiftPageState();
}

class _ClosingShiftPageState extends State<ClosingShiftPage> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ShiftController controller = Get.put(ShiftController());

  @override
  void initState() {
    super.initState();
    controller.loadClosingData();
  }

  // Mock data sesuai gambar
  final double initialBalance = 10000000;
  final double cashSales = 0;
  final double nonCashSales = 0;

  @override
  Widget build(BuildContext context) {
    // double totalExpected = initialBalance + cashSales;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_cafe.jpg', fit: BoxFit.cover),

          Container(color: Colors.black.withValues(alpha: 0.35)),

          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: size.height * 0.88),
              child: SizedBox(
                width: size.width * 0.7,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: _form(),
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

  Widget _form() {
    return Column(
      children: [
        Obx(
          () => TopBar(
            userName: controller.userName.value,
            menus: [
              TopBarMenuModel(
                label: 'Transaksi',
                icon: Icons.shopping_cart_outlined,
                onTap: () {
                  Get.toNamed(Routes.order);
                },
              ),
              TopBarMenuModel(
                label: 'Tutup Pesanan',
                icon: Icons.lock,
                onTap: () {},
                isActive: true,
              ),
            ],
            onLogout: () {
              final authController = Get.put(AuthController());
              authController.logout();
            },
          ),
        ),

        Obx(() {
          if (controller.isOldShift) {
            return Container(
              width: double.infinity,
              color: const Color(0xFFE6ECEC),
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFffae0d),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "Ini adalah shift lama yang belum ditutup.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // --- Header Section ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  color: const Color(0xFF4D3B2A), // Warna cokelat tua
                  child: Column(
                    children: [
                      const Icon(Icons.vpn_key, color: Colors.white70, size: 40),
                      const SizedBox(height: 16),
                      const Text(
                        "REKONSILIASI PENUTUPAN SHIFT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        "Pastikan uang fisik di laci sesuai dengan catatan sistem",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(20.0),
                  color: Color(0xFFE6ECEC),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Dropdown Section ---
                      const Text(
                        "Pilih Shift / Tanggal",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        String formattedDate = '';
                        if (controller.activeShiftDate.value.isNotEmpty) {
                          try {
                            final date = DateTime.parse(controller.activeShiftDate.value);
                            formattedDate = DateFormat('dd MMM yyyy HH:mm').format(date);
                          } catch (e) {
                            formattedDate = controller.activeShiftDate.value;
                          }
                        }
                        final label = "$formattedDate (${controller.activeShiftName.value})";

                        return DropdownButtonFormField<String>(
                          key: ValueKey(label), // Force rebuild if label changes
                          initialValue: label,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: [DropdownMenuItem(value: label, child: Text(label))],
                          onChanged: null, // Read-only mostly as it's the active one
                        );
                      }),

                      const SizedBox(height: 30),

                      // --- Main Content (Grid-like) ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: System Records
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Catatan Sistem",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Divider(),
                                Obx(
                                  () => _buildRowValue(
                                    "Modal Awal:",
                                    formatRupiah(controller.openingCashAmount.value),
                                  ),
                                ),
                                Obx(
                                  () => _buildRowValue(
                                    "Penjualan Tunai:",
                                    formatRupiah(controller.totalSalesCash.value),
                                    color: Colors.teal,
                                  ),
                                ),
                                const Divider(),
                                Obx(
                                  () => _buildRowValue(
                                    "Uang Tunai:",
                                    formatRupiah(controller.systemTotalCash),
                                    isBold: true,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildNonCashCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right Column: Inputs
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Input Fisik",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Divider(),
                                const Text(
                                  "Uang Fisik di Laci (Tunai)",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _cashController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [RupiahInputFormatter()],
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    hintText: "Rp 0",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    String numericString = val.replaceAll(RegExp(r'[^0-9]'), '');
                                    double value =
                                        numericString.isEmpty ? 0 : double.parse(numericString);
                                    controller.userInputCash.value = value;
                                  },
                                ),
                                const SizedBox(height: 6),
                                Obx(() {
                                  if (controller.userInputCash.value == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    terbilang(controller.userInputCash.value),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  );
                                }),
                                const SizedBox(height: 10),

                                // Discrepancy Banner
                                Obx(() {
                                  // if (controller.userInputCash.value == 0 && controller.systemTotalCash > 0) return const SizedBox.shrink();
                                  // Optional: hide if 0 input? But maybe user wants to see shortage.
                                  // Let's show it always if there's a difference or balance

                                  if (controller.userInputCash.value == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  Color bgColor = Colors.grey.shade200;
                                  Color textColor = Colors.black54;
                                  String text = "Balance: Rp 0";

                                  if (controller.isShort) {
                                    bgColor = const Color(0xFFFFE5E5); // Light red
                                    textColor = const Color(0xFFD32F2F); // Red
                                    text =
                                        "Kekurangan Kas (Short): ${formatRupiah(controller.cashDifference.abs())}";
                                  } else if (controller.isOver) {
                                    bgColor = const Color(0xFFE8F5E9); // Light green
                                    textColor = const Color(0xFF388E3C); // Green
                                    text =
                                        "Kelebihan Kas (Over): ${formatRupiah(controller.cashDifference.abs())}";
                                  } else {
                                    // Balance
                                    bgColor = Colors.grey.shade200;
                                    textColor = Colors.black54;
                                    text = "Sesuai (Balance): Rp 0";
                                  }

                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                const SizedBox(height: 10),

                                const Text(
                                  "Catatan/Alasan Selisih",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _noteController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: "Wajib diisi jika ada selisih uang...",
                                    hintStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // --- Submit Button (Fixed at bottom) ---
        Container(
          padding: const EdgeInsets.all(16.0),
          color: const Color(0xFFE6ECEC),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final cashStr = _cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
                final cash = int.tryParse(cashStr) ?? 0;
                controller.closeShift(actualCash: cash, notes: _noteController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D3B2A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Obx(
                () => Text(
                  controller.isLoading.value ? "LOADING..." : "SELESAIKAN & TUTUP SHIFT",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRowValue(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonCashCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Penjualan Non-Tunai (QRIS/Debit):",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Obx(
                () => Text(
                  formatRupiah(controller.totalSalesNonCash.value),
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "*Data non-tunai tidak dihitung dalam fisik kas.",
            style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
