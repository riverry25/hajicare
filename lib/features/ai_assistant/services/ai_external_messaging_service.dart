import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/state/hajicare_controller.dart';
import '../../../core/utils/app_logger.dart';
import '../../profile/controllers/profile_controller.dart';
import '../models/ai_messaging_config.dart';
import '../models/ai_reply.dart';
import '../models/sensor_context.dart';

/// Hasil pengiriman laporan AI / Smartband ke WhatsApp.
class WhatsAppDeliveryResult {
  const WhatsAppDeliveryResult({
    required this.success,
    required this.message,
    this.isBackgroundApi = false,
    this.openedWhatsAppApp = false,
    this.targetPhone = '',
  });

  final bool success;
  final String message;

  /// True jika terkirim otomatis di background via API Gateway (Fonnte / CallMeBot) tanpa buka aplikasi WA.
  final bool isBackgroundApi;

  /// True jika menggunakan fallback membuka aplikasi WhatsApp (`wa.me`).
  final bool openedWhatsAppApp;

  final String targetPhone;

  /// Ringkasan singkat ≤ 55 karakter ASCII untuk ditampilkan di layar OLED Smartband.
  String get oledConfirmation => isBackgroundApi
      ? 'WA terkirim otomatis ke Pendamping'
      : (openedWhatsAppApp
            ? 'Membuka WA ke Pendamping'
            : 'Gagal kirim WA: cek nomor tujuan');
}

/// Service terpusat untuk mengirimkan laporan **HajiCare AI Assistant & Smartband ESP32-S3**
/// ke **WhatsApp** (Pendamping / Keluarga) secara langsung dari aplikasi Flutter (*Serverless*).
class AiExternalMessagingService {
  AiExternalMessagingService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static final AiExternalMessagingService instance =
      AiExternalMessagingService();

  final http.Client _httpClient;

  static const String _prefKeyWaPhone = 'hajicare_ai_wa_phone';
  static const String _prefKeyWaToken = 'hajicare_ai_wa_api_token';
  static const String _prefKeyWaProvider = 'hajicare_ai_wa_provider';
  static const String _prefKeyAutoSosFall = 'hajicare_ai_wa_auto_sos_fall';
  static const String _prefKeyAutoRadius = 'hajicare_ai_wa_auto_radius';

  AiMessagingConfig _cachedConfig = AiMessagingConfig.defaults;
  bool _loaded = false;
  StreamSubscription<DocumentSnapshot>? _roomConfigSub;
  String? _listenedRoomId;

  /// Cooldown anti-spam untuk auto-alert darurat (per jenis alert).
  final Map<String, DateTime> _lastAutoAlertSentAt = <String, DateTime>{};
  static const Duration autoAlertCooldown = Duration(seconds: 45);

  AiMessagingConfig get currentConfig => _cachedConfig;

  /// Muat konfigurasi WhatsApp dari `SharedPreferences` & sinkronisasi Room Firestore.
  Future<AiMessagingConfig> loadConfig({bool forceReload = false}) async {
    if (_loaded && !forceReload) {
      _ensureRoomSyncListener();
      return _resolveEffectiveConfig(_cachedConfig);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString(_prefKeyWaPhone)?.trim() ?? '';
      final token = prefs.getString(_prefKeyWaToken)?.trim() ?? '';
      final provider = WhatsAppGatewayProviderX.fromId(
        prefs.getString(_prefKeyWaProvider),
      );
      final autoSos = prefs.getBool(_prefKeyAutoSosFall) ?? true;
      final autoRadius = prefs.getBool(_prefKeyAutoRadius) ?? true;

      _cachedConfig = AiMessagingConfig(
        whatsAppPhone: phone,
        whatsAppApiToken: token,
        gatewayProvider: provider,
        autoAlertOnSosAndFall: autoSos,
        autoAlertOnSafeRadius: autoRadius,
      );
      _loaded = true;
    } catch (e) {
      AppLogger.warn(
        'Gagal memuat AiMessagingConfig: $e',
        tag: 'AiMessagingService',
      );
    }

    _ensureRoomSyncListener();
    return _resolveEffectiveConfig(_cachedConfig);
  }

