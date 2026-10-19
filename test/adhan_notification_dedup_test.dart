import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/services/adhan_notification_service.dart';
import 'package:hajicare/core/services/prayer_alarm_manager_service.dart';
import 'package:hajicare/core/services/prayer_calculation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'prayer_cache_lat': -6.2088,
      'prayer_cache_lng': 106.8456,
      'prayer_cache_timezone': 'Asia/Jakarta',
      'prayer_cache_country_code': 'ID',
      'prayer_sound_subuh': true,
      'prayer_sound_dzuhur': true,
      'prayer_sound_ashar': true,
      'prayer_sound_maghrib': true,
      'prayer_sound_isya': true,
    });
  });

  group('Adhan Notification Deduplication Tests', () {
    test('Adhan alarm IDs and reminder IDs have distinct disjoint ranges', () {
      final adhanIds = <int>{};
      final reminderIds = <int>{};
      final legacyAlarmIds = <int>{};

      for (int day = 0; day < 7; day++) {
        for (int pIndex = 0; pIndex < 5; pIndex++) {
          adhanIds.add(91000 + (day * 10) + pIndex);
          reminderIds.add(92000 + (day * 10) + pIndex);
          legacyAlarmIds.add(
            PrayerAlarmManagerService.basePrayerAlarmId + (day * 10) + pIndex,
          );
        }
      }

      // Ensure no intersection between adhan notifications (91000) and reminders (92000)
      expect(adhanIds.intersection(reminderIds).isEmpty, true);

      // Ensure no intersection with legacy alarm IDs (70000)
      expect(adhanIds.intersection(legacyAlarmIds).isEmpty, true);
      expect(reminderIds.intersection(legacyAlarmIds).isEmpty, true);

      // Ensure foreground active service notification ID (991001) is distinct
      expect(
        adhanIds.contains(AdhanNotificationService.adhanNotificationId),
        false,
      );
      expect(
        reminderIds.contains(AdhanNotificationService.adhanNotificationId),
        false,
      );
    });

    test(
      'scheduleUpcomingPrayers generates unique non-colliding IDs across days and prayers',
      () {
        final calc = PrayerCalculationService();
        final now = DateTime.now();
        final result = calc.calculatePrayerSchedule(
          latitude: -6.2088,
          longitude: 106.8456,
          countryCode: 'ID',
          timezoneId: 'Asia/Jakarta',
          date: now,
        );

        const canonicalOrder = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
        final seenAdhanIds = <int>{};
        final seenReminderIds = <int>{};

        for (int day = 0; day < 7; day++) {
          for (final item in result.prayers) {
            final key = item.name.toLowerCase();
            final idx = canonicalOrder.indexOf(key);
            if (idx == -1) continue;

            final notifId = 91000 + (day * 10) + idx;
            final reminderId = 92000 + (day * 10) + idx;

            expect(
              seenAdhanIds.contains(notifId),
              false,
              reason: 'Adhan ID $notifId must be unique',
            );
            expect(
              seenReminderIds.contains(reminderId),
              false,
              reason: 'Reminder ID $reminderId must be unique',
            );

            seenAdhanIds.add(notifId);
            seenReminderIds.add(reminderId);
          }
        }

        expect(seenAdhanIds.length, 35);
        expect(seenReminderIds.length, 35);
      },
    );
  });
}
