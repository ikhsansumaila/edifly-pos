import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class PrintTspl {
  /// Test print with TSPL - full dummy receipt
  static Future<List<int>?> testPrint({required int labelWidth}) async {
    try {
      debugPrint("Testing TSPL print with dummy receipt...");

      final StringBuffer tspl = StringBuffer();
      final width = labelWidth;

      // Constants
      final int lineHeight = 35;
      final int smallLineHeight = 30;

      // Get data
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

      // Get logo height for calculation
      final logoHeight = await getLogoHeight(labelWidth);

      // Prepare Address Lines
      List<String> addressLines = [];
      if (outletAddress.isNotEmpty) {
        final maxChars = ((width * 8) - 40) ~/ 12; // Font 2 approx 12 dots width
        final words = outletAddress.split(' ');
        String currentLine = "";
        for (var word in words) {
          if ((currentLine + word).length > maxChars) {
            if (currentLine.isNotEmpty) addressLines.add(currentLine.trim());
            currentLine = "$word ";
          } else {
            currentLine += "$word ";
          }
        }
        if (currentLine.isNotEmpty) addressLines.add(currentLine.trim());
      }

      // Calculate dynamic height for test content
      int estimatedDots = 20;

      // Logo section
      if (logoHeight > 0) {
        estimatedDots += logoHeight;
      }

      estimatedDots += lineHeight + 8; // Header
      if (addressLines.isNotEmpty) {
        estimatedDots += (addressLines.length * smallLineHeight) + 4;
      }
      estimatedDots += lineHeight; // Date
      estimatedDots += 8; // Divider

      // Info section
      estimatedDots += smallLineHeight; // Queue number
      estimatedDots += smallLineHeight; // Order No
      estimatedDots += smallLineHeight; // Kasir
      estimatedDots += smallLineHeight; // Customer
      estimatedDots += smallLineHeight; // Payment Method
      estimatedDots += smallLineHeight + 4; // Channel
      estimatedDots += 8; // Divider

      // Items header
      estimatedDots += smallLineHeight + 4; // Header row
      estimatedDots += 8; // Divider

      // Items section
      for (final item in dummyItems) {
        String name = item['name'] as String;
        int nameLines = (name.length / 12).ceil();
        if (nameLines < 1) nameLines = 1;
        estimatedDots += smallLineHeight * nameLines; // Name lines
        estimatedDots += smallLineHeight + 2; // @Price line
      }
      estimatedDots += 10; // Divider

      // Total section
      estimatedDots += lineHeight + 4; // Total
      estimatedDots += smallLineHeight; // Cash
      estimatedDots += smallLineHeight; // Change
      estimatedDots += 20; // Padding

      // QR Code
      estimatedDots += 250;

      // Footer section
      estimatedDots += smallLineHeight; // Terima kasih
      estimatedDots += smallLineHeight; // Selamat menikmati
      estimatedDots += smallLineHeight; // TEST PRINT
      estimatedDots += 100; // Extra padding bottom

      final calculatedHeightMm = (estimatedDots / 8).ceil() + 20;
      final finalHeight = calculatedHeightMm;

      // Calculate positions
      int y = 20; // Start lower
      final int maxWidth = width * 8 - 20; // More right margin
      final int leftMargin = 20; // More left margin

      // ========== LOGO ==========
      // Get logo bitmap for embedding
      final logoBitmapData = await getLogoBitmapData(labelWidth, invert: true, yPosition: y);
      String? logoBitmapCommand;
      Uint8List? logoBitmapBytes;

      if (logoBitmapData != null) {
        logoBitmapCommand = logoBitmapData.command;
        logoBitmapBytes = logoBitmapData.bytes;
        y += logoBitmapData.height + 15; // Move y past logo
      }

      // ========== HEADER ==========
      // Calculate dynamic center for Outlet Name (Font 3 approx 15 dots/char)
      int nameWidth = outletName.length * 15;
      int nameX = ((width * 8) - nameWidth) ~/ 2;
      if (nameX < 0) nameX = 0;

      tspl.writeln('TEXT $nameX, $y, "3", 0, 1, 1, "$outletName"');
      y += lineHeight + 8;

      // Address
      for (final line in addressLines) {
        int lineX = ((width * 8) - (line.length * 12)) ~/ 2;
        if (lineX < 0) lineX = 0;
        tspl.writeln('TEXT $lineX, $y, "2", 0, 1, 1, "$line"');
        y += smallLineHeight;
      }
      if (addressLines.isNotEmpty) y += 4;

      // Date & Time
      final now = DateTime.now();
      final dateStr =
          'Tanggal: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 140}, $y, "2", 0, 1, 1, "$dateStr"');
      y += lineHeight;

      // Divider
      tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
      y += 8;

      // ========== INFO SECTION ==========
      // Queue number
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "No. Antrian: $queueNumber"');
      y += smallLineHeight;

      // Order No
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Order No: $orderNo"');
      y += smallLineHeight;

      // Kasir
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Kasir: $cashierName"');
      y += smallLineHeight;

      // Customer
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Customer: $customerName"');
      y += smallLineHeight;

      // Payment Method
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Metode: $paymentMethod"');
      y += smallLineHeight;

      // Channel
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Sumber: $channel"');
      y += smallLineHeight + 4;

      // Divider line
      tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
      y += 8;

      // ========== ITEMS HEADER ==========
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Item"');
      tspl.writeln('TEXT ${maxWidth - 60}, $y, "2", 0, 1, 1, "Total"');
      y += smallLineHeight + 4;

      // Divider
      tspl.writeln('BAR $leftMargin, $y, $maxWidth, 1');
      y += 8;

      // ========== ITEMS ==========
      for (final item in dummyItems) {
        final name = item['name'] as String;
        final qty = item['qty'] as int;
        final price = item['price'] as int;
        final discount = item['discount'] as int;
        final nominalDiscount = (price * (discount / 100)) * qty;
        final lineTotal = (price * qty) - nominalDiscount.toInt();

        // Item name (may wrap)
        final maxNameChars = 12;
        if (name.length > maxNameChars) {
          final parts = <String>[];
          for (int j = 0; j < name.length; j += maxNameChars) {
            parts.add(
              name.substring(j, j + maxNameChars > name.length ? name.length : j + maxNameChars),
            );
          }
          for (final part in parts) {
            tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "$part"');
            y += smallLineHeight;
          }
        } else {
          tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "$name"');
          y += smallLineHeight;
        }

        // Detail line: qty x @price (-discount) = total
        final priceFormatted = (price / 1000).toStringAsFixed(0);
        final totalFormatted = (lineTotal / 1000).toStringAsFixed(0);
        String detailText = '  $qty x @${priceFormatted}K';
        if (discount > 0) {
          detailText += ' (-${nominalDiscount.toInt()})';
        }
        tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "$detailText"');
        tspl.writeln('TEXT ${maxWidth - 50}, $y, "2", 0, 1, 1, "${totalFormatted}K"');
        y += smallLineHeight + 2;
      }

      // Divider before total
      tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
      y += 10;

      // ========== TOTAL ==========
      final totalFormatted = NumberFormat('#,###', 'id_ID').format(total);
      tspl.writeln('TEXT $leftMargin, $y, "3", 0, 1, 1, "TOTAL"');
      tspl.writeln('TEXT ${maxWidth - 100}, $y, "3", 0, 1, 1, "Rp $totalFormatted"');
      y += lineHeight + 4;

      // Cash
      final cashFormatted = NumberFormat('#,###', 'id_ID').format(cashAmount);
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Tunai:"');
      tspl.writeln('TEXT ${maxWidth - 80}, $y, "2", 0, 1, 1, "Rp $cashFormatted"');
      y += smallLineHeight;

      // Change
      final change = cashAmount - total;
      final changeFormatted = NumberFormat('#,###', 'id_ID').format(change);
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Kembali:"');
      tspl.writeln('TEXT ${maxWidth - 80}, $y, "2", 0, 1, 1, "Rp $changeFormatted"');
      y += smallLineHeight + 20;

      // QR Code
      int qrX = ((width * 8 - 200) ~/ 2) + 20;
      if (qrX < 0) qrX = 0;
      tspl.writeln('QRCODE $qrX, $y, L, 5, A, 0, "${printUrl.replaceAll('"', '\\"')}"');
      y += 250;

      // ========== FOOTER ==========
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 60}, $y, "2", 0, 1, 1, "Terima Kasih"');
      y += smallLineHeight;
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 80}, $y, "1", 0, 1, 1, "Selamat Menikmati!"');
      y += smallLineHeight;
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 80}, $y, "1", 0, 1, 1, "=== TEST PRINT ==="');

      // Print command
      tspl.writeln('PRINT 1');
      tspl.writeln('FORMFEED');
      tspl.writeln('EOP');

      // Build final TSPL command with bitmap
      if (logoBitmapCommand != null && logoBitmapBytes != null) {
        // Build: SETUP commands + BITMAP command + bitmap bytes + rest of commands
        // Note: writeln uses \n, so we match with \n
        final setupCommands =
            'SIZE $width mm, $finalHeight mm\nGAP 0 mm, 0 mm\nDIRECTION 1\nCLS\n$logoBitmapCommand';
        final restCommands = tspl.toString().replaceFirst(
          'SIZE $width mm, $finalHeight mm\nGAP 0 mm, 0 mm\nDIRECTION 1\nCLS\n',
          '',
        );

        final setupBytes = Uint8List.fromList(setupCommands.codeUnits);
        final restBytes = Uint8List.fromList(restCommands.codeUnits);

        // Combine: setup + bitmap bytes + rest
        final combined = Uint8List(setupBytes.length + logoBitmapBytes.length + restBytes.length);
        combined.setRange(0, setupBytes.length, setupBytes);
        combined.setRange(
          setupBytes.length,
          setupBytes.length + logoBitmapBytes.length,
          logoBitmapBytes,
        );
        combined.setRange(setupBytes.length + logoBitmapBytes.length, combined.length, restBytes);

        return combined.toList();
      } else {
        return Uint8List.fromList(tspl.toString().codeUnits).toList();
      }
    } catch (e) {
      debugPrint("TSPL print failed: $e");
      return null;
    }
  }

  /// Print receipt with TSPL (for label printers)
  static Future<List<int>?> printReceipt({
    required int labelWidth,
    required List<ProductModel> orderItems,
    required int total,
    required String customerName,
    required String queueNumber,
    required String paymentMethod,
    required String channel,
    int? cashAmount,
    String? printUrl,
    String? orderNo,
  }) async {
    try {
      final StringBuffer tspl = StringBuffer();
      final width = labelWidth;

      debugPrint("Starting TSPL print receipt...");

      // Get store info
      final outletName = await AuthStorage.getNamaOutlet() ?? '';
      final outletAddress = await AuthStorage.getAddress() ?? '';
      final cashierName = await AuthStorage.getName() ?? '-';

      // Get logo height for calculation
      final logoHeight = await getLogoHeight(labelWidth);

      // Prepare Address Lines
      List<String> addressLines = [];
      if (outletAddress.isNotEmpty) {
        final maxChars = ((width * 8) - 40) ~/ 12; // Font 2 approx 12 dots width
        final words = outletAddress.split(' ');
        String currentLine = "";
        for (var word in words) {
          if ((currentLine + word).length > maxChars) {
            if (currentLine.isNotEmpty) addressLines.add(currentLine.trim());
            currentLine = "$word ";
          } else {
            currentLine += "$word ";
          }
        }
        if (currentLine.isNotEmpty) addressLines.add(currentLine.trim());
      }

      // Constants
      final int lineHeight = 35;
      final int smallLineHeight = 30;

      // 1. Hitung estimasi tinggi konten (dalam dots)
      int estimatedDots = 20; // Initial Y

      // Logo section
      if (logoHeight > 0) {
        estimatedDots += logoHeight;
      }

      // Header section
      estimatedDots += lineHeight + 8; // Outlet name
      if (addressLines.isNotEmpty) {
        estimatedDots += (addressLines.length * smallLineHeight) + 4;
      }
      estimatedDots += lineHeight; // Date
      estimatedDots += 8; // Divider

      // Info section
      if (orderNo != null && orderNo.isNotEmpty) estimatedDots += smallLineHeight; // Order No
      estimatedDots += smallLineHeight; // Kasir
      if (customerName.isNotEmpty) estimatedDots += smallLineHeight;
      if (queueNumber.isNotEmpty && queueNumber != '-') estimatedDots += smallLineHeight;
      estimatedDots += smallLineHeight + 4; // Channel
      estimatedDots += 8; // Divider

      // Items section
      for (int i = 0; i < orderItems.length; i++) {
        // Estimate wrapped lines
        String name = orderItems[i].namaProduct;
        int nameLines = (name.length / 12).ceil();
        if (nameLines < 1) nameLines = 1;

        estimatedDots += smallLineHeight * nameLines; // Name lines
        estimatedDots += smallLineHeight + 2; // @Price line
      }
      estimatedDots += 10; // Divider

      // Total section
      estimatedDots += lineHeight + 4; // Total label & value
      estimatedDots += smallLineHeight; // Payment method
      if (cashAmount != null && cashAmount > 0) {
        estimatedDots += smallLineHeight; // Cash
        final change = cashAmount - total;
        if (change > 0) estimatedDots += smallLineHeight; // Change
      }
      estimatedDots += 8; // Padding

      // QR Code
      if (printUrl != null && printUrl.isNotEmpty) {
        estimatedDots += 250; // Estimate QR area height
      }

      // Footer section
      estimatedDots += smallLineHeight; // Terima kasih
      estimatedDots += smallLineHeight; // Selamat menikmati
      estimatedDots += 100; // Extra padding bottom (increased buffer)

      // Convert dots to mm (8 dots = 1 mm) + buffer
      // Add extra 20mm buffer to be safe
      final calculatedHeightMm = (estimatedDots / 8).ceil() + 20;

      // Use dynamic height if in custom/continuous mode, otherwise use fixed label height
      // But since user asked for dynamic height based on content, we prioritize calculated height
      // especially if it's longer than default setting.
      final finalHeight = calculatedHeightMm;

      // TSPL setup
      tspl.writeln('SIZE $width mm, $finalHeight mm');
      tspl.writeln('GAP 0 mm, 0 mm'); // Continuous mode
      tspl.writeln('DIRECTION 1');
      tspl.writeln('CLS');

      // Calculate positions (dots, 8 dots = 1mm approximately)
      int y = 20; // Start lower
      final int maxWidth = width * 8 - 20; // More right margin
      final int leftMargin = 20; // More left margin

      // ========== LOGO ==========
      // Get logo bitmap for embedding
      final logoBitmapData = await getLogoBitmapData(labelWidth, invert: true, yPosition: y);
      String? logoBitmapCommand;
      Uint8List? logoBitmapBytes;

      if (logoBitmapData != null) {
        logoBitmapCommand = logoBitmapData.command;
        logoBitmapBytes = logoBitmapData.bytes;
        y += logoBitmapData.height + 15; // Move y past logo
      }

      // ========== HEADER ==========
      // Outlet name (centered, bold - font 3)
      // Dynamic Center: (PaperWidth - TextWidth) / 2
      int nameWidth = outletName.length * 15;
      int nameX = ((width * 8) - nameWidth) ~/ 2;
      if (nameX < 0) nameX = 0;
      tspl.writeln('TEXT $nameX, $y, "3", 0, 1, 1, "$outletName"');
      y += lineHeight + 8;

      // Address
      for (final line in addressLines) {
        int lineX = ((width * 8) - (line.length * 12)) ~/ 2;
        if (lineX < 0) lineX = 0;
        tspl.writeln('TEXT $lineX, $y, "2", 0, 1, 1, "$line"');
        y += smallLineHeight;
      }
      if (addressLines.isNotEmpty) y += 4;

      // Date & Time
      final now = DateTime.now();
      final dateStr =
          'Tanggal: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 140}, $y, "2", 0, 1, 1, "$dateStr"');
      y += lineHeight;

      // Divider
      tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
      y += 8;

      // ========== INFO SECTION ==========
      if (orderNo != null && orderNo.isNotEmpty) {
        tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Order No: $orderNo"');
        y += smallLineHeight;
      }

      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Kasir: $cashierName"');
      y += smallLineHeight;

      if (customerName.isNotEmpty) {
        tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Customer: $customerName"');
        y += smallLineHeight;
      }
      if (queueNumber.isNotEmpty && queueNumber != '-') {
        tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "No. Antrian: $queueNumber"');
        y += smallLineHeight;
      }

      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Sumber: $channel"');
      y += smallLineHeight + 4; // Extra padding

      // Divider line
      tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
      y += 8;

      // Items loop
      for (int i = 0; i < orderItems.length; i++) {
        final item = orderItems[i];
        String name = item.namaProduct;
        final qty = item.qty;
        final price = item.harga;
        final discount = item.discount;

        // Calculate total per item
        final nominalDiscount = (price * (discount / 100)) * qty;
        final totalItem = (price * qty) - nominalDiscount;

        // Columns positions
        final col1 = leftMargin;
        // final col2 = leftMargin + 250;
        final col2 = leftMargin + (width * 8 * 0.45).toInt();
        // final col3 = leftMargin + 320;
        final col3 = leftMargin + (width * 8 * 0.58).toInt();
        // final col4 = maxWidth - 100;
        final col4 = leftMargin + (width * 8 * 0.75).toInt();

        // Wrap name logic
        final maxChars = ((col2 - col1) ~/ 12) - 1; // Approx chars fitting in col1
        List<String> nameLines = [];

        while (name.length > maxChars) {
          int splitIndex = name.lastIndexOf(' ', maxChars);
          if (splitIndex == -1) splitIndex = maxChars; // valid split not found, hard split

          nameLines.add(name.substring(0, splitIndex).trim());
          name = name.substring(splitIndex).trim();
        }
        nameLines.add(name);

        // Row 1: Name Line 1, Qty, Disc
        tspl.writeln('TEXT $col1, $y, "2", 0, 1, 1, "${nameLines[0]}"');
        tspl.writeln('TEXT $col2, $y, "2", 0, 1, 1, "${item.qty}"');
        tspl.writeln('TEXT $col3, $y, "2", 0, 1, 1, "${formatRupiah(nominalDiscount.toInt())}"');

        y += smallLineHeight;

        // Subsequent lines for Name
        for (int k = 1; k < nameLines.length; k++) {
          tspl.writeln('TEXT $col1, $y, "2", 0, 1, 1, "${nameLines[k]}"');
          y += smallLineHeight;
        }

        // Row 2: @Price (Left) & Total (Right)
        tspl.writeln('TEXT $col1, $y, "1", 0, 1, 1, "@${formatRupiah(item.harga)}"');
        tspl.writeln('TEXT $col4, $y, "2", 0, 1, 1, "${formatRupiah(totalItem.toInt())}"');

        y += smallLineHeight + 2;
      }

      // Divider line
      tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
      y += 10;

      // ========== TOTAL ==========
      tspl.writeln('TEXT $leftMargin, $y, "3", 0, 1, 1, "TOTAL"');
      tspl.writeln('TEXT ${maxWidth - 120}, $y, "3", 0, 1, 1, "${formatRupiah(total)}"');
      y += lineHeight + 4;

      // Cash & Change
      if (cashAmount != null && cashAmount > 0) {
        tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "Tunai"');
        tspl.writeln('TEXT ${maxWidth - 100}, $y, "1", 0, 1, 1, "${formatRupiah(cashAmount)}"');
        y += smallLineHeight;

        final change = cashAmount - total;
        if (change > 0) {
          tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "Kembalian"');
          tspl.writeln('TEXT ${maxWidth - 100}, $y, "1", 0, 1, 1, "${formatRupiah(change)}"');
          y += smallLineHeight;
        }
      }

      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Metode: $paymentMethod"');
      y += smallLineHeight;

      y += 20; // Increased spacing before QR Code

      // QR Code
      if (printUrl != null && printUrl.isNotEmpty) {
        // Calculate center for QR (rough estimate, assuming 200 dots width)
        int qrX = ((width * 8 - 200) ~/ 2) + 20; // Shift right by 20 dots
        if (qrX < 0) qrX = 0;
        tspl.writeln('QRCODE $qrX, $y, L, 5, A, 0, "${printUrl.replaceAll('"', '\\"')}"');
        y += 250;
      }

      // ========== FOOTER ==========
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 60}, $y, "2", 0, 1, 1, "Terima Kasih"');
      y += smallLineHeight;
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 80}, $y, "1", 0, 1, 1, "Selamat Menikmati!"');

      // Print command
      tspl.writeln('PRINT 1');
      tspl.writeln('FORMFEED');
      tspl.writeln('EOP');

      // Build final TSPL command with bitmap
      if (logoBitmapCommand != null && logoBitmapBytes != null) {
        // Build: SETUP commands + BITMAP command + bitmap bytes + rest of commands
        // Note: writeln uses \n, so we match with \n
        final setupCommands =
            'SIZE $width mm, $finalHeight mm\nGAP 0 mm, 0 mm\nDIRECTION 1\nCLS\n$logoBitmapCommand';
        final restCommands = tspl.toString().replaceFirst(
          'SIZE $width mm, $finalHeight mm\nGAP 0 mm, 0 mm\nDIRECTION 1\nCLS\n',
          '',
        );

        final setupBytes = Uint8List.fromList(setupCommands.codeUnits);
        final restBytes = Uint8List.fromList(restCommands.codeUnits);

        // Combine: setup + bitmap bytes + rest
        final combined = Uint8List(setupBytes.length + logoBitmapBytes.length + restBytes.length);
        combined.setRange(0, setupBytes.length, setupBytes);
        combined.setRange(
          setupBytes.length,
          setupBytes.length + logoBitmapBytes.length,
          logoBitmapBytes,
        );
        combined.setRange(setupBytes.length + logoBitmapBytes.length, combined.length, restBytes);

        return combined.toList();
      } else {
        return Uint8List.fromList(tspl.toString().codeUnits).toList();
      }
    } catch (e) {
      debugPrint("TSPL print error: $e");
      return null;
    }
  }

  /// Get logo bitmap data for embedding into TSPL commands
  /// Returns bitmap data with command header for use in receipt printing
  static Future<({String command, Uint8List bytes, int height})?> getLogoBitmapData(
    int labelWidth, {
    bool invert = true,
    int yPosition = 20,
  }) async {
    try {
      // Load and prepare logo
      final ByteData data = await rootBundle.load('assets/icons/receipt-logo.jpeg');
      final Uint8List bytes = data.buffer.asUint8List();
      final src = img.decodeImage(bytes);

      if (src == null) {
        debugPrint('Gagal decode gambar logo');
        return null;
      }

      final width = labelWidth;
      final targetLogoWidth = (width * 8 * 0.8).toInt(); // 80% of paper width

      // Resize with padding for 8-byte alignment
      var resized = img.copyResize(src, width: targetLogoWidth);
      final pad = (8 - (resized.width % 8)) % 8;
      if (pad != 0) {
        final newImg = img.Image(width: resized.width + pad, height: resized.height);
        // Fill white
        for (int y = 0; y < newImg.height; y++) {
          for (int x = 0; x < newImg.width; x++) {
            newImg.setPixelRgba(x, y, 255, 255, 255, 255);
          }
        }
        // Copy pixels
        for (int y = 0; y < resized.height; y++) {
          for (int x = 0; x < resized.width; x++) {
            newImg.setPixel(x, y, resized.getPixel(x, y));
          }
        }
        resized = newImg;
      }

      // Convert to monochrome with Floyd-Steinberg dithering
      final buf = List.generate(resized.height, (_) => List<double>.filled(resized.width, 0.0));

      // Grayscale
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final p = resized.getPixel(x, y);
          buf[y][x] = 0.299 * p.r.toDouble() + 0.587 * p.g.toDouble() + 0.114 * p.b.toDouble();
        }
      }

      // Floyd-Steinberg dithering
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final old = buf[y][x];
          final neu = old < 128.0 ? 0.0 : 255.0;
          final err = old - neu;
          buf[y][x] = neu;

          if (x + 1 < resized.width) buf[y][x + 1] += err * 7.0 / 16.0;
          if (y + 1 < resized.height) {
            if (x > 0) buf[y + 1][x - 1] += err * 3.0 / 16.0;
            buf[y + 1][x] += err * 5.0 / 16.0;
            if (x + 1 < resized.width) buf[y + 1][x + 1] += err * 1.0 / 16.0;
          }
        }
      }

      // Pack into bitmap bytes
      final wBytes = resized.width ~/ 8;
      final bitmap = Uint8List(wBytes * resized.height);
      int i = 0;
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x += 8) {
          int b = 0;
          for (int k = 0; k < 8; k++) {
            final isDark = buf[y][x + k] < 128.0;
            // If invert: light pixels set the bit, else dark pixels set the bit
            final shouldSetBit = invert ? !isDark : isDark;
            if (shouldSetBit) {
              b |= (0x80 >> k);
            }
          }
          bitmap[i++] = b;
        }
      }

      // Center X position
      final logoX = ((width * 8) - resized.width) ~/ 2;

      // Just the BITMAP command (without SIZE, GAP, CLS, PRINT, etc.)
      final command = 'BITMAP $logoX,$yPosition,$wBytes,${resized.height},0,';

      return (command: command, bytes: bitmap, height: resized.height);
    } catch (e) {
      debugPrint("Error preparing logo bitmap: $e");
      return null;
    }
  }

  /// Get estimated logo height for height calculation
  static Future<int> getLogoHeight(int labelWidth) async {
    try {
      final ByteData data = await rootBundle.load('assets/icons/receipt-logo.jpeg');
      final Uint8List bytes = data.buffer.asUint8List();
      final src = img.decodeImage(bytes);

      if (src == null) return 0;

      final width = labelWidth;
      final targetLogoWidth = (width * 8 * 0.8).toInt();
      final paddedWidth = targetLogoWidth + ((8 - (targetLogoWidth % 8)) % 8);
      final aspectRatio = src.height / src.width;
      return (paddedWidth * aspectRatio).toInt() + 20; // Add padding
    } catch (e) {
      debugPrint("Error calculating logo height: $e");
      return 0;
    }
  }
}
