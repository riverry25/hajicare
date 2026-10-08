import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:hajicare/features/sign_language/models/landmark_frame.dart';
import 'package:hajicare/features/sign_language/models/sign_capture_quality.dart';
import 'package:hajicare/features/sign_language/services/bisindo_classifier_service.dart';
import 'package:hajicare/features/sign_language/services/bisindo_feature_extractor.dart';
import 'package:hajicare/features/sign_language/services/bisindo_sequence_buffer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BISINDO MotionGRU Pipeline & Specification Tests (A..J)', () {
    // A. labels count: 47
    test('A. labels count is exactly 47 and matches model_metadata.json', () {
      final labelsFile = File('assets/models/bisindo/labels.txt');
      expect(labelsFile.existsSync(), isTrue);

      final labels = labelsFile
          .readAsLinesSync()
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      expect(labels.length, equals(47));

      final metadataFile = File('assets/models/bisindo/model_metadata.json');
      expect(metadataFile.existsSync(), isTrue);

      final meta =
          json.decode(metadataFile.readAsStringSync()) as Map<String, dynamic>;
      expect(meta['num_classes'], equals(47));
      expect((meta['labels'] as List).length, equals(47));
      expect(meta['labels'], equals(labels));
    });

    // B. base feature: 353
    test('B. base feature vector dimension is exactly 353', () {
      final frame = LandmarkFrame(
        leftHand: List.generate(21, (i) => [0.1 * i, 0.2, 0.3]),
        rightHand: List.generate(21, (i) => [0.05 * i, 0.25, 0.35]),
        pose: List.generate(33, (i) => [0.4, 0.5, 0.0]),
        faceBlendshapes: {'eyeBlinkLeft': 0.85, 'jawOpen': 0.42},
      );

      final feature = BisindoFeatureExtractor.extractBaseFeature(frame);
      expect(feature.length, equals(353));
      expect(BisindoFeatureExtractor.kBaseFeatureDim, equals(353));
    });

    // C. temporal shape: 48 x 353
    test('C. temporal sequence resampling produces exactly [48, 353]', () {
      // 10 raw captured frames
      final rawSequence = List.generate(10, (i) {
        final feat = Float32List(353);
        feat[0] = i.toDouble();
        feat[352] = 1.0;
        return feat;
      });

      final resampled = BisindoSequenceBuffer.resampleBaseSequence(
        rawSequence,
        targetLength: 48,
      );

      expect(resampled.length, equals(48));
      for (final f in resampled) {
        expect(f.length, equals(353));
      }
      // Check monotonicity of interpolation:
      expect(resampled.first[0], closeTo(0.0, 1e-4));
      expect(resampled.last[0], closeTo(9.0, 1e-4));
    });

    // D. motion shape: 48 x 706
    test('D. motion delta concatenation produces exactly [48, 706]', () {
      final baseSeq = List.generate(48, (i) {
        final feat = Float32List(353);
        feat.fillRange(0, 353, (i + 1).toDouble());
        return feat;
      });

      final deltas = BisindoSequenceBuffer.computeMotionDelta(baseSeq);
      expect(deltas.length, equals(48));

      final combined = BisindoSequenceBuffer.concatenateBaseAndDelta(
        baseSequence: baseSeq,
        deltaSequence: deltas,
      );

      expect(combined.length, equals(48));
      for (final f in combined) {
        expect(f.length, equals(706));
      }
    });

    // E. tensor: 1 x 48 x 706
    test('E. prepareModelInput creates [1, 48, 706] tensor format', () {
      final buffer = BisindoSequenceBuffer();
      for (int i = 0; i < 20; i++) {
        final feat = Float32List(353);
        feat[0] = i * 0.1;
        buffer.addBaseFeature(feat);
      }

      final tensor = buffer.prepareModelInput();
      expect(tensor.length, equals(1)); // Batch dimension
      expect(tensor[0].length, equals(48)); // Sequence timesteps
      expect(tensor[0][0].length, equals(706)); // Features
    });

    // F. output: 1 x 47
    test('F. metadata and labels specify 47 output classes', () {
      expect(BisindoClassifierService.kExpectedNumClasses, equals(47));
      expect(BisindoClassifierService.kExpectedInputFeatureDim, equals(706));
      expect(BisindoClassifierService.kExpectedBaseFeatureDim, equals(353));
      expect(BisindoClassifierService.kExpectedSequenceLen, equals(48));
    });

    // G. first delta frame: all zero
    test('G. first delta frame delta[0] is all zero', () {
      final baseSeq = List.generate(10, (i) {
        final feat = Float32List(353);
        feat.fillRange(0, 353, 5.0);
        return feat;
      });

      final deltas = BisindoSequenceBuffer.computeMotionDelta(baseSeq);
      expect(deltas.first.length, equals(353));
      for (int d = 0; d < 353; d++) {
        expect(deltas[0][d], equals(0.0), reason: 'delta[0][$d] must be zero');
      }
    });

    // H. delta clipping: within [-4, +4]
    test('H. delta values are strictly clipped within [-4.0, +4.0]', () {
      final f0 = Float32List(353)..fillRange(0, 353, 0.0);
      final f1 = Float32List(353)
        ..[0] =
            100.0 // difference +100 -> should clip to +4.0
        ..[1] =
            -100.0 // difference -100 -> should clip to -4.0
        ..[2] = 2.5; // difference 2.5 -> stays 2.5

      final deltas = BisindoSequenceBuffer.computeMotionDelta([f0, f1]);
      expect(deltas[1][0], equals(4.0));
      expect(deltas[1][1], equals(-4.0));
      expect(deltas[1][2], equals(2.5));

      for (int d = 0; d < 353; d++) {
        expect(deltas[1][d], greaterThanOrEqualTo(-4.0));
        expect(deltas[1][d], lessThanOrEqualTo(4.0));
      }
    });

    // I. missing landmarks: zero values + correct presence masks
    test(
      'I. missing landmarks produce 0.0 features and 0.0 presence masks',
      () {
        // Frame with NO hands, NO pose, NO face
        const emptyFrame = LandmarkFrame();
        final feature = BisindoFeatureExtractor.extractBaseFeature(emptyFrame);

        expect(feature.length, equals(353));

        // 0..62 left hand global: all 0.0
        for (int i = 0; i <= 62; i++) {
          expect(feature[i], equals(0.0));
        }

        // 63..125 left hand local: all 0.0
        for (int i = 63; i <= 125; i++) {
          expect(feature[i], equals(0.0));
        }

        // 126..188 right hand global: all 0.0
        for (int i = 126; i <= 188; i++) {
          expect(feature[i], equals(0.0));
        }

        // 189..251 right hand local: all 0.0
        for (int i = 189; i <= 251; i++) {
          expect(feature[i], equals(0.0));
        }

        // 252..296 selected pose: all 0.0
        for (int i = 252; i <= 296; i++) {
          expect(feature[i], equals(0.0));
        }

        // 297..348 face blendshapes: all 0.0
        for (int i = 297; i <= 348; i++) {
          expect(feature[i], equals(0.0));
        }

        // 349..352 presence masks: all 0.0
        expect(feature[349], equals(0.0), reason: 'left hand mask');
        expect(feature[350], equals(0.0), reason: 'right hand mask');
        expect(feature[351], equals(0.0), reason: 'pose mask');
        expect(feature[352], equals(0.0), reason: 'face mask');
      },
    );

    // J. face blendshapes: mapped by NAME, not returned array order
    test('J. face blendshapes are mapped by exact category name', () {
      // Provide blendshapes in arbitrary/random map order
      final testMap = <String, double>{
        'mouthSmileLeft': 0.95,
        'browDownRight': 0.77,
        '_neutral': 0.12,
        'unrelated_blendshape': 0.99, // Should be ignored
      };

      final frame = LandmarkFrame(faceBlendshapes: testMap);
      final feature = BisindoFeatureExtractor.extractBaseFeature(frame);

      // _neutral is index 0 in blendshapes (feature[297])
      expect(feature[297], closeTo(0.12, 1e-5));

      // browDownRight is index 2 in blendshapes (feature[299])
      expect(feature[299], closeTo(0.77, 1e-5));

      // mouthSmileLeft is index 44 in blendshapes (feature[297 + 44 = 341])
      final smileIdx = BisindoFeatureExtractor.kFaceBlendshapeNames.indexOf(
        'mouthSmileLeft',
      );
      expect(feature[297 + smileIdx], closeTo(0.95, 1e-5));

      // Unset blendshapes should default to 0.0
      final jawOpenIdx = BisindoFeatureExtractor.kFaceBlendshapeNames.indexOf(
        'jawOpen',
      );
      expect(feature[297 + jawOpenIdx], equals(0.0));

      // Face presence mask (feature[352]) is 1.0
      expect(feature[352], equals(1.0));
    });

    test('Quality gating rejects low hand visibility', () {
      final frames = List.generate(
        10,
        (i) => LandmarkFrame(
          leftHand: i < 2 ? List.generate(21, (_) => [0.1, 0.2, 0.3]) : null,
          pose: List.generate(33, (_) => [0.4, 0.5, 0.0]),
        ),
      );

      final quality = SignCaptureQuality.fromFrames(frames);
      expect(quality.anyHandRatio, equals(0.2)); // 2/10 < 0.35
      final result = quality.validate();
      expect(result.isValid, isFalse);
      expect(result.userErrorMessage, contains('Tangan kurang terlihat'));
    });
  });
}
