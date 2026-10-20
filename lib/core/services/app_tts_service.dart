import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import '../state/app_settings_controller.dart';

/// Centralized coordinator for Text-to-Speech (TTS) language resolution
/// engine configuration, and bilingual phrase mapping across HajiCare features
/// Turn-by-turn Navigation, BISINDO Sign Language, and Money Recognition).
class AppTtsService {
  AppTtsService._();

  /// Resolves the normalized 2-letter language code for TTS ('id' or 'en').
  /// If [explicitCode] is provided, it takes precedence.
  /// Otherwise, it reads the active locale from [AppSettingsController].
  /// Regional languages ('jv', 'su') gracefully fallback to 'id' due to
  /// mobile OS TTS voice availability.
  static String resolveLanguageCode([String? explicitCode]) {
    if (explicitCode != null && explicitCode.trim().isNotEmpty) {
      final code = explicitCode.trim().toLowerCase();
      return code == 'en' ? 'en' : 'id';
    }

    try {
      if (Get.isRegistered<AppSettingsController>()) {
        final current =
            Get.find<AppSettingsController>().currentLocale.languageCode;
        if (current.toLowerCase() == 'en') return 'en';
      }
    } catch (_) {}

    return 'id';
  }

  /// Resolves the engine-level locale string for FlutterTts ('id-ID' or 'en-US').
  static String resolveEngineLocale([String? explicitCode]) {
    final code = resolveLanguageCode(explicitCode);
    return code == 'en' ? 'en-US' : 'id-ID';
  }

  /// Checks if the currently active application TTS is in English mode.
  static bool get isEnglish => resolveLanguageCode() == 'en';

  /// Applies language, speech rate, volume, and pitch to a [FlutterTts] instance
  /// based on the active application language or an [explicitCode].
  static Future<void> configureEngine(
    FlutterTts tts, {
    String? explicitCode,
    double speechRate = 0.5,
    double volume = 1.0,
    double pitch = 1.0,
  }) async {
    final engineLocale = resolveEngineLocale(explicitCode);
    try {
      final isAvailable = await tts.isLanguageAvailable(engineLocale);
      if (isAvailable == true) {
        await tts.setLanguage(engineLocale);
      } else {
        await tts.setLanguage(engineLocale == 'en-US' ? 'en' : 'id');
      }
    } catch (e) {
      debugPrint('[AppTtsService] configureEngine setLanguage error: $e');
      try {
        await tts.setLanguage(engineLocale);
      } catch (_) {}
    }

    try {
      await tts.setSpeechRate(speechRate);
      await tts.setVolume(volume);
      await tts.setPitch(pitch);
    } catch (e) {
      debugPrint('[AppTtsService] configureEngine parameters error: $e');
    }
  }

  // BISINDO Sign Language Indonesian to English Mapping
  static const Map<String, String> _bisindoToEnglish = {
    'aku': 'i',
    'saya': 'i',
    'kamu': 'you',
    'anda': 'you',
    'dia': 'they',
    'kami': 'we',
    'kita': 'we',
    'apa': 'what',
    'dimana': 'where',
    'di mana': 'where',
    'kapan': 'when',
    'kenapa': 'why',
    'mengapa': 'why',
    'bagaimana': 'how',
    'siapa': 'who',
    'terima kasih': 'thank you',
    'terimakasih': 'thank you',
    'makasih': 'thank you',
    'syukran': 'thank you',
    'sama sama': "you're welcome",
    'sama-sama': "you're welcome",
    'tolong': 'help',
    'bantuan': 'help',
    'bantu': 'help',
    'sakit': 'pain',
    'dokter': 'doctor',
    'rumah sakit': 'hospital',
    'obat': 'medicine',
    'darurat': 'emergency',
    'polisi': 'police',
    'hotel': 'hotel',
    'masjid': 'mosque',
    'makan': 'eat',
    'minum': 'drink',
    'mandi': 'take a bath',
    'air': 'water',
    'uang': 'money',
    'kamar': 'room',
    'toilet': 'restroom',
    'kamar mandi': 'bathroom',
    'tuli': 'deaf',
    'tunarungu': 'hearing impaired',
    'halo': 'hello',
    'hai': 'hi',
    'apa kabar': 'how are you',
    'kabar baik': "i'm good",
    'selamat pagi': 'good morning',
    'selamat siang': 'good afternoon',
    'selamat sore': 'good afternoon',
    'selamat malam': 'good night',
    'sampai jumpa': 'see you later',
    'dadah': 'goodbye',
    'selamat jalan': 'safe travels',
    'ya': 'yes',
    'tidak': 'no',
    'bukan': 'not',
    'maaf': 'sorry',
    'permisi': 'excuse me',
    'haji': 'hajj',
    'umroh': 'umrah',
    'umrah': 'umrah',
    'ka\'bah': 'kaaba',
    'kabah': 'kaaba',
    'tawaf': 'tawaf',
    'sa\'i': 'sa\'i',
    'sai': 'sa\'i',
    'wudhu': 'wudu',
    'sholat': 'prayer',
    'salat': 'prayer',
    'bus': 'bus',
    'taksi': 'taxi',
    'jalan': 'walk',
    'tersesat': 'lost',
    'hilang': 'lost',
    'jamaah': 'pilgrim',
    'pendamping': 'companion',
  };

  /// Translates a recognized sign language word/phrase to English if active language is 'en'.
  /// Returns the original text if active language is 'id' or no translation is registered.
  static String translateSignWord(String word, {String? explicitCode}) {
    final lang = resolveLanguageCode(explicitCode);
    if (lang != 'en') return word;

    final trimmed = word.trim();
    if (trimmed.isEmpty) return word;

    final lower = trimmed.toLowerCase();
    final directMatch = _bisindoToEnglish[lower];
    if (directMatch != null) {
      if (trimmed == trimmed.toUpperCase() && trimmed.length > 1) {
        return directMatch.toUpperCase();
      }
      return directMatch;
    }

    // Multi-word fallback: translate known words within phrase
    if (lower.contains(' ')) {
      final tokens = lower.split(RegExp(r'\s+'));
      final translatedTokens = tokens.map((t) => _bisindoToEnglish[t] ?? t);
      return translatedTokens.join(' ');
    }

    return word;
  }
}
