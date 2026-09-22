import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/models/bisindo_mode.dart';
import 'package:hajicare/features/sign_language/models/bisindo_prediction.dart';
import 'package:hajicare/features/sign_language/services/bisindo_inference_service.dart';
import 'package:hajicare/features/sign_language/services/bisindo_preprocessor.dart';
import 'package:hajicare/features/sign_language/services/landmark_stream_buffer.dart';

class _FakePredictor implements BisindoPredictor {
  int callCount = 0;
  BisindoMatchQuality matchQuality = BisindoMatchQuality.possible;

  @override
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  ) async {
    callCount++;
    const candidate = BisindoCandidate(
      classId: 0,
      label: 'Air',
      distance: 1,
      confidence: 0.9,
    );
    return BisindoPrediction(
      classId: 0,
      label: 'Air',
      confidence: 0.9,
      distance: 1,
      candidates: const [candidate],
      matchQuality: matchQuality,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BisindoCameraLandmarkService & Stream Pipeline Tests', () {
    late LandmarkStreamBuffer buffer;
    late _FakePredictor inferenceService;

    setUp(() {
      inferenceService = _FakePredictor();
      buffer = LandmarkStreamBuffer(
        inferenceService: inferenceService,
        windowSize: 100,
        throttleDuration: Duration.zero,
      );
    });

    tearDown(() {
      buffer.dispose();
    });

    test('Validates exactly 543 landmarks structure', () {
      final validFrame = List.generate(
        543,
        (i) => [0.1 * (i % 10), 0.2 * (i % 5), 0.0],
      );
      expect(validFrame.length, equals(543));

      buffer.addFrame(validFrame);
      expect(buffer.bufferLength, equals(1));
    });

    test('Sliding window caps at exactly 100 frames', () {
      for (int f = 0; f < 120; f++) {
        final frame = List.generate(543, (i) => [0.1, 0.2, 0.0]);
        buffer.addFrame(frame);
      }

      expect(buffer.bufferLength, equals(100));
    });

    test(
      'End-to-End buffer frames pass through BisindoPreprocessor to [1, 2, 100, 27]',
      () {
        final syntheticFrames = BisindoPreprocessor.generateSyntheticSequence(
          frames: 45,
        );
        expect(syntheticFrames.length, equals(45));

        for (final frame in syntheticFrames) {
          buffer.addFrame(frame);
        }

        expect(buffer.bufferLength, equals(45));

        final tensor = BisindoPreprocessor.processRawLandmarks(syntheticFrames);
        expect(tensor.length, equals(5400));

        // Verify no NaNs or Infinities in processed output
        for (int i = 0; i < tensor.length; i++) {
          expect(tensor[i].isNaN, isFalse);
          expect(tensor[i].isInfinite, isFalse);
        }
      },
    );

    test('Does not infer before minimum frame count', () async {
      buffer.setMode(BisindoMode.word);
      final frame = List.generate(543, (i) => [0.1, 0.2, 0.0]);
      for (int i = 0; i < 29; i++) {
        buffer.addFrame(frame);
      }
      await Future<void>.delayed(Duration.zero);
      expect(inferenceService.callCount, 0);

      buffer.addFrame(frame);
      await Future<void>.delayed(Duration.zero);
      expect(inferenceService.callCount, 1);
    });

    test('Forwards every inference result to the recognition layer', () async {
      final results = <BisindoPrediction>[];
      buffer.dispose();
      buffer = LandmarkStreamBuffer(
        inferenceService: inferenceService,
        minimumFrames: 2,
        throttleDuration: Duration.zero,
        onPrediction: results.add,
      );
      final frame = List.generate(543, (i) => [0.1, 0.2, 0.0]);

      buffer.addFrame(frame);
      buffer.addFrame(frame);
      await Future<void>.delayed(Duration.zero);
      expect(results.single.isRecognized, isTrue);

      buffer.addFrame(frame);
      await Future<void>.delayed(Duration.zero);
      expect(results.last.isRecognized, isTrue);
      expect(buffer.bufferLength, 3);
    });

    test('Does not alter match quality from the inference service', () async {
      final results = <BisindoPrediction>[];
      inferenceService.matchQuality = BisindoMatchQuality.strong;
      buffer.dispose();
      buffer = LandmarkStreamBuffer(
        inferenceService: inferenceService,
        minimumFrames: 2,
        throttleDuration: Duration.zero,
        onPrediction: results.add,
      );
      final frame = List.generate(543, (i) => [0.1, 0.2, 0.0]);

      buffer.addFrame(frame);
      buffer.addFrame(frame);
      await Future<void>.delayed(Duration.zero);

      expect(results.single.isRecognized, isTrue);
      expect(results.single.matchQuality, BisindoMatchQuality.strong);
      expect(buffer.bufferLength, 2);
    });
  });
}
