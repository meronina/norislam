import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // 🟢 تم إضافة هذا الاستيراد لاستخدام debugPrint
import 'package:intl/intl.dart';

class PrayerService {
  static final PrayerService instance = PrayerService._internal();
  PrayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _prayerCheckTimer;

  dynamic prayerTimes;
  String nextPrayerName = "جاري التحميل...";

  // متغير لمتابعة حالة الأذان الحالية وإمكانية الاستماع له من الواجهة
  bool isAzanPlaying = false;
  Function(bool)? onAzanStateChanged;

  // متغير لمنع تكرار تشغيل الأذان أكثر من مرة في نفس الدقيقة
  String _lastTriggeredMinute = "";

  Future<void> playAzan() async {
    try {
      await _audioPlayer.play(AssetSource('audio/azan.mp3'));
      isAzanPlaying = true;
      if (onAzanStateChanged != null) onAzanStateChanged!(true);
      // ✅ تم استبدال print بـ debugPrint لحل التحذير الأول
      debugPrint("تم بدء تشغيل الأذان بنجاح");
    } catch (e) {
      // ✅ تم استبدال print بـ debugPrint لحل التحذير الثاني
      debugPrint("خطأ في تشغيل صوت الأذان: $e");
    }
  }

  Future<void> stopAzan() async {
    try {
      await _audioPlayer.stop();
      isAzanPlaying = false;
      if (onAzanStateChanged != null) onAzanStateChanged!(false);
      // ✅ تم استبدال print بـ debugPrint لحل التحذير الثالث
      debugPrint("تم إيقاف الأذان يدوياً");
    } catch (e) {
      // ✅ تم استبدال print بـ debugPrint لحل التحذير الرابع
      debugPrint("خطأ في إيقاف الأذان: $e");
    }
  }

  Future<void> loadPrayerTimes() async {
    // كود جلب المواقيت الخاص بك هنا...
    startPrayerClockCheck();
  }

  void startPrayerClockCheck() {
    _prayerCheckTimer?.cancel();
    _prayerCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (prayerTimes == null) return;

      String currentTime = DateFormat('HH:mm').format(DateTime.now());

      // إذا تم تشغيل الأذان بالفعل في هذه الدقيقة، تخطى الفحص تماماً
      if (_lastTriggeredMinute == currentTime) return;

      String fajrTime = DateFormat('HH:mm').format(prayerTimes.fajr);
      String dhuhrTime = DateFormat('HH:mm').format(prayerTimes.dhuhr);
      String asrTime = DateFormat('HH:mm').format(prayerTimes.asr);
      String maghribTime = DateFormat('HH:mm').format(prayerTimes.maghrib);
      String ishaTime = DateFormat('HH:mm').format(prayerTimes.isha);

      if (currentTime == fajrTime ||
          currentTime == dhuhrTime ||
          currentTime == asrTime ||
          currentTime == maghribTime ||
          currentTime == ishaTime) {
        if (!isAzanPlaying) {
          _lastTriggeredMinute =
              currentTime; // تسجيل الدقيقة الحالية لمنع التكرار
          playAzan();
        }
      }
    });
  }

  String formatTime(dynamic time) => DateFormat('hh:mm a').format(time);
  String formatCountdown() => "00:00:00";

  void dispose() {
    _prayerCheckTimer?.cancel();
    _audioPlayer.dispose();
  }
}
