import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service penyimpan kredensial dan sesi terenkripsi berbasis OWASP MASVS V1 (Storage & Privacy).
/// Menggunakan Android Keystore (EncryptedSharedPreferences) dan iOS Keychain.
class SecureStorageService {
  SecureStorageService._internal()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(resetOnError: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  static final SecureStorageService instance = SecureStorageService._internal();

  factory SecureStorageService({FlutterSecureStorage? customStorage}) {
    if (customStorage != null) {
      return SecureStorageService._custom(customStorage);
    }
    return instance;
  }

  SecureStorageService._custom(FlutterSecureStorage storage)
    : _storage = storage;

  final FlutterSecureStorage _storage;

  // ── Keys Kredensial & Sesi Sensitif ─────────────────────────────────────────
  static const String keyAuthToken = 'sec_auth_token';
  static const String keyRefreshToken = 'sec_refresh_token';
  static const String keyRememberMe = 'sec_remember_me';
  static const String keyActiveRoomId = 'sec_active_room_id';
  static const String keyUserRole = 'sec_user_role';
  static const String keyUserUid = 'sec_user_uid';

  // Legacy SharedPreferences keys for automatic migration
  static const String _legacyKeyRememberMe = 'hajicare_remember_me';
  static const String _legacyKeyActiveRoomId = 'activeRoomId';
  static const String _legacyKeyUserRole = 'userRole';

  /// Menyimpan nilai terenkripsi (dengan fallback graceful jika channel tidak tersedia)
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[SecureStorageService] Error write key $key: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } catch (_) {}
    }
  }

  /// Membaca nilai terenkripsi (dengan fallback graceful jika channel tidak tersedia)
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('[SecureStorageService] Error read key $key: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      } catch (_) {
        return null;
      }
    }
  }

  /// Menghapus kunci tertentu
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('[SecureStorageService] Error delete key $key: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  /// Memeriksa keberadaan kunci
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('[SecureStorageService] Error containsKey $key: $e');
      return false;
    }
  }

  /// Membersihkan seluruh data sesi terenkripsi (digunakan saat logout)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[SecureStorageService] Error deleteAll: $e');
    }
  }

  // ── Helpers Spesifik Autentikasi & Sesi ─────────────────────────────────────

  /// Menyimpan preferensi 'Remember Me' secara aman
  Future<void> setRememberMe(bool value) async {
    await write(keyRememberMe, value ? 'true' : 'false');
  }

  /// Membaca preferensi 'Remember Me' dengan fallback migrasi dari SharedPreferences
  Future<bool> isRememberMe() async {
    final val = await read(keyRememberMe);
    if (val != null) {
      return val == 'true';
    }

    // Coba migrasi dari SharedPreferences lama jika ada
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_legacyKeyRememberMe)) {
        final legacyVal = prefs.getBool(_legacyKeyRememberMe) ?? true;
        await setRememberMe(legacyVal);
        await prefs.remove(_legacyKeyRememberMe);
        return legacyVal;
      }
    } catch (_) {}

    return true; // Default true
  }

  /// Menyimpan room ID aktif secara terenkripsi
  Future<void> setActiveRoomId(String? roomId) async {
    if (roomId != null && roomId.trim().isNotEmpty) {
      await write(keyActiveRoomId, roomId.trim());
    } else {
      await delete(keyActiveRoomId);
    }
  }

  /// Membaca room ID aktif dengan fallback migrasi dari SharedPreferences
  Future<String?> getActiveRoomId() async {
    final val = await read(keyActiveRoomId);
    if (val != null && val.trim().isNotEmpty) {
      return val.trim();
    }

    // Fallback migrasi
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_legacyKeyActiveRoomId);
      if (legacy != null && legacy.trim().isNotEmpty) {
        final trimmed = legacy.trim();
        await setActiveRoomId(trimmed);
        await prefs.remove(_legacyKeyActiveRoomId);
        return trimmed;
      }
    } catch (_) {}

    return null;
  }

  /// Menyimpan peran pengguna secara terenkripsi
  Future<void> setUserRole(String role) async {
    await write(keyUserRole, role.trim().toLowerCase());
  }

  /// Membaca peran pengguna terenkripsi dengan fallback migrasi
  Future<String?> getUserRole() async {
    final val = await read(keyUserRole);
    if (val != null && val.trim().isNotEmpty) {
      return val.trim().toLowerCase();
    }

    // Fallback migrasi
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_legacyKeyUserRole);
      if (legacy != null && legacy.trim().isNotEmpty) {
        final role = legacy.trim().toLowerCase();
        await setUserRole(role);
        await prefs.remove(_legacyKeyUserRole);
        return role;
      }
    } catch (_) {}

    return null;
  }

  /// Membersihkan seluruh sesi dan kredensial saat logout
  Future<void> clearAuthSession() async {
    await delete(keyAuthToken);
    await delete(keyRefreshToken);
    await delete(keyActiveRoomId);
    await delete(keyUserRole);
    await delete(keyUserUid);

    // Juga bersihkan residu SharedPreferences lama
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKeyActiveRoomId);
      await prefs.remove(_legacyKeyUserRole);
    } catch (_) {}
  }
}
