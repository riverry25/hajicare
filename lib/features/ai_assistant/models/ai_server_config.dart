import 'package:flutter/foundation.dart';
import '../services/ai_secret_vault.dart';

/// Konfigurasi koneksi ke server Hermes Agent / Cloud AI (OpenAI-compatible API).
///
/// Immutable domain model: gunakan [copyWith] untuk membuat varian baru.
/// Nilai default dapat dioverride saat build melalui `--dart-define`:
/// `--dart-define=HERMES_BASE_URL=https://...`
/// `--dart-define=HERMES_API_KEY=...`
/// `--dart-define=HERMES_MODEL=...`
@immutable
class AiServerConfig {
  const AiServerConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  // 1. Endpoint Utama: Groq Cloud (Kecepatan LPU kilat ~300 tps)
  static const String groqBaseUrl = 'https://api.groq.com/openai';
  static const String groqModel = 'qwen/qwen3.8-27b';

  // 2. Endpoint Cadangan: OpenRouter Cloud (Jaring pengaman auto-fallback)
  static const String openRouterBaseUrl = 'https://openrouter.ai/api';
  static const String openRouterModel = 'dots-studio/dots-3-note-preview:free';

  /// Penanda kunci sistem yang terenkripsi di vault lokal (tidak pernah dibocorkan ke UI).
  static const String systemVaultMarker = '[TERLINDUNGI_SISTEM_VAULT]';

  /// True jika menggunakan kunci bawaan sistem yang terproteksi aman.
  static bool isSystemKey(String? key) {
    if (key == null || key.trim().isEmpty) return true;
    final k = key.trim();
    return k == systemVaultMarker ||
        k == AiSecretVault.groqApiKey ||
        k == AiSecretVault.openRouterApiKey ||
        k == legacyDefaultApiKey;
  }

  static String get defaultBaseUrl => const String.fromEnvironment(
    'HERMES_BASE_URL',
    defaultValue: groqBaseUrl,
  );

  static String get defaultApiKey => systemVaultMarker;

  static String get defaultModel =>
      const String.fromEnvironment('HERMES_MODEL', defaultValue: groqModel);

  /// Path endpoint OpenAI-compatible chat completions.
  static const String chatCompletionsPath = '/v1/chat/completions';

  /// Path endpoint OpenAI-compatible audio transcriptions.
  static const String audioTranscriptionsPath = '/v1/audio/transcriptions';

  /// Path endpoint health-check server Hermes.
  static const String healthPath = '/health';

  /// Penanda domain placeholder lama yang otomatis dimigrasikan ke URL produksi.
  static const String _placeholderMarker = 'DOMAIN_STATIC_NGROK_KAMU';
  static const String legacyDefaultApiKey = 'rahasia_hajicare_2026';
  static const String legacyDefaultModel = 'hermes';

  static AiServerConfig get groqDefault => AiServerConfig(
    baseUrl: groqBaseUrl,
    apiKey: AiSecretVault.groqApiKey,
    model: groqModel,
  );

  static AiServerConfig get openRouterFallback => AiServerConfig(
    baseUrl: openRouterBaseUrl,
    apiKey: AiSecretVault.openRouterApiKey,
    model: openRouterModel,
  );

  static AiServerConfig get defaults => groqDefault;

  /// Base URL tanpa trailing slash, mis. `https://api.groq.com/openai`.
  final String baseUrl;

  /// Bearer token untuk header `Authorization`.
  final String apiKey;

  /// Nama model yang dikirim pada field `model`.
  final String model;

  /// True jika URL masih placeholder bawaan (belum dikonfigurasi).
  bool get isPlaceholder => baseUrl.contains(_placeholderMarker);

  /// True jika host merupakan domain ngrok (butuh header skip-warning).
  bool get isNgrokHost {
    final host = Uri.tryParse(baseUrl)?.host.toLowerCase() ?? '';
    return host.contains('ngrok');
  }

  /// True jika menggunakan Groq Cloud
  bool get isGroq => baseUrl.toLowerCase().contains('groq.com');

  /// True jika menggunakan OpenRouter Cloud
  bool get isOpenRouter => baseUrl.toLowerCase().contains('openrouter.ai');

