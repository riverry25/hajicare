import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/services/prayer_calculation_service.dart';
import 'package:hajicare/core/services/timezone_service.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:hajicare/features/prayer/models/prayer_location_data.dart';
import 'package:hajicare/features/prayer/models/prayer_schedule_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimezoneService Tests', () {
    late TimezoneService tzService;

    setUp(() {
      tzService = TimezoneService();
    });

    test('Resolves Serang, Indonesia to Asia/Jakarta and WIB', () {
      const lat = -6.1200;
      const lng = 106.1500;

      final tzId = tzService.getTimezoneId(lat, lng);
      expect(tzId, equals('Asia/Jakarta'));

      final info = tzService.getTimezoneInfo(lat, lng);
      expect(info.timezoneId, equals('Asia/Jakarta'));
      expect(info.abbreviation, equals('WIB'));

      final formatted = tzService.formatTime(
        DateTime(2026, 6, 15, 12, 45),
        timezoneId: tzId,
        includeTimeZone: true,
      );
      expect(formatted.endsWith('WIB'), isTrue);
    });

    test('Resolves Makkah, Saudi Arabia to Asia/Riyadh and AST', () {
      const lat = 21.4225;
      const lng = 39.8262;

      final tzId = tzService.getTimezoneId(lat, lng);
      expect(tzId, equals('Asia/Riyadh'));

      final info = tzService.getTimezoneInfo(lat, lng);
      expect(info.timezoneId, equals('Asia/Riyadh'));
      expect(info.abbreviation, equals('AST'));

      final formatted = tzService.formatTime(
        DateTime(2026, 6, 15, 8, 21),
        timezoneId: tzId,
        includeTimeZone: true,
      );
      expect(formatted.endsWith('AST'), isTrue);
    });

    test('Resolves Tokyo, Japan to Asia/Tokyo and JST', () {
      const lat = 35.6762;
      const lng = 139.6503;

      final tzId = tzService.getTimezoneId(lat, lng);
      expect(tzId, equals('Asia/Tokyo'));

      final info = tzService.getTimezoneInfo(lat, lng);
      expect(info.timezoneId, equals('Asia/Tokyo'));
      expect(info.abbreviation, equals('JST'));

      final formatted = tzService.formatTime(
        DateTime(2026, 6, 15, 14, 32),
        timezoneId: tzId,
        includeTimeZone: true,
      );
      expect(formatted.endsWith('JST'), isTrue);
    });

    test('Resolves London, UK and handles DST (BST in summer, GMT in winter)', () {
      const lat = 51.5074;
      const lng = -0.1278;

      final tzId = tzService.getTimezoneId(lat, lng);
      expect(tzId, equals('Europe/London'));

      // Summer test (June) -> BST
      final summerInfo = tzService.getTimezoneInfo(lat, lng, dateTime: DateTime(2026, 6, 15));
      expect(summerInfo.abbreviation, equals('BST'));

      // Winter test (January) -> GMT
      final winterInfo = tzService.getTimezoneInfo(lat, lng, dateTime: DateTime(2026, 1, 15));
      expect(winterInfo.abbreviation, equals('GMT'));
    });

    test('Resolves New York, US and handles DST (EDT in summer, EST in winter)', () {
      const lat = 40.7128;
      const lng = -74.0060;

      final tzId = tzService.getTimezoneId(lat, lng);
      expect(tzId, equals('America/New_York'));

      // Summer test (June) -> EDT
      final summerInfo = tzService.getTimezoneInfo(lat, lng, dateTime: DateTime(2026, 6, 15));
      expect(summerInfo.abbreviation, equals('EDT'));

      // Winter test (January) -> EST
      final winterInfo = tzService.getTimezoneInfo(lat, lng, dateTime: DateTime(2026, 1, 15));
      expect(winterInfo.abbreviation, equals('EST'));
    });
  });

  group('PrayerCalculationService Tests', () {
    late PrayerCalculationService prayerService;
    late TimezoneService tzService;

    setUp(() {
      tzService = TimezoneService();
      prayerService = PrayerCalculationService(timezoneService: tzService);
    });

    test('Maps country codes to calculation methods', () {
      // Indonesia
      final (_, idLabel) = prayerService.resolveCalculationMethod('ID', -6.2, 106.8);
      expect(idLabel, contains('MABIMS'));

      // Saudi Arabia
      final (_, saLabel) = prayerService.resolveCalculationMethod('SA', 21.4, 39.8);
      expect(saLabel, equals('Umm Al-Qura'));

      // Pakistan
      final (_, pkLabel) = prayerService.resolveCalculationMethod('PK', 24.8, 67.0);
      expect(pkLabel, equals('Karachi'));

      // Egypt
      final (_, egLabel) = prayerService.resolveCalculationMethod('EG', 30.0, 31.2);
      expect(egLabel, contains('Egyptian'));

      // Turkey
      final (_, trLabel) = prayerService.resolveCalculationMethod('TR', 41.0, 28.9);
      expect(trLabel, equals('Diyanet'));

      // North America
      final (_, usLabel) = prayerService.resolveCalculationMethod('US', 37.7, -122.4);
      expect(usLabel, contains('North America'));
    });

    test('Calculates dynamic Qibla bearing based on coordinates', () {
      // Serang, Indonesia: ~295°
      final serangQibla = prayerService.calculateQibla(-6.12, 106.15);
      expect(serangQibla, greaterThan(290.0));
      expect(serangQibla, lessThan(300.0));

      // Tokyo, Japan: ~293°
      final tokyoQibla = prayerService.calculateQibla(35.6762, 139.6503);
      expect(tokyoQibla, greaterThan(285.0));
      expect(tokyoQibla, lessThan(305.0));
    });

    test('Calculates full prayer schedule for Serang, Indonesia', () {
      final result = prayerService.calculatePrayerSchedule(
        latitude: -6.12,
        longitude: 106.15,
        countryCode: 'ID',
        timezoneId: 'Asia/Jakarta',
        date: DateTime(2026, 9, 12, 10, 0), // 10:00 AM -> Next prayer is Dzuhur
      );

      expect(result.prayers.length, equals(6));
      expect(result.calculationMethodName, contains('MABIMS'));
      expect(result.nextPrayerName, equals('Dzuhur'));
      expect(result.nextPrayerArabic, equals('الظهر'));

      final isNextCount = result.prayers.where((p) => p.isNext).length;
      expect(isNextCount, equals(1));
    });

    test('Calculates full prayer schedule for Makkah, Saudi Arabia', () {
      final result = prayerService.calculatePrayerSchedule(
        latitude: 21.4225,
        longitude: 39.8262,
        countryCode: 'SA',
        timezoneId: 'Asia/Riyadh',
        date: DateTime(2026, 9, 12, 10, 0),
      );

      expect(result.prayers.length, equals(6));
      expect(result.calculationMethodName, equals('Umm Al-Qura'));
      expect(result.prayers.first.formattedTime, contains('AST'));
    });
  });

  group('Models & Fallback Constants Tests', () {
    test('PrayerLocationData serializes and deserializes cleanly', () {
      final data = PrayerLocationData(
        latitude: -6.12,
        longitude: 106.15,
        cityName: 'Serang',
        countryName: 'Indonesia',
        countryCode: 'ID',
        timezoneName: 'Asia/Jakarta',
        timezoneAbbr: 'WIB',
        timestamp: DateTime(2026, 9, 12, 12, 0),
      );

      final json = data.toJson();
      final recreated = PrayerLocationData.fromJson(json);

      expect(recreated.cityName, equals('Serang'));
      expect(recreated.countryCode, equals('ID'));
      expect(recreated.displayName, equals('Serang, Indonesia'));
      expect(recreated.timezoneAbbr, equals('WIB'));
    });

    test('PrayerScheduleItem copyWith works', () {
      final item = PrayerScheduleItem(
        name: 'Subuh',
        arabicName: 'الفجر',
        time: DateTime(2026, 9, 12, 4, 30),
        formattedTime: '04:30 WIB',
        isNext: false,
      );

      final updated = item.copyWith(isNext: true);
      expect(updated.isNext, isTrue);
      expect(updated.name, equals('Subuh'));
    });

    test('Fallback constants are clearly defined and not masked as GPS', () {
      expect(PrayerTimesController.fallbackLatitude, equals(-6.2088));
      expect(PrayerTimesController.fallbackLongitude, equals(106.8456));
      expect(PrayerTimesController.fallbackCityName, equals('Jakarta'));
      expect(PrayerTimesController.fallbackCountryCode, equals('ID'));
    });
  });
}
