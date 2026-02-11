import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:edifly_pos/core/utils/esc_pos_generator.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class PrintEscPos {
  static const String _logoPath = 'assets/icons/receipt-logo.jpeg';
  static const double _logoWidth = 0.6;

  /// Test print with ESC/POS
  static Future<bool> testPrint({
    required int paperWidth,
    required Future<bool> Function(List<int> bytes) printCallback,
  }) async {
    try {
      debugPrint("Testing ESC/POS print...");

      final gen = EscPosGenerator(paperWidth: paperWidth);
      gen.init();

      // Header with Logo
      try {
        final ByteData data = await rootBundle.load(_logoPath);
        final Uint8List bytes = data.buffer.asUint8List();
        final img.Image? originalImage = img.decodeImage(bytes);

        if (originalImage != null) {
          // Resize to 80% of paper width (matching TSPL)
          // 58mm = 384 dots, 80mm = 576 dots at 203 DPI
          final targetWidth = (paperWidth == 58 ? 384 : 576) * _logoWidth;
          final img.Image resized = img.copyResize(originalImage, width: targetWidth.toInt());
          gen.image(resized, align: PosTextAlign.center);
          gen.feed(1);
        }
      } catch (e) {
        debugPrint("Error printing logo: $e");
      }

      final outletName = await AuthStorage.getNamaOutlet() ?? '';
      final outletAddress = await AuthStorage.getAddress() ?? '';
      final cashierName = await AuthStorage.getName() ?? '-';

      // Dummy data
      const customerName = 'Budi Santoso';
      const queueNumber = '001';
      const orderNo = 'ORD-TEST-001';
      const channel = 'OFFLINE';
      const paymentMethod = 'Tunai (Cash)';
      const printUrl = 'https://www.instagram.com/dimonggoin?igsh=Zmc1YmFiNDc3eGV5';

      // Dummy items
      final dummyItems = [
        {'name': 'Kopi Susu', 'qty': 2, 'price': 15000, 'discount': 0},
        {'name': 'Roti Bakar Coklat', 'qty': 1, 'price': 20000, 'discount': 10},
        {'name': 'Es Teh Manis', 'qty': 1, 'price': 15000, 'discount': 0},
      ];

      int total = 0;
      for (final item in dummyItems) {
        final qty = item['qty'] as int;
        final price = item['price'] as int;
        final discount = item['discount'] as int;
        final nominalDiscount = (price * (discount / 100)) * qty;
        total += ((price * qty) - nominalDiscount).toInt();
      }

      const cashAmount = 100000;

      gen.text(outletName, align: PosTextAlign.center);
      gen.feed(1);
      if (outletAddress.isNotEmpty) {
        gen.text(outletAddress, align: PosTextAlign.center);
      }
      gen.feed(1);

      // Date & Time
      final now = DateTime.now();
      gen.text(
        'Tanggal: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        align: PosTextAlign.center,
      );
      gen.feed(1);

      // Customer info
      gen.text('No. Antrian: $queueNumber');
      gen.text('Order No: $orderNo');
      gen.text('Kasir: $cashierName');
      gen.text('Customer: $customerName');
      gen.text('Metode: $paymentMethod');
      gen.text('Sumber: $channel');
      gen.feed(1);

      gen.hr();
      gen.hr();

      // Items Header
      if (paperWidth == 58) {
        gen.text('Item      Qty  Disc. Total', bold: true);
      } else {
        gen.text('Item        Qty Disc.     Total', bold: true);
      }
      gen.hr();

      // Items
      for (final item in dummyItems) {
        final name = item['name'] as String;
        final qty = item['qty'] as int;
        final price = item['price'] as int;
        final discount = item['discount'] as int;
        final nominalDiscount = (price * (discount / 100)) * qty;
        final totalItem = (price * qty) - nominalDiscount;

        // Row 1: Name, Qty, Disc
        gen.row4(
          name,
          qty.toString(),
          formatRupiah(nominalDiscount.toInt()),
          "", // Total moved to next line
        );

        // Row 2: @Price ... Total
        gen.row("@${formatRupiah(price)}", formatRupiah(totalItem.toInt()));
      }

      gen.hr();

      // Total
      // gen.text('TOTAL', bold: true, doubleHeight: true);
      // gen.text(formatRupiah(total), bold: true, doubleHeight: true, align: PosTextAlign.right);
      gen.rowBold('TOTAL', formatRupiah(total), doubleHeight: true);
      gen.feed(1);

      // Payment info
      gen.row('Tunai', formatRupiah(cashAmount));
      final change = cashAmount - total;
      if (change > 0) {
        gen.row('Kembalian', formatRupiah(change));
      }

      gen.feed(2);

      // QR Code
      gen.qrcode(printUrl, size: 6);
      gen.feed(1);

      // Footer
      gen.text('Terima Kasih', bold: true, align: PosTextAlign.center);
      gen.text('Selamat Menikmati!', align: PosTextAlign.center);
      gen.text('=== TEST PRINT ===', align: PosTextAlign.center);
      gen.feed(4);

      debugPrint("Test Print ESC/POS: ${gen.bytes.length} bytes");

      return await printCallback(gen.bytes);
    } catch (e) {
      debugPrint("ESC/POS print failed: $e");
      return false;
    }
  }

  /// Print receipt with ESC/POS
  static Future<bool> printReceipt({
    required int paperWidth,
    required List<ProductModel> orderItems,
    required int total,
    String customerName = '-',
    String queueNumber = '-',
    required String paymentMethod,
    required String channel,
    required Future<bool> Function(List<int> bytes) printCallback,
    int? cashAmount,
    String? printUrl,
    String orderNo = '-',
  }) async {
    final gen = EscPosGenerator(paperWidth: paperWidth);
    gen.init();

    // Header
    try {
      final ByteData data = await rootBundle.load(_logoPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage != null) {
        // Resize to 80% of paper width (matching TSPL)
        // 58mm = 384 dots, 80mm = 576 dots at 203 DPI
        final targetWidth = (paperWidth == 58 ? 384 : 576) * _logoWidth;
        final img.Image resized = img.copyResize(originalImage, width: targetWidth.toInt());
        gen.image(resized, align: PosTextAlign.center);
        gen.feed(1);
      }
    } catch (e) {
      debugPrint("Error printing logo: $e");
    }

    final outletName = await AuthStorage.getNamaOutlet() ?? '';
    final outletAddress = await AuthStorage.getAddress() ?? '';
    final cashierName = await AuthStorage.getName() ?? '-';
    gen.text(outletName, align: PosTextAlign.center);
    gen.feed(1);
    if (outletAddress.isNotEmpty) {
      gen.text(outletAddress, align: PosTextAlign.center);
    }
    gen.feed(1);

    // Date & Time
    final now = DateTime.now();
    gen.text(
      'Tanggal: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      align: PosTextAlign.center,
    );
    gen.feed(1);

    // Customer info
    gen.text('No. Antrian: $queueNumber');
    gen.text('Order No: $orderNo');
    gen.text('Kasir: $cashierName');
    gen.text('Customer: $customerName');
    gen.text('Metode: $paymentMethod');
    gen.text('Sumber: $channel');
    gen.feed(1);

    gen.hr();

    gen.hr();

    // Items Header
    // Item (45%), Qty (10%), Disc (20%), Total (Remainder)
    if (paperWidth == 58) {
      gen.text('Item      Qty  Disc. Total', bold: true);
    } else {
      gen.text('Item        Qty Disc.     Total', bold: true);
    }
    gen.hr();

    // Items
    for (int i = 0; i < orderItems.length; i++) {
      final item = orderItems[i];
      final qty = item.qty;
      final price = item.harga;
      final discount = item.discount;

      // Calculate total per item
      final nominalDiscount = (price * (discount / 100)) * qty;
      final totalItem = (price * qty) - nominalDiscount;

      // Row 1: Name, Qty, Disc
      gen.row4(
        item.namaProduct,
        qty.toString(),
        formatRupiah(nominalDiscount.toInt()),
        "", // Total moved to next line
      );

      // Row 2: @Price ... Total
      gen.row("@${formatRupiah(price)}", formatRupiah(totalItem.toInt()));
    }

    gen.hr();
    gen.feed(1);

    // Total
    // gen.text('TOTAL              ${formatRupiah(total)}', bold: true, doubleHeight: true);
    // gen.text(formatRupiah(total), bold: true, doubleHeight: true, align: PosTextAlign.right);
    gen.rowBold('TOTAL', formatRupiah(total), doubleHeight: true);
    gen.feed(1);

    // Payment info
    if (cashAmount != null && cashAmount > 0) {
      gen.row('Tunai', formatRupiah(cashAmount));
      final change = cashAmount - total;
      if (change > 0) {
        gen.row('Kembalian', formatRupiah(change));
      }
    }
    gen.feed(2);

    // QR Code
    if (printUrl != null && printUrl.isNotEmpty) {
      gen.qrcode(printUrl, size: 6);
      gen.feed(1);
    }

    // Footer
    gen.text('Terima Kasih', bold: true, align: PosTextAlign.center);
    gen.text('Selamat Menikmati!', align: PosTextAlign.center);
    gen.feed(4);

    debugPrint("ESC/POS Print: ${gen.bytes.length} bytes");

    return await printCallback(gen.bytes);
  }
}
