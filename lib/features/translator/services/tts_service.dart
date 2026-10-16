import 'package:flutter_tts/flutter_tts.dart';
import 'tts_validation_tracker_service.dart';

enum TtsState { playing, stopped }

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;

  TtsState get state => _ttsState;
  bool get isPlaying => _ttsState == TtsState.playing;

  Function(TtsState state)? onStateChanged;

  TtsService() {
    _init();
  }

  void _init() {
    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      onStateChanged?.call(_ttsState);
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      onStateChanged?.call(_ttsState);
    });

    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
      onStateChanged?.call(_ttsState);
    });

    _flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
      onStateChanged?.call(_ttsState);
    });
  }

  /// Speaks the given [text] in the requested [languageCode] ('ar', 'id', 'en').
  /// Toggles between speak and stop if currently playing.
  Future<void> speak({
    required String text,
    required String languageCode,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (_ttsState == TtsState.playing) {
      await stop();
      return;
    }

    final stopwatch = Stopwatch()..start();

    String locale;
    switch (languageCode.toLowerCase()) {
      case 'ar':
        locale = 'ar-SA';
        break;
      case 'id':
        locale = 'id-ID';
        break;
      case 'en':
        locale = 'en-US';
        break;
      default:
        locale = 'id-ID';
    }

    try {
      final isAvailable = await _flutterTts.isLanguageAvailable(locale);
      if (isAvailable == true) {
        await _flutterTts.setLanguage(locale);
      } else if (languageCode.toLowerCase() == 'ar') {
        // Fallback to base 'ar' if specific dialect is unavailable
        await _flutterTts.setLanguage('ar');
      } else {
        await _flutterTts.setLanguage(locale);
      }
    } catch (_) {
      await _flutterTts.setLanguage(locale);
    }

    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    try {
      await _flutterTts.speak(trimmed);
      final durationSec = stopwatch.elapsedMilliseconds / 1000.0;
      await TtsValidationTrackerService.instance.logTrial(
        textSpoken: trimmed,
        languageCode: languageCode,
        durationSeconds: durationSec,
        isSuccess: true,
      );
    } catch (e) {
      final durationSec = stopwatch.elapsedMilliseconds / 1000.0;
      await TtsValidationTrackerService.instance.logTrial(
        textSpoken: trimmed,
        languageCode: languageCode,
        durationSeconds: durationSec,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
    onStateChanged?.call(_ttsState);
  }

  void dispose() {
    _flutterTts.stop();
  }
}
