import 'package:edifly_pos/app/routes/app_pages.dart';
import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:edifly_pos/core/config/app_theme_config.dart';
import 'package:edifly_pos/core/services/printer_service.dart';
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
      title: 'Dimonggoin Kasir',
      debugShowCheckedModeBanner: false,

      /// Disable Material 3 for stable POS UI
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        primaryColor: AppThemeConfig.primaryColor,
        scaffoldBackgroundColor: AppThemeConfig.scaffoldBackgroundColor,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeConfig.primaryColor,
            foregroundColor: AppThemeConfig.onPrimaryColor,
          ),
        ),
      ),

      initialRoute: Routes.login,
      getPages: AppPages.pages,
    );
  }
}
