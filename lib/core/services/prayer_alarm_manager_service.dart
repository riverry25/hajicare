import 'dart:async';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'prayer_calculation_service.dart';

/// Top-level callback executed by Android AlarmManager when a scheduled prayer alarm fires,
/// even when the HajiCare application process has been terminated.
@pragma('vm:entry-point')
void prayerAlarmCallback(int id, Map<String, dynamic> params) async {
  final prayerName =
      params['prayerName'] as String? ?? _resolvePrayerNameFromId(id);

  debugPrint(
    '🕌 [PRAYER-ALARM-TRIGGERED] ========================================\n'
    '🕌 [PRAYER-ALARM-TRIGGERED] prayerAlarmCallback fired!\n'
    '🕌 [PRAYER-ALARM-TRIGGERED] Prayer: $prayerName | ID: $id\n'
    '🕌 [PRAYER-ALARM-TRIGGERED] Timestamp: ${DateTime.now()}\n'
    '🕌 [PRAYER-ALARM-TRIGGERED] ========================================',
  );

  try {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await notificationsPlugin.initialize(settings: initSettings);

    const androidDetails = AndroidNotificationDetails(
      'prayer_alarm_poc_channel',
      'Jadwal Waktu Salat',
      channelDescription:
          'Notifikasi pengingat waktu salat via AndroidAlarmManager alarmClock',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    await notificationsPlugin.show(
      id: id,
      title: 'Waktu Salat $prayerName Telah Tiba',
      body:
          'Waktu salat $prayerName telah tiba (Pukul $timeStr). Mari tunaikan salat.',
      notificationDetails: notifDetails,
    );

    debugPrint(
      '🕌 [PRAYER-ALARM-NOTIFICATION-POSTED] Notification shown for $prayerName (ID: $id) at $timeStr',
    );
  } catch (e, st) {
    debugPrint(
      '❌ [PRAYER-ALARM-NOTIFICATION-ERROR] Failed to show notification: $e\n$st',
    );
  }
}

String _resolvePrayerNameFromId(int id) {
  if (id == 79999) return 'Dzuhur Test';
  final prayerIndex = id % 10;
  switch (prayerIndex) {
    case 0:
      return 'Subuh';
    case 1:
      return 'Dzuhur';
    case 2:
      return 'Ashar';
    case 3:
      return 'Maghrib';
    case 4:
      return 'Isya';
    default:
      return 'Salat';
  }
}

/// Android-specific prayer scheduler utilizing AndroidAlarmManager.alarmClock()
/// to ensure reliable execution when the app is completely closed.
class PrayerAlarmManagerService {
  static const int testAlarmId = 79999;
  static const int basePrayerAlarmId = 70000;

  /// Schedules a test prayer alarm for [delaySeconds] from now with the name "Dzuhur Test".
  static Future<bool> scheduleTestPrayerAlarm({int delaySeconds = 30}) async {
    final now = DateTime.now();
    final targetTime = now.add(Duration(seconds: delaySeconds));
    const prayerName = 'Dzuhur Test';

    debugPrint(
      '========================================================================\n'
      '⏰ [PRAYER-TEST-SCHEDULE] Menjadwalkan Simulasi Jadwal Sholat Background:\n'
      '  - Nama Salat: $prayerName\n'
      '  - ID Alarm: $testAlarmId\n'
      '  - Waktu Sekarang: $now\n'
      '  - Waktu Target: $targetTime (+ $delaySeconds detik)\n'
      '  - Mode: AndroidAlarmManager.alarmClock (Exact & Wakeup)\n'
      '========================================================================',
    );

    try {
      final success = await AndroidAlarmManager.oneShotAt(
        targetTime,
        testAlarmId,
        prayerAlarmCallback,
        alarmClock: true,
        allowWhileIdle: true,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {'prayerName': prayerName},
      );

      debugPrint(
        '⏰ [PRAYER-TEST-RESULT] Berhasil didaftarkan ke AlarmManager: $success (ID: $testAlarmId)\n'
        '========================================================================',
      );

      return success;
    } catch (e, st) {
      debugPrint(
        '❌ [PRAYER-TEST-ERROR] Gagal menjadwalkan alarm sholat test: $e\n$st',
      );
      return false;
    }
  }

  /// Calculates upcoming prayers using [PrayerCalculationService] and schedules each as an exact alarmClock.
  /// Stable ID format: 70000 + (day * 10) + prayerIndex (0: Subuh, 1: Dzuhur, 2: Ashar, 3: Maghrib, 4: Isya).
  static Future<void> scheduleUpcomingPrayers({
    required double latitude,
    required double longitude,
    required String timezoneId,
    String countryCode = 'ID',
    int daysAhead = 7,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (latitude == 0.0 && longitude == 0.0) return;

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

          final alarmId = basePrayerAlarmId + (day * 10) + prayerIndex;

          if (item.time.isAfter(now)) {
            await AndroidAlarmManager.oneShotAt(
              item.time,
              alarmId,
              prayerAlarmCallback,
              alarmClock: true,
              allowWhileIdle: true,
              exact: true,
              wakeup: true,
              rescheduleOnReboot: true,
              params: {'prayerName': item.name},
            );
          }
        }
      } catch (e) {
        debugPrint(
          '❌ [PRAYER-ALARM-ERROR] Gagal menghitung/menjadwalkan hari $day: $e',
        );
      }
    }
  }

  /// Cancels all scheduled prayer alarms in range 70000..70099
  static Future<void> cancelAllPrayerAlarms({int daysAhead = 7}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    for (int day = 0; day < daysAhead; day++) {
      for (int i = 0; i < 5; i++) {
        final alarmId = basePrayerAlarmId + (day * 10) + i;
        await AndroidAlarmManager.cancel(alarmId);
      }
    }
    await AndroidAlarmManager.cancel(testAlarmId);
  }

  static String _normalizePrayerKey(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('subuh') || lower.contains('fajr')) return 'subuh';
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
