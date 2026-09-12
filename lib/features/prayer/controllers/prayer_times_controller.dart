import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
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
  // Location & Coordinates (Default to Masjidil Haram, Makkah)
  static const double defaultLat = 21.4225;
  static const double defaultLng = 39.8262;

  double currentLat = defaultLat;
  double currentLng = defaultLng;
  String locationName = 'Makkah Al-Mukarramah';
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
    final hijri = HijriCalendar.now();
    // Month names in Indonesian/standard
    const monthNames = [
      '',
      'Muharram',
      'Safar',
      'Rabiul Awwal',
      'Rabiul Akhir',
      'Jumadil Awwal',
      'Jumadil Akhir',
      'Rajab',
      'Sya\'ban',
      'Ramadhan',
      'Syawwal',
      'Dzulqa\'dah',
      'Dzulhijjah'
    ];
    final monthName = (hijri.hMonth >= 1 && hijri.hMonth <= 12)
        ? monthNames[hijri.hMonth]
        : hijri.longMonthName;
    hijriDateText = '${hijri.hDay} $monthName ${hijri.hYear} H';
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

          // Check if user is near Makkah/Madinah
          final distToMakkah = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            defaultLat,
            defaultLng,
          );

          if (distToMakkah < 50000) {
            locationName = 'Makkah Al-Mukarramah';
          } else {
            locationName = 'GPS (${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°)';
          }
        }
      }
    } catch (_) {
      // Gracefully fall back to Makkah default
    }

    calculatePrayers();
  }

  void calculatePrayers() {
    final coordinates = Coordinates(currentLat, currentLng);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;

    final dateComponents = DateComponents.from(DateTime.now());
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    // Calculate exact Qibla direction for this coordinate
    qiblaBearing = Qibla(coordinates).direction;

    final now = DateTime.now();

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
    nextPrayerTime = '${_formatTime(targetNextTime)} AST';

    // Build the observable list
    prayers = rawList.map((p) {
      final isNext = p.$1 == targetNextName;
      return PrayerScheduleItem(
        name: p.$1,
        arabicName: p.$2,
        time: p.$3,
        formattedTime: _formatTime(p.$3),
        isNext: isNext,
      );
    }).toList();
    
    notifyListeners();
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
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
    final params = CalculationMethod.umm_al_qura.getParameters();
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