  /// Simpan konfigurasi WhatsApp ke `SharedPreferences`.
  /// Jika pengguna adalah **Pendamping / Admin** yang aktif di sebuah Room,
  /// otomatis menyinkronkan ke dokumen `rooms/{roomId}` agar seluruh jamaah di rombongan
  /// mewarisi nomor WhatsApp & token gateway pendamping tanpa perlu setting manual.
  Future<AiMessagingConfig> saveConfig(AiMessagingConfig config) async {
    final normalized = config.copyWith(
      whatsAppPhone: config.whatsAppPhone.trim(),
      whatsAppApiToken: config.whatsAppApiToken.trim(),
    );
    _cachedConfig = normalized;
    _loaded = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyWaPhone, normalized.whatsAppPhone);
      await prefs.setString(_prefKeyWaToken, normalized.whatsAppApiToken);
      await prefs.setString(_prefKeyWaProvider, normalized.gatewayProvider.id);
      await prefs.setBool(_prefKeyAutoSosFall, normalized.autoAlertOnSosAndFall);
      await prefs.setBool(_prefKeyAutoRadius, normalized.autoAlertOnSafeRadius);
    } catch (e) {
      AppLogger.warn(
        'Gagal menyimpan AiMessagingConfig ke SharedPreferences: $e',
        tag: 'AiMessagingService',
      );
    }

    // Sinkronkan ke Room Firestore jika user adalah Pendamping / Admin
    unawaited(_syncConfigToActiveRoomIfCompanion(normalized));
    return _resolveEffectiveConfig(normalized);
  }

  Future<void> _syncConfigToActiveRoomIfCompanion(
    AiMessagingConfig config,
  ) async {
    try {
      if (!Get.isRegistered<HajiCareController>()) return;
      final hajiCtrl = Get.find<HajiCareController>();
      final roomId = hajiCtrl.activeRoomId.value?.trim();
      if (roomId == null || roomId.isEmpty) return;

      final isCompanionOrAdmin =
          hajiCtrl.role == UserRole.pendamping ||
          hajiCtrl.role == UserRole.admin;
      if (!isCompanionOrAdmin) return;

      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        'whatsAppConfig': config.toMap(),
        'whatsAppUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.info(
        'Konfigurasi WhatsApp Pendamping berhasil disinkronkan ke Room $roomId',
        tag: 'AiMessagingService',
      );
    } catch (e) {
      AppLogger.warn(
        'Gagal sinkronisasi konfigurasi WA ke Room Firestore: $e',
        tag: 'AiMessagingService',
      );
    }
  }

  /// Dengarkan perubahan `whatsAppConfig` pada dokumen `rooms/{roomId}` agar jamaah
  /// otomatis mendapatkan nomor WA & token gateway yang disetel oleh Pendamping.
  void _ensureRoomSyncListener() {
    try {
      if (!Get.isRegistered<HajiCareController>()) return;
      final hajiCtrl = Get.find<HajiCareController>();
      final roomId = hajiCtrl.activeRoomId.value?.trim();
      if (roomId == null || roomId.isEmpty) {
        _roomConfigSub?.cancel();
        _roomConfigSub = null;
        _listenedRoomId = null;
        return;
      }
      if (_listenedRoomId == roomId && _roomConfigSub != null) return;

      _roomConfigSub?.cancel();
      _listenedRoomId = roomId;
      _roomConfigSub = FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .snapshots()
          .listen((doc) async {
            if (!doc.exists) return;
            final data = doc.data();
            if (data == null) return;
            final waMap = data['whatsAppConfig'];
            if (waMap is Map<String, dynamic>) {
              final roomCfg = AiMessagingConfig.fromMap(waMap);
              // Jika di HP jamaah belum ada nomor WA atau token, warisi dari Pendamping Room
              final mergedPhone = _cachedConfig.whatsAppPhone.trim().isNotEmpty
                  ? _cachedConfig.whatsAppPhone
                  : roomCfg.whatsAppPhone;
              final mergedToken =
                  _cachedConfig.whatsAppApiToken.trim().isNotEmpty
                  ? _cachedConfig.whatsAppApiToken
                  : roomCfg.whatsAppApiToken;

              if (mergedPhone != _cachedConfig.whatsAppPhone ||
                  mergedToken != _cachedConfig.whatsAppApiToken) {
                _cachedConfig = _cachedConfig.copyWith(
                  whatsAppPhone: mergedPhone,
                  whatsAppApiToken: mergedToken,
                  gatewayProvider: roomCfg.gatewayProvider,
                );
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_prefKeyWaPhone, mergedPhone);
                await prefs.setString(_prefKeyWaToken, mergedToken);
              }
            }
          }, onError: (_) {});
    } catch (_) {}
  }

  /// Jika `whatsAppPhone` belum diisi di pengaturan AI, otomatis gunakan `emergencyContact`
  /// dari `ProfileController` (Kontak Darurat Profil).
  AiMessagingConfig _resolveEffectiveConfig(AiMessagingConfig base) {
    if (base.hasValidPhone) return base;

    if (Get.isRegistered<ProfileController>()) {
      final emergency = Get.find<ProfileController>().emergencyContact.value
          .trim();
      if (AiMessagingConfig.normalizePhoneNumber(emergency).length >= 9) {
        return base.copyWith(whatsAppPhone: emergency);
      }
    }
    return base;
  }

  /// Deteksi apakah pertanyaan pengguna atau respons AI meminta pengiriman laporan ke WhatsApp.
  static bool shouldSendToWhatsApp({
    required String userQuestion,
    required AiReply reply,
  }) {
    final channel = reply.notifyChannel?.toLowerCase().trim() ?? '';
    if (channel == 'whatsapp' ||
        channel == 'wa' ||
        channel == 'both' ||
        channel == 'all') {
      return true;
    }

    final q = userQuestion.toLowerCase();

    // 1. Kata kunci eksplisit menyebut WhatsApp / WA
    final mentionsWa =
        q.contains('whatsapp') ||
        q.contains('whats app') ||
        RegExp(r'\b(wa|w\.a)\b').hasMatch(q);
    final hasSendVerb =
        q.contains('kirim') ||
        q.contains('kabari') ||
        q.contains('kabar') ||
        q.contains('lapor') ||
        q.contains('hubungi') ||
        q.contains('chat') ||
        q.contains('pesan') ||
        q.contains('share') ||
        q.contains('bagikan') ||
        q.contains('kasih tahu') ||
        q.contains('beritahu') ||
        q.contains('infokan') ||
        q.contains('tolong');

    if (mentionsWa && hasSendVerb) return true;
    if (q.contains('kirim ke wa') ||
        q.contains('kirim wa') ||
        q.contains('lewat wa') ||
        q.contains('via wa') ||
        q.contains('ke whatsapp')) {
      return true;
    }

    // 2. Perintah suara dari gelang/HP untuk menghubungi/mengabari pendamping atau keluarga
    final mentionsTarget =
        q.contains('pendamping') ||
        q.contains('keluarga') ||
        q.contains('ketua rombongan') ||
        q.contains('petugas');
    final requestsAction =
        q.contains('kabari') ||
        q.contains('kirim pesan') ||
        q.contains('kirim lokasi') ||
        q.contains('kirim kondisi') ||
        q.contains('laporkan') ||
        q.contains('hubungi') ||
        q.contains('kasih tahu') ||
        q.contains('beritahu') ||
        q.contains('minta tolong');

    if (mentionsTarget && requestsAction) {
      return true;
    }

    return false;
  }

  /// Format pesan laporan lengkap ke WhatsApp (Tanpa SpO2 sesuai spesifikasi hardware ESP32-S3).
  static String formatWhatsAppReport({
    required String aiOrAlertMessage,
    required SensorContext sensor,
    bool isEmergencyAlert = false,
    String? emergencyReason,
  }) {
    final buffer = StringBuffer();

    if (isEmergencyAlert) {
      buffer.writeln('🚨 *PERINGATAN DARURAT HAJICARE SMARTBAND* 🚨');
      if (emergencyReason != null && emergencyReason.trim().isNotEmpty) {
        buffer.writeln('⚠️ *Status:* ${emergencyReason.trim()}');
      }
    } else {
      buffer.writeln('🕌 *LAPORAN ASISTEN AI HAJICARE*');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    // 1. Pesan AI / Keluhan Jamaah
    final cleanMsg = aiOrAlertMessage.trim();
    if (cleanMsg.isNotEmpty) {
      buffer.writeln('💬 *Pesan:*');
      buffer.writeln(cleanMsg);
      buffer.writeln('');
    }

    // 2. Identitas Jamaah & Rombongan
    buffer.writeln('👤 *Identitas Jamaah:*');
    buffer.writeln('• Nama: *${sensor.userName}* (${sensor.userRole})');
    if (sensor.hasActiveRoom) {
      final roomParts = <String>[
        if (sensor.roomName != null && sensor.roomName!.isNotEmpty)
          sensor.roomName!,
        if (sensor.kloter != null && sensor.kloter!.isNotEmpty)
          'Kloter ${sensor.kloter}',
        if (sensor.maktab != null && sensor.maktab!.isNotEmpty)
          'Maktab ${sensor.maktab}',
      ];
      if (roomParts.isNotEmpty) {
        buffer.writeln('• Rombongan: ${roomParts.join(" • ")}');
      }
      if (sensor.companionName != null && sensor.companionName!.isNotEmpty) {
        buffer.writeln('• Pendamping: ${sensor.companionName}');
      }
    }
    buffer.writeln('');

    // 3. Telemetri Smartband Real-Time (Tanpa SpO2)
    buffer.writeln('⌚ *Telemetri Smartband ESP32-S3:*');
    if (sensor.isSmartbandConnected) {
      final hrStr = sensor.heartRateBpm > 0
          ? '${sensor.heartRateBpm} BPM'
          : 'Menunggu sensor kulit';
      final tempStr = sensor.temperatureC > 0
          ? '${sensor.temperatureC.toStringAsFixed(1)} °C'
          : 'Menunggu sensor';
      final fallStr = sensor.isFallDetected
          ? '⚠️ TERDETEKSI JATUH!'
          : 'Aman (Tidak Jatuh)';
      final stepsStr = sensor.stepCount != null
          ? '${sensor.stepCount} langkah'
          : '-';

      buffer.writeln('• Status Gelang: Terhubung (${sensor.braceletId})');
      buffer.writeln('• Detak Jantung: *$hrStr*');
      buffer.writeln('• Suhu Tubuh: *$tempStr*');
      buffer.writeln('• Sensor Gerak/Jatuh: *$fallStr*');
      buffer.writeln('• Langkah Kaki: $stepsStr');
    } else {
      buffer.writeln('• Status Gelang: Belum terhubung ke Bluetooth HP');
    }

    // Jarak ke Pendamping & Safe Radius
    if (sensor.distanceToCompanionMeters != null) {
      final dist = sensor.distanceToCompanionMeters!.round();
      final rad = (sensor.safeRadiusMeters ?? 200).round();
      final statusRadius = dist > rad
          ? '⚠️ DI LUAR RADIUS AMAN (> ${rad}m)'
          : '✅ Di Dalam Radius Aman (≤ ${rad}m)';
      buffer.writeln('• Jarak ke Pendamping: *$dist meter* ($statusRadius)');
    }
    buffer.writeln('');

    // 4. Lokasi & Link Google Maps
    buffer.writeln('📍 *Lokasi Real-Time:*');
    if (sensor.locationCityName != null &&
        sensor.locationCityName!.trim().isNotEmpty) {
      buffer.writeln('• Area/Kota: ${sensor.locationCityName}');
    }

    final lat = sensor.smartbandLatitude ?? sensor.latitude;
    final lng = sensor.smartbandLongitude ?? sensor.longitude;
    if (lat != null &&
        lng != null &&
        (lat.abs() > 0.0001 || lng.abs() > 0.0001)) {
      final coordSource = sensor.hasSmartbandLocation
          ? 'GPS Gelang ATGM336H'
          : 'GPS HP';
      final latStr = lat.toStringAsFixed(6);
      final lngStr = lng.toStringAsFixed(6);
      buffer.writeln('• Koordinat ($coordSource): `$latStr, $lngStr`');
      buffer.writeln(
        '• 🗺️ *Buka Google Maps:* https://maps.google.com/?q=$latStr,$lngStr',
      );
    } else {
      buffer.writeln('• Koordinat GPS: Menunggu penguncian satelit GPS');
    }

    return buffer.toString().trim();
  }

  /// Kirim laporan lengkap ke WhatsApp (Otomatis via API Gateway jika token tersedia,
  /// atau fallback membuka `wa.me` jika tanpa token).
  Future<WhatsAppDeliveryResult> sendWhatsAppReport({
    required String aiOrAlertMessage,
    required SensorContext sensor,
    bool isEmergencyAlert = false,
    String? emergencyReason,
    bool allowDeepLinkFallback = true,
    AiMessagingConfig? overrideConfig,
  }) async {
    final config = overrideConfig ?? await loadConfig();
    final phone = config.normalizedPhone;

    final reportText = formatWhatsAppReport(
      aiOrAlertMessage: aiOrAlertMessage,
      sensor: sensor,
      isEmergencyAlert: isEmergencyAlert,
      emergencyReason: emergencyReason,
    );

    // 1. Jika Token Gateway (Fonnte / CallMeBot) tersedia & nomor tujuan valid -> Kirim otomatis di background!
    if (config.hasBackgroundGatewayToken && phone.length >= 9) {
      final bgResult = await _sendViaBackgroundGateway(
        config: config,
        phone: phone,
        message: reportText,
      );
      if (bgResult.success) {
        return bgResult;
      }
      AppLogger.warn(
        'Background WA Gateway gagal (${bgResult.message}), beralih ke fallback wa.me...',
        tag: 'AiMessagingService',
      );
    }

    // 2. Fallback ke Deep Link WhatsApp (`wa.me`)
    if (!allowDeepLinkFallback) {
      return WhatsAppDeliveryResult(
        success: false,
        message: phone.length < 9
            ? 'Nomor WhatsApp tujuan belum diatur di Pengaturan AI / Kontak Darurat.'
            : 'Token API Gateway WhatsApp belum diisi untuk pengiriman background.',
        targetPhone: phone,
      );
    }

    return _openWhatsAppDeepLink(phone: phone, message: reportText);
  }

  /// Kirim pesan WhatsApp di background menggunakan Fonnte API atau CallMeBot API.
  Future<WhatsAppDeliveryResult> _sendViaBackgroundGateway({
    required AiMessagingConfig config,
    required String phone,
    required String message,
  }) async {
    final token = config.whatsAppApiToken.trim();
    try {
      if (config.gatewayProvider == WhatsAppGatewayProvider.callmebot) {
        final uri = Uri.https('api.callmebot.com', '/whatsapp.php', {
          'phone': phone,
          'text': message,
          'apikey': token,
        });
        final response = await _httpClient
            .get(uri)
            .timeout(const Duration(seconds: 12));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return WhatsAppDeliveryResult(
            success: true,
            isBackgroundApi: true,
            targetPhone: phone,
            message:
                'Pesan WhatsApp berhasil dikirim otomatis di background ke +$phone.',
          );
        }
        return WhatsAppDeliveryResult(
          success: false,
          targetPhone: phone,
          message: 'CallMeBot merespons HTTP ${response.statusCode}.',
        );
      }

      // Default: Fonnte WhatsApp API (`https://api.fonnte.com/send`)
      final response = await _httpClient
          .post(
            Uri.parse('https://api.fonnte.com/send'),
            headers: <String, String>{'Authorization': token},
            body: <String, String>{
              'target': phone,
              'message': message,
              'countryCode': '62',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final status = decoded is Map ? (decoded['status'] == true) : true;
        if (status) {
          AppLogger.info(
            'WhatsApp berhasil dikirim otomatis via Fonnte ke +$phone',
            tag: 'AiMessagingService',
          );
          return WhatsAppDeliveryResult(
            success: true,
            isBackgroundApi: true,
            targetPhone: phone,
            message:
                'Laporan berhasil dikirim otomatis ke WhatsApp (+$phone) tanpa membuka aplikasi.',
          );
        }
        final reason = decoded['reason']?.toString() ?? 'Token/target tidak valid';
        return WhatsAppDeliveryResult(
          success: false,
          targetPhone: phone,
          message: 'Fonnte menolak pengiriman: $reason',
        );
      }

      return WhatsAppDeliveryResult(
        success: false,
        targetPhone: phone,
        message: 'Gateway Fonnte merespons HTTP ${response.statusCode}.',
      );
    } catch (e) {
      return WhatsAppDeliveryResult(
        success: false,
        targetPhone: phone,
        message: 'Gagal menghubungi server gateway WhatsApp: $e',
      );
    }
  }

  /// Buka aplikasi WhatsApp (`wa.me`) dengan teks yang sudah disiapkan.
  Future<WhatsAppDeliveryResult> _openWhatsAppDeepLink({
    required String phone,
    required String message,
  }) async {
    try {
      // Jika nomor tujuan ada, arahkan langsung ke nomor tersebut; jika kosong, buka pemilih kontak WA dengan teks
      final Uri uri = phone.length >= 9
          ? Uri.https('wa.me', '/$phone', <String, String>{'text': message})
          : Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return WhatsAppDeliveryResult(
          success: true,
          openedWhatsAppApp: true,
          targetPhone: phone,
          message: phone.length >= 9
              ? 'Membuka WhatsApp ke +$phone dengan laporan lengkap.'
              : 'Membuka WhatsApp untuk memilih penerima laporan.',
        );
      }

      // Fallback kedua via https://api.whatsapp.com/send
      final fallbackUri = Uri.https(
        'api.whatsapp.com',
        '/send',
        <String, String>{
          if (phone.length >= 9) 'phone': phone,
          'text': message,
        },
      );
      final fallbackLaunched = await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalApplication,
      );
      if (fallbackLaunched) {
        return WhatsAppDeliveryResult(
          success: true,
          openedWhatsAppApp: true,
          targetPhone: phone,
          message: 'Membuka WhatsApp dengan laporan lengkap.',
        );
      }

      return WhatsAppDeliveryResult(
        success: false,
        targetPhone: phone,
        message: 'Tidak dapat membuka aplikasi WhatsApp di perangkat ini.',
      );
    } catch (e) {
      return WhatsAppDeliveryResult(
        success: false,
        targetPhone: phone,
        message: 'Gagal membuka WhatsApp: $e',
      );
    }
  }

  /// Pemicu Otomatis (Auto-Alert) saat terjadi kondisi darurat pada Smartband:
  /// - Tombol SOS Gelang (Tahan 3 detik)
  /// - Deteksi Jatuh MPU6050 (`FALL_ALERT`)
  /// - Keluar dari Batas Safe Radius
  Future<WhatsAppDeliveryResult?> dispatchEmergencyAutoAlert({
    required String alertKey,
    required String emergencyReason,
    required SensorContext sensor,
  }) async {
    final config = await loadConfig();
    if (!config.hasValidPhone) {
      AppLogger.debug(
        'Auto-Alert WA dilewati karena nomor WhatsApp tujuan belum diatur.',
        tag: 'AiMessagingService',
      );
      return null;
    }

    if (alertKey == 'SAFE_RADIUS' && !config.autoAlertOnSafeRadius) {
      return null;
    }
    if ((alertKey == 'SOS' || alertKey == 'FALL') &&
        !config.autoAlertOnSosAndFall) {
      return null;
    }

    // Cooldown anti-spam
    final now = DateTime.now();
    final lastSent = _lastAutoAlertSentAt[alertKey];
    if (lastSent != null && now.difference(lastSent) < autoAlertCooldown) {
      return null;
    }
    _lastAutoAlertSentAt[alertKey] = now;

    final String detailMessage = switch (alertKey) {
      'SOS' =>
        'Jamaah *${sensor.userName}* menekan tombol darurat SOS pada gelang Smartband (Tahan 3 Detik) dan membutuhkan pertolongan segera!',
      'FALL' =>
        'Sensor akselerometer MPU6050 pada gelang Smartband mendeteksi indikasi *TERJATUH* pada jamaah *${sensor.userName}*. Mohon segera periksa kondisi beliau!',
      'SAFE_RADIUS' =>
        'Jamaah *${sensor.userName}* terdeteksi bergerak keluar dari batas radius aman (${(sensor.safeRadiusMeters ?? 200).round()}m) dari posisi pendamping.',
      _ => emergencyReason,
    };

    return sendWhatsAppReport(
      aiOrAlertMessage: detailMessage,
      sensor: sensor,
      isEmergencyAlert: true,
      emergencyReason: emergencyReason,
      // Jika untuk radius alert dan tidak ada token background, jangan tiba-tiba keluar dari aplikasi setiap jalan
      allowDeepLinkFallback: alertKey == 'SOS' || alertKey == 'FALL',
    );
  }
}
