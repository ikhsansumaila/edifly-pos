import 'package:edifly_pos/domains/order/order_page.dart';
import 'package:edifly_pos/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReconciliationPage extends StatefulWidget {
  const ReconciliationPage({super.key});

  @override
  State<ReconciliationPage> createState() => _ReconciliationPageState();
}

class _ReconciliationPageState extends State<ReconciliationPage> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Mock data sesuai gambar
  final double initialBalance = 10000000;
  final double cashSales = 0;
  final double nonCashSales = 0;

  @override
  Widget build(BuildContext context) {
    double totalExpected = initialBalance + cashSales;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            TopBar(
              menus: [
                TopBarMenuModel(
                  label: 'Pesanan',
                  icon: Icons.receipt_long,
                  onTap: () {
                    Get.to(() => const PosOrderPage());
                    // Jalankan fungsi A
                  },
                ),
                TopBarMenuModel(
                  label: 'Tutup Pesanan',
                  icon: Icons.lock,
                  onTap: () {},
                  isActive: true,
                ),
                TopBarMenuModel(
                  label: 'Logout',
                  icon: Icons.exit_to_app,
                  onTap: () {
                    // Jalankan fungsi C (Contoh: Show Dialog Logout)
                    // _showLogoutDialog(context);
                  },
                ),
              ],
            ),
            // --- Header Section ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Dropdown Section ---
                  const Text(
                    "Pilih Shift / Tanggal",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: "28 Jan 2026 20:23 (Shift 1)",
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "28 Jan 2026 20:23 (Shift 1)",
                        child: Text("28 Jan 2026 20:23 (Shift 1)"),
                      ),
                    ],
                    onChanged: (val) {},
                  ),

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
                            _buildRowValue("Modal Awal:", "Rp 10.000.000"),
                            _buildRowValue("Penjualan Tunai:", "Rp 0", color: Colors.teal),
                            const Divider(),
                            _buildRowValue("Uang Tunai:", "Rp 10.000.000", isBold: true),
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
                              decoration: InputDecoration(
                                prefixText: "Rp ",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 20),
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- Submit Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D3B2A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        "SELESAIKAN & TUTUP SHIFT",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            children: const [
              Text(
                "Penjualan Non-Tunai (QRIS/Debit):",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text("Rp 0", style: TextStyle(fontSize: 11, color: Colors.grey)),
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
