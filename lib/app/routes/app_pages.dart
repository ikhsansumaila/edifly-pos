import 'package:edifly_pos/app/middleware/shift_check_middleware.dart';
import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:edifly_pos/domains/printer/printer_settings_page.dart';
import 'package:edifly_pos/domains/shift/closing_shift.dart';
import 'package:edifly_pos/domains/shift/open_shift_page.dart';
import 'package:get/get.dart';

import '../../domains/auth/login_page.dart';
import '../../domains/order/order_page.dart';

class AppPages {
  static final pages = [
    GetPage(name: Routes.login, page: () => const PosLoginPage()),
    GetPage(
      name: Routes.order,
      page: () => const PosOrderPage(),
      middlewares: [ShiftCheckMiddleware()],
    ),
    GetPage(name: Routes.closingShift, page: () => const ClosingShiftPage()),
    GetPage(name: Routes.openingShift, page: () => const OpenShiftPage()),
    GetPage(name: Routes.printSettings, page: () => const PrinterSettingsPage()),
  ];
}
