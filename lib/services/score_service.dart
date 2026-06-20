import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  ScoreService._privateConstructor();
  static final ScoreService instance = ScoreService._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // حفظ النتيجة
  Future<void> saveScore({
    required String category,
    required int score,
    required int total,
    required String difficultyLevel,
  }) async {
    final double percentage = total > 0 ? (score / total) * 100 : 0;
    final user = _auth.currentUser;

    final prefs = await SharedPreferences.getInstance();
    final localKey = 'high_score_$category';
    final currentLocalBest = prefs.getInt(localKey) ?? 0;

    if (score > currentLocalBest) {
      await prefs.setInt(localKey, score);
      await prefs.setDouble('high_score_percent_$category', percentage);
    }

    if (user != null) {
      await _firestore.collection('scores').add({
        'userId': user.uid,
        'category': category,
        'score': score,
        'total': total,
        'percentage': percentage.round(),
        'difficultyLevel': difficultyLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> getHighScoreText(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('high_score_$category') ?? 0;
    return '$score نقطة';
  }

  Future<Map<String, dynamic>> getHighScoreDetails(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final bestScore = prefs.getInt('high_score_$category') ?? 0;
    final bestPercent = prefs.getDouble('high_score_percent_$category') ?? 0.0;

    return {
      'bestScore': bestScore,
      'bestPercentage': bestPercent.toStringAsFixed(0),
    };
  }

  // 🛠️ تم تعديل المعامل إلى isEqualTo لمنع خطأ missing_identifier
  Future<List<Map<String, dynamic>>> getUserScores() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('scores')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'category': data['category'] ?? 'عام',
          'score': data['score'] ?? 0,
          'total': data['total'] ?? 0,
          'percentage': data['percentage'] ?? 0,
          'difficultyLevel': data['difficultyLevel'] ?? 'مبتدئ',
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // 🛠️ تم التعديل هنا أيضاً
  Future<int> getTotalAttempts() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('scores')
          .where('userId', isEqualTo: user.uid)
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  // 🛠️ تم التعديل هنا أيضاً
  Future<Map<String, dynamic>> getScoreSummary() async {
    final user = _auth.currentUser;
    if (user == null) return {'average': 0, 'highest': 0};

    try {
      final snapshot = await _firestore
          .collection('scores')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) return {'average': 0, 'highest': 0};

      int totalPercent = 0;
      int highest = 0;

      for (var doc in snapshot.docs) {
        final percent = doc.data()['percentage'] as int? ?? 0;
        totalPercent += percent;
        if (percent > highest) highest = percent;
      }

      return {
        'average': (totalPercent / snapshot.docs.length).round(),
        'highest': highest,
      };
    } catch (_) {
      return {'average': 0, 'highest': 0};
    }
  }

  // 🛠️ تم التعديل هنا أيضاً
  Future<String> getBestCategory() async {
    final user = _auth.currentUser;
    if (user == null) return 'لا يوجد';

    try {
      final snapshot = await _firestore
          .collection('scores')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) return 'لا يوجد';

      final Map<String, List<int>> categoryScores = {};
      for (var doc in snapshot.docs) {
        final cat = doc.data()['category'] as String? ?? 'عام';
        final pct = doc.data()['percentage'] as int? ?? 0;
        categoryScores.putIfAbsent(cat, () => []).add(pct);
      }

      String bestCat = 'لا يوجد';
      double highestAvg = -1.0;

      categoryScores.forEach((category, list) {
        final avg = list.reduce((a, b) => a + b) / list.length;
        if (avg > highestAvg) {
          highestAvg = avg;
          bestCat = category;
        }
      });

      return bestCat;
    } catch (_) {
      return 'عام';
    }
  }

  // 🛠️ تم التعديل هنا أيضاً
  Future<String> getLastActivity() async {
    final user = _auth.currentUser;
    if (user == null) return 'لا يوجد نشاط';

    try {
      final snapshot = await _firestore
          .collection('scores')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return 'لا يوجد نشاط';
      return snapshot.docs.first.data()['category'] ?? 'عام';
    } catch (_) {
      return 'متاح قريباً';
    }
  }
}