  /// True jika pengguna memasukkan API key kustom pribadi (bukan kunci bawaan terproteksi).
  bool get isCustomApiKey {
    final trimmed = apiKey.trim();
    return trimmed.isNotEmpty &&
        trimmed != defaultApiKey &&
        trimmed != legacyDefaultApiKey &&
        trimmed != AiSecretVault.openRouterApiKey;
  }

  /// Kunci API aktif yang digunakan pada HTTP Bearer Authorization.
  /// Jika pengguna tidak memasukkan API key kustom, otomatis mengambil kunci rahasia
  /// terenkripsi dari [AiSecretVault] (Groq atau OpenRouter) secara dinamis di memori runtime.
  String get effectiveApiKey {
    final trimmed = apiKey.trim();
    if (trimmed.isNotEmpty && trimmed != legacyDefaultApiKey) {
      return trimmed;
    }
    return isOpenRouter
        ? AiSecretVault.openRouterApiKey
        : AiSecretVault.groqApiKey;
  }

  Uri get chatCompletionsUri => Uri.parse('$baseUrl$chatCompletionsPath');
  Uri get audioTranscriptionsUri =>
      Uri.parse('$baseUrl$audioTranscriptionsPath');
  Uri get healthUri => Uri.parse('$baseUrl$healthPath');
  Uri get modelsUri => Uri.parse('$baseUrl/v1/models');

  /// Normalisasi input URL dari pengguna:
  /// - trim spasi,
  /// - tambahkan `https://` bila skema tidak ditulis (atau `http://` untuk IP/localhost),
  /// - buang trailing slash,
  /// - buang sufiks endpoint yang tidak sengaja ikut ditempel.
  static String normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;
    if (!url.contains('://')) {
      final isLocalIp = RegExp(
        r'^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[0-1])\.)',
        caseSensitive: false,
      ).hasMatch(url);
      url = isLocalIp ? 'http://$url' : 'https://$url';
    }
    for (final suffix in const [
      chatCompletionsPath,
      '/v1/chat/completions/',
      healthPath,
      '/v1/',
      '/v1',
    ]) {
      if (url.toLowerCase().endsWith(suffix)) {
        url = url.substring(0, url.length - suffix.length);
      }
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Validasi base URL. Mengembalikan pesan error (Bahasa Indonesia) atau
  /// `null` jika valid. Mendukung domain Ngrok (`https://`) maupun IP Server (`http://`/`https://`).
  static String? validateBaseUrl(String raw) {
    final url = normalizeBaseUrl(raw);
    if (url.isEmpty) return 'URL server wajib diisi.';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return 'Format URL tidak valid. Contoh: https://api.groq.com/openai';
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return 'Gunakan skema https:// atau http:// yang valid.';
    }
    if (url.contains(_placeholderMarker)) {
      return 'Ganti placeholder dengan domain server Anda.';
    }
    return null;
  }

  /// Kunci API riil yang digunakan untuk memanggil endpoint AI (diamankan via AiSecretVault jika memakai kunci sistem).
  String get resolvedApiKey {
    if (isSystemKey(apiKey)) {
      if (isOpenRouter) {
        return AiSecretVault.openRouterApiKey;
      }
      return AiSecretVault.groqApiKey;
    }
    return apiKey.trim();
  }

  static String? validateApiKey(String raw) {
    final key = raw.trim();
    if (key.isEmpty) return 'API key wajib diisi.';
    if (key.contains(RegExp(r'\s'))) return 'API key tidak boleh berisi spasi.';
    return null;
  }

  static String? validateModel(String raw) {
    if (raw.trim().isEmpty) return 'Nama model wajib diisi.';
    return null;
  }

  /// API key yang disamarkan untuk ditampilkan di UI, mis. `gsk•••••SoX`.
  String get maskedApiKey {
    if (apiKey.length <= 6) return '•' * apiKey.length;
    return '${apiKey.substring(0, 3)}•••••${apiKey.substring(apiKey.length - 3)}';
  }

  AiServerConfig copyWith({String? baseUrl, String? apiKey, String? model}) {
    return AiServerConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiServerConfig &&
          other.baseUrl == baseUrl &&
          other.apiKey == apiKey &&
          other.model == model;

  @override
  int get hashCode => Object.hash(baseUrl, apiKey, model);

  @override
  String toString() =>
      'AiServerConfig(baseUrl: $baseUrl, apiKey: $maskedApiKey, model: $model)';
}
