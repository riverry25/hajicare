import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:hajicare/features/sign_language/models/bisindo_mode.dart';
import 'package:hajicare/features/sign_language/models/bisindo_prediction.dart';
import 'package:hajicare/features/sign_language/services/bisindo_preprocessor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BISINDO TFLite Models and Labels Asset Integrity', () {
    test('bisindo_wl_model.tflite exists and is non-empty', () {
      final file = File('assets/models/bisindo_wl_model.tflite');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(100000));
    });

    test('bisindo_alphabet_model_f32.tflite exists and is non-empty', () {
      final file = File('assets/models/bisindo_alphabet_model_f32.tflite');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(100000));
    });

    test(
      'bisindo_wl_labels.json contains 8 specific Indonesian word labels',
      () {
        final file = File('assets/models/bisindo_wl_labels.json');
        expect(file.existsSync(), isTrue);
        final jsonMap =
            json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        final labels = (jsonMap['labels'] as List).cast<String>();
        expect(labels.length, equals(8));
        expect(
          labels,
          containsAll([
            'air',
            'belajar',
            'hari',
            'maaf',
            'makan',
            'saya',
            'terima_kasih',
            'tuli',
          ]),
        );
        expect(jsonMap['feature_dim'], equals(100));
        expect(jsonMap['sequence_len'], equals(30));
        expect(jsonMap['temporal_total'], equals(300));
      },
    );

    test(
      'bisindo_alphabet_labels.json contains 27 labels with NOTHING at index 14',
      () {
        final file = File('assets/models/bisindo_alphabet_labels.json');
        expect(file.existsSync(), isTrue);
        final labels = (json.decode(file.readAsStringSync()) as List)
            .cast<String>();
        expect(labels.length, equals(27));
        expect(labels[14], equals('NOTHING'));
        expect(labels.first, equals('A'));
        expect(labels.last, equals('Z'));
      },
    );
  });

  group('BISINDO Preprocessor Exact Tensor Shapes', () {
    test(
      'processWordSequence outputs Float32List with shape [1, 30, 300] = 9000 elements',
      () {
        final synthetic = BisindoPreprocessor.generateSyntheticSequence(
          frames: 45,
        );
        final tensor = BisindoPreprocessor.processWordSequence(synthetic);
        expect(tensor.length, equals(1 * 30 * 300));
        expect(tensor.length, equals(9000));
        expect(tensor.every((v) => !v.isNaN && !v.isInfinite), isTrue);
      },
    );

    test('processWordSequence pads when frames < 30', () {
      final synthetic = BisindoPreprocessor.generateSyntheticSequence(
        frames: 10,
      );
      final tensor = BisindoPreprocessor.processWordSequence(synthetic);
      expect(tensor.length, equals(9000));
    });

    test('processAlphabetFrame outputs Float32List of length 86', () {
      final synthetic = BisindoPreprocessor.generateSyntheticSequence(
        frames: 1,
      );
      final tensor = BisindoPreprocessor.processAlphabetFrame(synthetic.first);
      expect(tensor.length, equals(86));
      expect(tensor.every((v) => !v.isNaN && !v.isInfinite), isTrue);
    });

    test(
      'processAlphabetFrame returns all zeros for empty or invalid frame',
      () {
        final tensor = BisindoPreprocessor.processAlphabetFrame([]);
        expect(tensor.length, equals(86));
        expect(tensor.every((v) => v == 0.0), isTrue);
      },
    );
  });

  group('BISINDO Controller & Stability Logic', () {
    late BisindoRecognitionController controller;
    late DateTime origin;

    setUp(() {
      controller = BisindoRecognitionController(autoTick: false);
      controller.onInit();
      origin = DateTime(2026, 9, 22, 10, 0, 0);
      controller.setCameraActive(true, now: origin);
    });

    tearDown(() {
      controller.onClose();
    });

    test('Default mode is UNIFIED and can switch modes', () {
      expect(controller.selectedMode.value, equals(BisindoMode.unified));
      controller.setMode(BisindoMode.word);
      expect(controller.selectedMode.value, equals(BisindoMode.word));
      controller.setMode(BisindoMode.alphabet);
      expect(controller.selectedMode.value, equals(BisindoMode.alphabet));
      expect(
        controller.recognitionState.value,
        equals(SignRecognitionState.idle),
      );
    });

    test('Commit word token appends to transcript correctly', () {
      const pred = BisindoPrediction(
        classId: 1,
        label: 'belajar',
        confidence: 0.95,
        distance: 0.05,
        candidates: [],
        isRecognized: true,
      );

      // Feed multiple stable predictions
      for (int i = 0; i < 5; i++) {
        controller.handlePrediction(
          pred,
          now: origin.add(Duration(milliseconds: i * 100)),
        );
      }

      // Check holding state
      expect(
        controller.recognitionState.value,
        equals(SignRecognitionState.holding),
      );
      expect(controller.currentCandidate.value, equals('belajar'));

      // Continuous prediction reaches confirmation duration (950ms)
      controller.handlePrediction(
        pred,
        now: origin.add(const Duration(milliseconds: 1400)),
      );

      // Check confirmed and committed
      expect(
        controller.recognitionState.value,
        equals(SignRecognitionState.confirmed),
      );
      expect(controller.rawTranscript.value, equals('belajar'));
      expect(controller.tokens.length, equals(1));
    });

    test(
      'Duplicate prevention prevents multiple consecutive commits of the same gesture',
      () {
        const pred = BisindoPrediction(
          classId: 1,
          label: 'belajar',
          confidence: 0.95,
          distance: 0.05,
          candidates: [],
          isRecognized: true,
        );

        // Stable feed and confirm
        for (int i = 0; i < 5; i++) {
          controller.handlePrediction(
            pred,
            now: origin.add(Duration(milliseconds: i * 100)),
          );
        }
        controller.handlePrediction(
          pred,
          now: origin.add(const Duration(milliseconds: 1400)),
        );
        expect(controller.tokens.length, equals(1));

        // User continues holding same gesture
        for (int i = 0; i < 5; i++) {
          controller.handlePrediction(
            pred,
            now: origin.add(Duration(milliseconds: 1200 + i * 100)),
          );
        }
        controller.handlePrediction(
          pred,
          now: origin.add(const Duration(milliseconds: 2000)),
        );

        // Must remain 1 token, not duplicate!
        expect(controller.tokens.length, equals(1));
        expect(controller.rawTranscript.value, equals('belajar'));
      },
    );

    test('Multi-word sequence commits distinct words with space', () {
      const pred1 = BisindoPrediction(
        classId: 5,
        label: 'saya',
        confidence: 0.95,
        distance: 0.05,
        candidates: [],
        isRecognized: true,
      );

      const pred2 = BisindoPrediction(
        classId: 4,
        label: 'makan',
        confidence: 0.95,
        distance: 0.05,
        candidates: [],
        isRecognized: true,
      );

      // Commit 'saya'
      for (int i = 0; i < 5; i++) {
        controller.handlePrediction(
          pred1,
          now: origin.add(Duration(milliseconds: i * 100)),
        );
      }
      controller.handlePrediction(
        pred1,
        now: origin.add(const Duration(milliseconds: 1400)),
      );
      expect(controller.rawTranscript.value, equals('saya'));

      // Release after 1400ms confirmation
      controller.handleNoHand(
        now: origin.add(const Duration(milliseconds: 1500)),
      );
      controller.handleNoHand(
        now: origin.add(const Duration(milliseconds: 1850)),
      );

      // Commit 'makan'
      for (int i = 0; i < 5; i++) {
        controller.handlePrediction(
          pred2,
          now: origin.add(Duration(milliseconds: 2000 + i * 100)),
        );
      }
      controller.handlePrediction(
        pred2,
        now: origin.add(const Duration(milliseconds: 3300)),
      );

      // Check combined transcript
      expect(controller.rawTranscript.value, equals('saya makan'));
      expect(controller.tokens.length, equals(2));
    });

    test('DeleteLast, InsertSpace, and ResetTranscript work correctly', () {
      const pred = BisindoPrediction(
        classId: 0,
        label: 'air',
        confidence: 0.95,
        distance: 0.05,
        candidates: [],
        isRecognized: true,
      );

      for (int i = 0; i < 5; i++) {
        controller.handlePrediction(
          pred,
          now: origin.add(Duration(milliseconds: i * 100)),
        );
      }
      controller.handlePrediction(
        pred,
        now: origin.add(const Duration(milliseconds: 1400)),
      );
      expect(controller.rawTranscript.value, equals('air'));

      controller.insertSpace();
      controller.deleteLast();
      expect(controller.rawTranscript.value, equals('air'));

      controller.deleteLast();
      expect(controller.rawTranscript.value, isEmpty);
      expect(controller.tokens, isEmpty);

      controller.resetTranscript();
      expect(controller.rawTranscript.value, isEmpty);
    });
  });
}
