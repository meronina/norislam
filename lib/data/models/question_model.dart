import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_stats.dart';

enum QuestionType {
  multipleChoice,
  trueFalse,
  imageBased,
  audioBased,
  ordering,
  matching,
}

class Question {
  final String id;
  final String categoryId;
  final String? subCategory;
  final String question;
  final QuestionType type;
  final List<String> options;
  final int correctIndex; // ← تغيير: أصبح int بدلاً من dynamic
  final int difficulty;
  final String? explanation;
  final String? reference;
  final String? mediaUrl;
  final String? mediaType;
  final List<String> tags;
  final QuestionStats stats;

  Question({
    required this.id,
    required this.categoryId,
    this.subCategory,
    required this.question,
    this.type = QuestionType.multipleChoice,
    required this.options,
    required this.correctIndex, // ← تغيير
    this.difficulty = 3,
    this.explanation,
    this.reference,
    this.mediaUrl,
    this.mediaType,
    this.tags = const [],
    QuestionStats? stats,
  }) : stats = stats ?? QuestionStats.initial();

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      subCategory: data['subCategory'],
      question: data['question'] ?? '',
      type: QuestionType.values.byName(data['type'] ?? 'multipleChoice'),
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0, // ← تغيير
      difficulty: data['difficulty'] ?? 3,
      explanation: data['explanation'],
      reference: data['reference'],
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      tags: List<String>.from(data['tags'] ?? []),
      stats: QuestionStats.fromMap(data['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'subCategory': subCategory,
      'question': question,
      'type': type.name,
      'options': options,
      'correctIndex': correctIndex, // ← تغيير
      'difficulty': difficulty,
      'explanation': explanation,
      'reference': reference,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'tags': tags,
      'stats': stats.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Question copyWith({
    String? id,
    String? categoryId,
    String? subCategory,
    String? question,
    QuestionType? type,
    List<String>? options,
    int? correctIndex,
    int? difficulty,
    String? explanation,
    String? reference,
    String? mediaUrl,
    String? mediaType,
    List<String>? tags,
    QuestionStats? stats,
  }) {
    return Question(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      subCategory: subCategory ?? this.subCategory,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      difficulty: difficulty ?? this.difficulty,
      explanation: explanation ?? this.explanation,
      reference: reference ?? this.reference,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      tags: tags ?? this.tags,
      stats: stats ?? this.stats,
    );
  }
}
