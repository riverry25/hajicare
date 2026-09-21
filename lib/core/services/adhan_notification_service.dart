import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level callback required by flutter_local_notifications for background notification actions.
@pragma('vm:entry-point')
void adhanBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint(
    '[AdhanNotificationService] Background notification action received: ${response.actionId}',
  );
  if (response.actionId == AdhanNotificationService.actionStopAdhan ||
      response.notificationResponseType ==
          NotificationResponseType.selectedNotificationAction ||
      response.notificationResponseType ==
          NotificationResponseType.selectedNotification) {
    AdhanNotificationService.globalStopAdhanCallback?.call();
  }
}

/// Service responsible for posting and dismissing Adhan notifications on mobile,
/// with an action button allowing the user to turn off / stop the Adhan directly
/// from their phone's notification shade.
class AdhanNotificationService {
  static const int adhanNotificationId = 991001;
  static const String adhanChannelId = 'adhan_playback_channel';
  static const String adhanChannelName = 'Panggilan Adzan & Sholat';
  static const String adhanChannelDescription =
      'Notifikasi pemutaran suara adzan ketika masuk waktu salat';
  static const String actionStopAdhan = 'action_stop_adhan';

  /// Global callback for stopping adhan from any isolate
  static VoidCallback? globalStopAdhanCallback;

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  VoidCallback? onStopAdhanRequested;
  bool _isInitialized = false;

  AdhanNotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  /// Initialize notifications plugin with default platform settings
  Future<void> initialize({VoidCallback? onStopAdhan}) async {
    if (onStopAdhan != null) {
      onStopAdhanRequested = onStopAdhan;
      globalStopAdhanCallback = onStopAdhan;
    }

    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
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
            '[AdhanNotificationService] Foreground notification response actionId: ${response.actionId}, type: ${response.notificationResponseType}',
          );
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

      // Request notification permission for Android 13+ (API 33+)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidImplementation?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      if (!e.toString().contains('LateInitializationError')) {
        debugPrint('[AdhanNotificationService] Initialization error: $e');
      }
    }
  }

  /// Show active adhan notification with a direct 'Matikan Adzan' action button
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
        adhanChannelId,
        adhanChannelName,
        channelDescription: adhanChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        playSound: false, // Audio is managed by AdhanAudioService
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
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
        macOS: darwinDetails,
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

  /// Cancel active adhan notification
  Future<void> cancelAdhanNotification() async {
    try {
      await _notificationsPlugin.cancel(id: adhanNotificationId);
    } catch (e) {
      debugPrint('[AdhanNotificationService] Cancel error: $e');
    }
  }
}
