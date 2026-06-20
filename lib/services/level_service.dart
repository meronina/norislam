import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LevelService {
  static final LevelService _instance = LevelService._internal();
  LevelService._internal();
  factory LevelService() => _instance;
  static LevelService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // مفاتيح SharedPreferences للتخزين المحلي
  static const String _keyXp = 'user_xp';
  static const String _keyLevel = 'user_difficulty_level';

  // نقاط الخبرة المطلوبة لكل مستوى صعوبة (1,2,3)
  static const Map<int, int> xpRequiredPerDifficulty = {
    1: 0, // المستوى الأول يبدأ بدون نقاط
    2: 500, // يحتاج 500 نقطة لفتح المستوى 2
    3: 1200, // يحتاج 1200 نقطة لفتح المستوى 3
  };

  // النقاط التي يحصل عليها المستخدم لكل إجابة صحيحة حسب صعوبة السؤال
  int getXpForDifficulty(int difficulty) {
    switch (difficulty) {
      case 1:
        return 10;
      case 2:
        return 20;
      case 3:
        return 35;
      default:
        return 10;
    }
  }

  Future<void> addXp(int difficulty) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final xpGain = getXpForDifficulty(difficulty);
    final prefs = await SharedPreferences.getInstance();
    int currentXp = prefs.getInt(_keyXp) ?? 0;
    currentXp += xpGain;
    await prefs.setInt(_keyXp, currentXp);

    // تحديث في Firestore للمزامنة بين الأجهزة
    await _firestore.collection('users').doc(user.uid).set({
      'xp': currentXp,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // تحديث مستوى الصعوبة الحالي بناءً على XP
    await _updateDifficultyLevel(currentXp);
  }

  Future<void> _updateDifficultyLevel(int currentXp) async {
    int newLevel = 1;
    if (currentXp >= xpRequiredPerDifficulty[3]!) {
      newLevel = 3;
    } else if (currentXp >= xpRequiredPerDifficulty[2]!) {
      newLevel = 2;
    }
    final prefs = await SharedPreferences.getInstance();
    final oldLevel = prefs.getInt(_keyLevel) ?? 1;
    if (newLevel != oldLevel) {
      await prefs.setInt(_keyLevel, newLevel);
      // يمكن إظهار إشعار للمستخدم بأنه رفع مستواه
    }
  }

  Future<int> getCurrentDifficultyLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLevel) ?? 1;
  }

  Future<int> getCurrentXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyXp) ?? 0;
  }

  Future<int> getXpRequiredForNextLevel() async {
    final currentLevel = await getCurrentDifficultyLevel();
    if (currentLevel == 3) return 0; // المستوى الأقصى
    return xpRequiredPerDifficulty[currentLevel + 1]!;
  }

  Future<int> getXpForCurrentLevel() async {
    final currentLevel = await getCurrentDifficultyLevel();
    return xpRequiredPerDifficulty[currentLevel]!;
  }

  // تحميل البيانات من Firestore إذا كان المستخدم مسجلاً (أول مرة أو تغيير جهاز)
  Future<void> syncUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final xp = (data['xp'] as int?) ?? 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyXp, xp);
      await _updateDifficultyLevel(xp);
    }
  }
}
