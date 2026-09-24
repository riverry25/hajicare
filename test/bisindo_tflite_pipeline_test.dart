import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:hajicare/features/sign_language/models/bisindo_prediction.dart';
import 'package:hajicare/features/sign_language/services/bisindo_preprocessor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Final Deploy-Ready BISINDO GRU Model Asset Integrity', () {
    test('hajicare_bisindo_gru_float32.tflite exists and is non-empty', () {
      final file = File(
        'assets/models/bisindo/hajicare_bisindo_gru_float32.tflite',
      );
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(100000));
      expect(file.lengthSync(), equals(336776));
    });

    test('labels.json contains exactly 23 classes in correct order', () {
      final file = File('assets/models/bisindo/labels.json');
      expect(file.existsSync(), isTrue);
      final jsonMap =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      final labelsList = jsonMap['labels'] as List;
      expect(labelsList.length, equals(23));

      final firstLabel = labelsList[0] as Map<String, dynamic>;
      expect(firstLabel['id'], equals(0));
      expect(firstLabel['name'], equals('Air'));

      final thirdLabel = labelsList[2] as Map<String, dynamic>;
      expect(thirdLabel['id'], equals(2));
      expect(thirdLabel['name'], equals('Apa Kabar'));

      final lastLabel = labelsList[22] as Map<String, dynamic>;
      expect(lastLabel['id'], equals(22));
      expect(lastLabel['name'], equals('Tuli'));
    });

    test('model_config.json specifies 48 sequence len and 135 feature dim', () {
      final file = File('assets/models/bisindo/model_config.json');
      expect(file.existsSync(), isTrue);
      final jsonMap =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(jsonMap['sequence_length'], equals(48));
      expect(jsonMap['feature_dim'], equals(135));
      expect(jsonMap['num_classes'], equals(23));
      expect(jsonMap['confidence_threshold'], equals(0.78));
      expect(jsonMap['swap_handedness'], isFalse);
    });

    test('hand_landmarker.task exists and is valid size', () {
      final file = File('assets/models/bisindo/hand_landmarker.task');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(5 * 1024 * 1024));
    });
  });

  group('BISINDO 135-D Feature Vector Parity', () {
    test('extract135Features produces exact 135 float values', () {
      final leftHand = List.generate(
        21,
        (i) => [0.3 + i * 0.01, 0.4 + i * 0.01, 0.0],
      );
      final rightHand = List.generate(
        21,
        (i) => [0.7 + i * 0.01, 0.5 + i * 0.01, 0.0],
      );

      final Float32List features = BisindoPreprocessor.extract135Features(
        leftHand: leftHand,
        rightHand: rightHand,
      );

      expect(features.length, equals(135));
      expect(features[126], equals(1.0)); // Left presence
      expect(features[127], equals(1.0)); // Right presence

      // Left wrist raw centered (leftHand[0].x - 0.5)
      expect(features[128], closeTo(0.3 - 0.5, 1e-5));
      expect(features[129], closeTo(0.4 - 0.5, 1e-5));

      // Right wrist raw centered (rightHand[0].x - 0.5)
      expect(features[130], closeTo(0.7 - 0.5, 1e-5));
      expect(features[131], closeTo(0.5 - 0.5, 1e-5));

      // Inter-hand wrist (rightWrist - leftWrist)
      expect(features[132], closeTo(0.7 - 0.3, 1e-5));
      expect(features[133], closeTo(0.5 - 0.4, 1e-5));
      expect(features[134], closeTo(0.0, 1e-5));

      // Check clamping [-5.0, 5.0]
      for (int i = 0; i < 135; i++) {
        expect(features[i], inInclusiveRange(-5.0, 5.0));
      }
    });

    test('Single hand presence leaves other slot zeroed', () {
      final rightHand = List.generate(21, (i) => [0.6, 0.6, 0.0]);
      final features = BisindoPreprocessor.extract135Features(
        leftHand: null,
        rightHand: rightHand,
      );

      expect(features.length, equals(135));
      expect(features[126], equals(0.0)); // Left presence
      expect(features[127], equals(1.0)); // Right presence

      // Left slot 0..62 must be strictly 0.0
      for (int i = 0; i < 63; i++) {
        expect(features[i], equals(0.0));
      }

      // Inter-hand must be 0.0 if one hand missing
      expect(features[132], equals(0.0));
      expect(features[133], equals(0.0));
      expect(features[134], equals(0.0));
    });

    test('processRaw543Frame produces exact 135 features', () {
      final synthetic = BisindoPreprocessor.generateSyntheticSequence(
        frames: 1,
      );
      final features = BisindoPreprocessor.processRaw543Frame(synthetic.first);
      expect(features.length, equals(135));
      expect(features.every((v) => !v.isNaN && !v.isInfinite), isTrue);
    });
  });

  group('BISINDO Controller & 4-Step Stability Gate Logic', () {
    late BisindoRecognitionController controller;
    late DateTime origin;

    setUp(() {
      controller = BisindoRecognitionController(
        config: const BisindoRecognitionConfig(
          confidenceThreshold: 0.78,
          stablePredictionsRequired: 4,
          duplicateCooldown: Duration(milliseconds: 1200),
          handPresenceTimeout: Duration(milliseconds: 1000),
        ),
        autoTick: false,
      );
      controller.onInit();
      origin = DateTime(2026, 9, 24, 10, 0, 0);
      controller.setCameraActive(true, now: origin);
    });

    tearDown(() {
      controller.onClose();
    });

    test('Rejects prediction with confidence below threshold (0.78)', () {
      const lowConfPred = BisindoPrediction(
        classId: 19,
        label: 'Minum',
        confidence: 0.65, // Below 0.78
        distance: 0.35,
        candidates: [],
        isRecognized: true,
      );

      controller.handlePrediction(lowConfPred, now: origin);
      expect(controller.stabilityStreak.value, equals(0));
      expect(controller.tokens, isEmpty);
      expect(controller.currentCandidate.value, isNull);
    });

    test('Requires 4 consecutive stable predictions to commit label', () {
      const pred = BisindoPrediction(
        classId: 19,
        label: 'Minum',
        confidence: 0.95,
        distance: 0.05,
        candidates: [],
        isRecognized: true,
      );

      // Frame 1
      controller.handlePrediction(pred, now: origin);
      expect(controller.stabilityStreak.value, equals(1));
      expect(controller.tokens, isEmpty);

      // Frame 2
      controller.handlePrediction(
        pred,
        now: origin.add(const Duration(milliseconds: 100)),
      );
      expect(controller.stabilityStreak.value, equals(2));
      expect(controller.tokens, isEmpty);

      // Frame 3
      controller.handlePrediction(
        pred,
        now: origin.add(const Duration(milliseconds: 200)),
      );
      expect(controller.stabilityStreak.value, equals(3));
      expect(controller.tokens, isEmpty);

      // Frame 4 -> Commit!
      controller.handlePrediction(
        pred,
        now: origin.add(const Duration(milliseconds: 300)),
      );
      expect(controller.tokens.length, equals(1));
      expect(controller.tokens.first.value, equals('minum'));
      expect(controller.rawTranscript.value, equals('minum'));
    });

    test('Reset stability streak if label changes before reaching 4', () {
      const predMinum = BisindoPrediction(
        classId: 19,
        label: 'Minum',
        confidence: 0.90,
        distance: 0.10,
        candidates: [],
        isRecognized: true,
      );

      const predAir = BisindoPrediction(
        classId: 0,
        label: 'Air',
        confidence: 0.90,
        distance: 0.10,
        candidates: [],
        isRecognized: true,
      );

      controller.handlePrediction(predMinum, now: origin);
      controller.handlePrediction(
        predMinum,
        now: origin.add(const Duration(milliseconds: 100)),
      );
      expect(controller.stabilityStreak.value, equals(2));

      // Alternating label resets streak
      controller.handlePrediction(
        predAir,
        now: origin.add(const Duration(milliseconds: 200)),
      );
      expect(controller.stabilityStreak.value, equals(1));
      expect(controller.currentCandidate.value, equals('Air'));
      expect(controller.tokens, isEmpty);
    });

    test('Anti-duplicate cooldown prevents spamming same token', () {
      const pred = BisindoPrediction(
        classId: 19,
        label: 'Minum',
        confidence: 0.95,
        distance: 0.05,
        candidates: [],
        isRecognized: true,
      );

      // 4 frames -> first commit
      for (int i = 0; i < 4; i++) {
        controller.handlePrediction(
          pred,
          now: origin.add(Duration(milliseconds: i * 100)),
        );
      }
      expect(controller.tokens.length, equals(1));

      // Another 4 frames immediately within 1200ms cooldown
      for (int i = 4; i < 8; i++) {
        controller.handlePrediction(
          pred,
          now: origin.add(Duration(milliseconds: i * 100)),
        );
      }
      // Must NOT commit second "Minum"!
      expect(controller.tokens.length, equals(1));
      expect(controller.rawTranscript.value, equals('minum'));
    });

    test('Multi-word phrase like "Apa Kabar" is treated as single token', () {
      const pred = BisindoPrediction(
        classId: 2,
        label: 'Apa Kabar',
        confidence: 0.95,
        distance: 0.05,
        candidates: [],
        isRecognized: true,
      );

      for (int i = 0; i < 4; i++) {
        controller.handlePrediction(
          pred,
          now: origin.add(Duration(milliseconds: i * 100)),
        );
      }

      expect(controller.tokens.length, equals(1));
      expect(controller.tokens.first.value, equals('apa kabar'));
      expect(controller.rawTranscript.value, equals('apa kabar'));
    });

    test('DeleteLast, InsertSpace, and ResetTranscript work correctly', () {
      const pred = BisindoPrediction(
        classId: 17,
        label: 'Makan',
        confidence: 0.95,
        distance: 0.05,
        candidates: [],
        isRecognized: true,
      );

      for (int i = 0; i < 4; i++) {
        controller.handlePrediction(
          pred,
          now: origin.add(Duration(milliseconds: i * 100)),
        );
      }
      expect(controller.rawTranscript.value, equals('makan'));

      controller.insertSpace();
      controller.deleteLast();
      expect(controller.rawTranscript.value, equals('makan'));

      controller.deleteLast();
      expect(controller.rawTranscript.value, isEmpty);
      expect(controller.tokens, isEmpty);
    });
  });
}
