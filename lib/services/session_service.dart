import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _loggedIn = 'loggedIn';
  static const _role = 'role';
  static const _phone = 'phone';

  /// SAVE SESSION
  static Future<void> saveSession({
    required String role,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedIn, true);
    await prefs.setString(_role, role);
    await prefs.setString(_phone, phone);
  }

  /// CLEAR SESSION (LOGOUT)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// GET SESSION
  static Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();

    final loggedIn = prefs.getBool(_loggedIn) ?? false;
    if (!loggedIn) return null;

    return {
      'role': prefs.getString(_role)!,
      'phone': prefs.getString(_phone)!,
    };
  }
}
