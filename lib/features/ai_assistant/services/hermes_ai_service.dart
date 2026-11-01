import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/state/app_settings_controller.dart';
import '../../../core/utils/app_logger.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_reply.dart';
import '../models/ai_server_config.dart';
import '../models/ai_server_status.dart';
import '../models/sensor_context.dart';
import 'hermes_response_parser.dart';
import 'oled_text_formatter.dart';

/// Exception terstruktur untuk komunikasi dengan server Hermes Agent.
class HermesAiException implements Exception {
  const HermesAiException(
    this.userMessage, {
    this.statusCode,
    this.isConfigError = false,
  });

  final String userMessage;
  final int? statusCode;
  final bool isConfigError;

  @override
  String toString() => 'HermesAiException($statusCode): $userMessage';
}

/// Data Service untuk berkomunikasi dengan **Hermes Agent**
/// (`/v1/chat/completions` & `/health`) serta mengelola penyimpanan konfigurasi
/// dinamis (`SharedPreferences`).
class HermesAiService {
  HermesAiService({
    http.Client? httpClient,
    Duration requestTimeout = const Duration(seconds: 25),
    Duration healthTimeout = const Duration(seconds: 7),
  }) : _httpClient = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _requestTimeout = requestTimeout,
       _healthTimeout = healthTimeout;

  final http.Client _httpClient;
  final bool _ownsClient;
  final Duration _requestTimeout;
  final Duration _healthTimeout;

  // Keys SharedPreferences untuk Dynamic URL & API Key Configuration
  static const String prefKeyBaseUrl = 'hajicare_hermes_base_url';
  static const String prefKeyApiKey = 'hajicare_hermes_api_key';
  static const String prefKeyModel = 'hajicare_hermes_model';

