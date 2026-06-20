import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/score_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScoreService _scoreService = ScoreService.instance;

  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    final stats = <String, dynamic>{
      'userId': user?.uid ?? 'غير معروف',
      'email': user?.email,
      'createdAt': null,
      'totalAttempts': 0,
      'totalScore': 0,
      'totalQuestions': 0,
      'averagePercent': 0.0,
      'bestCategory': 'غير متوفر',
      'lastActive': null,
    };

    final attempts = await _scoreService.getTotalAttempts();
    final summary = await _scoreService.getScoreSummary();
    final bestCategory = await _scoreService.getBestCategory();
    final lastActive = await _scoreService.getLastActivity();

    stats['totalAttempts'] = attempts;
    stats['totalScore'] = summary['totalScore'];
    stats['totalQuestions'] = summary['totalTotal'];
    stats['averagePercent'] = summary['averagePercent'];
    stats['bestCategory'] = bestCategory;
    stats['lastActive'] = lastActive;

    return stats;
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'غير متوفر';
    return DateFormat('yyyy/MM/dd hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          final stats = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.teal,
                  child: Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  stats['email'] ?? 'مستخدم مجهول',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'معرّف المستخدم: ${stats['userId']}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 26),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'إحصائياتك',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildStatRow(
                          icon: Icons.timeline_rounded,
                          label: 'عدد المحاولات',
                          value: '${stats['totalAttempts']}',
                        ),
                        const SizedBox(height: 14),
                        _buildStatRow(
                          icon: Icons.scoreboard_rounded,
                          label: 'النقاط الكلية',
                          value:
                              '${stats['totalScore']} / ${stats['totalQuestions']}',
                        ),
                        const SizedBox(height: 14),
                        _buildStatRow(
                          icon: Icons.insights_rounded,
                          label: 'المعدل',
                          value:
                              '${stats['averagePercent'].toStringAsFixed(1)}%',
                        ),
                        const SizedBox(height: 14),
                        _buildStatRow(
                          icon: Icons.category_rounded,
                          label: 'أفضل فئة',
                          value: stats['bestCategory'],
                        ),
                        const SizedBox(height: 14),
                        _buildStatRow(
                          icon: Icons.update_rounded,
                          label: 'آخر نشاط',
                          value: _formatDate(stats['lastActive'] as DateTime?),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  child: const Padding(
                    padding: EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'سجل التقدم السحابي',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'يمكنك متابعة تقدمك في الاختبارات وحفظه في السحابة للعودة إليه لاحقاً.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.teal, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
