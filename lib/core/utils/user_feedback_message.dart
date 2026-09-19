/// Converts internal failures into short, actionable messages for end users.
///
/// Technical details must stay in debug logs and must never be shown directly
/// to jamaah, especially elderly users.
class UserFeedbackMessage {
  UserFeedbackMessage._();

  static String from(
    Object error, {
    String fallback = 'Terjadi kendala. Silakan coba lagi.',
  }) {
    final raw = error.toString().toLowerCase();

    if (_containsAny(raw, const [
      'network',
      'socket',
      'connection',
      'clientexception',
      'host lookup',
      'unreachable',
      'offline',
      'http 5',
      'unavailable',
    ])) {
      return 'Sambungan internet sedang bermasalah. Periksa internet, lalu coba lagi.';
    }
    if (_containsAny(raw, const ['timeout', 'timed out'])) {
      return 'Prosesnya terlalu lama. Periksa internet, lalu coba lagi.';
    }
    if (_containsAny(raw, const [
      'permission-denied',
      'permission denied',
      'izin ditolak',
    ])) {
      return 'Izin yang dibutuhkan belum diberikan. Buka pengaturan ponsel, lalu berikan izin.';
    }
    if (_containsAny(raw, const [
      'unauthenticated',
      'not authenticated',
      'tidak terautentikasi',
      'no current user',
    ])) {
      return 'Waktu masuk Anda sudah berakhir. Silakan masuk kembali.';
    }
    if (_containsAny(raw, const [
      'not-found',
      'not found',
      'tidak ditemukan',
      'sudah tidak tersedia',
    ])) {
      return 'Data yang dicari tidak ditemukan. Periksa kembali, lalu coba lagi.';
    }
    if (_containsAny(raw, const [
      'already-exists',
      'already exists',
      'sudah terdaftar',
    ])) {
      return 'Data tersebut sudah terdaftar.';
    }
    if (_containsAny(raw, const [
      'bluetooth',
      'ble',
      'hajicare watch',
      'gatt',
    ])) {
      return 'Gelang belum dapat dihubungkan. Pastikan gelang menyala dan berada dekat dengan ponsel, lalu coba lagi.';
    }

    return fallback;
  }

  static bool _containsAny(String source, List<String> values) =>
      values.any(source.contains);
}
