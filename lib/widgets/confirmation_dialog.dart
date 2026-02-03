import 'package:edifly_pos/core/config/app_theme_config.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String source;
  final int total;
  final String method;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmationDialog({
    super.key,
    required this.source,
    required this.total,
    required this.method,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueGrey.shade200, width: 3),
                ),
                child: Center(
                  child: Icon(
                    Icons.question_mark_rounded,
                    size: 40,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Konfirmasi Pesanan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // Content
              Text("Sumber Pesanan: $source", style: _textStyle()),
              const SizedBox(height: 4),
              Text("Total: ${formatRupiah(total)}", style: _textStyle(isBold: true)),
              const SizedBox(height: 4),
              Text("Metode: $method", style: _textStyle()),

              const SizedBox(height: 32),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeConfig.primaryColor, // Brown color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Proses Sekarang',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade400, // Grey color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _textStyle({bool isBold = false}) {
    return TextStyle(
      fontSize: 16,
      color: Colors.black54,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );
  }
}
