import 'package:flutter/material.dart';

class AppThemeConfig {
  /// ============================================================
  /// KONFIGURASI TEMA APLIKASI
  /// Ubah nilai di bawah ini untuk mengganti warna tema saat build
  /// ============================================================

  /// Warna Utama Aplikasi (Primary Color)
  /// Digunakan untuk Appbar, Tombol, dan elemen utama lainnya.
  static const Color primaryColor = Color(0xFF4A3728); // Default: Brown
  // static const Color primaryColorLight = Color(0xFF5B3A1E); // Brown Light

  // Opsi Warna Lain (Uncomment salah satu untuk menggunakan):
  // static const Color primaryColor = Color(0xFF1976D2); // Blue
  // static const Color primaryColor = Color(0xFF388E3C); // Green
  // static const Color primaryColor = Color(0xFFD32F2F); // Red
  // static const Color primaryColor = Color(0xFF7B1FA2); // Purple

  /// Warna Latar Belakang Aplikasi
  static const Color scaffoldBackgroundColor = Colors.white;

  /// Warna Teks/Icon di atas Primary Color (misal: teks tombol)
  static const Color onPrimaryColor = Colors.white;
}
