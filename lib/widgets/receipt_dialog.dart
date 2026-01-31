import 'package:edifly_pos/core/services/printer_service.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReceiptDialog extends StatelessWidget {
  final List<ProductModel> cartItems;
  final int total;
  final String customerName;
  final String queueNumber;
  final String paymentMethod;
  final String channel;
  final int? cashAmount;
  final String cashierName;
  final String outletName;

  const ReceiptDialog({
    super.key,
    required this.cartItems,
    required this.total,
    required this.customerName,
    required this.queueNumber,
    required this.paymentMethod,
    required this.channel,
    this.cashAmount,
    required this.cashierName,
    required this.outletName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.white,
      child: Container(
        width: 350,
        height: 500, // Limit height to ensure it fits, but scrollable inside if needed
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
                    Text(
                      outletName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(DateTime.now()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black26),

                    // Info
                    _buildInfoRow("Kasir", cashierName),
                    if (customerName.isNotEmpty) _buildInfoRow("Customer", customerName),
                    if (queueNumber.isNotEmpty && queueNumber != '-')
                      _buildInfoRow("No. Antrian", queueNumber),
                    _buildInfoRow("Channel", channel),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.black26),

                    // Items
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaProduct,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${item.qty} x ${formatRupiah(item.harga)}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    formatRupiah(item.harga * item.qty),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
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
                    _buildInfoRow("Pembayaran", paymentMethod),
                    if (cashAmount != null && cashAmount! > 0) ...[
                      const SizedBox(height: 4),
                      _buildTotalRow("Tunai", cashAmount!),
                      _buildTotalRow("Kembalian", cashAmount! - total),
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
            // Print Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Get.find<PrinterService>().printReceipt(
                    cartItems: cartItems,
                    total: total,
                    customerName: customerName,
                    queueNumber: queueNumber,
                    paymentMethod: paymentMethod,
                    channel: channel,
                    cashAmount: cashAmount,
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text("Cetak Struk"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3A1E),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Close Button (Fixed at bottom)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Keep it black or simple grey
                  foregroundColor: Colors.white,
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
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
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
