import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Service untuk inisialisasi Firebase App Check sesuai standar OWASP MASVS V4 (Network Security)
/// dan pedoman keamanan Firebase AI Logic.
///
/// Memastikan bahwa seluruh permintaan API ke backend (Firestore, Storage, Cloud Functions, AI Logic)
/// diverifikasi keasliannya dan hanya diizinkan jika berasal dari build aplikasi resmi (Play Integrity).
class AppCheckService {
  AppCheckService._();

  static bool _isInitialized = false;

  /// Menginisialisasi Firebase App Check provider:
  /// - Di mode rilis (Production): Menggunakan [AndroidProvider.playIntegrity] pada Android dan
  ///   [AppleProvider.deviceCheck] pada iOS.
  /// - Di mode pengujian lokal (Debug): Menggunakan [AndroidProvider.debug] dan [AppleProvider.debug]
  ///   tanpa menyimpan hardcoded token dalam kode sumber.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        debugPrint(
          '[AppCheckService] Initializing Firebase App Check in DEBUG mode...',
        );
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidDebugProvider(),
          providerApple: const AppleDebugProvider(),
        );
      } else {
        debugPrint(
          '[AppCheckService] Initializing Firebase App Check with Play Integrity...',
        );
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidPlayIntegrityProvider(),
          providerApple: const AppleDeviceCheckProvider(),
        );
      }

      _isInitialized = true;
      debugPrint(
        '[AppCheckService] Firebase App Check activated successfully.',
      );
    } catch (e) {
      // Tangani error secara anggun agar aplikasi tidak crash jika dijalankan pada
      // lingkungan tanpa Google Play Services aktif.
      debugPrint(
        '[AppCheckService] Warning: Firebase App Check activation error: $e',
      );
    }
  }
}
