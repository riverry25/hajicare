import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';

class PhraseItem {
  final String indonesian;
  final String transliteration;
  final String arabic;
  final String category;
  final bool isUrgent;
  final String? translationKey;

  const PhraseItem({
    required this.indonesian,
    required this.transliteration,
    required this.arabic,
    required this.category,
    this.isUrgent = false,
    this.translationKey,
  });

  /// Returns localized meaning if available, otherwise falls back to Indonesian.
  String localizedMeaning(BuildContext context) {
    if (translationKey != null) {
      final translated = context.tr(translationKey!);
      if (translated.isNotEmpty && translated != translationKey) {
        return translated;
      }
    }
    return indonesian;
  }
}

class CommunicationController extends GetxController {
  late FlutterTts _tts;
  final isSpeaking = false.obs;
  final activePhrase = ''.obs;
  final hasTtsError = false.obs;
  final isTtsInitialized = false.obs;
  final searchQuery = ''.obs;

  final List<PhraseItem> phrases = const [
    // ── Darurat & Kesehatan ─────────────────────────────
    PhraseItem(
      indonesian: 'Tolong, saya butuh dokter',
      transliteration: "Musa'adah, ahtaju tabiban",
      arabic: 'مساعدة، أحتاج طبيباً',
      category: 'Darurat & Kesehatan',
      isUrgent: true,
      translationKey: 'quickComm.phrase.doctor',
    ),
    PhraseItem(
      indonesian: 'Saya merasa sakit',
      transliteration: 'Ana mareed',
      arabic: 'أنا مريض',
      category: 'Darurat & Kesehatan',
      isUrgent: false,
      translationKey: 'quickComm.phrase.sick',
    ),
    PhraseItem(
      indonesian: 'Dimana rumah sakit?',
      transliteration: 'Ayna al-mustashfa?',
      arabic: 'أين المستشفى؟',
      category: 'Darurat & Kesehatan',
      isUrgent: false,
      translationKey: 'quickComm.phrase.hospital',
    ),
    PhraseItem(
      indonesian: 'Saya butuh kursi roda',
      transliteration: 'Ahtaju kursi mutaharrik',
      arabic: 'أحتاج كرسي متحرك',
      category: 'Darurat & Kesehatan',
      isUrgent: false,
      translationKey: 'quickComm.phrase.wheelchair',
    ),

    // ── Arah & Lokasi ───────────────────────────────────
    PhraseItem(
      indonesian: 'Saya tersesat',
      transliteration: "Ana dae'e",
      arabic: 'أنا ضائع',
      category: 'Arah & Lokasi',
      isUrgent: true,
      translationKey: 'quickComm.phrase.lost',
    ),
    PhraseItem(
      indonesian: 'Dimana hotel saya?',
      transliteration: 'Ayna funduqi?',
      arabic: 'أين فندقي؟',
      category: 'Arah & Lokasi',
      isUrgent: false,
      translationKey: 'quickComm.phrase.hotel',
    ),
    PhraseItem(
      indonesian: 'Dimana pintu keluar?',
      transliteration: 'Ayna al-makhraj?',
      arabic: 'أين المخرج؟',
      category: 'Arah & Lokasi',
      isUrgent: false,
      translationKey: 'quickComm.phrase.exit',
    ),
    PhraseItem(
      indonesian: 'Dimana toilet / kamar mandi?',
      transliteration: 'Ayna dawrat al-miyah?',
      arabic: 'أين دورة المياه؟',
      category: 'Arah & Lokasi',
      isUrgent: false,
      translationKey: 'quickComm.phrase.bathroom',
    ),
    PhraseItem(
      indonesian: 'Dimana kantor polisi?',
      transliteration: 'Ayna markaz al-shurtah?',
      arabic: 'أين مركز الشرطة؟',
      category: 'Arah & Lokasi',
      isUrgent: false,
      translationKey: 'quickComm.phrase.police',
    ),

    // ── Umum ───────────────────────────────────────────
    PhraseItem(
      indonesian: 'Boleh minta air?',
      transliteration: "Mumaakin maa'?",
      arabic: 'ممكن ماء؟',
      category: 'Umum',
      isUrgent: false,
      translationKey: 'quickComm.phrase.water',
    ),
    PhraseItem(
      indonesian: 'Terima kasih',
      transliteration: 'Shukran',
      arabic: 'شكراً',
      category: 'Umum',
      isUrgent: false,
      translationKey: 'quickComm.phrase.thanks',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();

      // Handlers
      _tts.setStartHandler(() {
        isSpeaking.value = true;
        hasTtsError.value = false;
      });

      _tts.setCompletionHandler(() {
        isSpeaking.value = false;
        activePhrase.value = '';
      });

      _tts.setCancelHandler(() {
        isSpeaking.value = false;
        activePhrase.value = '';
      });

      _tts.setErrorHandler((dynamic msg) {
        debugPrint('[TTS] Error callback: $msg');
        isSpeaking.value = false;
        activePhrase.value = '';
        hasTtsError.value = true;
      });

      // Await speak completion for clean playback state
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (e) {
        debugPrint(
          '[TTS] awaitSpeakCompletion not supported on this platform: $e',
        );
      }

      // iOS Audio Session Configuration
      // Forces audio to play through loudspeaker even if silent switch is on.
      if (!kIsWeb && Platform.isIOS) {
        try {
          await _tts
              .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
                IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
                IosTextToSpeechAudioCategoryOptions.allowBluetooth,
                IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              ], IosTextToSpeechAudioMode.defaultMode);
          await _tts.setSharedInstance(true);
        } catch (e) {
          debugPrint('[TTS] iOS audio session configuration warning: $e');
        }
      }

