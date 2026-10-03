import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AdhanForegroundService {
  static const MethodChannel _channel =
      MethodChannel('com.hajicare/adhan_native_service');

  /// Starts the native Android Foreground Service to play the authentic adhan audio.
  static Future<bool> startAdhan({
    required String prayerName,
    required bool isSubuh,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('startAdhanService', {
        'prayerName': prayerName,
        'isSubuh': isSubuh,
      });
      return result ?? false;
    } catch (e) {
      // Requirement 17: print exact error if service start fails
      debugPrint('[SERVICE] ERROR: $e');
      return false;
    }
  }

  /// Stops the native Android Foreground Service and stops audio playback.
  static Future<bool> stopAdhan() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopAdhanService');
      return result ?? false;
    } catch (e) {
      debugPrint('[SERVICE] ERROR: $e');
      return false;
    }
  }

  /// Checks if the Foreground Service is currently running.
  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
