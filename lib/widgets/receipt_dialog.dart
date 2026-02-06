import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:edifly_pos/core/config/app_theme_config.dart';
import 'package:edifly_pos/core/services/printer_service.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiptDialog extends StatelessWidget {
  final List<ProductModel> orderItems;
  final int total;
  final String customerName;
  final String queueNumber;
  final String paymentMethod;
  final String channel;
  final int? cashAmount;
  final String cashierName;
  final String outletName;
  final String outletAddress;
  final String? printUrl;
  final String? orderNo;

  const ReceiptDialog({
    super.key,
    required this.orderItems,
    required this.total,
    required this.customerName,
    required this.queueNumber,
    required this.paymentMethod,
    required this.channel,
    this.cashAmount,
    required this.cashierName,
    required this.outletName,
    this.outletAddress = '',
    this.printUrl,
    this.orderNo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.white,
      child: Container(
        width: 350,
        height: 600, // Increased height to fit content better
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    // Logo
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        // width: 80,
                        height: 120,
                        decoration: BoxDecoration(
                          // shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: AssetImage('assets/icons/receipt-logo.jpeg'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      outletName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                    if (outletAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        outletAddress,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(DateTime.now()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black26),

                    // Info
                    if (queueNumber.isNotEmpty && queueNumber != '-')
                      _buildInfoRow("No. Antrian", queueNumber),
                    if (orderNo != null && orderNo!.isNotEmpty) _buildInfoRow("Order No", orderNo!),
                    _buildInfoRow("Kasir", cashierName),
                    if (customerName.isNotEmpty) _buildInfoRow("Customer", customerName),
                    _buildInfoRow("Pembayaran", paymentMethod),
                    _buildInfoRow("Sumber", channel),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.black26),

                    // Items Header
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'Item',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Disc.',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.black26, thickness: 1, height: 16),

                    // Items List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        final double nominalDiscount =
                            (item.harga * (item.discount / 100)) * item.qty;
                        final double totalItem = (item.harga * item.qty) - nominalDiscount;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item Name & Price
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.namaProduct,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "@${formatRupiah(item.harga)}",
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              // Qty
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "${item.qty}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              // Disc
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formatRupiah(nominalDiscount.toInt()),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              // Total
                              Expanded(
                                flex: 3,
                                child: Text(
                                  formatRupiah(totalItem.toInt()),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.black26),

                    // Totals
                    _buildTotalRow("TOTAL", total, isBold: true, fontSize: 16),
                    const SizedBox(height: 8),

                    // Payment method moved to Info section
                    if (cashAmount != null && cashAmount! > 0) ...[
                      const SizedBox(height: 4),
                      _buildTotalRow("Tunai", cashAmount!),
                      _buildTotalRow("Kembalian", cashAmount! - total),
                    ],

                    if (printUrl != null && printUrl!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: QrImageView(data: printUrl!, version: QrVersions.auto, size: 150.0),
                      ),
                    ],

                    const SizedBox(height: 20),
                    const Text(
                      'Terima Kasih\nSelamat Menikmati!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Fixed Buttons at bottom
            const SizedBox(height: 8),

            // Print Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final printerService = Get.find<PrinterService>();

                  // Check if printer is connected
                  final isConnected = await printerService.checkConnection();

                  if (!isConnected) {
                    // Show error dialog with option to go to printer settings
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 28),
                            const SizedBox(width: 8),
                            const Text('Printer Tidak Terhubung', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        content: const Text(
                          'Printer belum terhubung. Silakan hubungkan printer terlebih dahulu untuk mencetak struk.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(), // Close error dialog only
                            child: const Text('Batal'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Get.back(); // Close error dialog
                              Get.toNamed(Routes.printSettings); // Go to printer settings
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Atur Printer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemeConfig.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      barrierDismissible: true,
                    );
                    return;
                  }

                  // Printer is connected, proceed to print
                  await printerService.printReceipt(
                    orderItems: orderItems,
                    total: total,
                    customerName: customerName,
                    queueNumber: queueNumber,
                    paymentMethod: paymentMethod,
                    channel: channel,
                    cashAmount: cashAmount,
                    printUrl: 'https://www.instagram.com/dimonggoin?igsh=Zmc1YmFiNDc3eGV5',
                    orderNo: orderNo,
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text("Cetak Struk"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Keep it black or simple grey
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Tutup"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, int value, {bool isBold = false, double fontSize = 12}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatRupiah(value),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
