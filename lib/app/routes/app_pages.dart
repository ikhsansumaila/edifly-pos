import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:get/get.dart';

import '../../domains/auth/login_page.dart';
import '../../domains/order/order_page.dart';

class AppPages {
  static final pages = [
    GetPage(name: Routes.login, page: () => const PosLoginPage()),
    GetPage(name: Routes.order, page: () => PosOrderPage()),
  ];
}
