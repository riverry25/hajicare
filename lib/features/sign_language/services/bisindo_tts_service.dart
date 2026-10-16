import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/services/app_tts_service.dart';
import '../../../core/utils/app_logger.dart';

/// Service khusus untuk membaca hasil terjemahan BISINDO menggunakan
/// Text-to-Speech (TTS) yang beradaptasi secara dinamis dengan bahasa aktif
/// aplikasi ('id-ID' Bahasa Indonesia atau 'en-US' Bahasa Inggris).
class BisindoTtsService {
  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _currentEngineLocale;

  bool get isSpeaking => _isSpeaking;
  String? get currentEngineLocale => _currentEngineLocale;

  Future<void> initialize({String? languageCode}) async {
    if (_isInitialized) return;
    try {
      final tts = FlutterTts();
      _flutterTts = tts;
      final targetLang = AppTtsService.resolveLanguageCode(languageCode);
      await AppTtsService.configureEngine(
        tts,
        explicitCode: targetLang,
        speechRate: 0.5,
        pitch: 1.0,
        volume: 1.0,
      );
      _currentEngineLocale = AppTtsService.resolveEngineLocale(targetLang);
      await tts.awaitSpeakCompletion(true);

      tts.setStartHandler(() {
        _isSpeaking = true;
      });

      tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      tts.setCancelHandler(() {
        _isSpeaking = false;
      });

      tts.setErrorHandler((dynamic msg) {
        _isSpeaking = false;
        AppLogger.error('error: $msg', tag: 'BisindoTTS');
      });

      _isInitialized = true;
      AppLogger.info(
        'Initialized with $_currentEngineLocale language',
        tag: 'BisindoTTS',
      );
    } catch (e) {
      AppLogger.warn(
        'Initialization skipped or unavailable in current environment: $e',
        tag: 'BisindoTTS',
      );
    }
  }

  /// Membacakan teks tanda/kata BISINDO.
  /// Bila bahasa aplikasi/target adalah bahasa Inggris, teks kata diterjemahkan
  /// ke dalam Bahasa Inggris sebelum disuarakan oleh engine TTS 'en-US'.
  /// Jika teks kosong, method ini akan mengabaikan tanpa error.
  Future<void> speak(String text, {String? languageCode}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final targetLang = AppTtsService.resolveLanguageCode(languageCode);
    final targetEngineLocale = AppTtsService.resolveEngineLocale(targetLang);

    if (!_isInitialized || _flutterTts == null) {
      await initialize(languageCode: targetLang);
    }

    try {
      final tts = _flutterTts;
      if (tts == null) return;

      if (_currentEngineLocale != targetEngineLocale) {
        await AppTtsService.configureEngine(
          tts,
          explicitCode: targetLang,
          speechRate: 0.5,
          pitch: 1.0,
          volume: 1.0,
        );
        _currentEngineLocale = targetEngineLocale;
      }

      if (_isSpeaking) {
        await tts.stop();
      }

      final textToSpeak = targetLang == 'en'
          ? AppTtsService.translateSignWord(cleanText, explicitCode: targetLang)
          : cleanText;

      await tts.speak(textToSpeak);
    } catch (e) {
      AppLogger.error('Speak error: $e', tag: 'BisindoTTS');
    }
  }

  /// Menghentikan pembacaan yang sedang berlangsung.
  Future<void> stop() async {
    try {
      await _flutterTts?.stop();
      _isSpeaking = false;
    } catch (e) {
      AppLogger.error('Stop error: $e', tag: 'BisindoTTS');
    }
  }

  /// Melepas resource TTS.
  Future<void> dispose() async {
    try {
      await _flutterTts?.stop();
      _isSpeaking = false;
    } catch (e) {
      AppLogger.error('Dispose error: $e', tag: 'BisindoTTS');
    }
    _flutterTts = null;
    _isInitialized = false;
    _currentEngineLocale = null;
  }

  /// Injeksi mock untuk keperluan unit testing.
  @visibleForTesting
  void setMockTts(FlutterTts? tts) {
    _flutterTts = tts;
    _isInitialized = tts != null;
  }
}