  /// Bangun HTTP headers wajib sesuai spesifikasi teknis Groq, OpenRouter, atau server custom.
  static Map<String, String> buildHeaders(AiServerConfig config) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${config.resolvedApiKey}',
    };
    if (config.isOpenRouter) {
      headers['HTTP-Referer'] = 'https://hajicare.id';
      headers['X-Title'] = 'HajiCare';
    }
    if (config.isNgrokHost) {
      headers['ngrok-skip-browser-warning'] = 'true';
    }
    return headers;
  }

  static String _resolveReplyLanguageName() {
    final code = Get.isRegistered<AppSettingsController>()
        ? Get.find<AppSettingsController>()
              .currentLocale
              .languageCode
              .toLowerCase()
        : (Get.locale?.languageCode ?? 'id').toLowerCase();
    return switch (code) {
      'en' => 'English',
      'jv' => 'Basa Jawi (Krama Alus yang sopan dan mudah dipahami)',
      'su' => 'Basa Sunda (Lemes yang sopan dan mudah dipahami)',
      _ => 'Bahasa Indonesia',
    };
  }

  /// Bangun `system` prompt sesuai spesifikasi dengan konteks nyata dari
  /// Smartband BLE + seluruh modul aplikasi (GPS HP, Jarak Real-Time, Room, Salat, Kiblat, SOS).
  static String buildSystemPrompt(SensorContext sensor) {
    final replyLang = _resolveReplyLanguageName();
    final String bpmText = sensor.isSmartbandConnected
        ? (sensor.heartRateBpm > 0
              ? '${sensor.heartRateBpm}'
              : 'Menunggu pembacaan sensor gelang')
        : 'BELUM TERHUBUNG (Gelang Bluetooth belum tersambung)';
    final String tempText = sensor.isSmartbandConnected
        ? (sensor.temperatureC > 0
              ? sensor.temperatureC.toStringAsFixed(1)
              : 'Menunggu sensor')
        : 'BELUM TERHUBUNG';
    final String fallStatus = sensor.fallStatusLabel;
    final String distanceText = sensor.distanceToCompanionMeters != null
        ? '${sensor.distanceToCompanionMeters!.round()}'
        : 'Belum tersedia (${sensor.distanceStatusSummary})';

    final String smartbandExtra = sensor.isSmartbandConnected
        ? 'Status Gelang BLE=TERHUBUNG (ID: ${sensor.braceletId}, SpO2=${sensor.spo2Percent ?? "--"}%, Langkah=${sensor.stepCount ?? 0}, Baterai=${sensor.batteryPercent ?? "--"}%).'
        : 'Status Gelang BLE=BELUM TERHUBUNG ke HP.';

    final String roomContext = sensor.hasActiveRoom
        ? 'Tergabung di Room="${sensor.roomName ?? "-"}" (Kode: ${sensor.roomCode ?? "-"}, Kloter: ${sensor.kloter ?? "-"}, Maktab: ${sensor.maktab ?? "-"}, Pendamping: ${sensor.companionName ?? "-"}${sensor.closestJamaahSummary != null ? ". Ringkasan Terdekat/Terjauh: ${sensor.closestJamaahSummary}" : ""}${sensor.roomMembersSummary != null ? ". ${sensor.roomMembersSummary}" : ""}).'
        : 'Belum bergabung ke Room rombongan.';

    final String profileContext = sensor.userProfileSummary != null
        ? 'Profil & Rekam Medis Pengguna=(${sensor.userProfileSummary}). '
        : '';

    final String prayerContext =
        'Lokasi Kota=${sensor.locationCityName ?? "Sesuai GPS HP"}, '
        'Tanggal Hijriah=${sensor.hijriDateText ?? "-"}, '
        'Salat Berikutnya=${sensor.nextPrayerName ?? "-"} pukul ${sensor.nextPrayerTime ?? "-"} (Hitung mundur: ${sensor.nextPrayerCountdown ?? "-"}), '
        'Jadwal Salat Hari Ini=(${sensor.todayPrayerScheduleSummary ?? "-"}), '
        'Arah Kiblat=${sensor.qiblaBearingDegrees != null ? "${sensor.qiblaBearingDegrees!.round()} derajat dari Utara" : "-"}.';

    final String alertContext =
        'SOS Darurat Aktif=${sensor.activeSosCount} (SOS Pengguna=${sensor.isSelfSosActive ? "AKTIF" : "Tidak"}), '
        'Notifikasi Belum Dibaca=${sensor.unreadNotificationsCount}'
        '${sensor.latestNotificationSummary != null ? " (Pesan Terakhir: ${sensor.latestNotificationSummary})" : ""}.';

    return 'STOP CAVEMAN MODE / NORMAL MODE ACTIVE. '
        'Kamu adalah asisten kesehatan dan pemandu pintar HajiCare untuk jamaah haji/umrah lansia, disabilitas, dan pendamping. '
        'Kamu WAJIB BISA MENJAWAB SEMUA PERTANYAAN pengguna secara lengkap, baik pertanyaan tentang data real-time aplikasi (siapa jamaah terdekat/terjauh, daftar seluruh anggota room, jarak ke pendamping, koordinat GPS HP & gelang, kloter, maktab, nomor porsi/paspor/medis, jadwal salat, arah kiblat, peringatan SOS, notifikasi, sensor gelang BLE) MAUPUN pertanyaan umum apa saja (tata cara & rukun haji/umrah, bacaan doa lengkap beserta artinya, kesehatan di Tanah Suci, lokasi Makkah/Madinah, percakapan bahasa Arab, pengenalan uang Riyal, fitur BISINDO/bahasa isyarat di aplikasi, atau pengetahuan umum lainnya). '
        'Konteks sensor gelang jamaah saat ini: Detak Jantung=$bpmText BPM, Suhu=$tempText°C, Status Jatuh=$fallStatus, Jarak ke Pendamping=${distanceText}m. '
        '$smartbandExtra '
        'Konteks Nyata Aplikasi HajiCare di HP Pengguna (Nama=${sensor.userName}, Peran=${sensor.userRole}): '
        '$profileContext'
        'Posisi=(${sensor.positionStatusSummary}). '
        'Detail Jarak Pendamping=(${sensor.distanceStatusSummary}). '
        'Rombongan & Daftar Anggota=($roomContext) '
        'Ibadah=($prayerContext) '
        'Keamanan & Pesan=($alertContext) '
        'Fitur Aplikasi HajiCare yang Tersedia=(Peta Interaktif & Pelacakan Rombongan Real-time, Jadwal Salat & Kompas Kiblat, Panduan Doa Haji/Umrah Audio, Deteksi Uang Riyal/Rupiah Kamera untuk Tunanetra, Bahasa Isyarat BISINDO & Teks-ke-Isyarat untuk Tuli, Komunikasi Cepat Arab-Indonesia, Tombol Darurat SOS, dan Koneksi Gelang Pintar BLE). '
        'INSTRUKSI WAJIB: Gunakan data nyata di atas untuk pertanyaan status aplikasi, JANGAN membuat simulasi atau mengarang angka sensor. '
        'Jawab dalam bahasa $replyLang dengan kalimat utuh, ramah, sopan, tenang, dan jelas (JANGAN gunakan gaya "terse caveman"). '
        'DILARANG KERAS menulis tanda kurung siku atau timestamp angka seperti 0.0: atau 3.8: di dalam teks jawaban. '
        'WAJIB balas HANYA dalam format JSON murni tanpa markdown codeblock dengan struktur: '
        '{"speech": "kalimat lengkap untuk dibacakan suara", "oled": "ringkasan maksimal 55 karakter tanpa emoji untuk layar gelang"}.';
  }

  /// Bangun pesan user yang menyertakan pengingat konteks nyata & format JSON
  /// tanpa tanda kurung siku agar model tidak pernah menghasilkan timestamp subtitle.
  static String buildContextualUserMessage(
    String userQuestion,
    SensorContext sensor,
  ) {
    final replyLang = _resolveReplyLanguageName();
    final bandInfo = sensor.isSmartbandConnected
        ? 'Gelang BLE Terhubung (HR=${sensor.heartRateBpm} BPM, Suhu=${sensor.temperatureLabel}C, Jatuh=${sensor.fallStatusLabel})'
        : 'Gelang BLE BELUM TERHUBUNG';
    final distInfo = sensor.distanceToCompanionMeters != null
        ? 'Jarak ke ${sensor.companionName ?? "Pendamping"}=${sensor.distanceToCompanionMeters!.round()}m'
        : sensor.distanceStatusSummary;
    final closestInfo = sensor.closestJamaahSummary != null
        ? '${sensor.closestJamaahSummary}; '
        : '';

    return '$userQuestion\n\n'
        '(Catatan Sistem: STOP CAVEMAN MODE. Jawab dengan kalimat utuh dan ramah dalam bahasa $replyLang, TANPA timestamp angka dan TANPA kurung siku. '
        'Ringkasan Data Nyata: Pengguna=${sensor.userName}, $bandInfo, $distInfo, $closestInfo'
        'Salat berikutnya=${sensor.nextPrayerName ?? "-"} ${sensor.nextPrayerTime ?? "-"}. '
        'Balas HANYA JSON murni: {"speech": "jawaban kalimat utuh bahasa $replyLang tanpa kurung siku", "oled": "ringkasan <=55 char ASCII tanpa emoji"})';
  }

  /// Muat konfigurasi server AI dari `SharedPreferences`.
  /// Otomatis memigrasikan nilai placeholder lama ke konfigurasi final produksi.
  Future<AiServerConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(prefKeyBaseUrl)?.trim();
      final savedKey = prefs.getString(prefKeyApiKey)?.trim();
      final savedModel = prefs.getString(prefKeyModel)?.trim();

      final isOldPlaceholderUrl =
          savedUrl == null ||
          savedUrl.isEmpty ||
          savedUrl.contains('DOMAIN_STATIC_NGROK_KAMU') ||
          savedUrl.contains('unbalance-compile-chariot.ngrok-free.dev');
      final isOldPlaceholderKey =
          savedKey == null ||
          savedKey.isEmpty ||
          savedKey == AiServerConfig.legacyDefaultApiKey ||
          savedKey.startsWith('sk-675b8dd28e37e08f') ||
          AiServerConfig.isSystemKey(savedKey);
      final isOldPlaceholderModel =
          savedModel == null ||
          savedModel.isEmpty ||
          savedModel == 'ngoding-combo' ||
          (isOldPlaceholderUrl &&
              savedModel == AiServerConfig.legacyDefaultModel);

      final resolvedUrl = isOldPlaceholderUrl
          ? AiServerConfig.defaultBaseUrl
          : AiServerConfig.normalizeBaseUrl(savedUrl);
      final resolvedKey = isOldPlaceholderKey
          ? AiServerConfig.systemVaultMarker
          : savedKey;
      final resolvedModel = isOldPlaceholderModel
          ? AiServerConfig.defaultModel
          : savedModel;

      // Simpan hasil migrasi bila sebelumnya masih memakai nilai placeholder lama
      if (isOldPlaceholderUrl && savedUrl != null) {
        await prefs.setString(prefKeyBaseUrl, resolvedUrl);
      }
      if (isOldPlaceholderKey && savedKey != null) {
        await prefs.setString(prefKeyApiKey, resolvedKey);
      }
      if (isOldPlaceholderModel && savedModel != null) {
        await prefs.setString(prefKeyModel, resolvedModel);
      }

      return AiServerConfig(
        baseUrl: resolvedUrl,
        apiKey: resolvedKey,
        model: resolvedModel,
      );
    } catch (e) {
      AppLogger.warn(
        'Gagal memuat AiServerConfig dari SharedPreferences: $e',
        tag: 'HermesAiService',
      );
      return AiServerConfig.defaults;
    }
  }

  /// Simpan konfigurasi server AI ke `SharedPreferences`.
  Future<AiServerConfig> saveConfig(AiServerConfig config) async {
    final isSys = AiServerConfig.isSystemKey(config.apiKey);
    final normalized = AiServerConfig(
      baseUrl: AiServerConfig.normalizeBaseUrl(config.baseUrl),
      apiKey: isSys
          ? AiServerConfig.systemVaultMarker
          : config.apiKey.trim(),
      model: config.model.trim().isEmpty
          ? AiServerConfig.defaultModel
          : config.model.trim(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyBaseUrl, normalized.baseUrl);
      await prefs.setString(prefKeyApiKey, normalized.apiKey);
      await prefs.setString(prefKeyModel, normalized.model);
    } catch (e) {
      AppLogger.warn(
        'Gagal menyimpan AiServerConfig ke SharedPreferences: $e',
        tag: 'HermesAiService',
      );
    }
    return normalized;
  }

  /// Kembalikan konfigurasi server ke nilai default bawaan.
  Future<AiServerConfig> resetConfigToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKeyBaseUrl);
      await prefs.remove(prefKeyApiKey);
      await prefs.remove(prefKeyModel);
    } catch (_) {}
    return AiServerConfig.defaults;
  }

  /// Cek status koneksi Server Hermes via `GET /health` (dengan fallback `/v1/models`).
  Future<AiServerStatus> checkHealth(AiServerConfig config) async {
    if (config.isPlaceholder) {
      return AiServerStatus(
        health: AiServerHealth.notConfigured,
        message: 'Mode Demo Pintar aktif. Atur URL Ngrok untuk server live.',
        checkedAt: DateTime.now(),
      );
    }

    final urlError = AiServerConfig.validateBaseUrl(config.baseUrl);
    if (urlError != null) {
      return AiServerStatus(
        health: AiServerHealth.notConfigured,
        message: urlError,
        checkedAt: DateTime.now(),
      );
    }

    final stopwatch = Stopwatch()..start();
    final headers = buildHeaders(config);

    try {
      // Utamakan GET /v1/models (endpoint standar OpenAI-compatible & 9Router)
      // agar tidak memunculkan 404 Not Found pada log terminal Ngrok.
      var response = await _httpClient
          .get(config.modelsUri, headers: headers)
          .timeout(_healthTimeout);

      // Fallback ke GET /health hanya jika /v1/models mengembalikan 404
      if (response.statusCode == 404) {
        response = await _httpClient
            .get(config.healthUri, headers: headers)
            .timeout(_healthTimeout);
      }
      stopwatch.stop();

      final bodyLower = response.body.toLowerCase();
      final isNgrokErrorHtml =
          bodyLower.contains('err_ngrok') ||
          bodyLower.contains('ngrok-free.app is offline') ||
          (bodyLower.contains('<html') && bodyLower.contains('ngrok'));

      if (isNgrokErrorHtml) {
        return AiServerStatus(
          health: AiServerHealth.offline,
          latency: stopwatch.elapsed,
          message: 'Tunnel Ngrok sedang tidak aktif di server.',
          checkedAt: DateTime.now(),
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AiServerStatus(
          health: AiServerHealth.online,
          latency: stopwatch.elapsed,
          message:
              'Terhubung ke Hermes (${stopwatch.elapsedMilliseconds} ms)',
          checkedAt: DateTime.now(),
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return AiServerStatus(
          health: AiServerHealth.unauthorized,
          latency: stopwatch.elapsed,
          message:
              'API Key Bearer ditolak oleh server (${response.statusCode}).',
          checkedAt: DateTime.now(),
        );
      }

      return AiServerStatus(
        health: AiServerHealth.offline,
        latency: stopwatch.elapsed,
        message: 'Server merespons HTTP ${response.statusCode}.',
        checkedAt: DateTime.now(),
      );
    } on TimeoutException {
      stopwatch.stop();
      return AiServerStatus(
        health: AiServerHealth.offline,
        message: 'Waktu tunggu habis saat menghubungi server Hermes.',
        checkedAt: DateTime.now(),
      );
    } catch (e) {
      stopwatch.stop();
      return AiServerStatus(
        health: AiServerHealth.offline,
        message: 'Server Hermes tidak terjangkau. Periksa koneksi/URL Ngrok.',
        checkedAt: DateTime.now(),
      );
    }
  }

  /// Kirim pertanyaan jamaah + konteks sensor ke `/v1/chat/completions`.
  /// Jika target utama (misal Groq Cloud) mengalami rate limit / timeout / offline,
  /// secara otomatis dan senyap mengalihkan pertanyaan ke OpenRouter Cloud Fallback.
  Future<AiReply> sendChatCompletion({
    required AiServerConfig config,
    required String userQuestion,
    required SensorContext sensorContext,
    List<AiChatMessage> history = const <AiChatMessage>[],
  }) async {
    final trimmedQuestion = userQuestion.trim();
    if (trimmedQuestion.isEmpty) {
      throw const HermesAiException('Pertanyaan tidak boleh kosong.');
    }

    if (config.isPlaceholder) {
      throw const HermesAiException(
        'URL Server AI masih menggunakan domain placeholder.',
        isConfigError: true,
      );
    }

    final urlError = AiServerConfig.validateBaseUrl(config.baseUrl);
    if (urlError != null) {
      throw HermesAiException(urlError, isConfigError: true);
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': buildSystemPrompt(sensorContext)},
      ..._buildHistoryMessages(history, maxMessages: 4),
      {
        'role': 'user',
        'content': buildContextualUserMessage(trimmedQuestion, sensorContext),
      },
    ];

    final payload = <String, dynamic>{
      'model': config.model,
      'messages': messages,
      'temperature': 0.3,
      'max_tokens': 2048,
    };

    try {
      return await _executeChatCompletionRequest(config, payload);
    } catch (e) {
      // Auto-Fallback: Jika provider utama bukan OpenRouter (misal Groq atau Custom Server)
      // dan gagal (HTTP 429, timeout, network error, 5xx), otomatis lempar ke OpenRouter!
      if (!config.isOpenRouter) {
        AppLogger.info(
          'Target AI utama (${config.baseUrl}) mengalami kendala ($e). Mencoba Auto-Fallback ke OpenRouter Cloud...',
          tag: 'HermesAiService',
        );
        try {
          final fallbackConfig = AiServerConfig.openRouterFallback;
          final fallbackPayload = <String, dynamic>{
            'model': fallbackConfig.model,
            'messages': messages,
            'temperature': 0.3,
            'max_tokens': 2048,
          };
          return await _executeChatCompletionRequest(fallbackConfig, fallbackPayload);
        } catch (fallbackError) {
          AppLogger.warn(
            'Auto-Fallback OpenRouter juga mengalami kendala: $fallbackError',
            tag: 'HermesAiService',
          );
        }
      }
      rethrow;
    }
  }

  Future<AiReply> _executeChatCompletionRequest(
    AiServerConfig config,
    Map<String, dynamic> payload,
  ) async {
    const maxAttempts = 2;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await _httpClient
            .post(
              config.chatCompletionsUri,
              headers: buildHeaders(config),
              body: jsonEncode(payload),
            )
            .timeout(_requestTimeout);

        final rawBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        final lowerBody = rawBody.toLowerCase();

        if (lowerBody.contains('err_ngrok') ||
            (lowerBody.contains('<html') && lowerBody.contains('ngrok'))) {
          throw HermesAiException(
            'Tunnel Ngrok sedang offline atau halaman intersepsi aktif.',
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw HermesAiException(
            'Autentikasi gagal (HTTP ${response.statusCode}). Periksa API Key Bearer.',
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 429) {
          throw const HermesAiException(
            'Batas kuota/rate limit provider tercapai (HTTP 429).',
            statusCode: 429,
          );
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (attempt < maxAttempts && response.statusCode >= 500) {
            continue;
          }
          throw HermesAiException(
            'Server AI mengembalikan kode HTTP ${response.statusCode}.',
            statusCode: response.statusCode,
          );
        }

        return HermesResponseParser.parseHttpBody(rawBody);
      } on FormatException catch (e) {
        AppLogger.warn(
          'FormatException respons LLM (percobaan $attempt/$maxAttempts): ${e.message}',
          tag: 'HermesAiService',
        );
        if (attempt < maxAttempts) {
          continue;
        }
        throw HermesAiException(
          'Respons model server terpotong (${e.message}). Menggunakan asisten lokal berbasis data nyata.',
        );
      } on HermesAiException {
        rethrow;
      } on TimeoutException {
        if (attempt < maxAttempts) continue;
        throw const HermesAiException(
          'Koneksi ke server AI melebihi batas waktu.',
        );
      } catch (e) {
        if (attempt < maxAttempts) continue;
        throw HermesAiException('Gagal terhubung ke server AI: $e');
      }
    }

    throw const HermesAiException('Gagal memproses respons server AI.');
  }

  static List<Map<String, String>> _buildHistoryMessages(
    List<AiChatMessage> history, {
    int maxMessages = 6,
  }) {
    final completed = history
        .where(
          (m) =>
              m.status == AiChatStatus.done &&
              m.effectiveFullText.trim().isNotEmpty &&
              !m.isOfflineFallback,
        )
        .toList();

    final slice = completed.length > maxMessages
        ? completed.sublist(completed.length - maxMessages)
        : completed;

    return slice
        .map(
          (m) => <String, String>{
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.effectiveFullText,
          },
        )
        .toList();
  }

  /// Tentukan tombol aksi cepat kontekstual yang paling relevan bagi jamaah.
  static List<AiContextualAction> inferContextualActions({
    required String question,
    required String replySpeech,
    required SensorContext sensor,
  }) {
    final combined = '${question.toLowerCase()} ${replySpeech.toLowerCase()}';
    final actions = <AiContextualAction>[];

    if (sensor.isFallDetected ||
        combined.contains('pusing') ||
        combined.contains('ngelu') ||
        combined.contains('lieur') ||
        combined.contains('dizzy') ||
        combined.contains('lelah') ||
        combined.contains('sayah') ||
        combined.contains('tired') ||
        combined.contains('sakit') ||
        combined.contains('gerah') ||
        combined.contains('sesak') ||
        combined.contains('jatuh') ||
        combined.contains('dhawah') ||
        combined.contains('labuh') ||
        combined.contains('darurat') ||
        combined.contains('emergency') ||
        combined.contains('sos')) {
      actions.add(AiContextualAction.openSos);
    }

    if (sensor.isOutsideSafeRadius ||
        combined.contains('jarak') ||
        combined.contains('distance') ||
        combined.contains('far') ||
        combined.contains('dekat') ||
        combined.contains('nearest') ||
        combined.contains('pendamping') ||
        combined.contains('companion') ||
        combined.contains('tersesat') ||
        combined.contains('terpisah') ||
        combined.contains('lokasi') ||
        combined.contains('location') ||
        combined.contains('peta') ||
        combined.contains('map') ||
        combined.contains('arah')) {
      actions.add(AiContextualAction.openMap);
    }

    if (combined.contains('doa') ||
        combined.contains('donga') ||
        combined.contains('dua') ||
        combined.contains('thawaf') ||
        combined.contains('tawaf') ||
        combined.contains('sai') ||
        combined.contains("sa'i") ||
        combined.contains('ihram') ||
        combined.contains('zamzam') ||
        combined.contains('wukuf')) {
      actions.add(AiContextualAction.openDua);
    }

    if (combined.contains('salat') ||
        combined.contains('sholat') ||
        combined.contains('prayer') ||
        combined.contains('adzan') ||
        combined.contains('adhan') ||
        combined.contains('kiblat') ||
        combined.contains('qibla') ||
        combined.contains('subuh') ||
        combined.contains('dzuhur') ||
        combined.contains('ashar') ||
        combined.contains('maghrib') ||
        combined.contains('isya')) {
      actions.add(AiContextualAction.openPrayer);
    }

    if (actions.isEmpty) {
      actions.add(AiContextualAction.openSmartbandSheet);
    }

    return actions;
  }

  /// Balasan cerdas lokal berbasis kondisi nyata aplikasi & gelang ketika server
  /// Hermes/Ngrok sedang tidak terjangkau. 100% menggunakan data asli tanpa simulasi.
  static AiReply buildOfflineFallbackReply({
    required String question,
    required SensorContext sensor,
  }) {
    final q = question.toLowerCase();
    final radius = (sensor.safeRadiusMeters ?? 200).round();

    // 1. Kondisi Darurat Jatuh (hanya jika gelang benar-benar terhubung & mendeteksi jatuh)
    if (sensor.isSmartbandConnected && sensor.isFallDetected) {
      const speech =
          'Perhatian Bapak atau Ibu, sensor gelang mendeteksi indikasi terjatuh. '
          'Mohon tetap tenang, jangan memaksakan berdiri sendiri, dan tekan tombol Bantuan Darurat SOS di bawah agar pendamping segera menuju lokasi Anda.';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize('DARURAT: Jatuh! Tunggu pendamping'),
        isOfflineFallback: true,
      );
    }

    // 1b. Pertanyaan tentang Kemampuan AI / "Kamu bisa apa saja?" / "Apakah cuma akses Smartband?"
    if (q.contains('bisa apa') ||
        q.contains('apa saja') ||
        q.contains('fitur apa') ||
        q.contains('cuman') ||
        q.contains('cuma ') ||
        q.contains('hanya ') ||
        q.contains('siapa kamu') ||
        q.contains('fungsi kamu') ||
        q.contains('kegunaan')) {
      final bandPart = sensor.isSmartbandConnected
          ? 'Saat ini gelang Smartband Anda terhubung (Detak jantung ${sensor.heartRateBpm} BPM, Suhu ${sensor.temperatureLabel} derajat Celcius).'
          : 'Saat ini gelang Smartband belum terhubung via Bluetooth, namun saya tetap aktif membaca seluruh data dari HP Anda.';
      final posPart = sensor.hasPhoneLocation
          ? 'Posisi GPS HP Anda terdeteksi${sensor.locationCityName != null ? " di ${sensor.locationCityName}" : ""}.'
          : 'GPS HP siap melacak posisi Anda.';
      final prayerPart =
          (sensor.nextPrayerName != null && sensor.nextPrayerTime != null)
          ? 'Salat berikutnya adalah ${sensor.nextPrayerName} pukul ${sensor.nextPrayerTime}.'
          : '';

      final speech =
          'Tidak hanya gelang Smartband, saya terhubung dengan seluruh fitur aplikasi HajiCare Anda: '
          '1) Membaca posisi GPS HP dan lokasi kota Anda secara langsung, '
          '2) Menghitung jarak real-time Anda dengan pendamping beserta informasi Room, Kloter, dan Maktab rombongan, '
          '3) Mengecek jadwal waktu salat 5 waktu, hitung mundur adzan, dan derajat arah Kiblat, '
          '4) Membimbing bacaan doa Haji dan Umrah seperti Thawaf, Sa\'i, dan air Zamzam, '
          '5) Memantau peringatan darurat SOS dan pesan notifikasi, serta '
          '6) Memantau detak jantung, suhu tubuh, dan deteksi jatuh dari gelang Smartband. '
          '$bandPart $posPart $prayerPart';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize(
          'Asisten Penuh HajiCare: GPS, Jarak, Salat, Doa & BLE',
        ),
        isOfflineFallback: true,
      );
    }

    // 2. Pertanyaan tentang Jadwal Salat, Adzan, atau Arah Kiblat
    if (q.contains('salat') ||
        q.contains('sholat') ||
        q.contains('kiblat') ||
        q.contains('adzan') ||
        q.contains('azan') ||
        q.contains('jadwal') ||
        q.contains('subuh') ||
        q.contains('dzuhur') ||
        q.contains('ashar') ||
        q.contains('maghrib') ||
        q.contains('isya')) {
      final city = sensor.locationCityName ?? 'lokasi Anda saat ini';
      final nextName = sensor.nextPrayerName;
      final nextTime = sensor.nextPrayerTime;
      final countdown = sensor.nextPrayerCountdown;
      final qibla = sensor.qiblaBearingDegrees != null
          ? '${sensor.qiblaBearingDegrees!.round()} derajat'
          : 'kompas kiblat di halaman Jadwal Salat';
      final schedule = sensor.todayPrayerScheduleSummary;

      final String speech;
      final String oled;
      if (nextName != null && nextTime != null) {
        speech =
            'Berdasarkan lokasi GPS HP Anda di $city, waktu salat berikutnya adalah $nextName pada pukul $nextTime'
            '${countdown != null ? " (sekitar $countdown lagi)" : ""}. '
            '${schedule != null ? "Jadwal lengkap hari ini: $schedule. " : ""}'
            'Arah Kiblat berada pada $qibla.';
        oled = 'Salat $nextName $nextTime | Kiblat $qibla';
      } else {
        speech =
            'Untuk melihat jadwal waktu salat beserta kompas arah Kiblat ($qibla) sesuai GPS HP Anda, silakan tekan tombol Jadwal Salat & Kiblat di bawah.';
        oled = 'Cek Jadwal Salat & Arah Kiblat';
      }
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize(oled),
        isOfflineFallback: true,
      );
    }

    // 2b. Pertanyaan tentang Profil, Nomor Porsi, Paspor, NIK, atau Data Medis Pengguna
    if (q.contains('porsi') ||
        q.contains('paspor') ||
        q.contains('nik') ||
        q.contains('golongan darah') ||
        q.contains('alergi') ||
        q.contains('riwayat') ||
        q.contains('medis') ||
        q.contains('kontak darurat') ||
        q.contains('profil saya')) {
      final profileText = sensor.userProfileSummary != null
          ? 'Data profil dan medis Anda tercatat: ${sensor.userProfileSummary}.'
          : 'Data dokumen haji atau medis tambahan belum dilengkapi di halaman Profil.';
      final roomText = sensor.hasActiveRoom
          ? 'Anda tergabung di Room ${sensor.roomName ?? "-"} (Kloter ${sensor.kloter ?? "-"}, Maktab ${sensor.maktab ?? "-"}).'
          : 'Anda saat ini belum bergabung ke Room rombongan.';
      return AiReply(
        speech:
            'Nama akun Anda adalah ${sensor.userName} dengan peran ${sensor.userRole}. $roomText $profileText',
        oled: OledTextFormatter.sanitize(
          'Profil: ${sensor.userName} (${sensor.userRole})',
        ),
        isOfflineFallback: true,
      );
    }

    // 3. Pertanyaan tentang Jamaah Terdekat/Terjauh, Daftar Anggota Room, Posisi GPS, Jarak Pendamping, Rombongan, Kloter, Maktab
    if (q.contains('dekat') ||
        q.contains('jauh') ||
        q.contains('siapa') ||
        q.contains('anggota') ||
        q.contains('jarak') ||
        q.contains('pendamping') ||
        q.contains('rombongan') ||
        q.contains('room') ||
        q.contains('kloter') ||
        q.contains('maktab') ||
        q.contains('posisi') ||
        q.contains('lokasi') ||
        q.contains('dimana') ||
        q.contains('di mana') ||
        q.contains('tersesat') ||
        q.contains('terpisah')) {
      final posParts = <String>[];
      if (sensor.locationCityName != null) {
        posParts.add('di kawasan ${sensor.locationCityName}');
      }
      if (sensor.hasPhoneLocation) {
        posParts.add(
          'koordinat GPS HP (${sensor.phoneLatitude!.toStringAsFixed(5)}, ${sensor.phoneLongitude!.toStringAsFixed(5)})',
        );
      } else {
        posParts.add('GPS HP masih menunggu penguncian sinyal lokasi');
      }

      if (sensor.isSmartbandConnected) {
        if (sensor.hasSmartbandLocation) {
          posParts.add(
            'GPS Gelang (${sensor.smartbandLatitude!.toStringAsFixed(5)}, ${sensor.smartbandLongitude!.toStringAsFixed(5)})',
          );
        } else {
          posParts.add('gelang terhubung namun GPS gelang masih mencari satelit');
        }
      } else {
        posParts.add('gelang Smartband saat ini belum terhubung via Bluetooth');
      }

      final String roomPart;
      if (sensor.hasActiveRoom) {
        roomPart =
            'Anda tergabung di rombongan ${sensor.roomName ?? "-"}'
            '${sensor.kloter != null ? ", Kloter ${sensor.kloter}" : ""}'
            '${sensor.maktab != null ? ", Maktab ${sensor.maktab}" : ""}. ';
      } else {
        roomPart = 'Saat ini Anda belum bergabung ke Room rombongan. ';
      }

      final String closestAndMembersPart = [
        if (sensor.closestJamaahSummary != null) sensor.closestJamaahSummary!,
        if (sensor.roomMembersSummary != null) sensor.roomMembersSummary!,
      ].join(' ');

      final String distPart;
      final String oled;
      if (sensor.distanceToCompanionMeters != null) {
        final dist = sensor.distanceToCompanionMeters!.round();
        final comp = sensor.companionName ?? 'Pendamping';
        final isSafe = dist <= radius;
        distPart = isSafe
            ? 'Jarak real-time Anda dengan $comp adalah $dist meter (aman di dalam batas radius $radius meter).'
            : 'Perhatian, jarak real-time Anda dengan $comp saat ini $dist meter, berada di luar batas radius aman $radius meter. Silakan buka peta untuk kembali mendekat ke pendamping.';
        oled = sensor.closestJamaahSummary != null &&
                (q.contains('dekat') || q.contains('jamaah'))
            ? sensor.closestJamaahSummary!
            : (isSafe
                  ? 'Jarak ${dist}m ke $comp (Aman)'
                  : 'WASPADA Jarak ${dist}m >${radius}m');
      } else if (sensor.roomMembersSummary != null) {
        distPart = '';
        oled = sensor.closestJamaahSummary ?? 'Pantau anggota di Peta';
      } else {
        distPart = 'Status jarak ke pendamping: ${sensor.distanceStatusSummary}.';
        oled = sensor.hasActiveRoom
            ? 'Menunggu sinyal GPS Pendamping'
            : 'Belum gabung Room Rombongan';
      }

      final speech =
          'Posisi Anda saat ini tercatat ${posParts.join(", ")}. $roomPart$distPart'
          '${closestAndMembersPart.isNotEmpty ? " $closestAndMembersPart" : ""}';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize(oled),
        isOfflineFallback: true,
      );
    }

    // 4. Pertanyaan tentang Pesan, Notifikasi, atau Status SOS
    if (q.contains('pesan') ||
        q.contains('notifikasi') ||
        q.contains('pengumuman') ||
        q.contains('sos') ||
        q.contains('darurat')) {
      final sosInfo = sensor.activeSosCount > 0
          ? 'Terdapat ${sensor.activeSosCount} sinyal darurat SOS aktif di rombongan Anda.'
          : 'Saat ini tidak ada sinyal darurat SOS yang aktif.';
      final notifInfo = sensor.unreadNotificationsCount > 0
          ? 'Anda memiliki ${sensor.unreadNotificationsCount} notifikasi belum dibaca'
                '${sensor.latestNotificationSummary != null ? ", pesan terbaru: ${sensor.latestNotificationSummary}." : "."}'
          : 'Belum ada pesan atau notifikasi baru yang belum dibaca.';
      return AiReply(
        speech: '$sosInfo $notifInfo',
        oled: OledTextFormatter.sanitize(
          'SOS:${sensor.activeSosCount} Pesan:${sensor.unreadNotificationsCount}',
        ),
        isOfflineFallback: true,
      );
    }

    // 5. Keluhan Fisik (Pusing, Lelah, Haus, Sesak)
    if (q.contains('pusing') ||
        q.contains('lelah') ||
        q.contains('lemas') ||
        q.contains('sakit') ||
        q.contains('sesak') ||
        q.contains('haus') ||
        q.contains('panas')) {
      final vitalPart = sensor.hasSmartbandVitalSigns
          ? 'Sensor gelang mencatat detak jantung Anda ${sensor.heartRateBpm} BPM dan suhu ${sensor.temperatureLabel} derajat Celcius. '
          : 'Saat ini gelang Smartband belum terhubung ke Bluetooth HP sehingga detak jantung dan suhu gelang belum terbaca. ';
      final distPart = sensor.distanceToCompanionMeters != null
          ? 'Jarak Anda ke ${sensor.companionName ?? "pendamping"} sekitar ${sensor.distanceToCompanionMeters!.round()} meter. '
          : '';
      final speech =
          'Bapak atau Ibu, mohon segera menepi ke tempat yang teduh dan duduk perlahan. '
          '$vitalPart$distPart'
          'Minumlah air zamzam atau air putih sedikit demi sedikit, atur napas dengan tenang, dan tekan tombol Bantuan Darurat SOS di bawah bila membutuhkan pertolongan pendamping.';
      final oled = sensor.hasSmartbandVitalSigns
          ? 'Menepi & minum. HR:${sensor.heartRateBpm} T:${sensor.temperatureLabel}C'
          : 'Menepi, duduk tenang & minum air';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize(oled),
        isOfflineFallback: true,
      );
    }

    // 6. Panduan Doa Sa'i, Zamzam, & Thawaf
    if (q.contains('sai') ||
        q.contains("sa'i") ||
        q.contains('shafa') ||
        q.contains('marwah')) {
      const speech =
          'Saat memulai Sa\'i di bukit Shafa menghadap Kabah, bacalah: Innash shafaa wal marwata min sya\'aairillaah. '
          'Berjalanlah dengan tenang menuju bukit Marwah sambil berdzikir dan berdoa memohon ampunan serta kesehatan.';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize(
          'Sai: Innash shafa wal marwata min syaairillah',
        ),
        isOfflineFallback: true,
      );
    }

    if (q.contains('zamzam') || q.contains('minum')) {
      const speech =
          'Doa ketika minum air Zamzam: Allahumma innii as-aluka \'ilman naafi\'an, wa rizqan waasi\'an, wa syifaa-an min kulli daa-in. '
          'Artinya: Ya Allah, aku memohon kepada-Mu ilmu yang bermanfaat, rezeki yang luas, dan kesembuhan dari segala penyakit.';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize(
          'Doa Zamzam: Mohon ilmu, rezeki & kesembuhan',
        ),
        isOfflineFallback: true,
      );
    }

    if (q.contains('thawaf') || q.contains('tawaf') || q.contains('doa')) {
      const speech =
          'Saat melakukan thawaf mengelilingi Kabah, di antara Rukun Yamani dan Hajar Aswad bacalah doa sapu jagad: '
          'Rabbana aatina fid dunya hasanah, wa fil aakhirati hasanah, wa qinaa adzaaban naar. '
          'Artinya: Ya Tuhan kami, berikanlah kami kebaikan di dunia dan di akhirat, serta lindungilah kami dari siksa neraka.';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize(
          'Doa Thawaf: Rabbana atina fid dunya hasanah',
        ),
        isOfflineFallback: true,
      );
    }

    // 7. Pertanyaan Kesehatan / Status Gelang / Ringkasan Umum Aplikasi
    if (!sensor.isSmartbandConnected) {
      final posSummary = sensor.hasPhoneLocation
          ? 'Posisi GPS HP Anda aktif${sensor.locationCityName != null ? " di ${sensor.locationCityName}" : ""} (${sensor.phoneLatitude!.toStringAsFixed(4)}, ${sensor.phoneLongitude!.toStringAsFixed(4)}).'
          : 'GPS HP sedang menunggu sinyal lokasi.';
      final distSummary = sensor.distanceToCompanionMeters != null
          ? 'Jarak Anda ke ${sensor.companionName ?? "pendamping"} saat ini ${sensor.distanceToCompanionMeters!.round()} meter.'
          : sensor.distanceStatusSummary;
      final prayerSummary =
          (sensor.nextPrayerName != null && sensor.nextPrayerTime != null)
          ? 'Waktu salat berikutnya adalah ${sensor.nextPrayerName} pukul ${sensor.nextPrayerTime}.'
          : '';

      final speech =
          'Saat ini gelang pintar HajiCare Smartband belum terhubung ke Bluetooth HP Anda, sehingga detak jantung dan suhu tubuh gelang belum dapat dibaca. '
          'Namun dari aplikasi HP: $posSummary $distSummary $prayerSummary '
          'Silakan hubungkan gelang melalui menu Status Gelang bila ingin memantau detak jantung dan suhu tubuh.';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize('Gelang belum terhubung ke Bluetooth HP'),
        isOfflineFallback: true,
      );
    }

    final bpm = sensor.heartRateBpm;
    final temp = sensor.temperatureLabel;
    final spo2Str = sensor.spo2Percent != null
        ? ', saturasi oksigen ${sensor.spo2Percent}%'
        : '';
    final distStr = sensor.distanceToCompanionMeters != null
        ? 'Jarak Anda dengan ${sensor.companionName ?? "pendamping"} adalah ${sensor.distanceToCompanionMeters!.round()} meter.'
        : sensor.distanceStatusSummary;
    final speech =
        'Alhamdulillah gelang Smartband Anda terhubung. Detak jantung tercatat $bpm BPM$spo2Str, suhu tubuh $temp derajat Celcius, dan status jatuh aman. '
        '$distStr';
    return AiReply(
      speech: speech,
      oled: OledTextFormatter.sanitize(
        'Gelang Aktif HR:$bpm BPM T:${temp}C',
      ),
      isOfflineFallback: true,
    );
  }

  void dispose() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }
}
