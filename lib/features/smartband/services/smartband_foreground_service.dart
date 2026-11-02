import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/app_logger.dart';

/// Jembatan Dart ke Android Native Foreground Service untuk mempertahankan
/// koneksi Bluetooth Low Energy (BLE) dengan Smartband HajiCare (ESP32-S3)
/// dan menjaga AI Voice Assistant tetap siaga 24/7 saat layar terkunci / di saku.
class SmartbandForegroundService {
  SmartbandForegroundService._();

  static const MethodChannel _channel =
      MethodChannel('com.hajicare/smartband_background_service');

  static bool _isStarted = false;
  static String _lastMessage = '';

  /// Apakah foreground service saat ini aktif di Android
  static bool get isStarted => _isStarted;

  /// Memulai Android Foreground Service dengan notifikasi persisten
  static Future<bool> startService({
    String title = 'HajiCare Smartband Terhubung',
    String message = 'Monitor Sensor & AI Siaga 24/7',
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final success = await _channel.invokeMethod<bool>('startService', {
        'title': title,
        'message': message,
      });
      _isStarted = success ?? false;
      _lastMessage = message;
      AppLogger.info(
        'Smartband Foreground Service berhasil dimulai: $title ($message)',
        tag: 'SmartbandFgService',
      );
      return _isStarted;
    } catch (e) {
      AppLogger.warn(
        'Gagal memulai Smartband Foreground Service: $e',
        tag: 'SmartbandFgService',
      );
      return false;
    }
  }

  /// Memperbarui isi teks notifikasi persisten di status bar secara efisien
  static Future<bool> updateNotification({
    String title = 'HajiCare Smartband Terhubung',
    required String message,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    // Hindari pemanggilan platform channel berulang jika pesannya sama persis
    if (message == _lastMessage && _isStarted) return true;

    try {
      final success = await _channel.invokeMethod<bool>('updateNotification', {
        'title': title,
        'message': message,
      });
      _lastMessage = message;
      return success ?? false;
    } catch (e) {
      AppLogger.debug(
        'Gagal update notifikasi status bar: $e',
        tag: 'SmartbandFgService',
      );
      return false;
    }
  }

  /// Menghentikan Android Foreground Service saat gelang diputuskan sengaja
  static Future<bool> stopService() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final success = await _channel.invokeMethod<bool>('stopService');
      _isStarted = false;
      _lastMessage = '';
      AppLogger.info(
        'Smartband Foreground Service dihentikan.',
        tag: 'SmartbandFgService',
      );
      return success ?? false;
    } catch (e) {
      AppLogger.warn(
        'Gagal menghentikan Smartband Foreground Service: $e',
        tag: 'SmartbandFgService',
      );
      return false;
    }
  }

  /// Memeriksa status service ke layer native Android
  static Future<bool> isServiceRunning() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final running = await _channel.invokeMethod<bool>('isServiceRunning');
      _isStarted = running ?? false;
      return _isStarted;
    } catch (_) {
      return false;
    }
  }

  /// Meminta pengecualian penghemat baterai Android (Doze Mode / App Standby)
  static Future<bool> requestDisableBatteryOptimization() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final res = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return res ?? false;
    } catch (e) {
      AppLogger.warn(
        'Gagal request ignore battery optimizations: $e',
        tag: 'SmartbandFgService',
      );
      return false;
    }
  }

  /// Mengecek apakah aplikasi sudah dikecualikan dari pembatasan baterai
  static Future<bool> isBatteryOptimizationIgnored() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final res = await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Meminta izin runtime Bluetooth (BLUETOOTH_SCAN & BLUETOOTH_CONNECT pada Android 12+)
  static Future<bool> ensureBlePermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final res = await _channel.invokeMethod<bool>('ensureBlePermissions');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }
}

