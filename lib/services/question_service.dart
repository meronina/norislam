import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../data/models/question_model.dart';
import '../data/models/question_stats.dart';

class QuestionService {
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;
  QuestionService._internal();

  static QuestionService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Question>? _cachedQuestions;
  List<String>? _cachedCategories;

  static const Map<String, String> _categoryNormalization = {
    'فقه_الطهارة': 'الفقه',
    'الفقه الإسلامي': 'الفقه',
  };

  String _normalizeCategory(String categoryId) {
    final normalized = categoryId.trim();
    return _categoryNormalization[normalized] ?? normalized;
  }

  String _normalizeQuestionText(String question) {
    return question.trim();
  }

  List<Question> _dedupeQuestionsByText(List<Question> questions) {
    final Map<String, Question> unique = {};
    for (final question in questions) {
      final normalizedText = _normalizeQuestionText(question.question);
      if (!unique.containsKey(normalizedText)) {
        unique[normalizedText] = question;
      }
    }
    return unique.values.toList();
  }

  // ==================== جلب جميع الأسئلة (مع كاش) ====================
  Future<List<Question>> getAllQuestions() async {
    if (_cachedQuestions != null && _cachedQuestions!.isNotEmpty) {
      return _cachedQuestions!;
    }

    try {
      debugPrint('🔥 جلب الأسئلة من Firestore...');
      final snapshot = await _firestore
          .collection('questions')
          .get(const GetOptions(source: Source.serverAndCache));

      final questions = snapshot.docs.map((doc) {
        return Question.fromFirestore(doc);
      }).toList();

      final deduped = _dedupeQuestionsByText(questions);
      _cachedQuestions = deduped;
      debugPrint('✅ تم جلب ${deduped.length} سؤال من Firestore بعد إزالة التكرار');
      return deduped;
    } catch (e) {
      debugPrint('⚠️ فشل الاتصال بالسيرفر: $e → محاولة الملف المحلي');
      return await _getFromLocalJson();
    }
  }

  // ==================== جلب من JSON المحلي (احتياطي) ====================
  Future<List<Question>> _getFromLocalJson() async {
    try {
      final String response =
          await rootBundle.loadString('assets/questions.json');
      final List<dynamic> data = json.decode(response);

      final questions = data.map((jsonMap) {
        return Question(
          id: jsonMap['id'] ?? '',
          categoryId: jsonMap['categoryId'] ?? jsonMap['category'] ?? '',
          subCategory: jsonMap['subCategory'],
          question: jsonMap['question'] ?? '',
          type: QuestionType.values.byName(jsonMap['type'] ?? 'multipleChoice'),
          options: List<String>.from(jsonMap['options'] ?? []),
          correctIndex: jsonMap['correctIndex'] ?? 0,
          difficulty: jsonMap['difficulty'] ?? 3,
          explanation: jsonMap['explanation'],
          reference: jsonMap['reference'],
          mediaUrl: jsonMap['mediaUrl'],
          mediaType: jsonMap['mediaType'],
          tags: List<String>.from(jsonMap['tags'] ?? []),
          stats: QuestionStats.fromMap(jsonMap['stats'] ?? {}),
        );
      }).toList();

      final deduped = _dedupeQuestionsByText(questions);
      _cachedQuestions = deduped;
      debugPrint('📁 تم استخدام الملف المحلي (${deduped.length} سؤال) بعد إزالة التكرار');
      return deduped;
    } catch (e) {
      debugPrint('❌ خطأ في الملف المحلي: $e');
      return [];
    }
  }

