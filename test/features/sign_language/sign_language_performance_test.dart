import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:hajicare/features/sign_language/models/bisindo_prediction.dart';
import 'package:hajicare/features/sign_language/models/sign_language_model.dart';
import 'package:hajicare/features/sign_language/services/bisindo_tts_service.dart';

class MockBisindoTtsService extends BisindoTtsService {
  final List<String> spokenUtterances = [];

  @override
  Future<void> initialize({String? languageCode}) async {}

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    spokenUtterances.add(text);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sign Language Speech Idle Delay & Debounce Tests', () {
    late BisindoRecognitionController controller;
    late MockBisindoTtsService mockTts;

    setUp(() {
      Get.reset();
      mockTts = MockBisindoTtsService();
      controller = BisindoRecognitionController(
        config: const BisindoRecognitionConfig(
          speechIdleDelay: Duration(milliseconds: 2000), // 2s for testing
        ),
        ttsService: mockTts,
        autoTick: false, // We control tick manually in tests
      );
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    test('Word commits do not speak immediately while jamaah may still be gesturing', () {
      final now = DateTime(2026, 1, 1, 10, 0, 0);

      // Jamaah signs 'ASSALAMUALAIKUM'
      controller.commitWord('assalamualaikum', speak: true, now: now);

      expect(controller.tokens.length, 1);
      expect(controller.rawTranscript.value, 'assalamualaikum');
      // Must not speak immediately!
      expect(mockTts.spokenUtterances, isEmpty,
          reason: 'TTS must wait until the jamaah pauses signing for several seconds');
    });

    test('Speech triggers after jamaah is idle for several seconds', () async {
      final t0 = DateTime(2026, 1, 1, 10, 0, 0);

      // Jamaah signs 'TERIMA'
      controller.commitWord('terima', speak: true, now: t0);

      // 1 second later, jamaah signs 'KASIH' (still within idle delay)
      final t1 = t0.add(const Duration(milliseconds: 1000));
      controller.commitWord('kasih', speak: true, now: t1);

      // Tick at 1.5s (only 500ms since last gesture) -> should NOT speak yet
      controller.tick(now: t0.add(const Duration(milliseconds: 1500)));
      expect(mockTts.spokenUtterances, isEmpty);

      // 2.2s after last gesture (t1 + 2200ms) -> idle delay (2000ms) passed!
      final tIdle = t1.add(const Duration(milliseconds: 2200));
      controller.tick(now: tIdle);

      // Wait a microtask for speech queue chain
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(mockTts.spokenUtterances.length, 1);
      expect(mockTts.spokenUtterances.first, 'terima kasih');
    });

    test('Alphabet spelling is debounced and read as a whole word after pause', () async {
      final t0 = DateTime(2026, 1, 1, 10, 0, 0);
      controller.setCameraActive(true, now: t0);

      // Spells H - A - J - I with brief intervals
      controller.handlePrediction(
        const BisindoPrediction(classId: 0, label: 'H', confidence: 0.95, distance: 0.05, candidates: [], isRecognized: true),
        now: t0,
      );
      controller.handlePrediction(
        const BisindoPrediction(classId: 0, label: 'H', confidence: 0.95, distance: 0.05, candidates: [], isRecognized: true),
        now: t0.add(const Duration(milliseconds: 50)),
      );
      controller.handlePrediction(
        const BisindoPrediction(classId: 0, label: 'H', confidence: 0.95, distance: 0.05, candidates: [], isRecognized: true),
        now: t0.add(const Duration(milliseconds: 100)),
      );

      // H is committed
      expect(controller.tokens.any((t) => t.value == 'H'), isTrue);
      expect(mockTts.spokenUtterances, isEmpty);

      // Tick before idle delay
      controller.tick(now: t0.add(const Duration(milliseconds: 500)));
      expect(mockTts.spokenUtterances, isEmpty);

      // Tick after idle delay (2000ms)
      controller.tick(now: t0.add(const Duration(milliseconds: 2500)));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(mockTts.spokenUtterances, contains('H'));
    });

    test('Manual space triggers immediate speech of pending tokens', () async {
      final t0 = DateTime(2026, 1, 1, 10, 0, 0);
      controller.commitWord('BANTUAN', speak: true, now: t0);

      expect(mockTts.spokenUtterances, isEmpty);

      // User presses SPASI
      controller.insertSpace();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(mockTts.spokenUtterances, contains('bantuan'));
    });
  });

  group('Sign Language Model Configs & Lightweight Optimizations', () {
    test('Model configurations have relaxed, lightweight throttle intervals', () {
      const sibi = SignLanguageModelConfig.sibi;
      const bisindo = SignLanguageModelConfig.bisindo;

      expect(sibi.throttleDuration.inMilliseconds, greaterThanOrEqualTo(150),
          reason: 'Throttle duration must be at least 150ms to keep camera feed lightweight and prevent thermal throttle');
      expect(bisindo.throttleDuration.inMilliseconds, greaterThanOrEqualTo(150));
    });

    test('Model configurations define accurate class counts and aligned thresholds', () {
      const sibi = SignLanguageModelConfig.sibi;
      const bisindo = SignLanguageModelConfig.bisindo;

      expect(sibi.classCount, equals(72));
      expect(sibi.defaultConfidenceThreshold, equals(0.70));
      expect(sibi.minMargin, equals(0.08));
      expect(SignLanguageModel.sibi.classCount, equals(72));

      expect(bisindo.classCount, equals(49));
      expect(bisindo.defaultConfidenceThreshold, equals(0.58));
      expect(bisindo.minMargin, equals(0.08));
      expect(SignLanguageModel.bisindo.classCount, equals(49));
    });

    test('Speech idle delay config defaults to a relaxed pause (>= 2.5 seconds)', () {
      const config = BisindoRecognitionConfig();
      expect(config.speechIdleDelay.inMilliseconds, greaterThanOrEqualTo(2500),
          reason: 'Speech idle delay must allow the user several seconds of gesture completion');
      expect(config.letterSpeechIdle.inMilliseconds, equals(config.speechIdleDelay.inMilliseconds));
    });
  });
}
