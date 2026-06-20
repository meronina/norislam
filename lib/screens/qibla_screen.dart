import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _qiblaDirectionFromGps;
  bool _checkingGps = true;
  String _gpsStatusMessage = 'جاري تحديد موقعك الجغرافي لحساب القبلة...';

  // إحداثيات الكعبة المشرفة الثابتة
  final double _kaabaLat = 21.4225;
  final double _kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _determinePositionAndCalculateQibla();
  }

  // دالة فحص الصلاحيات وحساب زاوية القبلة عبر الـ GPS
  Future<void> _determinePositionAndCalculateQibla() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsStatusMessage = 'الرجاء تفعيل خدمات الموقع (GPS) في الهاتف.';
          _checkingGps = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsStatusMessage = 'تم رفض صلاحية الوصول للموقع الجغرافي.';
            _checkingGps = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsStatusMessage = 'صلاحية الموقع مرفوضة دائماً، يرجى تفعيلها من الإعدادات.';
          _checkingGps = false;
        });
        return;
      }

      // جلب الموقع الحالي للمستخدم
      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      // حساب زاوية القبلة رياضياً (Bearing)
      double qiblaAngle = _calculateBearing(
        position.latitude,
        position.longitude,
        _kaabaLat,
        _kaabaLng,
      );

      setState(() {
        _qiblaDirectionFromGps = qiblaAngle;
        _checkingGps = false;
      });
    } catch (e) {
      setState(() {
        _gpsStatusMessage = 'حدث خطأ أثناء جلب إحداثيات الموقع.';
        _checkingGps = false;
      });
    }
  }

  // الخوارزمية الرياضية لحساب الاتجاه المباشر نحو مكة (Bearing)
  double _calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    double startLatRad = startLat * (math.pi / 180);
    double startLngRad = startLng * (math.pi / 180);
    double endLatRad = endLat * (math.pi / 180);
    double endLngRad = endLng * (math.pi / 180);

    double dLng = endLngRad - startLngRad;

    double y = math.sin(dLng) * math.cos(endLatRad);
    double x = math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);

    double bearing = math.atan2(y, x);
    bearing = bearing * (180 / math.pi);
    return (bearing + 360) % 360; // تحويل النتيجة لزاوية بين 0 و 360
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اتجاه القبلة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _checkingGps
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 20),
                  Text(
                    _gpsStatusMessage,
                    style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : StreamBuilder<CompassEvent>(
              stream: FlutterCompass.events,
              builder: (context, snapshot) {
                // القيمة الافتراضية للزاوية إذا غاب مستشعر البوصلة (تعتمد على حسابات الـ GPS مباشرة)
                double finalDirection = 0.0;
                double offsetAngle = _qiblaDirectionFromGps ?? 45.0; // 45 كقيمة احتياطية

                // إذا كان الجهاز يدعم مستشعر البوصلة فيزيائياً ويقهر الحركة
                if (snapshot.hasData && snapshot.data!.heading != null) {
                  finalDirection = snapshot.data!.heading!;
                }

                // معادلة الدوران المدمجة (البوصلة تدير السهم، والـ GPS يحدد انحراف مكة بدقة لموقعك الحالي)
                double rotationAngle = ((finalDirection - offsetAngle) * (math.pi / 180)) * -1;

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green.shade700, width: 12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/kaaba.png',
                              width: 80,
                              height: 80,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.mosque, size: 60, color: Colors.green);
                              },
                            ),
                            Transform.rotate(
                              angle: rotationAngle,
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                size: 140,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        _qiblaDirectionFromGps != null
                            ? 'زاوية مكة المكرمة: ${_qiblaDirectionFromGps!.toStringAsFixed(1)}°'
                            : 'جاري الحساب...',
                        style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          snapshot.data?.heading == null
                              ? '⚠️ جهازك لا يدعم المستشعر الداخلي، يرجى توجيه أعلى الهاتف يدوياً نحو الزاوية أعلاه مقارنة بالشمال.'
                              : 'تم الدمج بنجاح بين نظام الموقع ومستشعر الهاتف.',
                          style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}