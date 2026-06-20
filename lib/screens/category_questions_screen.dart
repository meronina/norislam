import 'package:flutter/material.dart';
import '../data/models/question_model.dart';
import '../services/progress_service.dart';
import '../services/question_service.dart';
import 'quiz_screen.dart';

class CategoryQuestionsScreen extends StatefulWidget {
  final String category;

  const CategoryQuestionsScreen({super.key, required this.category});

  @override
  State<CategoryQuestionsScreen> createState() =>
      _CategoryQuestionsScreenState();
}

class _CategoryQuestionsScreenState extends State<CategoryQuestionsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Question> _questions = [];
  Map<String, dynamic>? _savedProgress;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadSavedProgress();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final questions = await QuestionService.instance
          .getQuestionsByCategory(widget.category);
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSavedProgress() async {
    final saved = await ProgressService.instance
        .getSavedProgressForCategory(widget.category);
    if (mounted) {
      setState(() {
        _savedProgress = saved;
      });
    }
  }

  void _startQuiz({bool resume = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          category: widget.category,
          resumeIndex:
              resume ? (_savedProgress?['currentIndex'] as int? ?? 0) : 0,
          resumeScore: resume ? (_savedProgress?['score'] as int? ?? 0) : 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 80, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('حدث خطأ أثناء تحميل الأسئلة:\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadQuestions,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.quiz_outlined,
                                size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('لا توجد أسئلة في هذه الفئة حتى الآن',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadQuestions,
                              icon: const Icon(Icons.refresh),
                              label: const Text('تحديث'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('جاهز للتحدي؟',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'اكتشف اختبار "${widget.category}" بأجواء تفاعلية وسريعة. لا نعرض قائمة الأسئلة مسبقًا حتى تظل التجربة مفاجئة وممتعة.',
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.category,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  Text('عدد الأسئلة: ${_questions.length}',
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'مستوى صعوبة متدرج لتحدي ذكي وتعلم أسرع.',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_savedProgress != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 18.0),
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'استمر من حيث توقفت',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'الفئة: ${widget.category}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      Text(
                                        'السؤال ${(_savedProgress?['currentIndex'] as int? ?? 0) + 1} من ${_savedProgress?['total'] ?? _questions.length}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _startQuiz(resume: true),
                                        icon: const Icon(Icons.replay_rounded),
                                        label:
                                            const Text('تابع الاختبار السابق'),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildInfoChip(Icons.flash_on, 'سريع ومكثف'),
                              _buildInfoChip(
                                  Icons.auto_stories, 'تعلم أثناء اللعب'),
                              _buildInfoChip(
                                  Icons.verified, 'أسئلة دقيقة ومناسبة'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: ListView(
                              children: [
                                _buildFeatureCard(
                                  icon: Icons.visibility_off,
                                  title: 'لن نعرض الأسئلة الآن',
                                  subtitle:
                                      'ستبدأ الإجابة أولًا ثم تكشف كل سؤال في وقته.',
                                ),
                                const SizedBox(height: 14),
                                _buildFeatureCard(
                                  icon: Icons.star,
                                  title: 'تحدّيً جديد كل مرة',
                                  subtitle:
                                      'اختبارك يستند إلى مجموعة أسئلة من الفئة دون تسريب محتواها.',
                                ),
                                const SizedBox(height: 14),
                                _buildFeatureCard(
                                  icon: Icons.smart_toy,
                                  title: 'بداية جذابة',
                                  subtitle:
                                      'اضغط ابدأ لتدخل تجربة منافسة مشوقة مع فورمة رائعة.',
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _startQuiz,
                                style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16))),
                                child: const Text('ابدأ الاختبار',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ✅ تم استبدال .withOpacity بـ .withValues لدعم إصدارات فلوتر الحديثة
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            // ✅ تم استبدال .withOpacity بـ .withValues
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.12),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
