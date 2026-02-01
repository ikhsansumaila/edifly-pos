import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _tokenKey = 'token';
  static const String _outletIdKey = 'outlet_id';
  static const String _userIdKey = 'user_id';
  static const String _roleKey = 'role';
  static const String _nameKey = 'name';
  static const String _namaOutletKey = 'nama_outlet';
  static const String _emailKey = 'email';
  static const String _addressKey = 'address';

  static Future<void> saveAuth({
    required String token,
    required String outletId,
    required String userId,
    required String role,
    required String name,
    required String namaOutlet,
    required String email,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_outletIdKey, outletId);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_namaOutletKey, namaOutlet);
    await prefs.setString(_emailKey, email);
    if (address != null) {
      await prefs.setString(_addressKey, address);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String?> getNamaOutlet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_namaOutletKey);
  }

  static Future<String?> getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_addressKey);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
