import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'azkar_screen.dart';
import 'category_questions_screen.dart';
import 'settings_screen.dart';
import 'prayer_times_screen.dart';
import 'login_screen.dart';
import 'qibla_screen.dart'; // 🟢 تم إضافة استيراد شاشة القبلة هنا

import '../services/auth_service.dart';
import '../services/high_score_service.dart';
import '../services/question_service.dart';
import '../services/prayer_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<String> _categories = [];
  bool _loading = true;

  final HighScoreService _highScoreService = HighScoreService();
  final AuthService _authService = AuthService();
  final PrayerService _prayerService = PrayerService.instance;

  final Map<String, String> _highScores = {};

  final Map<String, IconData> _categoryIcons = {
    'العقيدة الإسلامية': Icons.school_rounded,
    'الفقه': Icons.water_drop_rounded,
    'السيرة النبوية': Icons.person_4_rounded,
    'القرآن الكريم': Icons.menu_book_rounded,
    'الحديث النبوي': Icons.format_quote_rounded,
    'التاريخ الإسلامي': Icons.history_edu_rounded,
    'أسباب النزول': Icons.history_edu_rounded,
    'الأخلاق والآداب': Icons.face_rounded,
  };

  final Map<String, Color> _categoryColors = {
    'العقيدة الإسلامية': const Color(0xFF1E88E5),
    'الفقه': const Color(0xFF43A047),
    'السيرة النبوية': const Color(0xFF3949AB),
    'القرآن الكريم': const Color(0xFF8E24AA),
    'الحديث النبوي': const Color(0xFF6A1B9A),
    'التاريخ الإسلامي': const Color(0xFFEF6C00),
    'أسباب النزول': const Color(0xFF6A1B9A),
    'الأخلاق والآداب': const Color(0xFF00796B),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPrayerTimes();

    _prayerService.onAzanStateChanged = (isPlaying) {
      if (mounted) setState(() {});
    };
  }

  List<Widget> _getScreens() {
    return [
      _buildHomeContent(), // 0: الرئيسية
      const Center(
        child: Text(
          'قسم القرآن - قيد التطوير',
          style: TextStyle(fontSize: 20),
        ),
      ),
      const PrayerTimesScreen(), // 2: مواقيت الصلاة
      const AzkarScreen(), // 3: شاشة الأذكار
      const QiblaScreen(), // 🟢 4: تم استبدال النص بـ شاشة القبلة الحقيقية الآن
    ];
  }

  Future<void> _loadPrayerTimes() async {
    await _prayerService.loadPrayerTimes();
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cats = await QuestionService.instance.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
        });
        _loadHighScores(cats);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadHighScores(List<String> categories) async {
    for (var cat in categories) {
      final high = await _highScoreService.getHighScoreText(cat);
      if (mounted) {
        setState(() => _highScores[cat] = high);
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMiniPrayerCard(),
          const SizedBox(height: 24),
          const Text(
            'اختر الفئة',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('لا توجد فئات متاحة حالياً')),
            )
          else
            AnimationLimiter(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1.08,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final icon =
                      _categoryIcons[category] ?? Icons.category_rounded;
                  final color = _categoryColors[category] ?? Colors.teal;

                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 600),
                    columnCount: 2,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: Material(
                          borderRadius: BorderRadius.circular(26),
                          elevation: 10,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(26),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryQuestionsScreen(
                                  category: category,
                                ),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    // ✅ تم استبدال .withOpacity بـ .withValues لحل التحذير
                                    color.withValues(alpha: 0.9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(icon, size: 52, color: Colors.white),
                                  const SizedBox(height: 14),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      category,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniPrayerCard() {
    final prayer = _prayerService.prayerTimes;
    if (prayer == null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _prayerService.nextPrayerName,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    _prayerService.formatTime(prayer.dhuhr),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.access_time_rounded,
                  color: Colors.white, size: 50),
            ],
          ),
          const Divider(color: Colors.white38, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'متبقي: ${_prayerService.formatCountdown()}',
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _currentIndex = 2),
                icon: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 18),
                label: const Text(
                  'التفاصيل',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screens = _getScreens();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _currentIndex == 0
              ? 'أسئلة دينية'
              : _currentIndex == 2
                  ? 'أوقات الصلاة'
                  : _currentIndex == 3
                      ? 'الأذكار'
                      : 'الرئيسية',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
          ),
        ],
      ),
      body: screens[_currentIndex],
      floatingActionButton: _prayerService.isAzanPlaying
          ? FloatingActionButton.extended(
              onPressed: () async {
                await _prayerService.stopAzan();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إيقاف صوت الأذان',
                        textAlign: TextAlign.center),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              backgroundColor: Colors.red[700],
              icon: const Icon(Icons.volume_off_rounded, color: Colors.white),
              label: const Text('إيقاف الأذان',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ).animate().scale()
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        elevation: 20,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'القرآن',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_rounded),
            label: 'الصلاة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'الأذكار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'القبلة',
          ),
        ],
      ),
    );
  }
}
