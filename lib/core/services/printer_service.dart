import 'dart:async';

import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:edifly_pos/core/utils/esc_pos_generator.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Printer Type Enum
enum PrinterType {
  escPos, // ESC/POS for thermal receipt printers (QR-368BT, etc)
  tspl, // TSPL for label printers (D520BT-Z, Phomemo, etc)
}

/// Bluetooth Printer Device Info
class PrinterDevice {
  final String name;
  final String address;

  PrinterDevice({required this.name, required this.address});
}

class PrinterService extends GetxController {
  static PrinterService get to => Get.find<PrinterService>();

  // Native channel
  static const _channel = MethodChannel('com.example.edifly_pos/printer');
  static const _scanChannel = EventChannel('com.example.edifly_pos/printer_scan');

  final isScanning = false.obs;
  final isConnected = false.obs;
  final isPrinting = false.obs;

  final devices =
      <PrinterDevice>[].obs; // Deprecated, kept for backward compatibility if needed temporarily
  final pairedDevices = <PrinterDevice>[].obs;
  final availableDevices = <PrinterDevice>[].obs;

  final selectedDevice = Rxn<PrinterDevice>();

  /// Printer Type Config
  final printerType = PrinterType.escPos.obs;
  static const String _printerTypeKey = 'printer_type';

  /// Paper Size Config (32 chars for 58mm, 48 for 80mm)
  final paperWidth = 32.obs;
  static const String _paperSizeKey = 'printer_paper_size';
  static const String _savedDeviceKey = 'saved_printer_address';

  /// Label Size Config for TSPL (width x height in mm)
  final labelWidth = 50.obs;
  final labelHeight = 30.obs;
  final isCustomLabelSize = false.obs; // Track if custom mode is active
  static const String _labelWidthKey = 'label_width';
  static const String _labelHeightKey = 'label_height';

