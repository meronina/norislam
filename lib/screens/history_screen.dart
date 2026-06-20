import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/score_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام الـ Singleton الصحيح للخدمة
    final scoreService = ScoreService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تاريخ الاختبارات'),
        centerTitle: true,
      ),
      // 🔥 تم التغيير إلى FutureBuilder ليتوافق تماماً مع مخرجات الدالة الجديدة
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: scoreService.getUserScores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد نتائج مسجلة بعد'));
          }

          // البيانات قادمة مسبقاً على هيئة مصفوفة جاهزة من كلاس الـ Service
          final scoresList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scoresList.length,
            itemBuilder: (context, index) {
              final data = scoresList[index];

              final category = data['category'] ?? '';
              final score = data['score'] ?? 0;
              final total = data['total'] ?? 0;
              final timestamp = data['timestamp'] as DateTime?;

              final dateStr = timestamp != null
                  ? DateFormat('yyyy/MM/dd hh:mm a').format(timestamp)
                  : 'تاريخ غير معروف';

              final percentage =
                  total > 0 ? (score / total * 100).toStringAsFixed(1) : '0';

              final bool isPassed = total > 0 && (score / total) >= 0.7;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        isPassed ? Colors.amber : Colors.grey.shade400,
                    child: Text(
                      '$score/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(
                    category,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$dateStr\nالنسبة: $percentage%',
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                  trailing: Icon(
                    isPassed
                        ? Icons.emoji_events_rounded
                        : Icons.assessment_rounded,
                    color: isPassed ? Colors.amber : Colors.grey,
                    size: 28,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
