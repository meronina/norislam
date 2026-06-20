import 'package:flutter/material.dart';
import '../services/question_service.dart';
import '../services/progress_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = ThemeService.instance.themeMode == ThemeMode.dark;
  bool _isProcessing = false;

  void _toggleTheme(bool value) {
    ThemeService.instance.toggleTheme();
    setState(() => _isDarkMode = value);
  }

  Future<void> _clearProgress() async {
    setState(() => _isProcessing = true);
    await ProgressService.instance.clearSavedProgress();
    setState(() => _isProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف التقدم المحفوظ.')),
      );
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isProcessing = true);
    QuestionService.instance.clearCache();
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() => _isProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنظيف ذاكرة التخزين المؤقت للأسئلة.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              value: _isDarkMode,
              onChanged: (value) => _toggleTheme(value),
              title: const Text('الوضع الليلي'),
              subtitle: const Text('تبديل بين الوضع الفاتح والداكن'),
              secondary: const Icon(Icons.dark_mode_rounded),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_rounded,
                    color: Colors.redAccent),
                title: const Text('مسح التقدم المحفوظ'),
                subtitle:
                    const Text('يحذف بيانات الاستمرار في الاختبار الحالي.'),
                trailing: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                        onPressed: _clearProgress,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.cleaning_services_rounded,
                    color: Colors.teal),
                title: const Text('تنظيف ذاكرة الأسئلة'),
                subtitle: const Text(
                    'يرجع التطبيق إلى جلب الأسئلة من المصدر مرة أخرى.'),
                trailing: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                        onPressed: _clearCache,
                      ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'حول التطبيق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'تطبيق أسئلة دينية يقدم اختبارات تفاعلية مع تتبع التقدم والتاريخ.',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
