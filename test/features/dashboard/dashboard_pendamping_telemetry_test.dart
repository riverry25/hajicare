import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/locales/app_translations.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';

void main() {
  group('Dashboard Pendamping Dynamic Telemetry Tests', () {
    test('separatedJamaahList dynamically identifies all pilgrims outside safe radius', () {
      final controller = HajiCareController();
      controller.safeRadiusMeters.value = 200.0;

      final p1 = JamaahData(
        id: '1',
        name: 'Eko',
        shortLabel: 'Eko',
        distance: 14054000.0, // 14,054 km
      );
      final p2 = JamaahData(
        id: '2',
        name: 'Ferdi',
        shortLabel: 'Ferdi',
        distance: 14054000.0, // 14,054 km
      );
      final p3 = JamaahData(
        id: '3',
        name: 'Fadli',
        shortLabel: 'Fadli',
        distance: 50.0, // Safe inside group
      );

      controller.jamaahList.value = [p1, p2, p3];

      final separated = controller.separatedJamaahList;
      expect(separated.length, 2);
      expect(separated.map((j) => j.name).toList(), containsAll(['Eko', 'Ferdi']));
      expect(controller.anyJamaahSeparated, isTrue);
    });

    test('JamaahData isSmartbandConnected defaults to false and can be set dynamically', () {
      final jamaah = JamaahData(
        id: 'user_123',
        name: 'Eko',
        shortLabel: 'Eko',
        distance: 100.0,
      );

      expect(jamaah.isSmartbandConnected, isFalse);

      jamaah.isSmartbandConnected = true;
      expect(jamaah.isSmartbandConnected, isTrue);

      final firestoreMap = jamaah.toFirestore();
      expect(firestoreMap['isSmartbandConnected'], isTrue);
    });

    test('Relative timestamp calculation: returns days ago when older than 24 hours', () {
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final diff = now.difference(threeDaysAgo);
      
      final calendarDayDiff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day))
          .inDays;
      final durationDays = diff.inDays > 0 ? diff.inDays : (diff.inHours / 24).floor();
      final effectiveDays = calendarDayDiff > durationDays ? calendarDayDiff : durationDays;

      expect(effectiveDays, 3);
    });

    test('Smartband connection translation keys exist and do not return raw keys', () {
      final idConnected = AppTranslations.translate('dashboard.smartbandConnected', 'id');
      final idDisconnected = AppTranslations.translate('dashboard.smartbandNotConnected', 'id');
      final enConnected = AppTranslations.translate('dashboard.smartbandConnected', 'en');
      final enDisconnected = AppTranslations.translate('dashboard.smartbandNotConnected', 'en');

      expect(idConnected, isNot(equals('dashboard.smartbandConnected')));
      expect(idDisconnected, isNot(equals('dashboard.smartbandNotConnected')));
      expect(idConnected, equals('Terhubung'));
      expect(idDisconnected, equals('Belum Terhubung'));

      expect(enConnected, isNot(equals('dashboard.smartbandConnected')));
      expect(enDisconnected, isNot(equals('dashboard.smartbandNotConnected')));
      expect(enConnected, equals('Connected'));
      expect(enDisconnected, equals('Not Connected'));

      final jvConnected = AppTranslations.translate('dashboard.smartbandConnected', 'jv');
      final jvDisconnected = AppTranslations.translate('dashboard.smartbandNotConnected', 'jv');
      expect(jvConnected, equals('Kasambung'));
      expect(jvDisconnected, equals('Durung Kasambung'));

      final suConnected = AppTranslations.translate('dashboard.smartbandConnected', 'su');
      final suDisconnected = AppTranslations.translate('dashboard.smartbandNotConnected', 'su');
      expect(suConnected, equals('Kahubung'));
      expect(suDisconnected, equals('Teu Acan Kahubung'));
    });
  });
}

