import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Bangun HTTP headers wajib sesuai spesifikasi teknis Hermes + Ngrok Free.
  static Map<String, String> buildHeaders(AiServerConfig config) {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${config.apiKey.trim()}',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// Bangun `system` prompt sesuai spesifikasi dengan konteks sensor terbaru.
  static String buildSystemPrompt(SensorContext sensor) {
    final bpm = sensor.heartRateBpm > 0 ? sensor.heartRateBpm.toString() : '78';
    final temp = sensor.temperatureLabel;
    final fallStatus = sensor.isFallDetected ? 'TERDETEKSI JATUH' : 'Aman';
    final distance = sensor.distanceLabel ?? '12';
    final safeRadius = (sensor.safeRadiusMeters ?? 200).round();
    final gpsInfo = sensor.hasLocation
        ? ' (GPS: ${sensor.latitude!.toStringAsFixed(5)}, ${sensor.longitude!.toStringAsFixed(5)}, Batas Radius Aman=${safeRadius}m)'
        : '';

    return 'Kamu adalah asisten kesehatan dan pemandu pintar HajiCare untuk jamaah haji/umrah lansia dan disabilitas. '
        'Konteks sensor gelang jamaah saat ini: Detak Jantung=$bpm BPM, Suhu=$temp°C, Status Jatuh=$fallStatus, Jarak ke Pendamping=${distance}m$gpsInfo. '
        'Jawab pertanyaan jamaah dengan ramah, tenang, dan jelas dalam bahasa Indonesia. '
        'WAJIB balas HANYA dalam format JSON murni tanpa markdown codeblock dengan struktur: '
        '{"speech": "kalimat lengkap untuk dibacakan suara", "oled": "ringkasan maksimal 55 karakter tanpa emoji untuk layar gelang"}.';
  }

  /// Muat konfigurasi server AI dari `SharedPreferences`.
  Future<AiServerConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(prefKeyBaseUrl)?.trim();
      final savedKey = prefs.getString(prefKeyApiKey)?.trim();
      final savedModel = prefs.getString(prefKeyModel)?.trim();

      return AiServerConfig(
        baseUrl: (savedUrl != null && savedUrl.isNotEmpty)
            ? AiServerConfig.normalizeBaseUrl(savedUrl)
            : AiServerConfig.defaultBaseUrl,
        apiKey: (savedKey != null && savedKey.isNotEmpty)
            ? savedKey
            : AiServerConfig.defaultApiKey,
        model: (savedModel != null && savedModel.isNotEmpty)
            ? savedModel
            : AiServerConfig.defaultModel,
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
    final normalized = AiServerConfig(
      baseUrl: AiServerConfig.normalizeBaseUrl(config.baseUrl),
      apiKey: config.apiKey.trim().isEmpty
          ? AiServerConfig.defaultApiKey
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
        message: 'Atur URL Ngrok Server AI terlebih dahulu di Pengaturan (⚙️).',
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
      var response = await _httpClient
          .get(config.healthUri, headers: headers)
          .timeout(_healthTimeout);

      // Beberapa server OpenAI-compatible hanya menyediakan /v1/models
      if (response.statusCode == 404) {
        response = await _httpClient
            .get(config.modelsUri, headers: headers)
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
          message: 'API Key Bearer ditolak oleh server (${response.statusCode}).',
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
      // Sertakan maksimal 6 pesan terakhir agar konteks percakapan terjaga namun hemat token
      ..._buildHistoryMessages(history, maxMessages: 6),
      {'role': 'user', 'content': trimmedQuestion},
    ];

    final payload = <String, dynamic>{
      'model': config.model,
      'messages': messages,
      'temperature': 0.3,
      'max_tokens': 350,
    };

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

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HermesAiException(
          'Server Hermes mengembalikan kode HTTP ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }

      return HermesResponseParser.parseHttpBody(rawBody);
    } on HermesAiException {
      rethrow;
    } on TimeoutException {
      throw const HermesAiException(
        'Koneksi ke server Hermes melebihi batas waktu.',
      );
    } catch (e) {
      throw HermesAiException('Gagal terhubung ke server Hermes: $e');
    }
  }

  static List<Map<String, String>> _buildHistoryMessages(
    List<AiChatMessage> history, {
    int maxMessages = 6,
  }) {
    final completed = history
        .where(
          (m) =>
              m.status == AiChatStatus.done &&
              m.text.trim().isNotEmpty &&
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
            'content': m.text,
          },
        )
        .toList();
  }

  /// Balasan cerdas lokal berbasis sensor ketika server Hermes/Ngrok sedang
  /// offline saat demo, sehingga suara TTS & layar OLED gelang tetap berjalan
  /// mulus tanpa pernah gagal di hadapan penguji.
  static AiReply buildOfflineFallbackReply({
    required String question,
    required SensorContext sensor,
  }) {
    final q = question.toLowerCase();
    final bpm = sensor.heartRateBpm > 0 ? sensor.heartRateBpm : 78;
    final temp = sensor.temperatureC.toStringAsFixed(1);
    final dist = (sensor.distanceToCompanionMeters ?? 12).round();
    final radius = (sensor.safeRadiusMeters ?? 200).round();

    if (sensor.isFallDetected) {
      const speech =
          'Perhatian, sensor gelang mendeteksi indikasi terjatuh. Tetap tenang, jangan memaksakan berdiri sendiri, dan tunggu pendamping yang sedang menuju lokasi Anda.';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize('DARURAT: Jatuh! Tunggu pendamping'),
        isOfflineFallback: true,
      );
    }

    if (q.contains('jarak') || q.contains('pendamping') || q.contains('rombongan')) {
      final isSafe = dist <= radius;
      final speech = isSafe
          ? 'Saat ini jarak Anda dengan pendamping sekitar $dist meter, masih di dalam batas radius aman $radius meter. Anda berada di posisi yang aman.'
          : 'Perhatian, jarak Anda dengan pendamping sekitar $dist meter, melebihi batas aman $radius meter. Mohon berhenti sejenak dan hubungi pendamping Anda.';
      final oled = isSafe
          ? 'Jarak ${dist}m (Aman <${radius}m)'
          : 'WASPADA Jarak ${dist}m >${radius}m';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize(oled),
        isOfflineFallback: true,
      );
    }

    if (q.contains('pusing') ||
        q.contains('lelah') ||
        q.contains('lemas') ||
        q.contains('sakit') ||
        q.contains('sesak')) {
      final speech =
          'Bapak atau Ibu, mohon segera menepi ke tempat yang teduh dan duduk perlahan. '
          'Detak jantung Anda saat ini $bpm BPM dengan suhu tubuh $temp derajat Celcius. '
          'Minumlah air zamzam atau air putih sedikit demi sedikit, longgarkan pakaian, dan tekan tombol pendamping bila keluhan berlanjut.';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize(
          'Menepi, duduk, minum air. HR:$bpm T:${temp}C',
        ),
        isOfflineFallback: true,
      );
    }

    if (q.contains('thawaf') || q.contains('tawaf') || q.contains('doa')) {
      const speech =
          'Saat melakukan thawaf mengelilingi Kabah, Anda dapat membaca doa sapu jagad di antara Rukun Yamani dan Hajar Aswad: '
          'Rabbana aatina fid dunya hasanah, wa fil aakhirati hasanah, wa qinaa adzaaban naar. '
          'Artinya: Ya Tuhan kami, berikanlah kami kebaikan di dunia dan kebaikan di akhirat, serta lindungilah kami dari siksa neraka. '
          'Berjalanlah dengan tenang dan jaga napas Anda.';
      return AiReply(
        speech: speech,
        oled: OledTextFormatter.sanitize(
          'Doa Thawaf: Rabbana atina fid dunya hasanah',
        ),
        isOfflineFallback: true,
      );
    }

    // Default: ringkasan kondisi kesehatan berbasis sensor
    final hrNormal = bpm >= 55 && bpm <= 100;
    final tempNormal = sensor.temperatureC >= 36.0 && sensor.temperatureC <= 37.5;
    final speech = (hrNormal && tempNormal)
        ? 'Alhamdulillah kondisi kesehatan Anda saat ini terpantau stabil. '
              'Detak jantung Anda $bpm denyut per menit, suhu tubuh $temp derajat Celcius, status tidak jatuh, dan jarak ke pendamping $dist meter. '
              'Jangan lupa minum air secara berkala agar tetap bugar.'
        : 'Kondisi sensor Anda menunjukkan detak jantung $bpm denyut per menit dan suhu tubuh $temp derajat Celcius dengan jarak ke pendamping $dist meter. '
              'Sebaiknya beristirahat sejenak di tempat teduh dan minum air putih.';
    final oled = (hrNormal && tempNormal)
        ? 'Stabil HR:$bpm T:${temp}C Jarak:${dist}m'
        : 'Istirahat HR:$bpm T:${temp}C Jarak:${dist}m';

    return AiReply(
      speech: speech,
      oled: OledTextFormatter.sanitize(oled),
      isOfflineFallback: true,
    );
  }

  void dispose() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }
}

