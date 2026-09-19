import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/services/bisindo_inference_service.dart';
import 'package:hajicare/features/sign_language/services/bisindo_preprocessor.dart';
import 'package:hajicare/features/sign_language/services/landmark_stream_buffer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BisindoCameraLandmarkService & Stream Pipeline Tests', () {
    late LandmarkStreamBuffer buffer;
    late BisindoInferenceService inferenceService;

    setUp(() {
      inferenceService = BisindoInferenceService();
      buffer = LandmarkStreamBuffer(
        inferenceService: inferenceService,
        windowSize: 100,
        throttleDuration: const Duration(milliseconds: 100),
      );
    });

    tearDown(() {
      buffer.dispose();
    });

    test('Validates exactly 543 landmarks structure', () {
      final validFrame = List.generate(543, (i) => [0.1 * (i % 10), 0.2 * (i % 5), 0.0]);
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

    test('End-to-End buffer frames pass through BisindoPreprocessor to [1, 2, 100, 27]', () {
      final syntheticFrames = BisindoPreprocessor.generateSyntheticSequence(frames: 45);
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
    });
  });
}
