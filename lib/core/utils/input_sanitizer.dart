/// Utilitas sanitasi dan validasi masukan untuk mencegah manipulasi data
/// injeksi skrip (XSS), null-byte attacks, serta eksploitasi DoS/buffer overflow (OWASP  V6).
class InputSanitizer {
  InputSanitizer._();

  // Regex validasi standar
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _roomCodeRegExp = RegExp(r'^[A-Z0-9]{4,12}$');

  static final RegExp _htmlTagRegExp = RegExp(
    r'<[^>]*>',
    multiLine: true,
    caseSensitive: false,
  );

  // Karakter kontrol terlarang (ASCII 0-31 kecuali \t, \n, \r) dan null byte
  static final RegExp _controlCharsRegExp = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );

  /// Membersihkan teks dari tag HTML, karakter kontrol, dan memotong sesuai [maxLength].
  static String sanitizeText(String? input, {int maxLength = 255}) {
    if (input == null) return '';
    var text = input.trim();
    if (text.isEmpty) return '';

    // 1. Hilangkan null byte dan karakter kontrol berbahaya
    text = text.replaceAll('\x00', '').replaceAll(_controlCharsRegExp, '');

    // 2. Bersihkan tag HTML/skrip agar tidak dapat dievaluasi sebagai markup
    text = text.replaceAll(_htmlTagRegExp, '');

    // 3. Batasi panjang string untuk mencegah eksploitasi Resource Exhaustion
    if (text.length > maxLength) {
      text = text.substring(0, maxLength);
    }

    return text.trim();
  }

  /// Sanitasi nama pengguna / display name (maksimal 100 karakter
  static String sanitizeDisplayName(String? name) {
    return sanitizeText(name, maxLength: 100);
  }

  /// Sanitasi catatan medis / alergi / penyakit (maksimal 500 karakter
  static String sanitizeMedicalNotes(String? notes) {
    return sanitizeText(notes, maxLength: 500);
  }

  /// Memvalidasi format email
  static bool isValidEmail(String? email) {
    if (email == null) return false;
    final trimmed = email.trim();
    if (trimmed.isEmpty || trimmed.length > 254) return false;
    return _emailRegExp.hasMatch(trimmed);
  }

  /// Memvalidasi panjang dan kekuatan dasar password
  static bool isValidPassword(String? password, {int minLength = 6}) {
    if (password == null) return false;
    return password.length >= minLength && password.length <= 128;
  }

  /// Memvalidasi NIK / Nomor Identitas (numerik, 8-20 digit
  static bool isValidNik(String? nik) {
    if (nik == null) return false;
    final trimmed = nik.trim();
    if (trimmed.length < 8 || trimmed.length > 20) return false;
    return RegExp(r'^\d+$').hasMatch(trimmed);
  }

  /// Memvalidasi format kode rombongan (4-12 karakter alfanumerik kapital
  static bool isValidRoomCode(String? code) {
    if (code == null) return false;
    final trimmed = code.trim().toUpperCase();
    return _roomCodeRegExp.hasMatch(trimmed);
  }

  /// Memvalidasi nomor telepon darurat
  static bool isValidPhone(String? phone) {
    if (phone == null) return false;
    final trimmed = phone.trim();
    if (trimmed.length < 6 || trimmed.length > 25) return false;
    return RegExp(r'^\+?[0-9\s\-()]+$').hasMatch(trimmed);
  }
}
