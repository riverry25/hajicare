import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/utils/app_logger.dart';

/// Service khusus untuk membaca hasil terjemahan BISINDO menggunakan
/// Text-to-Speech (TTS) Bahasa Indonesia (`id-ID`).
class BisindoTtsService {
  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final tts = FlutterTts();
      _flutterTts = tts;
      await tts.setLanguage('id-ID');
      await tts.setSpeechRate(0.5);
      await tts.setPitch(1.0);
      await tts.setVolume(1.0);
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
      AppLogger.info('Initialized with id-ID language', tag: 'BisindoTTS');
    } catch (e) {
      AppLogger.warn(
        'Initialization skipped or unavailable in current environment: $e',
        tag: 'BisindoTTS',
      );
    }
  }

  /// Membacakan teks dalam Bahasa Indonesia.
  /// Jika teks kosong, method ini akan mengabaikan tanpa error.
  Future<void> speak(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    if (!_isInitialized) {
      await initialize();
    }

    try {
      final tts = _flutterTts;
      if (tts == null) return;

      if (_isSpeaking) {
        await tts.stop();
      }

      await tts.speak(cleanText);
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
  }
}
