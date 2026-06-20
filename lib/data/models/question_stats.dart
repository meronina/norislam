import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionStats {
  final int totalAttempts;
  final int correctCount;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final int interval; // عدد الأيام للمراجعة القادمة
  final double easeFactor;
  final int repetitions;

  QuestionStats({
    this.totalAttempts = 0,
    this.correctCount = 0,
    this.lastReviewed,
    this.nextReview,
    this.interval = 1,
    this.easeFactor = 2.5,
    this.repetitions = 0,
  });

  factory QuestionStats.initial() {
    return QuestionStats();
  }

  factory QuestionStats.fromMap(Map<String, dynamic> map) {
    return QuestionStats(
      totalAttempts: map['totalAttempts'] ?? 0,
      correctCount: map['correctCount'] ?? 0,
      lastReviewed: map['lastReviewed'] != null
          ? (map['lastReviewed'] as Timestamp).toDate()
          : null,
      nextReview: map['nextReview'] != null
          ? (map['nextReview'] as Timestamp).toDate()
          : null,
      interval: map['interval'] ?? 1,
      easeFactor: (map['easeFactor'] ?? 2.5).toDouble(),
      repetitions: map['repetitions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAttempts': totalAttempts,
      'correctCount': correctCount,
      'lastReviewed':
          lastReviewed != null ? Timestamp.fromDate(lastReviewed!) : null,
      'nextReview': nextReview != null ? Timestamp.fromDate(nextReview!) : null,
      'interval': interval,
      'easeFactor': easeFactor,
      'repetitions': repetitions,
    };
  }

  // تحديث الإحصائيات بعد إجابة المستخدم (خوارزمية SM-2)
  QuestionStats updateAfterReview(bool isCorrect, [double? customEase]) {
    final newRepetitions = repetitions + 1;
    double updatedEase = customEase ?? easeFactor;

    int newInterval;

    if (!isCorrect) {
      newInterval = 1;
      updatedEase = (updatedEase - 0.2).clamp(1.3, 2.5);
    } else if (newRepetitions == 1) {
      newInterval = 1;
    } else if (newRepetitions == 2) {
      newInterval = 6;
    } else {
      newInterval = (interval * updatedEase).round().clamp(1, 365);
    }

    final now = DateTime.now();
    final nextReviewDate = now.add(Duration(days: newInterval));

    return QuestionStats(
      totalAttempts: totalAttempts + 1,
      correctCount: isCorrect ? correctCount + 1 : correctCount,
      lastReviewed: now,
      nextReview: nextReviewDate,
      interval: newInterval,
      easeFactor: updatedEase,
      repetitions: newRepetitions,
    );
  }
}