      // Configure Arabic Language with intelligent fallbacks
      await _configureArabicLanguage();

      // Configure natural speech rate and volume for clarity
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      isTtsInitialized.value = true;
    } catch (e) {
      debugPrint('[TTS] Initialization error: $e');
      isTtsInitialized.value = false;
    }
  }

  /// Finds and applies the best available Arabic locale supported on this device.
  Future<void> _configureArabicLanguage() async {
    final candidateLocales = [
      'ar-SA',
      'ar_SA',
      'ar',
      'ar-EG',
      'ar_EG',
      'ar-AE',
      'ar_AE',
    ];

    bool languageSet = false;
    try {
      for (final loc in candidateLocales) {
        final isAvailable = await _tts.isLanguageAvailable(loc);
        if (isAvailable == true || isAvailable == 1) {
          await _tts.setLanguage(loc);
          languageSet = true;
          debugPrint('[TTS] Selected available Arabic locale: $loc');
          break;
        }
      }
    } catch (e) {
      debugPrint('[TTS] isLanguageAvailable check error: $e');
    }

    if (!languageSet) {
      // Default attempt
      try {
        await _tts.setLanguage('ar-SA');
      } catch (_) {
        try {
          await _tts.setLanguage('ar');
        } catch (_) {}
      }
    }
  }

  /// Speaks the given Arabic text. Toggles to stop if currently speaking the same phrase.
  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    // Toggle stop if already speaking this phrase
    if (isSpeaking.value && activePhrase.value == clean) {
      await stop();
      return;
    }

    // Stop preceding audio if speaking another phrase
    if (isSpeaking.value) {
      await stop();
    }

    try {
      hasTtsError.value = false;
      activePhrase.value = clean;
      isSpeaking.value = true;

      // Re-apply max volume and speech rate in case OS altered it
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.42);

      final result = await _tts.speak(clean);
      if (result == 0) {
        // Result 0 on flutter_tts indicates playback could not be started
        debugPrint('[TTS] flutter_tts speak returned 0 (failed)');
        hasTtsError.value = true;
        isSpeaking.value = false;
        activePhrase.value = '';
      }
    } catch (e) {
      debugPrint('[TTS] Speak error: $e');
      hasTtsError.value = true;
      isSpeaking.value = false;
      activePhrase.value = '';
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[TTS] Stop error: $e');
    } finally {
      isSpeaking.value = false;
      activePhrase.value = '';
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void clearSearchQuery() {
    searchQuery.value = '';
  }

  List<PhraseItem> filterPhrases({
    required String selectedCategory,
    String? query,
    BuildContext? context,
  }) {
    final q = (query ?? searchQuery.value).trim().toLowerCase();

    return phrases.where((p) {
      final matchesCategory =
          selectedCategory == 'Semua' ||
          selectedCategory == 'all' ||
          p.category == selectedCategory;

      if (!matchesCategory) return false;

      if (q.isEmpty) return true;

      final localized = context != null
          ? p.localizedMeaning(context).toLowerCase()
          : '';

      return p.indonesian.toLowerCase().contains(q) ||
          p.transliteration.toLowerCase().contains(q) ||
          p.arabic.contains(q) ||
          p.category.toLowerCase().contains(q) ||
          localized.contains(q);
    }).toList();
  }

  @override
  void onClose() {
    _tts.stop();
    super.onClose();
  }
}
