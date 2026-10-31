import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/services/app_tts_service.dart';
import '../../../core/utils/app_logger.dart';

/// Service terpadu untuk **Text-to-Speech (`flutter_tts`)** dan
/// **Speech-to-Text (`speech_to_text` bahasa `id_ID`)** pada HajiCare AI Assistant.
class AiVoiceService {
  AiVoiceService({FlutterTts? tts, SpeechToText? speechToText})
    : _tts = tts ?? FlutterTts(),
      _speechToText = speechToText ?? SpeechToText();

  final FlutterTts _tts;
  final SpeechToText _speechToText;

  bool _ttsInitialized = false;
  bool _sttInitialized = false;
  bool _hasSttPermission = false;
  bool _isDisposed = false;

  void Function(bool isSpeaking)? onSpeakingChanged;
  void Function(bool isListening, String statusMessage)? onListeningChanged;
  void Function(String recognizedWords, bool isFinal)? onSpeechResult;
  void Function(double soundLevel)? onSoundLevelChanged;

  bool get isListening => _speechToText.isListening;

  /// Inisialisasi engine `FlutterTts` berbahasa Indonesia (`id-ID`).
  Future<void> initTts() async {
    if (_isDisposed || _ttsInitialized) return;
    try {
      await AppTtsService.configureEngine(
        _tts,
        explicitCode: 'id',
        speechRate: 0.48,
        volume: 1.0,
        pitch: 1.0,
      );

      _tts.setStartHandler(() {
        if (!_isDisposed) onSpeakingChanged?.call(true);
      });
      _tts.setCompletionHandler(() {
        if (!_isDisposed) onSpeakingChanged?.call(false);
      });
      _tts.setCancelHandler(() {
        if (!_isDisposed) onSpeakingChanged?.call(false);
      });
      _tts.setErrorHandler((msg) {
        AppLogger.warn('FlutterTts error: $msg', tag: 'AiVoiceService');
        if (!_isDisposed) onSpeakingChanged?.call(false);
      });

      _ttsInitialized = true;
    } catch (e) {
      AppLogger.warn('Gagal menginisialisasi TTS: $e', tag: 'AiVoiceService');
    }
  }

  /// Bacakan kalimat penjelasan berbahasa Indonesia menggunakan `flutter_tts`.
  Future<void> speak(String text) async {
    if (_isDisposed) return;
    final clean = text.trim();
    if (clean.isEmpty) return;

    await initTts();
    try {
      await _tts.stop();
      onSpeakingChanged?.call(true);
      await AppTtsService.configureEngine(
        _tts,
        explicitCode: 'id',
        speechRate: 0.48,
        volume: 1.0,
        pitch: 1.0,
      );
      await _tts.speak(clean);
    } catch (e) {
      AppLogger.warn('Gagal menjalankan TTS speak: $e', tag: 'AiVoiceService');
      onSpeakingChanged?.call(false);
    }
  }

  /// Hentikan pembacaan suara (`flutter_tts.stop()`).
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    if (!_isDisposed) {
      onSpeakingChanged?.call(false);
    }
  }

  /// Inisialisasi `speech_to_text` dan pasang listener aktif.
  Future<bool> initStt() async {
    if (_isDisposed) return false;
    try {
      final ok = await _speechToText.initialize(
        onStatus: _handleSttStatus,
        onError: _handleSttError,
      );
      // Karena SpeechToText adalah singleton, pastikan listener selalu terhubung
      // ke instance service ini meskipun initialize() pernah dipanggil di fitur lain.
      _speechToText.statusListener = _handleSttStatus;
      _speechToText.errorListener = _handleSttError;

      _sttInitialized = true;
      _hasSttPermission = ok;
      return ok;
    } catch (e) {
      AppLogger.warn('Gagal inisialisasi STT: $e', tag: 'AiVoiceService');
      _sttInitialized = false;
      _hasSttPermission = false;
      return false;
    }
  }

  void _handleSttStatus(String status) {
    if (_isDisposed) return;
    final lower = status.toLowerCase();
    if (lower == 'listening') {
      onListeningChanged?.call(true, 'Mendengarkan... Silakan bicara');
    } else if (lower == 'notlistening' || lower == 'done') {
      onListeningChanged?.call(false, 'Siap mendengarkan');
    }
  }

  void _handleSttError(dynamic errorNotification) {
    if (_isDisposed) return;
    final errMsg = errorNotification?.errorMsg?.toString() ?? '';
    AppLogger.warn('STT error: $errMsg', tag: 'AiVoiceService');
    if (errMsg.contains('permission')) {
      onListeningChanged?.call(
        false,
        'Izin mikrofon belum diberikan. Aktifkan izin mikrofon di pengaturan HP.',
      );
    } else if (errMsg.contains('no_match') || errMsg.contains('speech_timeout')) {
      onListeningChanged?.call(
        false,
        'Suara belum terdengar jelas. Silakan tekan mikrofon dan bicara lagi.',
      );
    } else {
      onListeningChanged?.call(false, 'Perekaman suara selesai.');
    }
  }

  /// Mulai mendengarkan suara pengguna melalui mikrofon HP (`id_ID`).
  Future<bool> startListening({String localeId = 'id_ID'}) async {
    if (_isDisposed) return false;

    // Hentikan TTS terlebih dahulu agar suara asisten tidak ikut terekam mikrofon
    await stopSpeaking();

    if (!_sttInitialized || !_hasSttPermission) {
      final ready = await initStt();
      if (!ready) {
        onListeningChanged?.call(
          false,
          'Mikrofon belum tersedia atau izin mikrofon ditolak.',
        );
        return false;
      }
    } else {
      _speechToText.statusListener = _handleSttStatus;
      _speechToText.errorListener = _handleSttError;
    }

    try {
      String resolvedLocale = localeId;
      try {
        final locales = await _speechToText.locales();
        for (final loc in locales) {
          final id = loc.localeId.toLowerCase();
          if (id == 'id_id' || id == 'id-id' || id.startsWith('id')) {
            resolvedLocale = loc.localeId;
            break;
          }
        }
      } catch (_) {}

      onListeningChanged?.call(true, 'Mendengarkan suara Anda (Bahasa Indonesia)...');

      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          if (_isDisposed) return;
          onSpeechResult?.call(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: (double level) {
          if (_isDisposed) return;
          onSoundLevelChanged?.call(level);
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
          localeId: resolvedLocale,
        ),
      );
      return true;
    } catch (e) {
      AppLogger.warn('Gagal memulai STT listen: $e', tag: 'AiVoiceService');
      onListeningChanged?.call(
        false,
        'Gagal mengakses mikrofon. Silakan coba lagi atau ketik pertanyaan.',
      );
      return false;
    }
  }

  /// Hentikan perekaman mikrofon.
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (_) {}
    if (!_isDisposed) {
      onListeningChanged?.call(false, 'Siap mendengarkan');
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    onSpeakingChanged = null;
    onListeningChanged = null;
    onSpeechResult = null;
    onSoundLevelChanged = null;
    unawaited(_tts.stop());
    unawaited(_speechToText.cancel());
  }
}

