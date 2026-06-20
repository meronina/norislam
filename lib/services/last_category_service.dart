import 'package:shared_preferences/shared_preferences.dart';

class LastCategoryService {
  LastCategoryService._();
  static final LastCategoryService instance = LastCategoryService._();

  static const String _lastCategoryKey = 'last_selected_category';

  Future<void> saveLastCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCategoryKey, category);
  }

  Future<String?> getLastCategory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastCategoryKey);
  }

  Future<void> clearLastCategory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCategoryKey);
  }
}
