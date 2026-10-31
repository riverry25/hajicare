import 'dart:convert';

import '../models/ai_reply.dart';
import 'oled_text_formatter.dart';

/// Parser defensif untuk respons Hermes Agent (`/v1/chat/completions`).
///
/// Menangani berbagai variasi output LLM di dunia nyata agar aplikasi
/// **tidak pernah crash saat demo**:
/// 1. Amplop standar OpenAI (`choices[0].message.content`) maupun JSON langsung.
/// 2. Tag penalaran `<think>...</think>` yang mungkin keluar dari model.
/// 3. Pembungkus markdown ```` ```json ... ``` ````.
/// 4. Teks pengantar/penutup di luar objek JSON `{ "speech": ..., "oled": ... }`.
/// 5. Trailing comma di dalam JSON.
/// 6. Fallback teks biasa jika model sama sekali tidak mengembalikan JSON:
///    seluruh teks bersih dijadikan `speech`, dan 55 karakter ASCII pertama
///    dijadikan `oled`.
class HermesResponseParser {
  const HermesResponseParser._();

  static final RegExp _thinkBlock = RegExp(
    r'<think>[\s\S]*?</think>',
    caseSensitive: false,
  );
  static final RegExp _unclosedThink = RegExp(
    r'<think>[\s\S]*$',
    caseSensitive: false,
  );
  static final RegExp _codeFence = RegExp(
    r'```(?:json|javascript|js)?\s*([\s\S]*?)```',
    caseSensitive: false,
  );
  static final RegExp _trailingComma = RegExp(r',\s*([}\]])');
  static final RegExp _speechMarkdown = RegExp(r'[*_`#~]+');
  static final RegExp _multiSpaces = RegExp(r'[ \t]{2,}');

  /// Parse body HTTP mentah dari `/v1/chat/completions`.
  static AiReply parseHttpBody(String rawBody) {
    final trimmed = rawBody.trim();
    if (trimmed.isEmpty) {
      return _fallbackReply(
        'Maaf, asisten belum menerima jawaban. Silakan coba lagi.',
      );
    }

    // 1. Coba decode sebagai JSON amplop OpenAI atau JSON langsung {speech, oled}
    final decoded = _tryDecodeJson(trimmed);
    if (decoded is Map<String, dynamic>) {
      // Caso A: Respons langsung berbentuk {"speech": "...", "oled": "..."}
      if (_hasReplyFields(decoded)) {
        return _fromReplyMap(decoded);
      }

      // Caso B: Amplop OpenAI choices[0].message.content / choices[0].text
      final content = _extractEnvelopeContent(decoded);
      if (content != null && content.trim().isNotEmpty) {
        return parseModelContent(content);
      }
    }

    // 2. Jika body bukan amplop standar, parse langsung sebagai konten LLM
    return parseModelContent(trimmed);
  }

  /// Parse string `content` yang dihasilkan oleh model LLM.
  static AiReply parseModelContent(String rawContent) {
    // 1. Buang blok <think>...</think> bila ada
    var cleaned = rawContent
        .replaceAll(_thinkBlock, '')
        .replaceAll(_unclosedThink, '')
        .trim();

    if (cleaned.isEmpty) {
      cleaned = rawContent.trim();
    }

    // 2. Jika dibungkus ```json ... ```, ekstrak isi di dalamnya terlebih dahulu
    final fenceMatch = _codeFence.firstMatch(cleaned);
    if (fenceMatch != null) {
      final fencedBody = fenceMatch.group(1)?.trim() ?? '';
      final fromFence = _tryParseReplyObject(fencedBody);
      if (fromFence != null) return fromFence;
    }

    // 3. Coba parse langsung keseluruhan string sebagai JSON object
    final direct = _tryParseReplyObject(cleaned);
    if (direct != null) return direct;

    // 4. Ekstrak blok JSON {...} menggunakan pencarian kurung kurawal berimbang
    //    maupun RegExp apabila LLM menambahkan kalimat di luar JSON.
    for (final candidate in _extractJsonObjectCandidates(cleaned)) {
      final parsed = _tryParseReplyObject(candidate);
      if (parsed != null) return parsed;
    }

    // 5. Fallback dengan RegExp pasangan key-value "speech" & "oled"
    //    (berguna jika tanda kutip di dalam kalimat tidak di-escape sempurna).
    final regexFallback = _tryRegexFieldExtraction(cleaned);
    if (regexFallback != null) return regexFallback;

    // 6. Fallback terakhir: perlakukan seluruh teks bersih sebagai `speech`
    //    dan ambil maksimal 55 karakter ASCII pertama sebagai `oled`.
    return _fallbackReply(cleaned);
  }

  static bool _hasReplyFields(Map<String, dynamic> map) {
    final lowerKeys = map.keys.map((k) => k.toLowerCase()).toSet();
    return lowerKeys.contains('speech') || lowerKeys.contains('oled');
  }

