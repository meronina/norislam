import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 💡 مثال توضيحي لدالة إظهار إشعار فوري متوافق مع الإصدار 21+
  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'prayer_channels',
      'مواقيت الصلاة',
      channelDescription: 'تنبيهات مواقيت الصلاة والأذكار',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // ✅ تم إصلاح الخطأ: تحويل البرامترات إلى Named Parameters
    await flutterLocalNotificationsPlugin.show(
      id: 1,
      title: 'تنبيه الأذكار',
      body: 'لا تنسى قراءة أذكار المساء',
      notificationDetails: notificationDetails,
    );
  }

  // 💡 دالة جدولة الإشعارات للمواقيت متوافقة مع الإصدار 21+
  Future<void> schedulePrayerNotification(
      int id, String prayerName, tz.TZDateTime tzDateTime) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'prayer_channels',
      'مواقيت الصلاة',
      channelDescription: 'تنبيهات مواقيت الصلاة والأذكار',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // ✅ تم إصلاح الخطأ: تحويل البرامترات إلى Named وحذف uiLocalNotificationDateInterpretation الملغية
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: 'صلاة $prayerName',
      body: 'حان الآن موعد أذان $prayerName',
      scheduledDate: tzDateTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // 💡 دالة جلب الموقع الحالي للمستخدم
  Future<void> getUserLocation() async {
    // ✅ تم إصلاح التحذير: استخدام locationSettings بدلاً من desiredAccuracy المحذوفة
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    debugPrint('Location: ${position.latitude}, ${position.longitude}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مواقيت الصلاة')),
      body: Container(
        // ✅ تم إصلاح التحذير: استخدام withValues بدلاً من withOpacity
        color: Colors.blue.withValues(alpha: 0.1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                // ✅ تم إصلاح التحذير: استخدام withValues بدلاً من withOpacity
                color: Colors.white.withValues(alpha: 0.9),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child:
                      Text('الفجر - 04:30 ص', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
