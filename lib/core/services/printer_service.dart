import 'dart:async';

import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService extends GetxController {
  static PrinterService get to => Get.find<PrinterService>();

  final isScanning = false.obs;
  final isConnected = false.obs;
  final isPrinting = false.obs;
  final devices = <BluetoothInfo>[].obs;
  final selectedDevice = Rxn<BluetoothInfo>();

  /// Paper Size Config
  final paperSize = PaperSize.mm58.obs;
  static const String _paperSizeKey = 'printer_paper_size';

  CapabilityProfile? _profile;

  @override
  void onInit() {
    super.onInit();
    _loadPrinterSettings();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      _profile = await CapabilityProfile.load();
    } catch (e) {
      print("Error loading printer profile: $e");
    }
  }

  Future<void> _loadPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final size = prefs.getInt(_paperSizeKey);
    if (size == 80) {
      paperSize.value = PaperSize.mm80;
    } else {
      paperSize.value = PaperSize.mm58;
    }
  }

  Future<void> setPaperSize(PaperSize size) async {
    paperSize.value = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paperSizeKey, size == PaperSize.mm80 ? 80 : 58);
  }

  /// Request Bluetooth permissions
  Future<bool> requestPermissions() async {
    // print_bluetooth_thermal handles permissions largely, but we can double check
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    final bluetoothScan = await Permission.bluetoothScan.request();
    // Location is needed for some Android versions for scanning
    final location = await Permission.locationWhenInUse.request();

    return bluetoothConnect.isGranted && bluetoothScan.isGranted && location.isGranted;
  }

  /// Scan for paired Bluetooth devices
  Future<void> scanDevices() async {
    isScanning.value = true;
    devices.clear();

    // === SIMULATION MODE FOR EMULATOR/DEBUG ===
    // if (kDebugMode) {
    //   await Future.delayed(const Duration(seconds: 1)); // Fake scan delay
    //   devices.add(BluetoothInfo(name: "Simulated Printer", macAdress: "00:00:00:00:00:00"));
    //   isScanning.value = false;
    //   return;
    // }
    // ==========================================

    // Basic permission check
    final bool permissionStatus = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!permissionStatus) {
      // Request if not granted
      final granted = await requestPermissions();
      if (!granted) {
        Get.snackbar(
          'Permission Denied',
          'Bluetooth permissions are required to scan for printers',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isScanning.value = false;
        return;
      }
    }

    try {
      final List<BluetoothInfo> result = await PrintBluetoothThermal.pairedBluetooths;
      devices.assignAll(result);

      if (devices.isEmpty) {
        Get.snackbar(
          'No Devices',
          'No paired devices found. Please pair your printer in Android Settings first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to scan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isScanning.value = false;
    }
  }

  /// Connect to a selected Bluetooth device
  Future<bool> connectToDevice(BluetoothInfo device) async {
    isScanning.value = true; // Show loading state

    // === SIMULATION MODE FOR EMULATOR/DEBUG ===
    if (kDebugMode && device.macAdress == "00:00:00:00:00:00") {
      await Future.delayed(const Duration(seconds: 1)); // Fake connect delay
      selectedDevice.value = device;
      isConnected.value = true;
      isScanning.value = false;
      Get.snackbar(
        'Connected (Simulated)',
        'Connected to ${device.name}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    }
    // ==========================================

    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);
      if (result) {
        selectedDevice.value = device;
        isConnected.value = true;
        Get.snackbar(
          'Connected',
          'Connected to ${device.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Connection Failed',
          'Could not connect to ${device.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Connection error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isScanning.value = false;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    // === SIMULATION MODE ===
    if (kDebugMode && selectedDevice.value?.macAdress == "00:00:00:00:00:00") {
      isConnected.value = false;
      selectedDevice.value = null;
      return;
    }
    // =======================

    await PrintBluetoothThermal.disconnect;
    isConnected.value = false;
    selectedDevice.value = null;
  }

  /// Test print using ESC/POS commands - similar to real receipt
  Future<bool> testPrint() async {
    final connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) {
      Get.snackbar('Error', 'Printer tidak terhubung');
      return false;
    }

    try {
      // Ensure profile is loaded
      if (_profile == null) {
        await _loadProfile();
      }

      print('paperSize.value ${paperSize.value}');

      final generator = Generator(PaperSize.mm58, _profile!);
      List<int> bytes = [];

      // Reset printer
      bytes += generator.reset();

      // Header
      bytes += generator.text(
        'TES PRINT',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      bytes += generator.feed(1);

      // Date & Time
      final now = DateTime.now();
      bytes += generator.text(
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      // Customer info
      bytes += generator.text('Customer: Pelanggan Test');
      bytes += generator.text('No. Antrian: 001');
      bytes += generator.text('Channel: Dine In');
      bytes += generator.feed(1);

      // Divider
      bytes += generator.hr();

      // Item 1
      bytes += generator.text('Kopi Susu', styles: const PosStyles(bold: true));
      bytes += generator.row([
        PosColumn(text: '2 x Rp 15.000', width: 8),
        PosColumn(text: 'Rp 30.000', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);

      // Item 2
      bytes += generator.text('Roti Bakar', styles: const PosStyles(bold: true));
      bytes += generator.row([
        PosColumn(text: '1 x Rp 20.000', width: 8),
        PosColumn(text: 'Rp 20.000', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);

      // Divider
      bytes += generator.hr();

      // Total
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
        ),
        PosColumn(
          text: 'Rp 50.000',
          width: 6,
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
            align: PosAlign.right,
          ),
        ),
      ]);

      bytes += generator.feed(1);
      bytes += generator.text('Pembayaran: Cash');
      bytes += generator.feed(2);

      // Footer
      bytes += generator.text(
        'Terima Kasih',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        '=== TES BERHASIL ===',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.feed(3);

      // Debug
      print("Test print bytes length: ${bytes.length}");

      // Print
      // final result = await PrintBluetoothThermal.writeBytes(bytes);
      // final result = await PrintBluetoothThermal.writeString(
      //   printText: PrintTextSize(
      //     size: 2,
      //     text: "=== TES PRINT ===\n\nJika Anda melihat ini,\nprinter berfungsi!\n\n\n",
      //   ),
      // );// WAJIB
      await Future.delayed(const Duration(milliseconds: 1000));

      List<int> bytess = [
        27, 64, // INIT
        66, 69, 69, 80, 82, // "BEEPR"
        84, // "T"
        10, // newline
        10,
      ];

      final result = await PrintBluetoothThermal.writeBytes(bytess);
      if (result) {
        Get.snackbar('Sukses', 'Test print berhasil');
      } else {
        Get.snackbar('Error', 'Test print gagal');
      }
      return result;
    } catch (e) {
      print("Test print error: $e");
      Get.snackbar('Error', 'Test print error: $e');
      return false;
    }
  }

  /// Print a receipt
  Future<bool> printReceipt({
    required List<ProductModel> cartItems,
    required int total,
    required String customerName,
    required String queueNumber,
    required String paymentMethod,
    required String channel,
    int? cashAmount,
  }) async {
    print("kDebugMode $kDebugMode");
    // === SIMULATION MODE CHECK ===
    // if (kDebugMode) {
    //   // Simulate printing
    //   isPrinting.value = true;
    //   await Future.delayed(const Duration(seconds: 2)); // Fake print delay
    //   isPrinting.value = false;
    //   Get.snackbar(
    //     'Success (Simulated)',
    //     'Receipt printed successfully (Mock)',
    //     snackPosition: SnackPosition.BOTTOM,
    //     backgroundColor: Colors.green,
    //     colorText: Colors.white,
    //   );
    //   return true;
    // }
    // =============================

    final connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) {
      // Try to reconnect if we have a selected device
      if (selectedDevice.value != null) {
        final reconnected = await connectToDevice(selectedDevice.value!);
        if (!reconnected) return false;
      } else {
        Get.snackbar(
          'Printer Not Connected',
          'Please connect to a printer first',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
    }

    isPrinting.value = true;

    print("start Print");
    try {
      // Ensure profile is loaded
      if (_profile == null) {
        await _loadProfile();
      }

      final generator = Generator(paperSize.value, _profile!);
      List<int> bytes = [];

      // Reset printer
      bytes += generator.reset();

      final outletName = await AuthStorage.getNamaOutlet() ?? '';
      // Header
      bytes += generator.text(
        outletName,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      bytes += generator.feed(1);

      // Date & Time
      final now = DateTime.now();
      bytes += generator.text(
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      // Customer info
      if (customerName.isNotEmpty) {
        bytes += generator.text('Customer: $customerName');
      }
      if (queueNumber.isNotEmpty) {
        bytes += generator.text('No. Antrian: $queueNumber');
      }
      bytes += generator.text('Channel: $channel');
      bytes += generator.feed(1);

      // Divider
      bytes += generator.hr();

      // Items
      for (final item in cartItems) {
        bytes += generator.text(item.namaProduct, styles: const PosStyles(bold: true));
        bytes += generator.row([
          PosColumn(text: '${item.qty} x ${formatRupiah(item.harga)}', width: 8),
          PosColumn(
            text: formatRupiah(item.harga * item.qty),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      // Divider
      bytes += generator.hr();

      // Total
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
        ),
        PosColumn(
          text: formatRupiah(total),
          width: 6,
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
            align: PosAlign.right,
          ),
        ),
      ]);

      bytes += generator.feed(1);

      // Payment info
      bytes += generator.text('Pembayaran: $paymentMethod');

      if (cashAmount != null && cashAmount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Tunai', width: 6),
          PosColumn(
            text: formatRupiah(cashAmount),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        final change = cashAmount - total;
        if (change > 0) {
          bytes += generator.row([
            PosColumn(text: 'Kembalian', width: 6),
            PosColumn(
              text: formatRupiah(change),
              width: 6,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]);
        }
      }

      bytes += generator.feed(2);

      // Footer
      bytes += generator.text(
        'Terima Kasih',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'Selamat Menikmati!',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.feed(3);

      // Debug: Log bytes length
      print("Bytes length: ${bytes.length}");

      // Print - pass as List<int> (not Uint8List!)
      final result = await PrintBluetoothThermal.writeBytes(bytes);

      if (result) {
        print("success print");
        Get.snackbar(
          'Success',
          'Receipt printed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        print("error print snackbar");
        Get.snackbar(
          'Print Error',
          'Failed to print receipt',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print("error print $e");
      Get.snackbar(
        'Print Error',
        'Failed to print: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isPrinting.value = false;
    }
  }
}
