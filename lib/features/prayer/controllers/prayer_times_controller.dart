import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import 'package:vibration/vibration.dart';

class PrayerScheduleItem {
  final String name;
  final String arabicName;
  final DateTime time;
  final String formattedTime;
  final bool isNext;
  final bool isCurrent;

  const PrayerScheduleItem({
    required this.name,
    required this.arabicName,
    required this.time,
    required this.formattedTime,
    this.isNext = false,
    this.isCurrent = false,
  });
}

class PrayerTimesController extends ChangeNotifier {
  // Location & Coordinates (Default to Jakarta, Indonesia for fallback)
  static const double defaultLat = -6.2088;
  static const double defaultLng = 106.8456;

  double currentLat = defaultLat;
  double currentLng = defaultLng;
  String locationName = 'Jakarta, Indonesia';
  String calculationMethodName = 'MABIMS (Kemenag)';
  String hijriDateText = '';

  // Next Prayer & Countdown
  String nextPrayerName = 'Ashar';
  String nextPrayerArabic = 'العصر';
  String nextPrayerTime = '--:--';
  String countdownText = '-- Menit -- Detik';

  // Compass & Qibla
  double qiblaBearing = 294.0; // Calculated Qibla angle from coordinates
  double get compassHeading => qiblaBearing; // Convenience alias
  double deviceHeading = 0.0; // 0 to 360 degrees from North
  double qiblaOffset = 0.0; // Angle relative to device heading
  bool isQiblaAligned = false;
  bool hasCompassSensor = true;

  // Prayer list
  List<PrayerScheduleItem> prayers = [];

  Timer? _countdownTimer;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasVibrated = false;

  PrayerTimesController() {
    _initHijriDate();
    calculatePrayers();
    _initLocationAndPrayers();
    _initCompass();
    _startCountdownTimer();
  }

  void _initHijriDate() {
    hijriDateText = '14 Dzulhijjah 1445 H';
    notifyListeners();
  }