  StreamSubscription? _scanSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadPrinterSettings();
  }

  /// Show error snackbar (bottom, red, short duration)
  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
    );
  }

  /// Show success snackbar (bottom, green, short duration)
  void _showSuccess(String message) {
    Get.snackbar(
      'Sukses',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
    );
  }

  Future<void> _loadPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Paper size
    final size = prefs.getInt(_paperSizeKey);
    paperWidth.value = (size == 80) ? 48 : 32;

    // Printer type
    final type = prefs.getString(_printerTypeKey);
    printerType.value = (type == 'tspl') ? PrinterType.tspl : PrinterType.escPos;

    // Label size
    labelWidth.value = prefs.getInt(_labelWidthKey) ?? 50;
    labelHeight.value = prefs.getInt(_labelHeightKey) ?? 30;

    // Saved device
    final savedAddress = prefs.getString(_savedDeviceKey);
    if (savedAddress != null) {
      // We'll try to reconnect when scanning if needed, or just set as selected
    }
  }

  Future<void> setPaperSize(int mm) async {
    paperWidth.value = (mm == 80) ? 48 : 32;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paperSizeKey, mm);
  }

  Future<void> setPrinterType(PrinterType type) async {
    printerType.value = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerTypeKey, type == PrinterType.tspl ? 'tspl' : 'escpos');
  }

  Future<void> setLabelSize(int width, int height) async {
    labelWidth.value = width;
    labelHeight.value = height;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_labelWidthKey, width);
    await prefs.setInt(_labelHeightKey, height);
  }

  /// Request permissions
  Future<bool> requestPermissions() async {
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    final bluetoothScan = await Permission.bluetoothScan.request();
    // Location permission is required for Bluetooth scanning on Android
    final location = await Permission.locationWhenInUse.request();

    if (!bluetoothConnect.isGranted) {
      debugPrint("Bluetooth Connect permission denied");
    }
    if (!bluetoothScan.isGranted) {
      debugPrint("Bluetooth Scan permission denied");
    }
    if (!location.isGranted) {
      debugPrint("Location permission denied - required for Bluetooth scanning");
    }

    return bluetoothConnect.isGranted && bluetoothScan.isGranted && location.isGranted;
  }

  /// Load only paired devices (without starting discovery scan)
  Future<void> loadPairedDevices() async {
    final granted = await requestPermissions();
    if (!granted) return;

    pairedDevices.clear();

    try {
      final List<dynamic> result = await _channel.invokeMethod('getPairedDevices');
      for (var item in result) {
        final map = Map<String, dynamic>.from(item);
        final device = PrinterDevice(name: map['name'] ?? 'Unknown', address: map['address'] ?? '');
        pairedDevices.add(device);
        devices.add(device);
      }
    } catch (e) {
      debugPrint("Get paired devices error: $e");
    }
  }

  /// Scan for paired devices
  Future<void> scanDevices() async {
    isScanning.value = true;
    pairedDevices.clear();
    availableDevices.clear();
    devices.clear();

    final granted = await requestPermissions();
    if (!granted) {
      _showError('Bluetooth permissions required');
      isScanning.value = false;
      return;
    }

    try {
      // 1. Get Paired Devices first
      try {
        final List<dynamic> result = await _channel.invokeMethod('getPairedDevices');
        for (var item in result) {
          final map = Map<String, dynamic>.from(item);
          final device = PrinterDevice(
            name: map['name'] ?? 'Unknown',
            address: map['address'] ?? '',
          );
          pairedDevices.add(device);
          devices.add(device); // Keep for compatibility
        }
      } catch (e) {
        debugPrint("Get paired devices error: $e");
      }

      // 2. Start Discovery for new devices
      await _channel.invokeMethod('startScan');

      _scanSubscription?.cancel();
      _scanSubscription = _scanChannel.receiveBroadcastStream().listen(
        (event) {
          final map = Map<String, dynamic>.from(event);
          final name = map['name'] as String?;
          final address = map['address'] as String?;

          if (address != null && address.isNotEmpty) {
            // Don't add if already in paired list
            final isPaired = pairedDevices.any((d) => d.address == address);
            if (isPaired) return;

            final exists = availableDevices.any((d) => d.address == address);
            if (!exists) {
              final device = PrinterDevice(name: name ?? 'Unknown', address: address);
              availableDevices.add(device);
              devices.add(device); // Keep for compatibility
            }
          }
        },
        onError: (error) {
          debugPrint("Scan stream error: $error");
        },
      );

      // Auto stop after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        stopScanning();
      });
    } on PlatformException catch (e) {
      debugPrint("Scan error: ${e.message}");
      _showError('Scan failed: ${e.message}');
      isScanning.value = false;
    }
  }

  void stopScanning() {
    _channel.invokeMethod('stopScan');
    _scanSubscription?.cancel();
    isScanning.value = false;
  }

  /// Connect to device
  Future<bool> connectToDevice(PrinterDevice device) async {
    isScanning.value = true;

    try {
      debugPrint("Connecting to ${device.name} (${device.address})...");

      final bool result = await _channel.invokeMethod('connect', {'address': device.address});

      if (result) {
        selectedDevice.value = device;
        isConnected.value = true;

        // Save for auto-reconnect
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_savedDeviceKey, device.address);

        // Move device from availableDevices to pairedDevices if it was a new scan result
        if (availableDevices.any((d) => d.address == device.address)) {
          availableDevices.removeWhere((d) => d.address == device.address);
        }

        // Refresh paired devices list from system (device is now paired)
        await loadPairedDevices();

        _showSuccess('Terhubung ke ${device.name}');
        return true;
      } else {
        _showError('Gagal terhubung');
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint("Connection error: ${e.message}");
      _showError('Connection error: ${e.message}');
      return false;
    } finally {
      isScanning.value = false;
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } catch (e) {
      debugPrint("Disconnect error: $e");
    }
    isConnected.value = false;
    selectedDevice.value = null;
  }

  /// Check connection status
  Future<bool> checkConnection() async {
    try {
      final bool connected = await _channel.invokeMethod('isConnected');
      isConnected.value = connected;
      return connected;
    } catch (e) {
      return false;
    }
  }

  /// Unpair a device
  Future<void> unpairDevice(PrinterDevice device) async {
    try {
      if (isConnected.value && selectedDevice.value?.address == device.address) {
        await disconnect();
      }

      final bool success = await _channel.invokeMethod('unpairDevice', {'address': device.address});

      if (success) {
        // Remove from local lists immediately for instant UI feedback
        pairedDevices.removeWhere((d) => d.address == device.address);
        devices.removeWhere((d) => d.address == device.address);

        // Note: removeBond() is async on Android, the unpair happens in background
        // We already removed from local list, so UI is updated immediately
        // No need to call loadPairedDevices() as it might re-add if system hasn't finished

        _showSuccess('Perangkat berhasil dilupakan');
      } else {
        _showError('Gagal melupakan perangkat');
      }
    } on PlatformException catch (e) {
      debugPrint("Unpair error: ${e.message}");
      _showError('Gagal melupakan perangkat: ${e.message}');
    }
  }

  /// Print raw bytes via native
  Future<bool> _printBytes(List<int> bytes) async {
    try {
      final Uint8List data = Uint8List.fromList(bytes);
      final bool result = await _channel.invokeMethod('printBytes', {'bytes': data});
      return result;
    } on PlatformException catch (e) {
      debugPrint("Print error: ${e.message}");
      return false;
    }
  }

  /// Test print - uses selected printer type
  Future<bool> testPrint() async {
    final connected = await checkConnection();
    if (!connected) {
      _showError('Printer tidak terhubung');
      return false;
    }

    isPrinting.value = true;

    try {
      if (printerType.value == PrinterType.tspl) {
        return await _testPrintTSPL();
      } else {
        return await _testPrintESCPOS();
      }
    } catch (e) {
      debugPrint("Test print error: $e");
      _showError('Test print error: $e');
      return false;
    } finally {
      isPrinting.value = false;
    }
  }

  /// Test print with ESC/POS
  Future<bool> _testPrintESCPOS() async {
    try {
      debugPrint("Testing ESC/POS print...");

      final bool result = await _channel.invokeMethod('printSimple', {
        'text': 'TEST PRINT - ESC/POS\nHello World!\n\nPrinter berfungsi!',
      });

      debugPrint("ESC/POS print result: $result");

      if (result) {
        _showSuccess('ESC/POS print berhasil!');
      } else {
        _showError('ESC/POS print gagal');
      }
      return result;
    } catch (e) {
      debugPrint("ESC/POS print failed: $e");
      _showError('ESC/POS error: $e');
      return false;
    }
  }

  /// Test print with TSPL - full dummy receipt
  Future<bool> _testPrintTSPL() async {
    try {
      debugPrint("Testing TSPL print with dummy receipt...");

      final StringBuffer tspl = StringBuffer();
      final width = labelWidth.value;
      final height = labelHeight.value;

      // Constants
      final int lineHeight = 35;
      final int smallLineHeight = 30;

      // Calculate dynamic height for test content
      int estimatedDots = 20;
      estimatedDots += lineHeight + 8; // Header
      estimatedDots += lineHeight; // Date
      estimatedDots += 8; // Divider
      estimatedDots += smallLineHeight * 4 + 4; // Info (4 lines)
      estimatedDots += 8; // Divider
      estimatedDots += (smallLineHeight + smallLineHeight + 2) * 3; // 3 Items
      estimatedDots += 10; // Divider
      estimatedDots += lineHeight + 4; // Total
      estimatedDots += smallLineHeight * 3 + 8; // Payment info
      estimatedDots += smallLineHeight * 2; // Footer text
      estimatedDots += smallLineHeight; // TEST PRINT
      estimatedDots += 40; // Padding bottom

      final calculatedHeightMm = (estimatedDots / 8).ceil() + 10;
      final finalHeight = calculatedHeightMm;

      // TSPL setup
      tspl.writeln('SIZE $width mm, $finalHeight mm');
      tspl.writeln('GAP 0 mm, 0 mm'); // Continuous mode
      tspl.writeln('DIRECTION 1');
      tspl.writeln('CLS');

      // Dummy data
      final outletName = await AuthStorage.getNamaOutlet() ?? '';
      final cashierName = await AuthStorage.getName() ?? '';
      final customerName = 'Budi Santoso';
      final queueNumber = '001';
      final channel = 'Dine In';
      final paymentMethod = 'Cash';

      // Calculate positions
      int y = 20; // Start lower
      final int maxWidth = width * 8 - 20; // More right margin
      final int leftMargin = 20; // More left margin

      // ========== HEADER ==========
      // Calculate dynamic center for Outlet Name (Font 3 approx 15 dots/char)
      int nameWidth = outletName.length * 15;
      int nameX = ((width * 8) - nameWidth) ~/ 2;
      if (nameX < 0) nameX = 0;

      tspl.writeln('TEXT $nameX, $y, "3", 0, 1, 1, "$outletName"');
      y += lineHeight + 8;

      // Date & Time
      final now = DateTime.now();
      final dateStr =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 90}, $y, "2", 0, 1, 1, "$dateStr"');
      y += lineHeight;

      // Divider
      tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
      y += 8;

      // ========== INFO ==========
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Kasir: $cashierName"');
      y += smallLineHeight;
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Customer: $customerName"');
      y += smallLineHeight;
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "No. Antrian: $queueNumber"');
      y += smallLineHeight;
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Channel: $channel"');
      y += smallLineHeight + 4;

      // Divider
      tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
      y += 8;

      // ========== ITEMS ==========
      // Item 1: Kopi Susu
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Kopi Susu"');
      y += smallLineHeight;
      tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "2 x Rp 15.000"');
      tspl.writeln('TEXT ${maxWidth - 100}, $y, "1", 0, 1, 1, "Rp 30.000"'); // Shifted left
      y += smallLineHeight + 2;

      // Item 2: Roti Bakar
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Roti Bakar Coklat"');
      y += smallLineHeight;
      tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "1 x Rp 20.000"');
      tspl.writeln('TEXT ${maxWidth - 100}, $y, "1", 0, 1, 1, "Rp 20.000"'); // Shifted left
      y += smallLineHeight + 2;

      // Item 3: Es Teh
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Es Teh Manis"');
      y += smallLineHeight;
      tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "1 x Rp 15.000"');
      tspl.writeln('TEXT ${maxWidth - 100}, $y, "1", 0, 1, 1, "Rp 15.000"'); // Shifted left
      y += smallLineHeight + 4;

      // Divider
      tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
      y += 10;

      // ========== TOTAL ==========
      tspl.writeln('TEXT $leftMargin, $y, "3", 0, 1, 1, "TOTAL"');
      tspl.writeln('TEXT ${maxWidth - 120}, $y, "3", 0, 1, 1, "Rp 65.000"'); // Shifted left
      y += lineHeight + 4;

      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Pembayaran: $paymentMethod"');
      y += smallLineHeight;

      tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "Tunai"');
      tspl.writeln('TEXT ${maxWidth - 100}, $y, "1", 0, 1, 1, "Rp 100.000"'); // Shifted left
      y += smallLineHeight;

      tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "Kembalian"');
      tspl.writeln('TEXT ${maxWidth - 100}, $y, "1", 0, 1, 1, "Rp 35.000"'); // Shifted left
      y += smallLineHeight + 8;

      // ========== FOOTER ==========
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 60}, $y, "2", 0, 1, 1, "Terima Kasih"');
      y += smallLineHeight;
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 80}, $y, "1", 0, 1, 1, "Selamat Menikmati!"');
      y += smallLineHeight;
      tspl.writeln('TEXT ${maxWidth ~/ 2 - 80}, $y, "1", 0, 1, 1, "=== TEST PRINT ==="');

      // Print
      tspl.writeln('PRINT 1');
      tspl.writeln('FORMFEED'); // Stop paper
      tspl.writeln('EOP');

      final bool result = await _channel.invokeMethod('printTSPL', {
        'text': tspl.toString(),
        'width': width,
        'height': height,
        'raw': true,
      });

      debugPrint("TSPL print result: $result");

      if (result) {
        _showSuccess('Test print berhasil!');
      } else {
        _showError('Test print gagal');
      }
      return result;
    } catch (e) {
      debugPrint("TSPL print failed: $e");
      _showError('TSPL error: $e');
      return false;
    }
  }

  /// Print a receipt
  Future<bool> printReceipt({
    required List<ProductModel> orderItems,
    required int total,
    required String customerName,
    required String queueNumber,
    required String paymentMethod,
    required String channel,
    int? cashAmount,
  }) async {
    final connected = await checkConnection();
    if (!connected) {
      if (selectedDevice.value != null) {
        final reconnected = await connectToDevice(selectedDevice.value!);
        if (!reconnected) return false;
      } else {
        _showError('Printer tidak terhubung');
        return false;
      }
    }

    isPrinting.value = true;

    try {
      if (printerType.value == PrinterType.tspl) {
        return await _printReceiptTSPL(
          orderItems: orderItems,
          total: total,
          customerName: customerName,
          queueNumber: queueNumber,
          paymentMethod: paymentMethod,
          channel: channel,
          cashAmount: cashAmount,
        );
      } else {
        return await _printReceiptESCPOS(
          orderItems: orderItems,
          total: total,
          customerName: customerName,
          queueNumber: queueNumber,
          paymentMethod: paymentMethod,
          channel: channel,
          cashAmount: cashAmount,
        );
      }
    } catch (e) {
      debugPrint("Print error: $e");
      _showError('Print error: $e');
      return false;
    } finally {
      isPrinting.value = false;
    }
  }

  /// Print receipt with ESC/POS
  Future<bool> _printReceiptESCPOS({
    required List<ProductModel> orderItems,
    required int total,
    required String customerName,
    required String queueNumber,
    required String paymentMethod,
    required String channel,
    int? cashAmount,
  }) async {
    final gen = EscPosGenerator(paperWidth: paperWidth.value);
    gen.init();

    // Header
    final outletName = await AuthStorage.getNamaOutlet() ?? '';
    gen.text(
      outletName,
      bold: true,
      doubleHeight: true,
      doubleWidth: true,
      align: TextAlign.center,
    );
    gen.feed(1);

    // Date & Time
    final now = DateTime.now();
    gen.text(
      '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      align: TextAlign.center,
    );
    gen.feed(1);

    // Customer info
    if (customerName.isNotEmpty) {
      gen.text('Customer: $customerName');
    }
    if (queueNumber.isNotEmpty) {
      gen.text('No. Antrian: $queueNumber');
    }
    gen.text('Channel: $channel');
    gen.feed(1);

    gen.hr();

    // Items
    for (final item in orderItems) {
      gen.text(item.namaProduct, bold: true);
      gen.row('${item.qty} x ${formatRupiah(item.harga)}', formatRupiah(item.harga * item.qty));
    }

    gen.hr();

    // Total
    gen.text('TOTAL', bold: true, doubleHeight: true);
    gen.text(formatRupiah(total), bold: true, doubleHeight: true, align: TextAlign.right);
    gen.feed(1);

    // Payment info
    gen.text('Pembayaran: $paymentMethod');

    if (cashAmount != null && cashAmount > 0) {
      gen.row('Tunai', formatRupiah(cashAmount));
      final change = cashAmount - total;
      if (change > 0) {
        gen.row('Kembalian', formatRupiah(change));
      }
    }

    gen.feed(2);

    // Footer
    gen.text('Terima Kasih', bold: true, align: TextAlign.center);
    gen.text('Selamat Menikmati!', align: TextAlign.center);
    gen.feed(4);

    debugPrint("Receipt ESC/POS: ${gen.bytes.length} bytes");

    final result = await _printBytes(gen.bytes);

    if (result) {
      _showSuccess('Receipt printed');
      return true;
    } else {
      _showError('Print failed');
      return false;
    }
  }

  /// Print receipt with TSPL (for label printers)
  Future<bool> _printReceiptTSPL({
    required List<ProductModel> orderItems,
    required int total,
    required String customerName,
    required String queueNumber,
    required String paymentMethod,
    required String channel,
    int? cashAmount,
  }) async {
    // Build TSPL command string
    final StringBuffer tspl = StringBuffer();

    final width = labelWidth.value;
    final height = labelHeight.value;

    // Get outlet name and cashier
    final outletName = await AuthStorage.getNamaOutlet() ?? '';
    final cashierName = await AuthStorage.getName() ?? '-';

    // Constants
    final int lineHeight = 35;
    final int smallLineHeight = 30;

    // 1. Hitung estimasi tinggi konten (dalam dots)
    int estimatedDots = 20; // Initial Y

    // Header section
    estimatedDots += lineHeight + 8; // Outlet name
    estimatedDots += lineHeight; // Date
    estimatedDots += 8; // Divider

    // Info section
    estimatedDots += smallLineHeight; // Kasir
    if (customerName.isNotEmpty) estimatedDots += smallLineHeight;
    if (queueNumber.isNotEmpty && queueNumber != '-') estimatedDots += smallLineHeight;
    estimatedDots += smallLineHeight + 4; // Channel
    estimatedDots += 8; // Divider

    // Items section
    for (int i = 0; i < orderItems.length; i++) {
      estimatedDots += smallLineHeight; // Name
      estimatedDots += smallLineHeight + 2; // Qty & Price
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

    // Footer section
    estimatedDots += smallLineHeight; // Terima kasih
    estimatedDots += smallLineHeight; // Selamat menikmati
    estimatedDots += 40; // Extra padding bottom

    // Convert dots to mm (8 dots = 1 mm) + buffer
    final calculatedHeightMm = (estimatedDots / 8).ceil() + 10;

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

    // ========== HEADER ==========
    // Outlet name (centered, bold - font 3)
    // Dynamic Center: (PaperWidth - TextWidth) / 2
    int nameWidth = outletName.length * 15;
    int nameX = ((width * 8) - nameWidth) ~/ 2;
    if (nameX < 0) nameX = 0;
    tspl.writeln('TEXT $nameX, $y, "3", 0, 1, 1, "$outletName"');
    y += lineHeight + 8;

    // Date & Time (centered, small - font 2)
    final now = DateTime.now();
    final dateStr =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    tspl.writeln('TEXT ${maxWidth ~/ 2 - 90}, $y, "2", 0, 1, 1, "$dateStr"');
    y += lineHeight;

    // Divider line
    tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
    y += 8;

    // ========== INFO SECTION ==========
    // Kasir
    tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Kasir: $cashierName"');
    y += smallLineHeight;

    // Customer
    if (customerName.isNotEmpty) {
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Customer: $customerName"');
      y += smallLineHeight;
    }

    // Queue number
    if (queueNumber.isNotEmpty && queueNumber != '-') {
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "No. Antrian: $queueNumber"');
      y += smallLineHeight;
    }

    // Channel
    tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Channel: $channel"');
    y += smallLineHeight + 4;

    // Divider line
    tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
    y += 8;

    // ========== ITEMS ==========
    for (int i = 0; i < orderItems.length && y < height * 8 - 100; i++) {
      final item = orderItems[i];
      final subtotal = item.harga * item.qty;

      // Product name (bold)
      tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "${item.namaProduct}"');
      y += smallLineHeight;

      // Quantity x Price = Subtotal
      final qtyPrice = '${item.qty} x ${formatRupiah(item.harga)}';
      final subtotalStr = formatRupiah(subtotal);
      tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "$qtyPrice"');
      tspl.writeln('TEXT ${maxWidth - 100}, $y, "1", 0, 1, 1, "$subtotalStr"'); // Shifted left
      y += smallLineHeight + 2;
    }

    // Divider line
    tspl.writeln('BAR $leftMargin, $y, $maxWidth, 2');
    y += 10;

    // ========== TOTAL ==========
    tspl.writeln('TEXT $leftMargin, $y, "3", 0, 1, 1, "TOTAL"');
    tspl.writeln(
      'TEXT ${maxWidth - 120}, $y, "3", 0, 1, 1, "${formatRupiah(total)}"',
    ); // Shifted left
    y += lineHeight + 4;

    // Payment method
    tspl.writeln('TEXT $leftMargin, $y, "2", 0, 1, 1, "Pembayaran: $paymentMethod"');
    y += smallLineHeight;

    // Cash & Change
    if (cashAmount != null && cashAmount > 0) {
      tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "Tunai"');
      tspl.writeln(
        'TEXT ${maxWidth - 100}, $y, "1", 0, 1, 1, "${formatRupiah(cashAmount)}"',
      ); // Shifted left
      y += smallLineHeight;

      final change = cashAmount - total;
      if (change > 0) {
        tspl.writeln('TEXT $leftMargin, $y, "1", 0, 1, 1, "Kembalian"');
        tspl.writeln(
          'TEXT ${maxWidth - 100}, $y, "1", 0, 1, 1, "${formatRupiah(change)}"',
        ); // Shifted left
        y += smallLineHeight;
      }
    }

    y += 8;

    // ========== FOOTER ==========
    tspl.writeln('TEXT ${maxWidth ~/ 2 - 60}, $y, "2", 0, 1, 1, "Terima Kasih"');
    y += smallLineHeight;
    tspl.writeln('TEXT ${maxWidth ~/ 2 - 80}, $y, "1", 0, 1, 1, "Selamat Menikmati!"');

    // Print command
    tspl.writeln('PRINT 1');
    tspl.writeln('FORMFEED'); // Stop paper
    tspl.writeln('EOP');

    final bool result = await _channel.invokeMethod('printTSPL', {
      'text': tspl.toString(),
      'width': width,
      'height': height,
      'raw': true,
    });

    debugPrint("TSPL print result: $result");

    if (result) {
      Get.snackbar(
        'Success',
        'Receipt printed',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } else {
      _showError('Print failed');
      return false;
    }
  }
}
