import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/services/app_tts_service.dart';

/// Service responsible for turn-by-turn voice guidance in navigation mode.
/// Dynamically adjusts language between Indonesian ('id-ID') and English ('en-US'
/// with debouncing and cooldowns to provide natural, non-repetitive audio cues.
class NavigationVoiceService {
  static final NavigationVoiceService _instance =
      NavigationVoiceService._internal();
  factory NavigationVoiceService() => _instance;
  NavigationVoiceService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isMuted = false;
  String? _currentEngineLocale;

  String? _lastSpokenPrompt;
  DateTime? _lastSpokenTime;

  bool get isMuted => _isMuted;
  String? get currentEngineLocale => _currentEngineLocale;

  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      stop();
    }
  }

  Future<void> _initTts({String? languageCode}) async {
    try {
      _flutterTts ??= FlutterTts();
      await AppTtsService.configureEngine(
        _flutterTts!,
        explicitCode: languageCode,
        speechRate: 0.5,
      );
      _currentEngineLocale = AppTtsService.resolveEngineLocale(languageCode);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[NavigationVoiceService] Init error: $e');
    }
  }

  /// Speaks a voice navigation prompt.
  /// Dynamically detects and configures language according to active locale or [languageCode].
  /// Enforces cooldown guards to prevent audio stutter and annoying repetition.
  Future<void> speak(
    String text, {
    bool force = false,
    String? languageCode,
  }) async {
    if (_isMuted) return;
    var clean = text.trim();
    if (clean.isEmpty) return;

    final targetLang = AppTtsService.resolveLanguageCode(languageCode);
    final targetEngineLocale = AppTtsService.resolveEngineLocale(targetLang);

    // Translate common navigation phrases if speech text was passed in Indonesian
    // while the app/explicit language is English
    if (targetLang == 'en') {
      final lower = clean.toLowerCase();
      if (lower.startsWith('memulai navigasi menuju')) {
        final dest = clean.substring('memulai navigasi menuju'.length).trim();
        clean = 'Starting navigation to $dest';
      } else if (lower.contains('sampai di tujuan') ||
          lower.contains('telah sampai')) {
        clean = 'You have arrived at your destination.';
      }
    }

    final now = DateTime.now();

    // Prevent repeating the exact same cue within 8 seconds unless forced (e.g. arrival
    if (!force && _lastSpokenPrompt == clean && _lastSpokenTime != null) {
      if (now.difference(_lastSpokenTime!).inSeconds < 8) {
        return;
      }
    }

    // Minimum 3.5s cooldown between consecutive prompts to prevent audio overlap
    if (!force &&
        _lastSpokenTime != null &&
        now.difference(_lastSpokenTime!).inMilliseconds < 3500) {
      return;
    }

    _lastSpokenPrompt = clean;
    _lastSpokenTime = now;

    try {
      if (!_isInitialized || _flutterTts == null) {
        await _initTts(languageCode: targetLang);
      } else if (_currentEngineLocale != targetEngineLocale) {
        await AppTtsService.configureEngine(
          _flutterTts!,
          explicitCode: targetLang,
          speechRate: 0.5,
        );
        _currentEngineLocale = targetEngineLocale;
      }
      await _flutterTts?.stop();
      await _flutterTts?.speak(clean);
    } catch (e) {
      debugPrint('[NavigationVoiceService] Speak error: $e');
    }
  }

  /// Evaluates and speaks appropriate voice prompt based on distance and maneuver.
  /// [distanceMeters] is the distance to the upcoming turn or destination.
  /// [durationSeconds] is estimated travel time to destination.
  /// [instruction] is the upcoming directional instruction (e.g., 'Belok kiri', 'Turn left').
  Future<void> announceManeuver({
    required String instruction,
    double? distanceMeters,
    int? durationSeconds,
    String? languageCode,
  }) async {
    if (_isMuted) return;

    final lang = AppTtsService.resolveLanguageCode(languageCode);
    final isEn = lang == 'en';
    final lower = instruction.toLowerCase();

    // Determine normalized maneuver action
    String direction;
    if (lower.contains('kanan') || lower.contains('right')) {
      direction = isEn ? 'turn right' : 'belok kanan';
    } else if (lower.contains('kiri') || lower.contains('left')) {
      direction = isEn ? 'turn left' : 'belok kiri';
    } else if (lower.contains('lurus') || lower.contains('straight')) {
      direction = isEn ? 'continue straight' : 'lurus terus';
    } else {
      direction = lower;
    }

    // 1. Immediate Turn: <= 18 meters
    if (distanceMeters != null && distanceMeters <= 18.0) {
      if (lower.contains('kiri') ||
          lower.contains('kanan') ||
          lower.contains('left') ||
          lower.contains('right')) {
        final prompt = isEn ? 'Now $direction' : 'Sekarang $direction';
        await speak(prompt, languageCode: lang);
        return;
      }
    }

    // 2. Near Turn: 40 - 70 meters
    if (distanceMeters != null &&
        distanceMeters <= 70.0 &&
        distanceMeters > 30.0) {
      final prompt = isEn
          ? 'In 50 meters, $direction'
          : 'Dalam 50 meter, $direction';
      await speak(prompt, languageCode: lang);
      return;
    }

    // 3. Medium Warning: 90 - 140 meters
    if (distanceMeters != null &&
        distanceMeters <= 140.0 &&
        distanceMeters > 80.0) {
      final prompt = isEn
          ? 'In 100 meters, $direction'
          : 'Dalam 100 meter, $direction';
      await speak(prompt, languageCode: lang);
      return;
    }

    // 4. Time-based advance cue (e.g., ~3 minutes or > 150m away
    if (durationSeconds != null &&
        durationSeconds >= 160 &&
        durationSeconds <= 210) {
      final minutes = (durationSeconds / 60).round();
      if (minutes > 0) {
        final prompt = isEn
            ? 'In about $minutes minute${minutes > 1 ? 's' : ''}, $direction'
            : 'Sekitar $minutes menit lagi, $direction';
        await speak(prompt, languageCode: lang);
        return;
      }
    }
  }

  /// Stops current speech output.
  Future<void> stop() async {
    try {
      await _flutterTts?.stop();
    } catch (_) {}
  }

  /// Resets state when exiting navigation mode.
  void reset() {
    _lastSpokenPrompt = null;
    _lastSpokenTime = null;
    stop();
  }

  /// Sets custom FlutterTts instance (useful for unit testing).
  @visibleForTesting
  void setMockTts(FlutterTts? tts) {
    _flutterTts = tts;
    _isInitialized = tts != null;
  }
}
