import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveProgress({
    required String category,
    required int currentIndex,
    required int score,
    required int total,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final progressRef = _firestore.collection('progress').doc(user.uid);
      await progressRef.set({
        'userId': user.uid,
        'category': category,
        'currentIndex': currentIndex,
        'score': score,
        'total': total,
        'percentage': total > 0 ? ((score / total) * 100).round() : 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<Map<String, dynamic>?> getSavedProgress() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('progress').doc(user.uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('Error loading saved progress: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSavedProgressForCategory(
      String category) async {
    final saved = await getSavedProgress();
    if (saved == null) return null;
    if ((saved['category'] as String?)?.trim() == category.trim()) {
      return saved;
    }
    return null;
  }

  Future<void> clearSavedProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('progress').doc(user.uid).delete();
    } catch (e) {
      debugPrint('Error clearing saved progress: $e');
    }
  }
}
