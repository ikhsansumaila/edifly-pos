import 'package:edifly_pos/core/services/printer_service.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrinterSettingsPage extends StatelessWidget {
  const PrinterSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final printerService = Get.find<PrinterService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        backgroundColor: const Color(0xFF5B3A1E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Obx(() {
              final isConnected = printerService.isConnected.value;
              final device = printerService.selectedDevice.value;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isConnected ? Colors.green : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.print : Icons.print_disabled,
                      color: isConnected ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected ? 'Terhubung' : 'Tidak Terhubung',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isConnected ? Colors.green : Colors.grey,
                            ),
                          ),
                          if (device != null)
                            Text(device.name, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    if (isConnected)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => printerService.testPrint(),
                            child: const Text('Test', style: TextStyle(color: Color(0xFF5B3A1E))),
                          ),
                          TextButton(
                            onPressed: () => printerService.disconnect(),
                            child: const Text('Lupakan', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            // Paper Size Settings
            const Text(
              'Ukuran Kertas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Obx(() {
                final currentSize = printerService.paperSize.value;
                return Column(
                  children: [
                    RadioListTile<PaperSize>(
                      title: const Text('58mm'),
                      value: PaperSize.mm58,
                      groupValue: currentSize,
                      onChanged: (val) {
                        if (val != null) printerService.setPaperSize(val);
                      },
                      activeColor: const Color(0xFF5B3A1E),
                      contentPadding: EdgeInsets.zero,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    RadioListTile<PaperSize>(
                      title: const Text('80mm'),
                      value: PaperSize.mm80,
                      groupValue: currentSize,
                      onChanged: (val) {
                        if (val != null) printerService.setPaperSize(val);
                      },
                      activeColor: const Color(0xFF5B3A1E),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 24),

            // Scan Button
            SizedBox(
              width: double.infinity,
              child: Obx(() {
                final isScanning = printerService.isScanning.value;
                return ElevatedButton.icon(
                  onPressed: isScanning ? null : () => printerService.scanDevices(),
                  icon:
                      isScanning
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                          : const Icon(Icons.bluetooth_searching),
                  label: Text(isScanning ? 'Mencari...' : 'Cari Koneksi Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3A1E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Device List
            const Text(
              'Perangkat Ditemukan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Obx(() {
                final devices = printerService.devices;
                if (devices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('Tidak ada perangkat ditemukan', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          'Tekan tombol "Cari Printer" untuk memuat perangkat yang sudah diparing',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Card(
                      color: Colors.grey.shade100,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.print, color: Color(0xFF5B3A1E)),
                        title: Text(device.name),
                        subtitle: Text(device.macAdress),
                        trailing: Obx(() {
                          final selectedDevice = printerService.selectedDevice.value;
                          final isSelected = selectedDevice?.macAdress == device.macAdress;
                          return isSelected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : TextButton(
                                onPressed: () => printerService.connectToDevice(device),
                                child: const Text('Hubungkan'),
                              );
                        }),
                        onTap: () => printerService.connectToDevice(device),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