  static String? _extractEnvelopeContent(Map<String, dynamic> envelope) {
    final choices = envelope['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map) {
          final content = message['content'];
          if (content is String) return content;
          if (content is List) {
            // Format multimodal OpenAI: [{type: 'text', text: '...'}]
            final buffer = StringBuffer();
            for (final part in content) {
              if (part is Map && part['text'] is String) {
                buffer.write(part['text']);
              }
            }
            if (buffer.isNotEmpty) return buffer.toString();
          }
        }
        if (first['text'] is String) return first['text'] as String;
        if (first['content'] is String) return first['content'] as String;
      }
    }

    for (final altKey in const ['content', 'response', 'reply', 'output', 'text']) {
      final value = envelope[altKey];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  static AiReply? _tryParseReplyObject(String candidate) {
    if (candidate.isEmpty) return null;
    final decoded = _tryDecodeJson(candidate);
    if (decoded is Map<String, dynamic>) {
      if (_hasReplyFields(decoded)) {
        return _fromReplyMap(decoded);
      }
      final nested = _extractEnvelopeContent(decoded);
      if (nested != null && nested != candidate) {
        return parseModelContent(nested);
      }
    }
    return null;
  }

  static Object? _tryDecodeJson(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      // Coba perbaiki trailing comma sebelum } atau ]
      try {
        final fixed = source.replaceAllMapped(
          _trailingComma,
          (m) => m.group(1)!,
        );
        return jsonDecode(fixed);
      } catch (_) {
        return null;
      }
    }
  }

  static AiReply _fromReplyMap(Map<String, dynamic> map) {
    String? rawSpeech;
    String? rawOled;

    for (final entry in map.entries) {
      final key = entry.key.toLowerCase().trim();
      final val = entry.value?.toString().trim();
      if (val == null || val.isEmpty) continue;
      if (key == 'speech' || key == 'text' || key == 'message' || key == 'jawaban') {
        rawSpeech ??= val;
      } else if (key == 'oled' || key == 'display' || key == 'summary' || key == 'ringkasan') {
        rawOled ??= val;
      }
    }

    final cleanSpeech = cleanSpeechText(
      rawSpeech?.isNotEmpty == true ? rawSpeech! : (rawOled ?? ''),
    );
    final effectiveSpeech = cleanSpeech.isNotEmpty
        ? cleanSpeech
        : 'Kondisi Anda terpantau baik. Tetap tenang dan perbanyak minum air.';

    final cleanOled = OledTextFormatter.sanitize(
      rawOled?.isNotEmpty == true ? rawOled! : effectiveSpeech,
    );

    return AiReply(
      speech: effectiveSpeech,
      oled: cleanOled.isNotEmpty
          ? cleanOled
          : OledTextFormatter.sanitize(effectiveSpeech),
      isStructured: true,
    );
  }

  /// Cari kandidat substring `{ ... }` di dalam teks menggunakan RegExp dan
  /// pencocokan kurung kurawal berimbang.
  static Iterable<String> _extractJsonObjectCandidates(String text) sync* {
    final regexMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (regexMatch != null) {
      yield regexMatch.group(0)!;
    }

    var depth = 0;
    var start = -1;
    var inQuotes = false;
    var escaped = false;

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (ch == r'\' && inQuotes) {
        escaped = true;
        continue;
      }
      if (ch == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (inQuotes) continue;

      if (ch == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (ch == '}') {
        if (depth > 0) {
          depth--;
          if (depth == 0 && start >= 0) {
            yield text.substring(start, i + 1);
            start = -1;
          }
        }
      }
    }
  }

  static AiReply? _tryRegexFieldExtraction(String text) {
    final speechMatch = RegExp(
      r'"speech"\s*:\s*"((?:[^"\\]|\\.)*)"',
      caseSensitive: false,
    ).firstMatch(text);
    final oledMatch = RegExp(
      r'"oled"\s*:\s*"((?:[^"\\]|\\.)*)"',
      caseSensitive: false,
    ).firstMatch(text);

    if (speechMatch == null && oledMatch == null) return null;

    final speechRaw = _unescapeJsonString(speechMatch?.group(1) ?? '');
    final oledRaw = _unescapeJsonString(oledMatch?.group(1) ?? '');
    return _fromReplyMap({'speech': speechRaw, 'oled': oledRaw});
  }

  static String _unescapeJsonString(String input) {
    if (input.isEmpty) return '';
    try {
      return jsonDecode('"$input"') as String;
    } catch (_) {
      return input
          .replaceAll(r'\"', '"')
          .replaceAll(r'\n', ' ')
          .replaceAll(r'\t', ' ');
    }
  }

  static AiReply _fallbackReply(String rawText) {
    // Buang pagar ``` bila tersisa
    var stripped = rawText
        .replaceAll(RegExp(r'```(?:json|javascript|js)?', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    final speech = cleanSpeechText(stripped);
    final effectiveSpeech = speech.isNotEmpty
        ? speech
        : 'Kondisi Anda terpantau stabil. Silakan istirahat bila merasa lelah.';
    final oled = OledTextFormatter.sanitize(effectiveSpeech);

    return AiReply(
      speech: effectiveSpeech,
      oled: oled.isNotEmpty ? oled : 'Kondisi Anda stabil',
      isStructured: false,
    );
  }

  /// Bersihkan teks speech dari simbol markdown agar nyaman dibacakan TTS.
  static String cleanSpeechText(String input) {
    return input
        .replaceAll(_speechMarkdown, '')
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(_multiSpaces, ' ')
        .trim();
  }
}

