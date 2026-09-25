import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/models/sign_language_model.dart';
import 'package:hajicare/features/sign_language/services/bisindo_inference_service.dart';
import 'package:hajicare/features/sign_language/services/bisindo_preprocessor.dart';
import 'package:hajicare/features/sign_language/services/landmark_stream_buffer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SignLanguageModel & Configuration Tests', () {
    test('SIBI configuration uses correct assets and dimensions', () {
      final config = SignLanguageModelConfig.sibi;
      expect(config.model, equals(SignLanguageModel.sibi));
      expect(config.modelAsset, equals('assets/models/sibi/sibi.tflite'));
      expect(config.labelAsset, equals('assets/models/sibi/labels_sibi.txt'));
      expect(config.windowSize, equals(12));
      expect(config.minimumFrames, equals(1));
      expect(File(config.modelAsset).existsSync(), isTrue);
      expect(File(config.labelAsset).existsSync(), isTrue);
    });

    test('BISINDO configuration uses correct assets and dimensions', () {
      final config = SignLanguageModelConfig.bisindo;
      expect(config.model, equals(SignLanguageModel.bisindo));
      expect(
        config.modelAsset,
        equals('assets/models/bisindo/hajicare_bisindo_gru_float32.tflite'),
      );
      expect(config.labelAsset, equals('assets/models/bisindo/labels.json'));
      expect(
        config.configAsset,
        equals('assets/models/bisindo/model_config.json'),
      );
      expect(config.expectedInputFeatures, equals(135));
      expect(config.windowSize, equals(48));
      expect(config.minimumFrames, equals(24));
      expect(File(config.modelAsset).existsSync(), isTrue);
      expect(File(config.labelAsset).existsSync(), isTrue);
      expect(File(config.configAsset!).existsSync(), isTrue);
    });

    test('forModel returns corresponding model config', () {
      expect(
        SignLanguageModelConfig.forModel(SignLanguageModel.sibi).model,
        equals(SignLanguageModel.sibi),
      );
      expect(
        SignLanguageModelConfig.forModel(SignLanguageModel.bisindo).model,
        equals(SignLanguageModel.bisindo),
      );
    });
  });

  group('LandmarkStreamBuffer Pause & Dynamic Config Tests', () {
    test('Pausing buffer prevents frame addition and inference execution', () {
      final mockService = BisindoInferenceService();
      final buffer = LandmarkStreamBuffer(
        inferenceService: mockService,
        windowSize: 48,
        minimumFrames: 24,
      );

      expect(buffer.isPaused, isFalse);
      expect(buffer.bufferLength, equals(0));

      final dummyFrame = List.generate(543, (_) => [0.0, 0.0, 0.0]);

      buffer.addFrame(dummyFrame);
      expect(buffer.bufferLength, equals(1));

      // Pause buffer
      buffer.pause();
      expect(buffer.isPaused, isTrue);

      buffer.addFrame(dummyFrame);
      // Buffer length should not increase when paused
      expect(buffer.bufferLength, equals(1));

      // Clear & resume
      buffer.clear();
      expect(buffer.bufferLength, equals(0));
      buffer.resume();
      expect(buffer.isPaused, isFalse);

      buffer.addFrame(dummyFrame);
      expect(buffer.bufferLength, equals(1));
    });

    test('updateConfig dynamically alters window size and minimum frames', () {
      final mockService = BisindoInferenceService();
      final buffer = LandmarkStreamBuffer(
        inferenceService: mockService,
        windowSize: 48,
        minimumFrames: 24,
      );

      final dummyFrame = List.generate(543, (_) => [0.0, 0.0, 0.0]);
      for (int i = 0; i < 30; i++) {
        buffer.addFrame(dummyFrame);
      }
      expect(buffer.bufferLength, equals(30));

      // Switch config to SIBI (window: 12, minFrames: 1)
      buffer.updateConfig(windowSize: 12, minimumFrames: 1);
      expect(buffer.windowSize, equals(12));
      expect(buffer.minimumFrames, equals(1));
      expect(buffer.effectiveMinFrames, equals(1));
      // Truncated to new windowSize
      expect(buffer.bufferLength, equals(12));

      // Switch back to BISINDO (window: 48, minFrames: 24)
      buffer.updateConfig(windowSize: 48, minimumFrames: 24);
      expect(buffer.windowSize, equals(48));
      expect(buffer.minimumFrames, equals(24));
      expect(buffer.effectiveMinFrames, equals(24));
    });
  });

  group('SIBI Landmark Preprocessor Tests', () {
    test('processSibiAlphabetFrame produces exact 42 floats', () {
      // Empty/small frame returns 42 zeros
      final emptyResult = BisindoPreprocessor.processSibiAlphabetFrame([]);
      expect(emptyResult.length, equals(42));
      expect(emptyResult.every((v) => v == 0.0), isTrue);

      // Frame with 543 zero landmarks returns 42 zeros
      final zeroFrame = List.generate(543, (_) => [0.0, 0.0, 0.0]);
      final zeroResult = BisindoPreprocessor.processSibiAlphabetFrame(
        zeroFrame,
      );
      expect(zeroResult.length, equals(42));
      expect(zeroResult.every((v) => v == 0.0), isTrue);

      // Frame with simulated right hand (indices 522..542)
      final activeFrame = List.generate(543, (_) => [0.0, 0.0, 0.0]);
      final wristX = 0.5;
      final wristY = 0.6;
      activeFrame[522] = [wristX, wristY, 0.0];
      for (int i = 523; i <= 542; i++) {
        activeFrame[i] = [
          wristX + (i - 522) * 0.01,
          wristY + (i - 522) * 0.01,
          0.0,
        ];
      }

      final activeResult = BisindoPreprocessor.processSibiAlphabetFrame(
        activeFrame,
      );
      expect(activeResult.length, equals(42));
      // Wrist relative coordinates: wrist itself must be 0.0, 0.0
      expect(activeResult[0], closeTo(0.0, 1e-5));
      expect(activeResult[1], closeTo(0.0, 1e-5));
      // Subsequent finger landmarks must be relative to wrist
      expect(activeResult[2], closeTo(0.01, 1e-5));
      expect(activeResult[3], closeTo(0.01, 1e-5));
    });
  });

  group('Race Condition Simulation & Generation Token Tests', () {
    test('Generation token ensures only the latest request wins', () async {
      int activeGeneration = 0;
      SignLanguageModel? resolvedModel;

      Future<void> simulateSwitch(
        SignLanguageModel target,
        Duration delay,
      ) async {
        final gen = ++activeGeneration;
        await Future.delayed(delay);
        if (gen != activeGeneration) {
          // Stale request discarded
          return;
        }
        resolvedModel = target;
      }

      // Simulate rapid switching: SIBI -> BISINDO (takes 100ms) -> SIBI (takes 20ms)
      simulateSwitch(
        SignLanguageModel.bisindo,
        const Duration(milliseconds: 100),
      );
      simulateSwitch(SignLanguageModel.sibi, const Duration(milliseconds: 20));

      await Future.delayed(const Duration(milliseconds: 150));

      // SIBI was the final requested model, even though BISINDO finished later,
      // BISINDO's result was safely discarded.
      expect(resolvedModel, equals(SignLanguageModel.sibi));
    });
  });
}
