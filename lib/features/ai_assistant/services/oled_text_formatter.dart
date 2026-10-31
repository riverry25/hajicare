/// Utilitas murni (tanpa dependensi Flutter) untuk menyiapkan teks yang aman
/// ditampilkan pada layar OLED SSD1306 128x64 di gelang HajiCare.
///
/// Aturan:
/// - Hanya karakter ASCII printable (0x20..0x7E) → font bawaan Adafruit GFX.
/// - Tanpa emoji, newline, tab, atau markdown.
/// - Maksimal [maxLength] karakter (dipotong di batas kata bila memungkinkan).
/// - Payload BLE berformat `AI:<teks>`.
class OledTextFormatter {
  const OledTextFormatter._();

  /// Panjang maksimal teks OLED (tanpa prefix).
  static const int maxLength = 55;

  /// Prefix protokol firmware ESP32 untuk pesan AI.
  static const String payloadPrefix = 'AI:';

  /// Jumlah karakter per baris OLED 128px dengan font 6x8 (textSize 1).
  static const int charsPerLine = 21;

  static const Map<String, String> _transliteration = {
    '°C': 'C',
    '°': '',
    '–': '-',
    '—': '-',
    '‘': "'",
    '’': "'",
    '‚': ',',
    '“': '"',
    '”': '"',
    '…': '...',
    '•': '-',
    '×': 'x',
    '÷': '/',
    '±': '+/-',
    'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a',
    'Á': 'A', 'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ã': 'A', 'Å': 'A', 'Ā': 'A',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e',
    'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E', 'Ē': 'E',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
    'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I', 'Ī': 'I',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ō': 'o',
    'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Ö': 'O', 'Õ': 'O', 'Ō': 'O',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
    'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U', 'Ū': 'U',
    'ç': 'c', 'Ç': 'C', 'ñ': 'n', 'Ñ': 'N',
  };

  static final RegExp _lineBreaks = RegExp(r'[\r\n\t\f\v]+');
  static final RegExp _bracketAnnotations = RegExp(r'\[[^\]]*\]');
  static final RegExp _nonPrintableAscii = RegExp(r'[^\x20-\x7E]');
  static final RegExp _markdown = RegExp(r'[*_`#~|]');
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _leadingAiPrefix = RegExp(
    r'^\s*AI\s*:\s*',
    caseSensitive: false,
  );

  /// Bersihkan teks agar aman untuk OLED: ASCII-only, tanpa kurung siku `[...]`, satu baris, ≤ [limit].
  static String sanitize(String input, {int limit = maxLength}) {
    if (input.isEmpty || limit <= 0) return '';

    var text = input;
    _transliteration.forEach((from, to) => text = text.replaceAll(from, to));
    text = text
        .replaceAll(_bracketAnnotations, ' ')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll(_lineBreaks, ' ')
        .replaceAll(_nonPrintableAscii, '')
        .replaceAll(_markdown, '')
        .replaceFirst(_leadingAiPrefix, '')
        .replaceAll(_whitespace, ' ')
        .trim();

    return truncate(text, limit: limit);
  }

  /// Potong aman di batas kata bila kata terakhir tidak terlalu panjang.
  static String truncate(String text, {int limit = maxLength}) {
    if (text.length <= limit) return text;
    final cut = text.substring(0, limit);
    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace >= (limit * 0.6).floor()) {
      return cut.substring(0, lastSpace).trimRight();
    }
    return cut.trimRight();
  }

  /// Bangun payload BLE final: `AI:<teks bersih ≤ 55 karakter>`.
  static String buildPayload(String oledText) =>
      '$payloadPrefix${sanitize(oledText)}';

  /// Bungkus teks menjadi baris-baris OLED (word wrap, ≤ [width] karakter).
  /// Dipakai pratinjau UI agar persis meniru tampilan firmware.
  static List<String> wrap(String text, {int width = charsPerLine}) {
    final words = text.split(' ').where((w) => w.isNotEmpty);
    final lines = <String>[];
    var current = StringBuffer();

    void flush() {
      if (current.isNotEmpty) {
        lines.add(current.toString());
        current = StringBuffer();
      }
    }

    for (var word in words) {
      while (word.length > width) {
        flush();
        lines.add(word.substring(0, width));
        word = word.substring(width);
      }
      final needed = current.isEmpty ? word.length : current.length + 1 + word.length;
      if (needed > width) flush();
      if (current.isNotEmpty) current.write(' ');
      current.write(word);
    }
    flush();
    return lines;
  }
}

