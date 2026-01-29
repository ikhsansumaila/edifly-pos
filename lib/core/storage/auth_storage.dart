import 'package:get_storage/get_storage.dart';

class AuthStorage {
  static final _box = GetStorage();

  static void saveAuth({required String token, required int outletId}) {
    _box.write('token', token);
    _box.write('outlet_id', outletId);
  }

  static String? get token => _box.read('token');
  static int? get outletId => _box.read('outlet_id');

  static bool get isLoggedIn => token != null;
}
