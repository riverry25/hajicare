import 'dart:async';
import 'package:adhan_foreground_service/adhan_foreground_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level callback executed in an isolated background Isolate by AndroidAlarmManager
/// when the exact alarm fires, even if the HajiCare app process was terminated.
@pragma('vm:entry-point')
void backgroundAlarmPocCallback(int id) async {
  debugPrint(
    '🔥 [POC-ALARM-TRIGGERED] ========================================\n'
    '🔥 [POC-ALARM-TRIGGERED] backgroundAlarmPocCallback fired!\n'
    '🔥 [POC-ALARM-TRIGGERED] Alarm ID: $id\n'
    '🔥 [POC-ALARM-TRIGGERED] Timestamp: ${DateTime.now()}\n'
    '🔥 [POC-ALARM-TRIGGERED] ========================================',
  );

  // Post a high-priority notification to visually prove the callback executed
  try {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await notificationsPlugin.initialize(settings: initSettings);

    const androidDetails = AndroidNotificationDetails(
      'poc_alarm_channel',
      'Proof of Concept Alarm',
      channelDescription:
          'Channel pengujian verifikasi alarm exact saat aplikasi ditutup',
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
      title: '✅ Alarm 30 Detik Berhasil!',
      body:
          'Alarm ID $id berhasil dieksekusi oleh Android saat aplikasi tertutup (Pukul $timeStr).',
      notificationDetails: notifDetails,
    );

    debugPrint(
      '🔥 [POC-ALARM-NOTIFICATION-POSTED] Notification successfully displayed for ID: $id at $timeStr',
    );
  } catch (e, st) {
    debugPrint(
      '❌ [POC-ALARM-NOTIFICATION-ERROR] Failed to show notification from callback: $e\n$st',
    );
  }
}

/// Dedicated top-level callback for "Test Background Adzan 30 Detik"
/// Executed in an isolated background isolate by AndroidAlarmManager.
@pragma('vm:entry-point')
void backgroundAdhanTestCallback(int id) async {
  final nowStr = DateTime.now().toIso8601String();
  debugPrint('[$nowStr] [ALARM] callback received (ID: $id)');

  // Requirement 14: Keep background notification working together with audio
  try {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await notificationsPlugin.initialize(settings: initSettings);

    const androidDetails = AndroidNotificationDetails(
      'poc_adhan_audio_channel',
      'Test Background Adzan 30 Detik',
      channelDescription:
          'Channel verifikasi notifikasi dan audio adzan foreground service saat aplikasi tertutup',
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
      title: '🕌 Waktu Salat Telah Tiba (Test 30s)',
      body:
          'Alarm ID $id terpanggil pada pukul $timeStr. Memulai Foreground Service & pemutaran adzan...',
      notificationDetails: notifDetails,
    );
  } catch (e) {
    debugPrint('❌ [NOTIF-ERROR] Gagal menampilkan notifikasi background: $e');
  }

  // Start native Foreground Service to play authentic adhan audio
  try {
    final success = await AdhanForegroundService.startAdhan(
      prayerName: 'Dzuhur Test',
      isSubuh: false,
    );
    if (!success) {
      debugPrint('[SERVICE] ERROR: startAdhanService returned false');
    }
  } catch (e) {
    // Requirement 17: Show EXACT error if service fails to start
    debugPrint('[SERVICE] ERROR: $e');
  }
}

/// Service dedicated to testing AndroidAlarmManager.alarmClock() as a Proof of Concept.
class BackgroundAlarmPocService {
  static const int pocAlarmId = 99999;
  static const int pocAdhanAlarmId = 88888;

  /// Schedules an exact alarm using alarmClock mode [delaySeconds] from now (Notification POC).
  static Future<bool> schedulePocAlarm({int delaySeconds = 30}) async {
    final now = DateTime.now();
    final targetTime = now.add(Duration(seconds: delaySeconds));

    debugPrint(
      '========================================================================\n'
      '⏰ [POC-SCHEDULE-START] Menjadwalkan AndroidAlarmManager (alarmClock):\n'
      '  - ID Alarm: $pocAlarmId\n'
      '  - Waktu Sekarang: $now\n'
      '  - Waktu Target: $targetTime (+ $delaySeconds detik)\n'
      '  - Mode: setAlarmClock (Exact & Wakeup)\n'
      '========================================================================',
    );

    try {
      final success = await AndroidAlarmManager.oneShotAt(
        targetTime,
        pocAlarmId,
        backgroundAlarmPocCallback,
        alarmClock: true,
        allowWhileIdle: true,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      debugPrint(
        '⏰ [POC-SCHEDULE-RESULT] Berhasil didaftarkan ke AlarmManager: $success (ID: $pocAlarmId)\n'
        '========================================================================',
      );

      return success;
    } catch (e, st) {
      debugPrint(
        '❌ [POC-SCHEDULE-ERROR] Gagal menjadwalkan alarmClock: $e\n$st',
      );
      return false;
    }
  }

  /// Requirement 13: Schedules "Test Background Adzan 30 Detik"
  /// Flow:
  /// - alarm dijadwalkan 30 detik via AndroidAlarmManager.alarmClock()
  /// - user menutup HajiCare / swipe recent apps
  /// - user mengunci layar
  /// - alarm terpanggil
  /// - foreground service dimulai
  /// - audio adzan diputar.
  static Future<bool> scheduleBackgroundAdhanTest({
    int delaySeconds = 30,
  }) async {
    final now = DateTime.now();
    final targetTime = now.add(Duration(seconds: delaySeconds));

    debugPrint(
      '========================================================================\n'
      '🔊 [ADZAN-TEST-START] Menjadwalkan Test Background Adzan 30 Detik:\n'
      '  - ID Alarm: $pocAdhanAlarmId\n'
      '  - Waktu Sekarang: $now\n'
      '  - Waktu Target: $targetTime (+ $delaySeconds detik)\n'
      '  - Mode: AndroidAlarmManager.alarmClock (Exact & Wakeup)\n'
      '========================================================================',
    );

    try {
      final success = await AndroidAlarmManager.oneShotAt(
        targetTime,
        pocAdhanAlarmId,
        backgroundAdhanTestCallback,
        alarmClock: true,
        allowWhileIdle: true,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      debugPrint(
        '🔊 [ADZAN-TEST-RESULT] Berhasil didaftarkan: $success (ID: $pocAdhanAlarmId)\n'
        '========================================================================',
      );

      return success;
    } catch (e, st) {
      debugPrint('❌ [ADZAN-TEST-ERROR] Gagal menjadwalkan test adzan: $e\n$st');
      return false;
    }
  }
}
