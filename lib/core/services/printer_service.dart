import 'dart:async';

import 'package:edifly_pos/core/services/print_ecspos.dart';
import 'package:edifly_pos/core/services/print_tspl.dart';
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
        final result = await PrintTspl.testPrint(labelWidth: labelWidth.value);
        if (result != null) {
          final success = await _printBytes(result);
          if (success) {
            _showSuccess('Test print berhasil!');
          } else {
            _showError('Test print gagal');
          }
          return success;
        } else {
          _showError('Gagal generate TSPL command');
          return false;
        }
      } else {
        return await PrintEscPos.testPrint(
          paperWidth: paperWidth.value,
          printCallback: (bytes) async {
            final success = await _printBytes(bytes);
            if (success) {
              _showSuccess('Test print berhasil!');
            } else {
              _showError('Test print gagal');
            }
            return success;
          },
        );
      }
    } catch (e) {
      debugPrint("Test print error: $e");
      _showError('Test print error: $e');
      return false;
    } finally {
      isPrinting.value = false;
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
    String? printUrl,
    String? orderNo,
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
        final result = await PrintTspl.printReceipt(
          labelWidth: labelWidth.value,
          orderItems: orderItems,
          total: total,
          customerName: customerName,
          queueNumber: queueNumber,
          paymentMethod: paymentMethod,
          channel: channel,
          cashAmount: cashAmount,
          printUrl: printUrl,
          orderNo: orderNo,
        );

        if (result != null) {
          final success = await _printBytes(result);
          if (success) {
            _showSuccess('Receipt printed');
          } else {
            _showError('Print failed');
          }
          return success;
        } else {
          _showError('Gagal generate TSPL command');
          return false;
        }
      } else {
        return await PrintEscPos.printReceipt(
          paperWidth: paperWidth.value,
          orderItems: orderItems,
          total: total,
          customerName: customerName,
          queueNumber: queueNumber,
          paymentMethod: paymentMethod,
          channel: channel,
          cashAmount: cashAmount,
          printUrl: printUrl,
          orderNo: orderNo,
          printCallback: (bytes) async {
            final success = await _printBytes(bytes);
            if (success) {
              _showSuccess('Receipt printed');
            } else {
              _showError('Print failed');
            }
            return success;
          },
        );
      }
    } catch (e) {
      debugPrint("Print receipt error: $e");
      _showError('Print receipt error: $e');
      return false;
    } finally {
      isPrinting.value = false;
    }
  }
}
