import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service responsible for turn-by-turn voice guidance in navigation mode.
/// Uses FlutterTts configured for Indonesian (id-ID) with debouncing and cooldowns
/// to provide natural, non-repetitive audio cues.
class NavigationVoiceService {
  static final NavigationVoiceService _instance =
      NavigationVoiceService._internal();
  factory NavigationVoiceService() => _instance;
  NavigationVoiceService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isMuted = false;

  String? _lastSpokenPrompt;
  DateTime? _lastSpokenTime;

  bool get isMuted => _isMuted;

  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      stop();
    }
  }

  Future<void> _initTts() async {
    if (_isInitialized) return;
    try {
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage('id-ID');
      await _flutterTts!.setSpeechRate(0.5); // Natural, clear Indonesian pacing
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[NavigationVoiceService] Init error: $e');
    }
  }

  /// Speaks a voice navigation prompt.
  /// Enforces cooldown guards to prevent audio stutter and annoying repetition.
  Future<void> speak(String text, {bool force = false}) async {
    if (_isMuted) return;
    final clean = text.trim();
    if (clean.isEmpty) return;

    final now = DateTime.now();

    // Prevent repeating the exact same cue within 8 seconds unless forced (e.g. arrival)
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
      await _initTts();
      await _flutterTts?.stop();
      await _flutterTts?.speak(clean);
    } catch (e) {
      debugPrint('[NavigationVoiceService] Speak error: $e');
    }
  }

  /// Evaluates and speaks appropriate voice prompt based on distance and maneuver.
  /// [distanceMeters] is the distance to the upcoming turn or destination.
  /// [durationSeconds] is estimated travel time to destination.
  /// [instruction] is the upcoming directional instruction (e.g., 'Belok kiri', 'Belok kanan').
  Future<void> announceManeuver({
    required String instruction,
    double? distanceMeters,
    int? durationSeconds,
  }) async {
    if (_isMuted) return;

    final lower = instruction.toLowerCase();

    // 1. Immediate Turn: <= 18 meters
    if (distanceMeters != null && distanceMeters <= 18.0) {
      if (lower.contains('kiri') || lower.contains('kanan')) {
        await speak('Sekarang ${lower.replaceAll('belok ', 'belok ')}');
        return;
      }
    }

    // 2. Near Turn: 40 - 70 meters
    if (distanceMeters != null &&
        distanceMeters <= 70.0 &&
        distanceMeters > 30.0) {
      await speak('Dalam 50 meter, $lower');
      return;
    }

    // 3. Medium Warning: 90 - 140 meters
    if (distanceMeters != null &&
        distanceMeters <= 140.0 &&
        distanceMeters > 80.0) {
      await speak('Dalam 100 meter, $lower');
      return;
    }

    // 4. Time-based advance cue (e.g., ~3 minutes or > 150m away)
    if (durationSeconds != null &&
        durationSeconds >= 160 &&
        durationSeconds <= 210) {
      final minutes = (durationSeconds / 60).round();
      if (minutes > 0) {
        await speak('Sekitar $minutes menit lagi, $lower');
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
}
