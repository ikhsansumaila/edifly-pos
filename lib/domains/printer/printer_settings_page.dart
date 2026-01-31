import 'package:edifly_pos/core/services/printer_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrinterSettingsPage extends StatelessWidget {
  const PrinterSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final printerService = Get.find<PrinterService>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan Printer'),
          backgroundColor: const Color(0xFF5B3A1E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.bluetooth), text: "Koneksi"),
              Tab(icon: Icon(Icons.settings), text: "Pengaturan"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: KONEKSI & PERANGKAT
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConnectionStatus(printerService),
                  const SizedBox(height: 24),
                  _buildScanButton(printerService),
                  const SizedBox(height: 24),
                  _buildDeviceList(printerService),
                ],
              ),
            ),

            // TAB 2: TIPE PRINTER & UKURAN
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrinterTypeSelection(printerService),
                  const SizedBox(height: 24),
                  // Conditional Settings based on printer type
                  Obx(() {
                    if (printerService.printerType.value == PrinterType.escPos) {
                      return _buildPaperSizeSettings(printerService);
                    } else {
                      return _buildLabelSizeSettings(printerService);
                    }
                  }),
                  const SizedBox(height: 8),
                  Obx(
                    () => Text(
                      'Mode Aktif: ${printerService.printerType.value == PrinterType.tspl ? "TSPL (Label)" : "ESC/POS (Receipt)"}',
                      style: TextStyle(
                        color:
                            printerService.printerType.value == PrinterType.tspl
                                ? Colors.blue.shade600
                                : Colors.green.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildConnectionStatus(PrinterService printerService) {
    return Obx(() {
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
                    child: const Text('Test Print', style: TextStyle(color: Color(0xFF5B3A1E))),
                  ),
                  TextButton(
                    onPressed: () => printerService.disconnect(),
                    child: const Text('Putus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _buildScanButton(PrinterService printerService) {
    return SizedBox(
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
          label: Text(isScanning ? 'Mencari...' : 'Cari Printer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B3A1E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }),
    );
  }

  Widget _buildDeviceList(PrinterService printerService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perangkat Dipasangkan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final deviceList = printerService.devices;
          if (deviceList.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Tidak ada perangkat ditemukan', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      'Tekan "Cari Printer" untuk memuat perangkat',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deviceList.length,
            itemBuilder: (context, index) {
              final device = deviceList[index];
              return Card(
                color: Colors.grey.shade100,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.print, color: Color(0xFF5B3A1E)),
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  trailing: Obx(() {
                    final selected = printerService.selectedDevice.value;
                    final isSelected = selected?.address == device.address;
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
      ],
    );
  }

  Widget _buildPrinterTypeSelection(PrinterService printerService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipe Printer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Obx(() {
            final currentType = printerService.printerType.value;
            return Column(
              children: [
                RadioListTile<PrinterType>(
                  title: const Text('ESC/POS'),
                  subtitle: const Text('(Receipt Printer)'),
                  value: PrinterType.escPos,
                  groupValue: currentType,
                  onChanged: (val) {
                    if (val != null) printerService.setPrinterType(val);
                  },
                  activeColor: const Color(0xFF5B3A1E),
                  contentPadding: EdgeInsets.zero,
                ),
                Divider(height: 1, color: Colors.grey.shade300),
                RadioListTile<PrinterType>(
                  title: const Text('TSPL'),
                  subtitle: const Text('(Label Printer)'),
                  value: PrinterType.tspl,
                  groupValue: currentType,
                  onChanged: (val) {
                    if (val != null) printerService.setPrinterType(val);
                  },
                  activeColor: const Color(0xFF5B3A1E),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Build paper size settings for ESC/POS printers
  Widget _buildPaperSizeSettings(PrinterService printerService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ukuran Kertas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Obx(() {
            final currentWidth = printerService.paperWidth.value;
            return Column(
              children: [
                RadioListTile<int>(
                  title: const Text('58mm'),
                  value: 32,
                  groupValue: currentWidth,
                  onChanged: (val) {
                    if (val != null) printerService.setPaperSize(58);
                  },
                  activeColor: const Color(0xFF5B3A1E),
                  contentPadding: EdgeInsets.zero,
                ),
                Divider(height: 1, color: Colors.grey.shade300),
                RadioListTile<int>(
                  title: const Text('80mm'),
                  value: 48,
                  groupValue: currentWidth,
                  onChanged: (val) {
                    if (val != null) printerService.setPaperSize(80);
                  },
                  activeColor: const Color(0xFF5B3A1E),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Build label size settings for TSPL printers
  Widget _buildLabelSizeSettings(PrinterService printerService) {
    final widthController = TextEditingController(text: printerService.labelWidth.value.toString());
    final heightController = TextEditingController(
      text: printerService.labelHeight.value.toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ukuran Label (mm)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preset sizes + Custom option
              const Text('Pilih Ukuran:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _labelSizeChip(printerService, 50, 30, '50x30'),
                  _labelSizeChip(printerService, 40, 30, '40x30'),
                  _labelSizeChip(printerService, 60, 40, '60x40'),
                  _labelSizeChip(printerService, 100, 50, '100x50'),
                  _labelSizeChip(printerService, 100, 150, '100x150'),
                  // Custom chip
                  Obx(() {
                    final isCustom = printerService.isCustomLabelSize.value;
                    return ChoiceChip(
                      label: const Text('Custom'),
                      selected: isCustom,
                      onSelected: (selected) {
                        printerService.isCustomLabelSize.value = selected;
                      },
                      selectedColor: Colors.orange.shade200,
                      backgroundColor: Colors.white,
                      avatar: isCustom ? const Icon(Icons.edit, size: 16) : null,
                    );
                  }),
                ],
              ),

              // Custom input fields - only show when custom is selected
              Obx(() {
                if (!printerService.isCustomLabelSize.value) {
                  return const SizedBox.shrink();
                }

                // Update controllers when shown
                widthController.text = printerService.labelWidth.value.toString();
                heightController.text = printerService.labelHeight.value.toString();

                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Masukkan ukuran custom:',
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: widthController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Lebar',
                                    suffixText: 'mm',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'x',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Tinggi',
                                    suffixText: 'mm',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final w = int.tryParse(widthController.text) ?? 50;
                                final h = int.tryParse(heightController.text) ?? 30;
                                if (w > 0 && h > 0) {
                                  printerService.setLabelSize(w, h);
                                  Get.snackbar(
                                    'Sukses',
                                    'Ukuran label diatur ke ${w}x$h mm',
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Terapkan Ukuran'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 16),

              // Current size display
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Ukuran aktif: ${printerService.labelWidth.value} x ${printerService.labelHeight.value} mm',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _labelSizeChip(PrinterService printerService, int width, int height, String label) {
    return Obx(() {
      final isSelected =
          !printerService.isCustomLabelSize.value &&
          printerService.labelWidth.value == width &&
          printerService.labelHeight.value == height;
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            printerService.isCustomLabelSize.value = false; // Hide custom input
            printerService.setLabelSize(width, height);
          }
        },
        selectedColor: Colors.blue.shade200,
        backgroundColor: Colors.white,
      );
    });
  }
}
