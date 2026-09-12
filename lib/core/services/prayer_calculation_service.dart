import 'package:adhan/adhan.dart';
import '../../features/prayer/models/prayer_schedule_item.dart';
import 'timezone_service.dart';

class PrayerScheduleResult {
  final List<PrayerScheduleItem> prayers;
  final String nextPrayerName;
  final String nextPrayerArabic;
  final DateTime nextPrayerTime;
  final String calculationMethodName;
  final double qiblaBearing;

  const PrayerScheduleResult({
    required this.prayers,
    required this.nextPrayerName,
    required this.nextPrayerArabic,
    required this.nextPrayerTime,
    required this.calculationMethodName,
    required this.qiblaBearing,
  });
}

class PrayerCalculationService {
  final TimezoneService _timezoneService;

  PrayerCalculationService({TimezoneService? timezoneService})
    : _timezoneService = timezoneService ?? TimezoneService();

  /// Map country codes to appropriate CalculationMethod and human-readable label
  (CalculationMethod method, String label) resolveCalculationMethod(
    String countryCode,
    double latitude,
    double longitude,
  ) {
    final code = countryCode.trim().toUpperCase();

    // Explicit country code matching
    switch (code) {
      case 'ID':
        return (CalculationMethod.singapore, 'MABIMS (Kemenag)');
      case 'SA':
        return (CalculationMethod.umm_al_qura, 'Umm Al-Qura');
      case 'PK':
      case 'BD':
      case 'IN':
      case 'AF':
        return (CalculationMethod.karachi, 'Karachi');
      case 'EG':
      case 'SD':
      case 'LY':
        return (CalculationMethod.egyptian, 'Egyptian General Authority');
      case 'TR':
        return (CalculationMethod.turkey, 'Diyanet');
      case 'US':
      case 'CA':
        return (CalculationMethod.north_america, 'ISNA (North America)');
      case 'MY':
      case 'SG':
      case 'BN':
        return (CalculationMethod.singapore, 'MABIMS (Singapura/Malaysia)');
      case 'AE':
      case 'OM':
      case 'BH':
        return (CalculationMethod.dubai, 'Gulf / Dubai');
      case 'KW':
        return (CalculationMethod.kuwait, 'Kuwait');
      case 'QA':
        return (CalculationMethod.qatar, 'Qatar');
      case 'IR':
        return (CalculationMethod.tehran, 'Tehran');
    }

    // Geolocation fallback if country code is blank or unknown
    if (latitude >= 16 &&
        latitude <= 32 &&
        longitude >= 34 &&
        longitude <= 55) {
      return (CalculationMethod.umm_al_qura, 'Umm Al-Qura');
    }
    if (latitude >= -11 &&
        latitude <= 6 &&
        longitude >= 95 &&
        longitude <= 141) {
      return (CalculationMethod.singapore, 'MABIMS (Kemenag)');
    }

    // Default global method
    return (CalculationMethod.muslim_world_league, 'Muslim World League');
  }

  /// Calculate accurate Qibla bearing from current coordinates
  double calculateQibla(double latitude, double longitude) {
    final coordinates = Coordinates(latitude, longitude);
    return Qibla(coordinates).direction;
  }

  /// Single source of truth for calculating prayer times schedule
  PrayerScheduleResult calculatePrayerSchedule({
    required double latitude,
    required double longitude,
    required String countryCode,
    required String timezoneId,
    DateTime? date,
    Madhab madhab = Madhab.shafi,
  }) {
    final now = date ?? DateTime.now();
    final coordinates = Coordinates(latitude, longitude);

    final (calcMethod, methodName) = resolveCalculationMethod(
      countryCode,
      latitude,
      longitude,
    );

    final params = calcMethod.getParameters();
    params.madhab = madhab;

    final dateComponents = DateComponents.from(now);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    final qiblaAngle = Qibla(coordinates).direction;

    final rawList = [
      ('Subuh', 'الفجر', prayerTimes.fajr),
      ('Terbit', 'الشروق', prayerTimes.sunrise),
      ('Dzuhur', 'الظهر', prayerTimes.dhuhr),
      ('Ashar', 'العصر', prayerTimes.asr),
      ('Maghrib', 'المغرب', prayerTimes.maghrib),
      ('Isya', 'العشاء', prayerTimes.isha),
    ];

    // Find next prayer today
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

    // If all prayers today passed, next prayer is tomorrow's Fajr
    if (targetNextTime == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowPrayers = PrayerTimes(
        coordinates,
        DateComponents.from(tomorrow),
        params,
      );
      targetNextName = 'Subuh';
      targetNextArabic = 'الفجر';
      targetNextTime = tomorrowPrayers.fajr;
    }

    // Map prayer items
    final prayers = rawList.map((p) {
      final isNext = p.$1 == targetNextName;
      final formatted = _timezoneService.formatTime(
        p.$3,
        timezoneId: timezoneId,
        includeTimeZone: true,
      );

      return PrayerScheduleItem(
        name: p.$1,
        arabicName: p.$2,
        time: p.$3,
        formattedTime: formatted,
        isNext: isNext,
      );
    }).toList();

    return PrayerScheduleResult(
      prayers: prayers,
      nextPrayerName: targetNextName,
      nextPrayerArabic: targetNextArabic,
      nextPrayerTime: targetNextTime,
      calculationMethodName: methodName,
      qiblaBearing: qiblaAngle,
    );
  }
}
