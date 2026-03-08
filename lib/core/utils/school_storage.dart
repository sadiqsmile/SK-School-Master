import 'package:shared_preferences/shared_preferences.dart';

class SchoolStorage {
  static const String schoolKey = 'school_id';

  static Future<void> saveSchoolId(String schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(schoolKey, schoolId);
  }

  static Future<String?> getSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(schoolKey);
  }

  static Future<void> clearSchool() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(schoolKey);
  }
}
