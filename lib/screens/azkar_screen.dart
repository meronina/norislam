import 'package:flutter/material.dart';
import 'package:religious_qa_app/data/models/azkar_model.dart';
class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // الاحتفاظ بالحالة الحالية للعدادات لكل قسم
  final Map<int, int> _sabahCounters = {};
  final Map<int, int> _masaaCounters = {};
  final Map<int, int> _prayerCounters = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _resetCounters();
  }

  void _resetCounters() {
    for (int i = 0; i < AzkarData.sabah.length; i++) {
      _sabahCounters[i] = AzkarData.sabah[i].count;
    }
    for (int i = 0; i < AzkarData.masaa.length; i++) {
      _masaaCounters[i] = AzkarData.masaa[i].count;
    }
    for (int i = 0; i < AzkarData.afterPrayer.length; i++) {
      _prayerCounters[i] = AzkarData.afterPrayer[i].count;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار الصحيحة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF43A047),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'أذكار الصباح'),
            Tab(text: 'أذكار المساء'),
            Tab(text: 'بعد الصلاة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildZikrList(AzkarData.sabah, _sabahCounters, isDark),
          _buildZikrList(AzkarData.masaa, _masaaCounters, isDark),
          _buildZikrList(AzkarData.afterPrayer, _prayerCounters, isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _resetCounters()),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        label: const Text('إعادة تعيين العدادات',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildZikrList(
      List<ZikrItem> items, Map<int, int> counters, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final currentCount = counters[index] ?? item.count;
        final isCompleted = currentCount == 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isCompleted
                ? (isDark ? const Color(0xFF1B3D20) : const Color(0xFFE8F5E9))
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted ? const Color(0xFF43A047) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: isCompleted
                  ? null
                  : () {
                      setState(() {
                        if (counters[index]! > 0) {
                          counters[index] = counters[index]! - 1;
                        }
                      });
                    },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.text,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (item.fadl.isNotEmpty) ...[
                      Text(
                        item.fadl,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF43A047)
                                : const Color(0xFF0F4C81),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            isCompleted
                                ? '✓ تم الاكتمال'
                                : 'التكرار المتبقي: $currentCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
