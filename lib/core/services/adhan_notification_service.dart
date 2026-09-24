import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'prayer_calculation_service.dart';

/// Top-level callback required by flutter_local_notifications for background notification actions.
@pragma('vm:entry-point')
void adhanBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint(
    '[AdhanNotificationService] Background notification action received: ${response.actionId}, id: ${response.id}',
  );
  if (response.actionId == AdhanNotificationService.actionStopAdhan ||
      response.notificationResponseType ==
          NotificationResponseType.selectedNotificationAction ||
      response.notificationResponseType ==
          NotificationResponseType.selectedNotification) {
    AdhanNotificationService.globalStopAdhanCallback?.call();
    try {
      final plugin = AdhanNotificationService.activePlugin;
      if (plugin != null) {
        if (response.id != null) {
          plugin.cancel(id: response.id!).catchError((_) {});
        }
        plugin
            .cancel(id: AdhanNotificationService.adhanNotificationId)
            .catchError((_) {});
      }
    } catch (_) {}
  }
}

/// Service responsible for posting, scheduling, and dismissing Adhan notifications & alarms.
///
/// Features:
/// 1. Plays authentic adhan audio even when the app is completely closed or device is locked
///    via system-level exact alarm notifications with custom raw resource audio.
/// 2. Integrates dedicated Subuh & Regular notification channels with Alarm priority.
/// 3. Schedules prayer times up to 7 days in advance.
/// 4. Direct 'Matikan Adzan' action button to immediately silence and dismiss the alarm.
class AdhanNotificationService {
  static const int adhanNotificationId = 991001;

  // Notification Channel Constants
  static const String channelIdSubuh = 'adhan_alarm_channel_subuh';
  static const String channelNameSubuh = 'Panggilan Adzan Subuh';
  static const String channelDescSubuh =
      'Notifikasi dan lantunan suara adzan Subuh ketika waktu salat tiba';

  static const String channelIdRegular = 'adhan_alarm_channel_regular';
  static const String channelNameRegular =
      'Panggilan Adzan (Dzuhur, Ashar, Maghrib, Isya)';
  static const String channelDescRegular =
      'Notifikasi dan lantunan suara adzan ketika waktu salat tiba';

  static const String channelIdReminder = 'prayer_reminder_channel';
  static const String channelNameReminder = 'Pengingat Menjelang Waktu Salat';
  static const String channelDescReminder =
      'Notifikasi pengingat sebelum waktu salat tiba (10 menit sebelum adzan)';

  static const String channelIdPlayback = 'adhan_playback_channel';
  static const String channelNamePlayback = 'Pemutaran Adzan Aktif';
  static const String channelDescPlayback =
      'Notifikasi pemutaran suara adzan dalam aplikasi';

  static const String actionStopAdhan = 'action_stop_adhan';

  // Sound resource names (must exist in android/app/src/main/res/raw/)
  static const String soundAdzanRegular = 'adzan_regular';
  static const String soundAdzanSubuh = 'adzan_subuh';

  /// Global callback for stopping adhan from any isolate
  static VoidCallback? globalStopAdhanCallback;

  /// Global reference to active notification plugin instance
  static FlutterLocalNotificationsPlugin? activePlugin;

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  VoidCallback? onStopAdhanRequested;
  bool _isInitialized = false;

  AdhanNotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  /// Initialize notifications plugin and register notification channels
  Future<void> initialize({VoidCallback? onStopAdhan}) async {
    activePlugin = _notificationsPlugin;
    if (onStopAdhan != null) {
      onStopAdhanRequested = onStopAdhan;
      globalStopAdhanCallback = onStopAdhan;
    }

    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint(
            '[AdhanNotificationService] Foreground notification response actionId: ${response.actionId}, id: ${response.id}',
          );
          if (response.id != null) {
            cancelNotification(response.id!);
          }
          if (response.actionId == actionStopAdhan ||
              response.notificationResponseType ==
                  NotificationResponseType.selectedNotificationAction ||
              response.notificationResponseType ==
                  NotificationResponseType.selectedNotification) {
            onStopAdhanRequested?.call();
            globalStopAdhanCallback?.call();
          }
        },
        onDidReceiveBackgroundNotificationResponse:
            adhanBackgroundNotificationResponse,
      );

      // Create Android Notification Channels with custom sound & alarm audio attributes
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImpl != null) {
          // Request POST_NOTIFICATIONS (Android 13+)
          await androidImpl.requestNotificationsPermission();

          // Request exact alarms permission (Android 12+)
          await androidImpl.requestExactAlarmsPermission();

          // Channel for Subuh
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelIdSubuh,
              channelNameSubuh,
              description: channelDescSubuh,
              importance: Importance.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound(soundAdzanSubuh),
              audioAttributesUsage: AudioAttributesUsage.alarm,
              enableVibration: true,
            ),
          );

          // Channel for Dzuhur, Ashar, Maghrib, Isya
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelIdRegular,
              channelNameRegular,
              description: channelDescRegular,
              importance: Importance.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound(soundAdzanRegular),
              audioAttributesUsage: AudioAttributesUsage.alarm,
              enableVibration: true,
            ),
          );

          // Silent foreground playback channel
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelIdPlayback,
              channelNamePlayback,
              description: channelDescPlayback,
              importance: Importance.max,
              playSound: false,
              enableVibration: true,
            ),
          );

          // Approaching prayer reminder channel (10 mins before adzan)
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelIdReminder,
              channelNameReminder,
              description: channelDescReminder,
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );
        }
      }

      _isInitialized = true;
    } catch (e) {
      if (!e.toString().contains('LateInitializationError')) {
        debugPrint('[AdhanNotificationService] Initialization error: $e');
      }
    }
  }

  /// Show active adhan notification with a direct 'Matikan Adzan' action button
  /// (used for in-app or foreground playback)
  Future<void> showAdhanNotification({
    required String prayerName,
    VoidCallback? onStopAdhan,
  }) async {
    if (onStopAdhan != null) {
      onStopAdhanRequested = onStopAdhan;
      globalStopAdhanCallback = onStopAdhan;
    }

    try {
      if (!_isInitialized) {
        await initialize();
      }

      final androidDetails = AndroidNotificationDetails(
        channelIdPlayback,
        channelNamePlayback,
        channelDescription: channelDescPlayback,
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        playSound:
            false, // In foreground, audio is handled by AdhanAudioService
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            actionStopAdhan,
            'Matikan Adzan',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: adhanNotificationId,
        title: 'Waktu Salat $prayerName Berkumandang',
        body: 'Suara adzan sedang diputar. Ketuk tombol untuk mematikan.',
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('[AdhanNotificationService] Show error: $e');
    }
  }

  /// Schedules a background alarm notification with custom adhan audio for a specific prayer time.
  /// Works reliably even when the device is locked and the application is terminated.
  Future<void> schedulePrayerAdhan({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required String timezoneId,
  }) async {
    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return;

    try {
      if (!_isInitialized) {
        await initialize();
      }

      tz.initializeTimeZones();
      tz.Location location;
      try {
        location = tz.getLocation(timezoneId);
      } catch (_) {
        location = tz.local;
      }
      final tzScheduled = tz.TZDateTime.from(scheduledTime, location);

      final isSubuh =
          prayerName.trim().toLowerCase() == 'subuh' ||
          prayerName.trim().toLowerCase() == 'fajr';
      final soundRes = isSubuh ? soundAdzanSubuh : soundAdzanRegular;
      final channelId = isSubuh ? channelIdSubuh : channelIdRegular;
      final channelName = isSubuh ? channelNameSubuh : channelNameRegular;
      final channelDesc = isSubuh ? channelDescSubuh : channelDescRegular;

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundRes),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            actionStopAdhan,
            'Matikan Adzan',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: '$soundRes.mp3',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: 'Waktu Salat $prayerName Telah Tiba',
          body:
              'Mari tunaikan salat $prayerName. Suara adzan sedang berkumandang.',
          scheduledDate: tzScheduled,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (scheduleErr) {
        debugPrint(
          '[AdhanNotificationService] Exact alarm failed, trying inexact fallback: $scheduleErr',
        );
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: 'Waktu Salat $prayerName Telah Tiba',
          body:
              'Mari tunaikan salat $prayerName. Suara adzan sedang berkumandang.',
          scheduledDate: tzScheduled,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      debugPrint(
        '[AdhanNotificationService] Scheduled adhan for $prayerName at $tzScheduled (ID: $id)',
      );
    } catch (e) {
      debugPrint('[AdhanNotificationService] Error scheduling adhan: $e');
    }
  }

  /// Schedules an approaching prayer reminder notification [minutesBefore] prayer time arrives.
  Future<void> schedulePrayerReminder({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required String timezoneId,
    DateTime? reminderTime,
    int minutesBefore = 10,
  }) async {
    final scheduledReminder =
        reminderTime ?? prayerTime.subtract(Duration(minutes: minutesBefore));
    final now = DateTime.now();
    if (scheduledReminder.isBefore(now)) return;

    try {
      if (!_isInitialized) {
        await initialize();
      }

      tz.initializeTimeZones();
      tz.Location location;
      try {
        location = tz.getLocation(timezoneId);
      } catch (_) {
        location = tz.local;
      }
      final tzScheduled = tz.TZDateTime.from(scheduledReminder, location);

      const androidDetails = AndroidNotificationDetails(
        channelIdReminder,
        channelNameReminder,
        channelDescription: channelDescReminder,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final formattedHour =
          '${prayerTime.hour.toString().padLeft(2, '0')}:${prayerTime.minute.toString().padLeft(2, '0')}';

      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: 'Waktu Salat $prayerName $minutesBefore Menit Lagi',
          body:
              'Salat $prayerName akan tiba pukul $formattedHour. Mari bersiap mengambil wudhu.',
          scheduledDate: tzScheduled,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: 'Waktu Salat $prayerName $minutesBefore Menit Lagi',
          body:
              'Salat $prayerName akan tiba pukul $formattedHour. Mari bersiap mengambil wudhu.',
          scheduledDate: tzScheduled,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      debugPrint(
        '[AdhanNotificationService] Scheduled reminder for $prayerName at $tzScheduled (ID: $id)',
      );
    } catch (e) {
      debugPrint('[AdhanNotificationService] Error scheduling reminder: $e');
    }
  }

  /// Request notifications and exact alarm permissions explicitly
  Future<bool> requestPermissions() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final notifGranted =
            await androidImpl?.requestNotificationsPermission() ?? false;
        final exactGranted =
            await androidImpl?.requestExactAlarmsPermission() ?? false;
        return notifGranted && exactGranted;
      }
      return true;
    } catch (e) {
      debugPrint('[AdhanNotificationService] requestPermissions error: $e');
      return false;
    }
  }

  /// Calculates and schedules exact adhan alarm notifications for upcoming prayers (next [daysAhead] days).
  /// Automatically filters out prayers where user disabled sound, and cancels past/disabled alarm IDs.
  Future<void> scheduleUpcomingPrayers({
    required double latitude,
    required double longitude,
    required String timezoneId,
    String countryCode = 'ID',
    bool Function(String prayerKey)? isPrayerSoundEnabled,
    int daysAhead = 7,
  }) async {
    if (latitude == 0.0 && longitude == 0.0) return;

    if (!_isInitialized) {
      await initialize();
    }

    final now = DateTime.now();
    final prayerCalc = PrayerCalculationService();
    const canonicalOrder = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

    for (int day = 0; day < daysAhead; day++) {
      final targetDate = now.add(Duration(days: day));
      try {
        final result = prayerCalc.calculatePrayerSchedule(
          latitude: latitude,
          longitude: longitude,
          countryCode: countryCode,
          timezoneId: timezoneId,
          date: targetDate,
        );

        for (final item in result.prayers) {
          final normalized = _normalizePrayerKey(item.name);
          final prayerIndex = canonicalOrder.indexOf(normalized);
          if (prayerIndex == -1) continue; // Skip sunrise/terbit

          final notificationId = 91000 + (day * 10) + prayerIndex;
          final reminderId = 92000 + (day * 10) + prayerIndex;
          final isEnabled =
              isPrayerSoundEnabled == null || isPrayerSoundEnabled(normalized);

          if (!isEnabled) {
            await cancelNotification(notificationId);
            await cancelNotification(reminderId);
            continue;
          }

          if (item.time.isAfter(now)) {
            // 1. Approaching prayer reminder (10 minutes before)
            await schedulePrayerReminder(
              id: reminderId,
              prayerName: item.name,
              prayerTime: item.time,
              timezoneId: timezoneId,
              minutesBefore: 10,
            );

            // 2. Adhan alarm when prayer time arrives
            await schedulePrayerAdhan(
              id: notificationId,
              prayerName: item.name,
              scheduledTime: item.time,
              timezoneId: timezoneId,
            );
          }
        }
      } catch (e) {
        debugPrint(
          '[AdhanNotificationService] Failed to calculate/schedule day $day: $e',
        );
      }
    }
  }

  /// Schedules upcoming prayers using coordinates and preferences stored in SharedPreferences.
  /// Ideal for calling upon app startup even before the user opens the Prayer screen.
  Future<void> scheduleFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double lat;
      double lng;
      String tz;
      String countryCode;

      if (prefs.containsKey('prayer_cache_lat') &&
          prefs.containsKey('prayer_cache_lng')) {
        lat = prefs.getDouble('prayer_cache_lat')!;
        lng = prefs.getDouble('prayer_cache_lng')!;
        tz = prefs.getString('prayer_cache_timezone') ?? 'Asia/Jakarta';
        countryCode = prefs.getString('prayer_cache_country_code') ?? 'ID';
      } else {
        // Smart fallback: check device local timezone
        lat = -6.2088;
        lng = 106.8456;
        tz = 'Asia/Jakarta';
        countryCode = 'ID';
      }

      await scheduleUpcomingPrayers(
        latitude: lat,
        longitude: lng,
        timezoneId: tz,
        countryCode: countryCode,
        isPrayerSoundEnabled: (key) =>
            prefs.getBool('prayer_sound_$key') ?? true,
      );
    } catch (e) {
      debugPrint(
        '[AdhanNotificationService] scheduleFromPreferences error: $e',
      );
    }
  }

  /// Schedules a test adhan notification [delaySeconds] from now, including an approaching reminder.
  /// Useful for users to verify that background alarms and audio play properly when phone is locked or app is closed.
  Future<void> scheduleTestAdhan({int delaySeconds = 5}) async {
    final now = DateTime.now();
    tz.initializeTimeZones();
    final localTz = tz.local.name.isNotEmpty ? tz.local.name : 'Asia/Jakarta';

    // 1. Pre-adhan approaching reminder simulation (fires 2 seconds ahead if delaySeconds >= 4)
    if (delaySeconds >= 4) {
      final simReminderTime = now.add(const Duration(seconds: 2));
      final simPrayerTime = now.add(Duration(seconds: delaySeconds));
      await schedulePrayerReminder(
        id: 99998,
        prayerName: 'Dzuhur (Simulasi)',
        prayerTime: simPrayerTime,
        reminderTime: simReminderTime,
        timezoneId: localTz,
        minutesBefore: 10,
      );
    }

    // 2. Exact Adhan alarm with audio
    final fireTime = now.add(Duration(seconds: delaySeconds));
    await schedulePrayerAdhan(
      id: 99999,
      prayerName: 'Uji Coba Adzan',
      scheduledTime: fireTime,
      timezoneId: localTz,
    );
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint(
        '[AdhanNotificationService] Cancel notification $id error: $e',
      );
    }
  }

  /// Cancel active foreground adhan notification
  Future<void> cancelAdhanNotification() async {
    await cancelNotification(adhanNotificationId);
  }

  /// Cancel all scheduled and active adhan notifications
  Future<void> cancelAllScheduledAdhans() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('[AdhanNotificationService] Cancel all error: $e');
    }
  }

  static String _normalizePrayerKey(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('subuh') || lower.contains('fajr')) return 'subuh';
    if (lower.contains('terbit') || lower.contains('sunrise')) return 'terbit';
    if (lower.contains('dzuhur') ||
        lower.contains('dhuhr') ||
        lower.contains('zuhur')) {
      return 'dzuhur';
    }
    if (lower.contains('ashar') || lower.contains('asr')) return 'ashar';
    if (lower.contains('maghrib')) return 'maghrib';
    if (lower.contains('isya') || lower.contains('isha')) return 'isya';
    return lower;
  }
}
