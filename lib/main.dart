import 'package:edifly_pos/core/services/printer_service.dart';
import 'package:edifly_pos/domains/auth/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:requests_inspector/requests_inspector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Force landscape for POS tablet
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  /// Hide status bar (optional for kiosk/POS mode)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  /// Initialize PrinterService
  Get.put(PrinterService());

  runApp(const RequestsInspector(enabled: kDebugMode ? true : false, child: PosApp()));
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'POS Retail',
      debugShowCheckedModeBanner: false,

      /// Disable Material 3 for stable POS UI
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF4A3728),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A3728),
            foregroundColor: Colors.white,
          ),
        ),
      ),

      home: const PosLoginPage(),
    );
  }
}
