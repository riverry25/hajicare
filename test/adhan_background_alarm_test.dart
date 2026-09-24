import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/services/adhan_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAdhanNotificationService extends AdhanNotificationService {
  final List<int> scheduledIds = [];
  final List<String> scheduledPrayers = [];
  final List<int> reminderIds = [];
  final List<String> reminderPrayers = [];
  final List<int> cancelledIds = [];

  @override
  Future<void> schedulePrayerAdhan({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required String timezoneId,
  }) async {
    scheduledIds.add(id);
    scheduledPrayers.add(prayerName);
  }

  @override
  Future<void> schedulePrayerReminder({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required String timezoneId,
    DateTime? reminderTime,
    int minutesBefore = 10,
  }) async {
    reminderIds.add(id);
    reminderPrayers.add(prayerName);
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelledIds.add(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'prayer_cache_lat': 21.4225,
      'prayer_cache_lng': 39.8262,
      'prayer_cache_timezone': 'Asia/Riyadh',
      'prayer_cache_country_code': 'SA',
      'prayer_sound_subuh': true,
      'prayer_sound_dzuhur': true,
      'prayer_sound_ashar': false, // Ashar disabled
      'prayer_sound_maghrib': true,
      'prayer_sound_isya': true,
    });
  });

  group('Adhan Background Alarm & Notification Tests', () {
    test(
      'Notification channels and raw sound resources are correctly configured',
      () {
        expect(
          AdhanNotificationService.channelIdSubuh,
          'adhan_alarm_channel_subuh',
        );
        expect(
          AdhanNotificationService.channelIdRegular,
          'adhan_alarm_channel_regular',
        );
        expect(
          AdhanNotificationService.channelIdReminder,
          'prayer_reminder_channel',
        );
        expect(
          AdhanNotificationService.channelIdPlayback,
          'adhan_playback_channel',
        );
        expect(AdhanNotificationService.soundAdzanSubuh, 'adzan_subuh');
        expect(AdhanNotificationService.soundAdzanRegular, 'adzan_regular');
        expect(AdhanNotificationService.actionStopAdhan, 'action_stop_adhan');
        expect(AdhanNotificationService.adhanNotificationId, 991001);
      },
    );

    test(
      'scheduleUpcomingPrayers schedules canonical prayers and respects sound toggle',
      () async {
        final service = MockAdhanNotificationService();

        await service.scheduleUpcomingPrayers(
          latitude: 21.4225,
          longitude: 39.8262,
          timezoneId: 'Asia/Riyadh',
          countryCode: 'SA',
          isPrayerSoundEnabled: (key) => key != 'ashar', // Ashar disabled
          daysAhead: 3,
        );

        // Sunrise/Terbit must NOT be in scheduled prayers
        expect(service.scheduledPrayers.contains('Terbit'), false);
        expect(service.scheduledPrayers.contains('Sunrise'), false);

        // Ashar must have been cancelled
        expect(service.cancelledIds.isNotEmpty, true);

        // Subuh, Dzuhur, Maghrib, Isya must be scheduled
        expect(
          service.scheduledPrayers.any(
            (p) => p.toLowerCase().contains('subuh'),
          ),
          true,
        );
        expect(
          service.scheduledPrayers.any(
            (p) => p.toLowerCase().contains('dzuhur'),
          ),
          true,
        );
        expect(
          service.scheduledPrayers.any(
            (p) => p.toLowerCase().contains('maghrib'),
          ),
          true,
        );
        expect(
          service.scheduledPrayers.any((p) => p.toLowerCase().contains('isya')),
          true,
        );

        // Pre-adhan approaching reminders (10 minutes before) must also be scheduled
        expect(
          service.reminderPrayers.any((p) => p.toLowerCase().contains('subuh')),
          true,
        );
        expect(
          service.reminderPrayers.any(
            (p) => p.toLowerCase().contains('dzuhur'),
          ),
          true,
        );
      },
    );

    test(
      'scheduleFromPreferences loads stored preferences and schedules upcoming alarms',
      () async {
        final service = MockAdhanNotificationService();
        await service.scheduleFromPreferences();

        // Schedules for Mecca coordinates stored in mock SharedPreferences
        expect(service.scheduledIds.isNotEmpty, true);
        expect(service.scheduledPrayers.contains('Terbit'), false);
      },
    );
  });
}
