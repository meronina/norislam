import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class HighScoreService {
  static const String _highScoreKey = 'high_score_';

  Future<void> saveHighScore(String category, int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_highScoreKey${category.replaceAll(' ', '_')}';
    final percentage = (score / total) * 100.0;

    final currentHigh = prefs.getDouble(key) ?? 0.0;

    if (percentage > currentHigh) {
      await prefs.setDouble(key, percentage);
      debugPrint(
          '🎯 تم تحديث أعلى نتيجة لـ $category: ${percentage.toStringAsFixed(1)}%');
    }
  }

  Future<double> getHighScore(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_highScoreKey${category.replaceAll(' ', '_')}';
    return prefs.getDouble(key) ?? 0.0;
  }

  Future<String> getHighScoreText(String category) async {
    final high = await getHighScore(category);
    return high > 0 ? '${high.toStringAsFixed(1)}%' : 'لا يوجد بعد';
  }
}
