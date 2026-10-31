import 'package:flutter/foundation.dart';

/// Konfigurasi koneksi ke server Hermes Agent (OpenAI-compatible API).
///
/// Immutable domain model: gunakan [copyWith] untuk membuat varian baru.
/// Nilai default dapat dioverride saat build melalui `--dart-define`:
/// `--dart-define=HERMES_BASE_URL=https://xxx.ngrok-free.app`
/// `--dart-define=HERMES_API_KEY=...`
/// `--dart-define=HERMES_MODEL=hermes`
@immutable
class AiServerConfig {
  const AiServerConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  static const String defaultBaseUrl = String.fromEnvironment(
    'HERMES_BASE_URL',
    defaultValue: 'https://unbalance-compile-chariot.ngrok-free.dev',
  );
  static const String defaultApiKey = String.fromEnvironment(
    'HERMES_API_KEY',
    defaultValue: 'sk-675b8dd28e37e08f-jrv5r5-49d88117',
  );
  static const String defaultModel = String.fromEnvironment(
    'HERMES_MODEL',
    defaultValue: 'ngoding-combo',
  );

  /// Path endpoint OpenAI-compatible chat completions.
  static const String chatCompletionsPath = '/v1/chat/completions';

  /// Path endpoint health-check server Hermes.
  static const String healthPath = '/health';

  /// Penanda domain placeholder lama yang otomatis dimigrasikan ke URL produksi.
  static const String _placeholderMarker = 'DOMAIN_STATIC_NGROK_KAMU';
  static const String legacyDefaultApiKey = 'rahasia_hajicare_2026';
  static const String legacyDefaultModel = 'hermes';

  static const AiServerConfig defaults = AiServerConfig(
    baseUrl: defaultBaseUrl,
    apiKey: defaultApiKey,
    model: defaultModel,
  );

  /// Base URL tanpa trailing slash, mis. `https://abc.ngrok-free.app`.
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

  Uri get chatCompletionsUri => Uri.parse('$baseUrl$chatCompletionsPath');
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
      return 'Format URL tidak valid. Contoh: https://nama.ngrok-free.app';
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return 'Gunakan skema https:// atau http:// yang valid.';
    }
    if (url.contains(_placeholderMarker)) {
      return 'Ganti placeholder dengan domain Ngrok atau IP server Anda.';
    }
    return null;
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

  /// API key yang disamarkan untuk ditampilkan di UI, mis. `rah•••••026`.
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

