import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'adhan_native_bridge.dart';
import 'adhan_notification_service.dart';

/// Service to handle playing and stopping Adhan audio.
/// Uses high quality, authentic human recordings of Syaikh Mishary Rashid Al-Afasy.
/// Integrates with system notifications so users can stop the Adhan from their phone notification.
class AdhanAudioService extends GetxService {
  AudioPlayer? _player;
  final AdhanNotificationService _notificationService;

  AdhanAudioService({
    AudioPlayer? player,
    AdhanNotificationService? notificationService,
  }) : _player = player,
       _notificationService = notificationService ?? AdhanNotificationService();

  AdhanNotificationService get notificationService => _notificationService;

  static AdhanAudioService? instance;

  final isPlaying = false.obs;
  final currentPrayerName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    instance = this;
    AdhanNotificationService.globalStopAdhanCallback = stopAdhan;
    _notificationService.initialize(onStopAdhan: stopAdhan);
  }

  @protected
  void initPlayer() {
    if (_player != null) return;
    try {
      _player = AudioPlayer();
      _player?.setReleaseMode(ReleaseMode.stop);

      // Listen for completion
      _player?.onPlayerComplete.listen((_) {
        isPlaying.value = false;
        currentPrayerName.value = '';
        _notificationService.cancelAdhanNotification();
      });

      // Listen for state changes - do NOT cancel notification on transient non-playing states
      _player?.onPlayerStateChanged.listen((state) {
        final active = (state == PlayerState.playing);
        isPlaying.value = active;
        if (state == PlayerState.completed) {
          _notificationService.cancelAdhanNotification();
        }
      });
    } catch (e) {
      debugPrint('[AdhanAudioService] Initialization error: $e');
    }
  }

  /// Plays the authentic adhan for the specified prayer name.
  /// Subuh uses the specific Fajr adhan with 'Ash-shalatu khairum minan naum'.
  /// Other canonical prayers (Dzuhur, Ashar, Maghrib, Isya) use regular adhan.
  Future<void> playAdhan({required String prayerName}) async {
    try {
      if (isPlaying.value && currentPrayerName.value == prayerName) {
        return;
      }

      await stopAdhan();

      final isFajr =
          prayerName.trim().toLowerCase() == 'subuh' ||
          prayerName.trim().toLowerCase() == 'fajr';

      final assetPath = isFajr
          ? 'audio/adzan_subuh.mp3'
          : 'audio/adzan_regular.mp3';

      currentPrayerName.value = prayerName;
      isPlaying.value = true;

      // On Android: Start native foreground service (plays audio + displays 1 single notification)
      bool nativeStarted = false;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        nativeStarted = await AdhanNativeBridge.startAdhanService(
          prayerName: prayerName,
          isSubuh: isFajr,
        );
      }

      // If native service didn't start (iOS / Web / fallback): use audioplayers and local notification
      if (!nativeStarted) {
        initPlayer();
        await _notificationService.showAdhanNotification(
          prayerName: prayerName,
          onStopAdhan: stopAdhan,
        );
        await _player?.play(AssetSource(assetPath));
      }
    } catch (e) {
      debugPrint('[AdhanAudioService] Play error for $prayerName: $e');
      isPlaying.value = false;
      currentPrayerName.value = '';
      await _notificationService.cancelAdhanNotification();
    }
  }

  /// Immediately stops the adhan playback and cancels active notification.
  Future<void> stopAdhan() async {
    try {
      await _player?.stop();
      await AdhanNativeBridge.stopAdhanService();
    } catch (e) {
      debugPrint('[AdhanAudioService] Stop error: $e');
    } finally {
      isPlaying.value = false;
      currentPrayerName.value = '';
      await _notificationService.cancelAdhanNotification();
    }
  }

  @override
  void onClose() {
    if (identical(instance, this)) {
      instance = null;
    }
    _notificationService.cancelAdhanNotification();
    _player?.dispose();
    super.onClose();
  }
}
