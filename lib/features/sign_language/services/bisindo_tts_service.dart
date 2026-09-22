import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
        debugPrint('[BISINDO][TTS] error: $msg');
      });

      _isInitialized = true;
      debugPrint('[BISINDO][TTS] Initialized with id-ID language');
    } catch (e) {
      debugPrint(
        '[BISINDO][TTS] Initialization skipped or unavailable in current environment: $e',
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
      debugPrint('[BISINDO][TTS] Speak error: $e');
    }
  }

  /// Menghentikan pembacaan yang sedang berlangsung.
  Future<void> stop() async {
    try {
      await _flutterTts?.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('[BISINDO][TTS] Stop error: $e');
    }
  }

  /// Melepas resource TTS.
  Future<void> dispose() async {
    try {
      await _flutterTts?.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('[BISINDO][TTS] Dispose error: $e');
    }
    _flutterTts = null;
    _isInitialized = false;
  }
}
