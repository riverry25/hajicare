import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/models/bisindo_prediction.dart';
import 'package:hajicare/features/sign_language/services/bisindo_inference_service.dart';
import 'package:hajicare/features/sign_language/services/landmark_stream_buffer.dart';

class _FakePredictor implements BisindoPredictor {
  int callCount = 0;

  @override
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  ) async {
    callCount++;
    const candidate = BisindoCandidate(
      classId: 0,
      label: 'Air',
      distance: 0.1,
      confidence: 0.9,
    );
    return const BisindoPrediction(
      classId: 0,
      label: 'Air',
      confidence: 0.9,
      distance: 0.1,
      candidates: [candidate],
      isRecognized: true,
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
        windowSize: 48,
        inferenceStride: 4,
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

    test('Sliding window caps at exactly 48 frames', () {
      for (int f = 0; f < 60; f++) {
        final frame = List.generate(543, (i) => [0.1, 0.2, 0.0]);
        buffer.addFrame(frame);
      }

      expect(buffer.bufferLength, equals(48));
    });

    test('Does not infer before buffer reaches 48 frames', () async {
      final frame = List.generate(543, (i) => [0.1, 0.2, 0.0]);
      for (int i = 0; i < 47; i++) {
        buffer.addFrame(frame);
      }
      await Future<void>.delayed(Duration.zero);
      expect(inferenceService.callCount, 0);

      // Frame 48: triggers inference!
      buffer.addFrame(frame);
      await Future<void>.delayed(Duration.zero);
      expect(inferenceService.callCount, 1);
    });

    test(
      'Inference triggers on stride of 4 frames after reaching 48 frames',
      () async {
        final frame = List.generate(543, (i) => [0.1, 0.2, 0.0]);
        for (int i = 0; i < 48; i++) {
          buffer.addFrame(frame);
        }
        await Future<void>.delayed(Duration.zero);
        expect(inferenceService.callCount, 1);

        // Add 3 frames (49, 50, 51) -> no new inference
        buffer.addFrame(frame);
        buffer.addFrame(frame);
        buffer.addFrame(frame);
        await Future<void>.delayed(Duration.zero);
        expect(inferenceService.callCount, 1);

        // Add 4th frame (stride = 4) -> triggers 2nd inference!
        buffer.addFrame(frame);
        await Future<void>.delayed(Duration.zero);
        expect(inferenceService.callCount, 2);
      },
    );

    test('Forwards prediction and buffer progress callbacks', () async {
      final results = <BisindoPrediction>[];
      int lastBufferLen = 0;

      buffer.dispose();
      buffer = LandmarkStreamBuffer(
        inferenceService: inferenceService,
        windowSize: 48,
        inferenceStride: 4,
        throttleDuration: Duration.zero,
        onPrediction: results.add,
        onBufferLengthChanged: (len) => lastBufferLen = len,
      );

      final frame = List.generate(543, (i) => [0.1, 0.2, 0.0]);
      for (int i = 0; i < 48; i++) {
        buffer.addFrame(frame);
      }
      await Future<void>.delayed(Duration.zero);

      expect(results.length, 1);
      expect(results.first.label, 'Air');
      expect(lastBufferLen, 48);
    });
  });
}
