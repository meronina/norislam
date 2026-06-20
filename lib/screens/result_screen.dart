import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import '../services/score_service.dart';
import '../services/level_service.dart';
import 'home_screen.dart';
import 'quiz_screen.dart' as quiz;

class ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final String category;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.category,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ScoreService _scoreService = ScoreService.instance;
  late ConfettiController _confettiController;

  late double _percentage;
  String _highScoreText = 'جاري التحميل...';
  Map<String, dynamic> _highScoreDetails = {};

  @override
  void initState() {
    super.initState();
    _percentage = widget.total > 0 ? (widget.score / widget.total) * 100 : 0;
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _initializeResult();
    if (_percentage >= 70) _confettiController.play();
  }

  Future<void> _initializeResult() async {
    final currentLevel =
        await LevelService.instance.getCurrentDifficultyLevel();

    // إصلاح الخطأ: تحويل المستوى إلى String لتجنب تعارض الأنواع (argument_type_not_assignable)
    await _scoreService.saveScore(
      category: widget.category,
      score: widget.score,
      total: widget.total,
      difficultyLevel: currentLevel.toString(),
    );

    // جلب أعلى نتيجة + تفاصيلها
    final highText = await _scoreService.getHighScoreText(widget.category);
    final details = await _scoreService.getHighScoreDetails(widget.category);

    if (mounted) {
      setState(() {
        _highScoreText = highText;
        _highScoreDetails = details;
      });
    }
  }

  String _getResultMessage() {
    if (_percentage >= 90) return 'أداء أسطوري! بارك الله فيك 🎉';
    if (_percentage >= 75) return 'ممتاز! أنت على الطريق الصحيح';
    if (_percentage >= 60) return 'جيد جداً، استمر';
    return 'لا بأس، المحاولة القادمة ستكون أفضل 💪';
  }

  Color _getResultColor() {
    if (_percentage >= 85) return Colors.green;
    if (_percentage >= 65) return Colors.orange;
    return Colors.redAccent;
  }

  Future<void> _shareResult() async {
    final message = '''
🏆 نتيجتي في ${widget.category}

${widget.score} / ${widget.total} (${_percentage.toStringAsFixed(1)}%)

${_getResultMessage()}

أعلى نتيجة: $_highScoreText

جرب التطبيق: أسئلة دينية إسلامية
    '''
        .trim();

    await SharePlus.instance.share(ShareParams(text: message));
  }

  @override
  Widget build(BuildContext context) {
    final color = _getResultColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('نتيجة الاختبار'),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // تحديث دالة الشفافية لمنع تحذيرات الـ deprecation
                  color.withValues(alpha: 0.15),
                  Colors.white,
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Trophy Icon
                  Icon(
                    _percentage >= 70 ? Icons.emoji_events : Icons.school,
                    size: 110,
                    color: color,
                  )
                      .animate()
                      .scale(duration: 800.ms, curve: Curves.elasticOut)
                      .then()
                      .shimmer(duration: 1500.ms),

                  const SizedBox(height: 20),

                  // Result Message
                  Text(
                    _getResultMessage(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms),

                  const SizedBox(height: 30),

                  // Circular Progress
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: _percentage / 100,
                          strokeWidth: 18,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 58,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            '${widget.score}/${widget.total}',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ).animate().scale(duration: 800.ms),

                  const SizedBox(height: 40),

                  // ================= High Score Cards =================
                  const Text(
                    'أعلى النتائج',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Main High Score Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('أعلى نتيجة مسجلة',
                                    style: TextStyle(fontSize: 15)),
                                Text(
                                  _highScoreText,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Additional High Score Details Cards
                  if (_highScoreDetails.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallScoreCard(
                            title: 'أفضل محاولة',
                            value:
                                '${_highScoreDetails['bestScore'] ?? 0}/${widget.total}',
                            icon: Icons.leaderboard,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSmallScoreCard(
                            title: 'النسبة',
                            value:
                                '${_highScoreDetails['bestPercentage'] ?? 0}%',
                            icon: Icons.percent,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 50),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => quiz.QuizScreen(
                                category: widget.category,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.replay),
                          label: const Text('إعادة الاختبار'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                            (route) => false,
                          ),
                          icon: const Icon(Icons.home),
                          label: const Text('الرئيسية'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _shareResult,
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة النتيجة'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallScoreCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}