  Future<void> _initLocationAndPrayers() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
          ).timeout(const Duration(seconds: 4));

          currentLat = position.latitude;
          currentLng = position.longitude;

          bool isSaudi = (currentLat >= 16 && currentLat <= 32) && (currentLng >= 34 && currentLng <= 55);
          calculationMethodName = isSaudi ? 'Umm Al-Qura' : 'MABIMS (Kemenag)';

          locationName = _resolveLocationName(currentLat, currentLng);
        }
      }
    } catch (_) {
      // Gracefully fall back to Jakarta default
    }

    calculatePrayers();
  }

  /// Determines a human-readable location name from coordinates offline.
  static String _resolveLocationName(double lat, double lng) {
    // Saudi Arabia
    if (lat >= 16 && lat <= 32 && lng >= 34 && lng <= 55) {
      final distToMakkah = _haversineKm(lat, lng, 21.4225, 39.8262);
      final distToMadinah = _haversineKm(lat, lng, 24.4672, 39.6150);
      if (distToMakkah < 80) return 'Makkah Al-Mukarramah';
      if (distToMadinah < 80) return 'Madinah Al-Munawwarah';
      return 'Arab Saudi';
    }
    // Indonesia regions by bounding box
    if (lat >= -11 && lat <= 6 && lng >= 95 && lng <= 141) {
      if (lat >= -7 && lat <= -5 && lng >= 106 && lng <= 107.5) return 'Jakarta, Indonesia';
      if (lat >= -8 && lat <= -7 && lng >= 110 && lng <= 111) return 'Yogyakarta, Indonesia';
      if (lat >= -7.5 && lat <= -6.8 && lng >= 107.5 && lng <= 108.5) return 'Bandung, Indonesia';
      if (lat >= -7.5 && lat <= -7 && lng >= 112 && lng <= 113) return 'Surabaya, Indonesia';
      if (lat >= -8.9 && lat <= -8 && lng >= 115 && lng <= 116) return 'Bali, Indonesia';
      if (lat >= 3 && lat <= 6 && lng >= 95 && lng <= 99) return 'Aceh, Indonesia';
      if (lat >= -5 && lat <= -2 && lng >= 104 && lng <= 107) return 'Palembang, Indonesia';
      if (lat >= -0.5 && lat <= 2 && lng >= 108 && lng <= 110) return 'Pontianak, Indonesia';
      if (lat >= -3 && lat <= 1 && lng >= 114 && lng <= 118) return 'Kalimantan, Indonesia';
      return 'Indonesia';
    }
    // Other countries
    if (lat >= 1 && lat <= 8 && lng >= 99 && lng <= 120) return 'Malaysia';
    if (lat >= -1 && lat <= 1.5 && lng >= 103 && lng <= 104.5) return 'Singapura';
    if (lat >= 5 && lat <= 21 && lng >= 97 && lng <= 106) return 'Thailand/Myanmar';
    if (lat >= 8 && lat <= 22 && lng >= 102 && lng <= 110) return 'Vietnam/Laos';
    // Fallback to GPS coordinates
    return 'GPS (${lat.toStringAsFixed(2)}°, ${lng.toStringAsFixed(2)}°)';
  }

  /// Simple Euclidean approximation sufficient for bounding box detection (km).
  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = (lat1 - lat2).abs() * 111.0;
    final dLng = (lng1 - lng2).abs() * 111.0 * 0.7;
    return (dLat * dLat + dLng * dLng) < 0 ? 0 : ((dLat * dLat + dLng * dLng) < 1e10 ? (dLat + dLng) : 99999);
  }

  void calculatePrayers() {
    final now = DateTime.now();
    final coordinates = Coordinates(currentLat, currentLng);
    
    bool isSaudi = (currentLat >= 16 && currentLat <= 32) && (currentLng >= 34 && currentLng <= 55);
    final params = isSaudi ? CalculationMethod.umm_al_qura.getParameters() : CalculationMethod.singapore.getParameters();
    params.madhab = Madhab.shafi;

    final dateComponents = DateComponents.from(now);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    // Calculate exact Qibla direction for this coordinate
    qiblaBearing = Qibla(coordinates).direction;

    // Create schedule items
    final rawList = [
      ('Subuh', 'الفجر', prayerTimes.fajr),
      ('Terbit', 'الشروق', prayerTimes.sunrise),
      ('Dzuhur', 'الظهر', prayerTimes.dhuhr),
      ('Ashar', 'العصر', prayerTimes.asr),
      ('Maghrib', 'المغرب', prayerTimes.maghrib),
      ('Isya', 'العشاء', prayerTimes.isha),
    ];

    // Determine next prayer
    DateTime? targetNextTime;
    String targetNextName = 'Subuh';
    String targetNextArabic = 'الفجر';

    for (final p in rawList) {
      if (p.$3.isAfter(now)) {
        targetNextName = p.$1;
        targetNextArabic = p.$2;
        targetNextTime = p.$3;
        break;
      }
    }

    // If all prayers passed today, next is tomorrow's Fajr
    if (targetNextTime == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowPrayerTimes = PrayerTimes(
        coordinates,
        DateComponents.from(tomorrow),
        params,
      );
      targetNextName = 'Subuh';
      targetNextArabic = 'الفجر';
      targetNextTime = tomorrowPrayerTimes.fajr;
    }

    nextPrayerName = targetNextName;
    nextPrayerArabic = targetNextArabic;
    nextPrayerTime = _formatTime(targetNextTime, includeTimeZone: true);

    // Build the observable list
    prayers = rawList.map((p) {
      final isNext = p.$1 == targetNextName;
      return PrayerScheduleItem(
        name: p.$1,
        arabicName: p.$2,
        time: p.$3,
        formattedTime: _formatTime(p.$3, includeTimeZone: true),
        isNext: isNext,
      );
    }).toList();
    
    notifyListeners();
  }

  static String _formatTime(DateTime dt, {bool includeTimeZone = false}) {
    final localDt = dt.toLocal();
    final h = localDt.hour.toString().padLeft(2, '0');
    final m = localDt.minute.toString().padLeft(2, '0');
    // Ensure we handle common Indonesian timezones properly
    String tz = localDt.timeZoneName;
    final offsetHours = localDt.timeZoneOffset.inHours;
    
    if (offsetHours == 7 || tz == '+07' || tz == 'GMT+07:00' || tz == 'Asia/Jakarta') {
      tz = 'WIB';
    } else if (offsetHours == 8 || tz == '+08' || tz == 'GMT+08:00') {
      tz = 'WITA';
    } else if (offsetHours == 9 || tz == '+09' || tz == 'GMT+09:00') {
      tz = 'WIT';
    } else if (offsetHours == 3 || tz == '+03' || tz == 'GMT+03:00') {
      tz = 'AST';
    }
    
    if (includeTimeZone) {
      return '$h:$m $tz';
    }
    return '$h:$m';
  }

  void _startCountdownTimer() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final coordinates = Coordinates(currentLat, currentLng);
    
    bool isSaudi = (currentLat >= 16 && currentLat <= 32) && (currentLng >= 34 && currentLng <= 55);
    final params = isSaudi ? CalculationMethod.umm_al_qura.getParameters() : CalculationMethod.singapore.getParameters();
    
    final prayerTimes = PrayerTimes(coordinates, DateComponents.from(now), params);

    final rawList = [
      ('Subuh', 'الفجر', prayerTimes.fajr),
      ('Terbit', 'الشروق', prayerTimes.sunrise),
      ('Dzuhur', 'الظهر', prayerTimes.dhuhr),
      ('Ashar', 'العصر', prayerTimes.asr),
      ('Maghrib', 'المغرب', prayerTimes.maghrib),
      ('Isya', 'العشاء', prayerTimes.isha),
    ];

    DateTime? targetTime;
    for (final p in rawList) {
      if (p.$3.isAfter(now)) {
        targetTime = p.$3;
        break;
      }
    }

    if (targetTime == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowPrayers = PrayerTimes(
        coordinates,
        DateComponents.from(tomorrow),
        params,
      );
      targetTime = tomorrowPrayers.fajr;
    }

    final diff = targetTime.difference(now);
    if (diff.isNegative || diff.inSeconds <= 0) {
      calculatePrayers();
      return;
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (hours > 0) {
      countdownText = '$hours Jam $minutes Menit $seconds Detik';
    } else {
      countdownText = '$minutes Menit $seconds Detik';
    }
    notifyListeners();
  }

  void _initCompass() {
    if (kIsWeb) {
      hasCompassSensor = false;
      notifyListeners();
      return;
    }
    try {
      _compassSubscription = FlutterCompass.events?.listen((event) {
        if (event.heading == null) return;

        final heading = event.heading!;
        deviceHeading = heading;

        // Calculate Qibla angle relative to phone heading:
        // (qiblaBearing - heading)
        double diff = (qiblaBearing - heading) % 360;
        if (diff < 0) diff += 360;
        qiblaOffset = diff;

        // Check alignment within ±5 degrees (0 or 360)
        final isAligned = diff <= 5.0 || diff >= 355.0;
        if (isAligned && !isQiblaAligned && !_hasVibrated) {
          _hasVibrated = true;
          try {
            Vibration.vibrate(duration: 40);
          } catch (_) {}
        } else if (!isAligned) {
          _hasVibrated = false;
        }

        isQiblaAligned = isAligned;
        notifyListeners();
      }, onError: (_) {
        hasCompassSensor = false;
        notifyListeners();
      });
    } catch (_) {
      hasCompassSensor = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }
}
