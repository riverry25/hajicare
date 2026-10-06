/// Konfigurasi tunggal (Single Source of Truth) untuk remote hosting bahasa isyarat.
class SignLanguageConfig {
  SignLanguageConfig._();

  /// Base URL Firebase Hosting static sign-language.
  static const String baseUrl = 'https://hajicare-sign.web.app';

  /// URL static catalog metadata.
  static const String catalogUrl = '$baseUrl/index.json';

  /// Timeout durasi koneksi untuk HTTP request.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 25);

  /// Helper untuk merakit full URL remote video dari relative path di catalog.
  static String resolveVideoUrl(String relativePath) {
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }
    final cleanPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return '$baseUrl/$cleanPath';
  }
}
