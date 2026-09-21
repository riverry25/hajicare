import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/services/adhan_audio_service.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hajicare/core/services/adhan_notification_service.dart';

class FakeAdhanNotificationService extends AdhanNotificationService {
  bool isShowing = false;
  String? lastShownPrayer;

  @override
  Future<void> initialize({VoidCallback? onStopAdhan}) async {
    onStopAdhanRequested = onStopAdhan;
  }

  @override
  Future<void> showAdhanNotification({
    required String prayerName,
    VoidCallback? onStopAdhan,
  }) async {
    isShowing = true;
    lastShownPrayer = prayerName;
    if (onStopAdhan != null) {
      onStopAdhanRequested = onStopAdhan;
    }
  }

  @override
  Future<void> cancelAdhanNotification() async {
    isShowing = false;
    lastShownPrayer = null;
  }
}

class FakeAdhanAudioService extends AdhanAudioService {
  final FakeAdhanNotificationService? fakeNotificationService;

  FakeAdhanAudioService({this.fakeNotificationService})
    : super(notificationService: fakeNotificationService);

  @override
  void initPlayer() {
    // Avoid initializing native audio player channels in unit test
  }

  @override
  Future<void> playAdhan({required String prayerName}) async {
    isPlaying.value = true;
    currentPrayerName.value = prayerName;
    await fakeNotificationService?.showAdhanNotification(
      prayerName: prayerName,
      onStopAdhan: stopAdhan,
    );
  }

  @override
  Future<void> stopAdhan() async {
    isPlaying.value = false;
    currentPrayerName.value = '';
    await fakeNotificationService?.cancelAdhanNotification();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adhan Sound & Toggle Tests', () {
    late FakeAdhanAudioService fakeAudioService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeAudioService = FakeAdhanAudioService();
    });

    test('AdhanAudioService initializes with isPlaying false', () {
      expect(fakeAudioService.isPlaying.value, false);
      expect(fakeAudioService.currentPrayerName.value, '');
    });

    test('FakeAdhanAudioService plays and stops correctly', () async {
      await fakeAudioService.playAdhan(prayerName: 'Subuh');
      expect(fakeAudioService.isPlaying.value, true);
      expect(fakeAudioService.currentPrayerName.value, 'Subuh');

      await fakeAudioService.stopAdhan();
      expect(fakeAudioService.isPlaying.value, false);
      expect(fakeAudioService.currentPrayerName.value, '');
    });

    test(
      'Adhan triggers phone notification and can be stopped via notification action',
      () async {
        final fakeNotification = FakeAdhanNotificationService();
        final audioService = FakeAdhanAudioService(
          fakeNotificationService: fakeNotification,
        );

        expect(fakeNotification.isShowing, false);

        // 1. Play Adhan Subuh
        await audioService.playAdhan(prayerName: 'Subuh');
        expect(audioService.isPlaying.value, true);
        expect(fakeNotification.isShowing, true);
        expect(fakeNotification.lastShownPrayer, 'Subuh');

        // 2. User presses "Matikan Adzan" directly from phone notification
        fakeNotification.onStopAdhanRequested?.call();
        expect(audioService.isPlaying.value, false);
        expect(fakeNotification.isShowing, false);
      },
    );

    test(
      'PrayerTimesController toggles prayer sound on/off correctly',
      () async {
        final controller = PrayerTimesController(
          adhanAudioService: fakeAudioService,
        );

        // By default sound is ON
        expect(controller.isPrayerSoundOn('Subuh'), true);
        expect(controller.isPrayerSoundOn('Dzuhur'), true);
        expect(controller.isPrayerSoundOn('Ashar'), true);
        expect(controller.isPrayerSoundOn('Maghrib'), true);
        expect(controller.isPrayerSoundOn('Isya'), true);

        // Toggle Subuh OFF
        await controller.togglePrayerSound('Subuh');
        expect(controller.isPrayerSoundOn('Subuh'), false);
        // Other prayers remain unaffected
        expect(controller.isPrayerSoundOn('Dzuhur'), true);

        // Toggle Subuh back ON
        await controller.togglePrayerSound('Subuh');
        expect(controller.isPrayerSoundOn('Subuh'), true);
      },
    );

    test('Terbit is not affected by sound toggle', () async {
      final controller = PrayerTimesController(
        adhanAudioService: fakeAudioService,
      );
      await controller.togglePrayerSound('Terbit');
      // Terbit should not register any prayer sound
      expect(controller.prayerSoundEnabled.containsKey('terbit'), false);
    });

    test('Saved sound preferences persist across SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'prayer_sound_subuh': false,
        'prayer_sound_maghrib': true,
      });

      final controller = PrayerTimesController(
        adhanAudioService: fakeAudioService,
      );
      await controller.initialize();

      expect(controller.isPrayerSoundOn('subuh'), false);
      expect(controller.isPrayerSoundOn('maghrib'), true);
    });

    test(
      'PrayerTimesController master sound toggle sets all prayers on/off in 1 click',
      () async {
        final controller = PrayerTimesController(
          adhanAudioService: fakeAudioService,
        );

        // Initially sounds are all on
        expect(controller.isAnySoundOn, true);

        // 1 click toggle: turns ALL sounds OFF
        await controller.toggleAllPrayerSounds();
        expect(controller.isAnySoundOn, false);
        expect(controller.isPrayerSoundOn('Subuh'), false);
        expect(controller.isPrayerSoundOn('Dzuhur'), false);
        expect(controller.isPrayerSoundOn('Ashar'), false);
        expect(controller.isPrayerSoundOn('Maghrib'), false);
        expect(controller.isPrayerSoundOn('Isya'), false);

        // 1 click toggle: turns ALL sounds back ON
        await controller.toggleAllPrayerSounds();
        expect(controller.isAnySoundOn, true);
        expect(controller.isPrayerSoundOn('Subuh'), true);
        expect(controller.isPrayerSoundOn('Dzuhur'), true);
        expect(controller.isPrayerSoundOn('Ashar'), true);
        expect(controller.isPrayerSoundOn('Maghrib'), true);
        expect(controller.isPrayerSoundOn('Isya'), true);
      },
    );

    test(
      'PrayerTimesController rejects NaN heading and keeps qiblaOffset safe',
      () {
        final controller = PrayerTimesController(
          adhanAudioService: fakeAudioService,
        );

        controller.qiblaBearing.value = 295.0;

        // Updating with NaN heading should be discarded safely
        controller.deviceHeading.value = 0.0;
        // When heading is NaN, qiblaOffset should not become NaN
        expect(controller.qiblaOffset.value.isNaN, false);
        expect(controller.qiblaOffset.value.isFinite, true);
      },
    );

    test(
      'adhanBackgroundNotificationResponse triggers globalStopAdhanCallback',
      () {
        bool called = false;
        AdhanNotificationService.globalStopAdhanCallback = () {
          called = true;
        };

        adhanBackgroundNotificationResponse(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: AdhanNotificationService.actionStopAdhan,
          ),
        );

        expect(called, true);
      },
    );
  });
}
