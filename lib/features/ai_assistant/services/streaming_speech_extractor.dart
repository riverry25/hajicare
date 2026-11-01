import 'hermes_response_parser.dart';

/// Ekstraktor inkremental untuk mengekstrak nilai string `speech` dari respons
/// streaming LLM yang menghasilkan format JSON `{"speech": "...", "oled": "..."}`
/// atau teks biasa.
class StreamingSpeechExtractor {
  final StringBuffer _rawBuffer = StringBuffer();
  String _currentExtractedSpeech = '';
  bool _isDirectPlainTextMode = false;

  static final RegExp _thinkBlock = RegExp(
    r'<think>[\s\S]*?</think>',
    caseSensitive: false,
  );
  static final RegExp _unclosedThink = RegExp(
    r'<think>[\s\S]*$',
    caseSensitive: false,
  );
  static final RegExp _codeFencePrefix = RegExp(
    r'^```(?:json|javascript|js)?\s*',
    caseSensitive: false,
  );

  /// Tambahkan chunk token teks baru yang diterima dari SSE stream.
  /// Mengembalikan teks kumulatif bersih `speech` sampai saat ini.
  String addChunk(String chunk) {
    if (chunk.isEmpty) return _currentExtractedSpeech;
    _rawBuffer.write(chunk);
    _extractCurrent();
    return _currentExtractedSpeech;
  }

  /// Teks kumulatif bersih yang telah diekstrak saat ini.
  String get currentSpeech => _currentExtractedSpeech;

  /// Seluruh teks mentah yang terakumulasi.
  String get rawAccumulatedText => _rawBuffer.toString();

  void _extractCurrent() {
    var raw = _rawBuffer.toString();

    // 1. Buang blok penalaran <think>...</think>
    raw = raw.replaceAll(_thinkBlock, '');
    raw = raw.replaceAll(_unclosedThink, '');

    // 2. Buang code fence pembuka bila ada
    raw = raw.trimLeft().replaceFirst(_codeFencePrefix, '').trimLeft();

    if (raw.isEmpty) {
      _currentExtractedSpeech = '';
      return;
    }

    // 3. Cek apakah model berbicara dalam format JSON {"speech": ...}
    // Cari key "speech" (bisa di awal atau setelah {)
    final speechKeyMatch = RegExp(
      r'"speech"\s*:\s*"',
      caseSensitive: false,
    ).firstMatch(raw);

    if (speechKeyMatch != null) {
      _isDirectPlainTextMode = false;
      final valueStartIndex = speechKeyMatch.end;
      final extracted = _extractJsonStringContent(raw, valueStartIndex);
      _currentExtractedSpeech = HermesResponseParser.cleanSpeechText(extracted);
      return;
    }

    // 4. Jika belum menemukan key "speech":
    // Cek apakah output model jelas-jelas plain text (bukan JSON)
    final trimmed = raw.trim();
    if (!_isDirectPlainTextMode) {
      // Jika teks sudah cukup panjang (>= 25 char) dan tidak dimulai dengan `{`
      // atau jika tidak mengandung kurung kurawal sama sekali
      if (!trimmed.startsWith('{') && (trimmed.length > 25 || !trimmed.contains('{'))) {
        _isDirectPlainTextMode = true;
      }
    }

    if (_isDirectPlainTextMode) {
      // Model membalas dengan teks langsung (bukan JSON)
      var clean = trimmed
          .replaceAll(RegExp(r'```(?:json|javascript|js)?', caseSensitive: false), '')
          .replaceAll('```', '');
      _currentExtractedSpeech = HermesResponseParser.cleanSpeechText(clean);
      return;
    }

    // Masih dalam fase awal JSON pembuka sebelum key "speech" tiba (mis. `{"spe`)
    _currentExtractedSpeech = '';
  }

  /// Membaca karakter demi karakter string JSON dari [startIndex] hingga tanda kutip penutup unescaped,
  /// dengan decoding escape sequence secara toleran.
  String _extractJsonStringContent(String source, int startIndex) {
    final sb = StringBuffer();
    var i = startIndex;
    final len = source.length;

    while (i < len) {
      final ch = source[i];

      if (ch == r'\') {
        // Cek karakter escape berikutnya
        if (i + 1 >= len) {
          // Backslash menggantung di akhir buffer chunk, tunggu chunk berikutnya
          break;
        }
        final next = source[i + 1];
        if (next == '"') {
          sb.write('"');
          i += 2;
        } else if (next == r'\') {
          sb.write(r'\');
          i += 2;
        } else if (next == '/') {
          sb.write('/');
          i += 2;
        } else if (next == 'n') {
          sb.write(' ');
          i += 2;
        } else if (next == 'r') {
          i += 2;
        } else if (next == 't') {
          sb.write(' ');
          i += 2;
        } else if (next == 'u') {
          if (i + 5 < len) {
            final hex = source.substring(i + 2, i + 6);
            final code = int.tryParse(hex, radix: 16);
            if (code != null) {
              sb.write(String.fromCharCode(code));
              i += 6;
              continue;
            }
          }
          // Incomplete unicode escape, stop processing here for now
          break;
        } else {
          sb.write(next);
          i += 2;
        }
      } else if (ch == '"') {
        // Tanda kutip penutup string "speech" tercapai! Selesai mengekstrak field speech.
        break;
      } else {
        sb.write(ch);
        i++;
      }
    }

    return sb.toString();
  }

  /// Reset extractor untuk sesi streaming baru.
  void reset() {
    _rawBuffer.clear();
    _currentExtractedSpeech = '';
    _isDirectPlainTextMode = false;
  }
}

