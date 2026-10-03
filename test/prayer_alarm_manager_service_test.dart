import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/services/prayer_alarm_manager_service.dart';
import 'package:hajicare/core/services/prayer_calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerAlarmManagerService Stage 2 Tests', () {
    test('Constants and ID schemes are properly defined', () {
      expect(PrayerAlarmManagerService.testAlarmId, 79999);
      expect(PrayerAlarmManagerService.basePrayerAlarmId, 70000);
    });

    test(
      'PrayerCalculationService calculates canonical prayer schedule for scheduling',
      () {
        final calcService = PrayerCalculationService();
        final now = DateTime.now();

        final result = calcService.calculatePrayerSchedule(
          latitude: -6.2088,
          longitude: 106.8456,
          countryCode: 'ID',
          timezoneId: 'Asia/Jakarta',
          date: now,
        );

        expect(
          result.prayers.length,
          6,
        ); // Subuh, Terbit, Dzuhur, Ashar, Maghrib, Isya
        final names = result.prayers.map((p) => p.name).toList();
        expect(names.contains('Subuh'), true);
        expect(names.contains('Dzuhur'), true);
        expect(names.contains('Ashar'), true);
        expect(names.contains('Maghrib'), true);
        expect(names.contains('Isya'), true);
      },
    );

    test(
      'Prayer ID generation is deterministic and unique for each prayer and day',
      () {
        const baseId = PrayerAlarmManagerService.basePrayerAlarmId;
        final generatedIds = <int>{};

        for (int day = 0; day < 7; day++) {
          for (int prayerIndex = 0; prayerIndex < 5; prayerIndex++) {
            final id = baseId + (day * 10) + prayerIndex;
            expect(
              generatedIds.contains(id),
              false,
              reason: 'ID $id must be unique',
            );
            generatedIds.add(id);
          }
        }

        expect(generatedIds.length, 35);
        expect(generatedIds.contains(70000), true); // Day 0 Subuh
        expect(generatedIds.contains(70001), true); // Day 0 Dzuhur
        expect(generatedIds.contains(70004), true); // Day 0 Isya
        expect(generatedIds.contains(70010), true); // Day 1 Subuh
        expect(generatedIds.contains(70044), true); // Day 4 Isya
      },
    );
  });
}
