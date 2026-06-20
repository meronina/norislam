// scripts/upload_questions.dart (معدل)
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:religious_qa_app/firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  const String jsonData = '''
[
  {"categoryId": "العقيدة الإسلامية", "question": "ما هو أول واجب على المسلم؟", "options": ["الصلاة", "الزكاة", "التوحيد", "الحج"], "correctIndex": 2, "difficulty": 1, "explanation": "التوحيد هو أساس الدين"},
  {"categoryId": "العقيدة الإسلامية", "question": "كم عدد أركان الإيمان؟", "options": ["5", "6", "7", "10"], "correctIndex": 1, "difficulty": 1, "explanation": "الإيمان له ستة أركان"},
  {"categoryId": "العقيدة الإسلامية", "question": "من هو خاتم الأنبياء والمرسلين؟", "options": ["موسى", "عيسى", "محمد", "إبراهيم"], "correctIndex": 2, "difficulty": 1, "explanation": "محمد ﷺ خاتم النبيين"},
  {"categoryId": "السيرة النبوية", "question": "ما اسم والد النبي محمد ﷺ؟", "options": ["عبدالمطلب", "عبدالله", "أبو طالب", "حمزة"], "correctIndex": 1, "difficulty": 1, "explanation": "عبدالله بن عبدالمطلب"},
  {"categoryId": "السيرة النبوية", "question": "في أي مدينة ولد النبي ﷺ؟", "options": ["مكة", "المدينة", "الطائف", "جدة"], "correctIndex": 0, "difficulty": 1, "explanation": "ولد في مكة"},
  {"categoryId": "الفقه وأحكام العبادات", "question": "كم عدد ركعات صلاة الفجر؟", "options": ["2", "3", "4", "4"], "correctIndex": 0, "difficulty": 1, "explanation": "ركعتان"},
  {"categoryId": "القرآن الكريم", "question": "كم عدد سور القرآن؟", "options": ["114", "120", "99", "666"], "correctIndex": 0, "difficulty": 1, "explanation": "114 سورة"},
  {"categoryId": "التاريخ الإسلامي", "question": "من فتح القسطنطينية؟", "options": ["صلاح الدين", "محمد الفاتح", "طارق بن زياد", "خالد بن الوليد"], "correctIndex": 1, "difficulty": 1, "explanation": "محمد الفاتح"}
]
''';

  final List<dynamic> questions = json.decode(jsonData);
  debugPrint('📊 عدد الأسئلة: ${questions.length}');

  int uploaded = 0;
  for (var q in questions) {
    await firestore.collection('questions').add({
      'categoryId': q['categoryId'],
      'question': q['question'],
      'options': q['options'],
      'correctIndex': q['correctIndex'],
      'difficulty': q['difficulty'],
      'explanation': q['explanation'],
      'createdAt': FieldValue.serverTimestamp(),
    });
    uploaded++;
    debugPrint('✅ تم رفع $uploaded');
  }

  debugPrint('🎉 اكتمل الرفع: $uploaded سؤال');
}