  // ==================== جلب أسئلة لفئة معينة (استعلام مباشر) ====================
  Future<List<Question>> getQuestionsByCategory(String categoryId) async {
    final normalizedCategory = _normalizeCategory(categoryId);
    debugPrint('🔍 جلب أسئلة القسم مباشرة من Firestore: "$normalizedCategory"');
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('categoryId', isEqualTo: normalizedCategory)
          .get();

      var questions =
          snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
      debugPrint(
          '📊 عدد الأسئلة في "$categoryId" عبر categoryId: ${questions.length}');

      if (questions.isEmpty) {
        debugPrint('🔄 محاولة البحث باستخدام الحقل البديل "category"');
        final fallbackSnapshot = await _firestore
            .collection('questions')
            .where('category', isEqualTo: normalizedCategory)
            .get();

        questions = fallbackSnapshot.docs
            .map((doc) => Question.fromFirestore(doc))
            .toList();
      }

      if (questions.isEmpty && normalizedCategory == 'الفقه') {
        debugPrint('🔄 محاولة البحث في الفئة القديمة "فقه_الطهارة" أو "الفقه الإسلامي"');
        final fallbackCategories = ['فقه_الطهارة', 'الفقه الإسلامي'];
        for (final category in fallbackCategories) {
          final fallbackSnapshot = await _firestore
              .collection('questions')
              .where('categoryId', isEqualTo: category)
              .get();
          final fallbackQuestions = fallbackSnapshot.docs
              .map((doc) => Question.fromFirestore(doc))
              .toList();
          if (fallbackQuestions.isNotEmpty) {
            questions = fallbackQuestions;
            break;
          }
        }
      }

      if (questions.isEmpty) {
        debugPrint(
            '🔄 محاولة البحث في الملف المحلي بعد فشل Firestore أو عدم وجود أسئلة');
        final localQuestions = await _getFromLocalJson();
        questions = localQuestions
            .where((q) => _normalizeCategory(q.categoryId) == normalizedCategory)
            .toList();
        questions = _dedupeQuestionsByText(questions);
        debugPrint(
            '📁 عدد الأسئلة في الملف المحلي للفئة "$normalizedCategory" بعد إزالة التكرار: ${questions.length}');
      }

      if (questions.isEmpty) {
        final allSnapshot = await _firestore.collection('questions').get();
        final allCategories = allSnapshot.docs
            .map((d) {
              final data = d.data();
              return (data['categoryId'] as String?) ??
                  (data['category'] as String?) ??
                  '';
            })
            .where((category) => category.isNotEmpty)
            .toSet();
        debugPrint(
            '⚠️ لا توجد أسئلة للفئة "$categoryId". الفئات الموجودة: $allCategories');
      } else {
        questions = _dedupeQuestionsByText(questions);
        debugPrint('✅ أول سؤال: ${questions.first.question}');
      }
      return questions;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الأسئلة: $e');
      final localQuestions = await _getFromLocalJson();
      var questions = localQuestions
          .where((q) => _normalizeCategory(q.categoryId) == normalizedCategory)
          .toList();
      questions = _dedupeQuestionsByText(questions);
      debugPrint(
          '📁 استخدام الملف المحلي بسبب خطأ، عدد الأسئلة للفئة "$normalizedCategory" بعد إزالة التكرار: ${questions.length}');
      return questions;
    }
  }

  // ==================== جلب أسئلة بمستوى صعوبة محدد (لنظام المستويات) ====================
  Future<List<Question>> getQuestionsByCategoryAndDifficulty(
    String categoryId,
    int difficultyLevel,
  ) async {
    final all = await getQuestionsByCategory(categoryId);
    final filtered = all.where((q) => q.difficulty <= difficultyLevel).toList();

    debugPrint(
        '📊 أسئلة "$categoryId" بمستوى <= $difficultyLevel: ${filtered.length}');

    if (filtered.isEmpty) {
      debugPrint(
          '⚠️ لا توجد أسئلة بمستوى <= $difficultyLevel، استخدام جميع الأسئلة للفئة');
      return all;
    }

    if (filtered.length < 5) {
      debugPrint(
          '⚠️ عدد الأسئلة قليل، إضافة أسئلة أصعب حتى يصبح العدد كافياً...');
      final harderLevels =
          all.where((q) => q.difficulty > difficultyLevel).toList();
      return [...filtered, ...harderLevels].take(5).toList();
    }
    return filtered;
  }

  // ==================== جلب قائمة الفئات ====================
  Future<List<String>> getCategories() async {
    if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }

    try {
      final snapshot = await _firestore.collection('questions').get();
      final categories = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return (data['categoryId'] as String?) ??
                (data['category'] as String?) ??
                '';
          })
          .where((category) => category.isNotEmpty)
          .map(_normalizeCategory)
          .toSet()
          .toList();
      categories.sort();
      _cachedCategories = categories;
      debugPrint('📂 تم جلب ${categories.length} فئة: $categories');
      return categories;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الفئات من Firestore: $e');
      final allQuestions = await _getFromLocalJson();
      final categories = allQuestions
          .map((question) => _normalizeCategory(question.categoryId))
          .toSet()
          .toList()
        ..sort();
      _cachedCategories = categories;
      debugPrint('📂 تم جلب الفئات من الملف المحلي: $categories');
      return categories;
    }
  }

  // ==================== تنظيف الكاش ====================
  void clearCache() {
    _cachedQuestions = null;
    _cachedCategories = null;
    debugPrint('🧹 تم تنظيف الكاش بالكامل');
  }
}
