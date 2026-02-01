import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String formatRupiah(num value) {
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  return formatter.format(value);
}

class RupiahInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Hapus semua non-digit
    String numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericString.isEmpty) return const TextEditingValue(text: '');

    // Format jadi Rupiah
    String formatted = _formatter.format(int.parse(numericString));

    // Simpan cursor di akhir
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RupiahInput extends StatelessWidget {
  const RupiahInput({
    super.key,
    required this.hint,
    required this.onChanged,
    this.fontSize = 13,
    this.controller,
  });

  final String hint;
  final void Function(int) onChanged;
  final double fontSize;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [RupiahInputFormatter()],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: fontSize),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: Colors.grey.shade400, // warna border ketika enable
            width: 0.8,
          ),
        ),
      ),
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: fontSize, color: Colors.black),
      onChanged: (val) {
        // hapus Rp dan titik
        String numericString = val.replaceAll(RegExp(r'[^0-9]'), '');
        int value = numericString.isEmpty ? 0 : int.parse(numericString);
        onChanged(value);
      },
    );
  }
}
