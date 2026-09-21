import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/models/bisindo_prediction.dart';
import 'package:hajicare/features/sign_language/services/bisindo_preprocessor.dart';
import 'package:hajicare/features/sign_language/services/bisindo_inference_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BISINDO Preprocessor Tests', () {
    test(
      'Should produce exact Float32List shape [1, 2, 100, 27] (5400 floats)',
      () {
        final synthetic = BisindoPreprocessor.generateSyntheticSequence(
          frames: 60,
        );
        final tensor = BisindoPreprocessor.processRawLandmarks(synthetic);

        expect(tensor.length, equals(1 * 2 * 100 * 27));
        expect(tensor.length, equals(5400));
      },
    );

    test('Empty input sequence should return 5400 zero floats', () {
      final tensor = BisindoPreprocessor.processRawLandmarks([]);
      expect(tensor.length, equals(5400));
      expect(tensor.every((v) => v == 0.0), isTrue);
    });

    test('Zero-pads frames when input T < 100', () {
      const inputFrames = 40;
      final synthetic = BisindoPreprocessor.generateSyntheticSequence(
        frames: inputFrames,
      );
      final tensor = BisindoPreprocessor.processRawLandmarks(synthetic);

      // Frames 0..39 should have non-zero data
      bool hasActiveFrames = false;
      for (int t = 0; t < inputFrames; t++) {
        for (int v = 0; v < 27; v++) {
          final x = tensor[(0 * 100 + t) * 27 + v];
          if (x != 0.0) hasActiveFrames = true;
        }
      }
      expect(hasActiveFrames, isTrue);

      // Frames 40..99 must be strictly 0.0 (padded)
      for (int t = inputFrames; t < 100; t++) {
        for (int v = 0; v < 27; v++) {
          final x = tensor[(0 * 100 + t) * 27 + v];
          final y = tensor[(1 * 100 + t) * 27 + v];
          expect(x, equals(0.0), reason: 'Channel 0 frame $t should be 0.0');
          expect(y, equals(0.0), reason: 'Channel 1 frame $t should be 0.0');
        }
      }
    });

    test('Truncates frames when input T > 100', () {
      const inputFrames = 130;
      final synthetic = BisindoPreprocessor.generateSyntheticSequence(
        frames: inputFrames,
      );
      final tensor = BisindoPreprocessor.processRawLandmarks(synthetic);

      expect(tensor.length, equals(5400));
      // First 100 frames are filled
      for (int t = 0; t < 100; t++) {
        final xLeftShoulder =
            tensor[(0 * 100 + t) * 27 + BisindoPreprocessor.kLeftShoulderIdx];
        expect(xLeftShoulder.isNaN, isFalse);
        expect(xLeftShoulder.isInfinite, isFalse);
      }
    });

    test('Shoulder centering centers shoulder midpoint around 0,0', () {
      final synthetic = BisindoPreprocessor.generateSyntheticSequence(
        frames: 50,
      );
      final tensor = BisindoPreprocessor.processRawLandmarks(synthetic);

      // Compute mean shoulder position across frames
      double sumMidX = 0.0;
      double sumMidY = 0.0;
      for (int t = 0; t < 50; t++) {
        final x1 =
            tensor[(0 * 100 + t) * 27 + BisindoPreprocessor.kLeftShoulderIdx];
        final x2 =
            tensor[(0 * 100 + t) * 27 + BisindoPreprocessor.kRightShoulderIdx];
        final y1 =
            tensor[(1 * 100 + t) * 27 + BisindoPreprocessor.kLeftShoulderIdx];
        final y2 =
            tensor[(1 * 100 + t) * 27 + BisindoPreprocessor.kRightShoulderIdx];

        sumMidX += (x1 + x2) / 2.0;
        sumMidY += (y1 + y2) / 2.0;
      }

      final avgMidX = sumMidX / 50;
      final avgMidY = sumMidY / 50;

      // Because of normalization, average shoulder midpoint should be centered at (0, 0)
      expect(avgMidX, closeTo(0.0, 1e-4));
      expect(avgMidY, closeTo(0.0, 1e-4));
    });

    test(
      'Golden Validation: Preprocessing parity matches Python reference pipeline',
      () {
        // Deterministic synthetic input [T=50, 543, 3] with non-trivial values
        const int tFrames = 50;
        final List<List<List<double>>> input = List.generate(tFrames, (t) {
          return List.generate(543, (idx) {
            final x = 0.2 + 0.001 * idx + 0.005 * t;
            final y = 0.3 + 0.0008 * idx - 0.003 * t;
            final z = 0.01 * idx;
            return [x, y, z];
          });
        });

        // 1. Compute ground-truth Python reference manually step-by-step
        // The 27 indices in the 543 holistic format
        const holistic27 = [
          0, 2, 5, 11, 12, 13, 14, // Body 7
          501, 505, 506, 509, 510, 513, 514, 517, 518, 521, // Left hand 10
          522, 526, 527, 530, 531, 534, 535, 538, 539, 542, // Right hand 10
        ];

        // Extract 27 keypoints [T, 27, 2]
        final ref27 = List.generate(tFrames, (t) {
          return List.generate(27, (v) {
            final hIdx = holistic27[v];
            return [input[t][hIdx][0], input[t][hIdx][1]];
          });
        });

        // Compute clip-level center and scale (left shoulder=11->index 3, right shoulder=12->index 4)
        double sumMidX = 0.0;
        double sumMidY = 0.0;
        double sumDist = 0.0;

        for (int t = 0; t < tFrames; t++) {
          final p1 = ref27[t][3]; // left shoulder
          final p2 = ref27[t][4]; // right shoulder
          final midX = (p1[0] + p2[0]) / 2.0;
          final midY = (p1[1] + p2[1]) / 2.0;
          final dx = p1[0] - p2[0];
          final dy = p1[1] - p2[1];
          final dist = math.sqrt(dx * dx + dy * dy);

          sumMidX += midX;
          sumMidY += midY;
          sumDist += dist;
        }

        final refCenterX = sumMidX / tFrames;
        final refCenterY = sumMidY / tFrames;
        final refMeanDist = sumDist / tFrames;
        final refScale = 1.0 / refMeanDist;

        // Build expected [1, 2, 100, 27] Float32 tensor
        final expectedTensor = Float32List(1 * 2 * 100 * 27);
        for (int t = 0; t < tFrames; t++) {
          for (int v = 0; v < 27; v++) {
            final normX = (ref27[t][v][0] - refCenterX) * refScale;
            final normY = (ref27[t][v][1] - refCenterY) * refScale;

            final xIdx = (0 * 100 + t) * 27 + v;
            final yIdx = (1 * 100 + t) * 27 + v;

            expectedTensor[xIdx] = normX;
            expectedTensor[yIdx] = normY;
          }
        }

        // 2. Run actual Dart BisindoPreprocessor
        final actualTensor = BisindoPreprocessor.processRawLandmarks(input);

        // 3. Compare shape
        expect(actualTensor.length, equals(expectedTensor.length));
        expect(actualTensor.length, equals(5400));

        // 4. Compare statistics: min, max, mean, max absolute difference
        double refMin = expectedTensor[0];
        double refMax = expectedTensor[0];
        double refSum = 0.0;

        double actMin = actualTensor[0];
        double actMax = actualTensor[0];
        double actSum = 0.0;

        double maxAbsDiff = 0.0;

        for (int i = 0; i < 5400; i++) {
          final refVal = expectedTensor[i];
          final actVal = actualTensor[i];

          if (refVal < refMin) refMin = refVal;
          if (refVal > refMax) refMax = refVal;
          refSum += refVal;

          if (actVal < actMin) actMin = actVal;
          if (actVal > actMax) actMax = actVal;
          actSum += actVal;

          final diff = (actVal - refVal).abs();
          if (diff > maxAbsDiff) {
            maxAbsDiff = diff;
          }
        }

        final refMean = refSum / 5400;
        final actMean = actSum / 5400;

        // Verify numerical parity
        expect(
          maxAbsDiff,
          lessThan(1e-5),
          reason: 'Max absolute difference must be negligible',
        );
        expect(actMin, closeTo(refMin, 1e-5), reason: 'Min values must match');
        expect(actMax, closeTo(refMax, 1e-5), reason: 'Max values must match');
        expect(
          actMean,
          closeTo(refMean, 1e-5),
          reason: 'Mean values must match',
        );

        // Sample index checks
        expect(actualTensor[0], closeTo(expectedTensor[0], 1e-5));
        expect(actualTensor[26], closeTo(expectedTensor[26], 1e-5));
        expect(
          actualTensor[2700],
          closeTo(expectedTensor[2700], 1e-5),
        ); // Channel 1, frame 0, kp 0
        expect(actualTensor[5399], equals(0.0)); // Padded zone
      },
    );
  });

  group('BISINDO Prototype Assets & Math Tests', () {
    test('Prototypes JSON file contains 8 classes with 256-d embeddings', () {
      final file = File('assets/models/hajicare_prototypes.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'hajicare_prototypes.json must exist',
      );

      final jsonContent =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(jsonContent['embedding_dimension'], equals(256));

      final classesMap = jsonContent['classes'] as Map<String, dynamic>;
      expect(classesMap.length, equals(8));

      // Verify all 8 prototype keys
      for (int i = 0; i < BisindoPrediction.kPrototypeJsonKeys.length; i++) {
        final key = BisindoPrediction.kPrototypeJsonKeys[i];
        final expectedLabel = BisindoPrediction.kClassLabels[i];

        expect(
          classesMap.containsKey(key),
          isTrue,
          reason: 'Missing class key $key',
        );
        final classData = classesMap[key] as Map<String, dynamic>;
        expect(classData['name'], equals(expectedLabel));

        final proto = (classData['prototype'] as List<dynamic>).cast<num>();
        expect(proto.length, equals(256));

        // Ensure no NaNs or Infinities in prototype
        for (int d = 0; d < 256; d++) {
          final val = proto[d].toDouble();
          expect(val.isNaN, isFalse);
          expect(val.isInfinite, isFalse);
        }
      }
    });

    test('L2 distance and confidence candidate ranking works accurately', () {
      // Simulate 8 prototypes
      final List<List<double>> prototypes = List.generate(8, (i) {
        return List.generate(
          256,
          (d) => (i == 2 ? 1.0 : 0.0),
        ); // class 2 is ones
      });

      // Query embedding identical to class 2
      final query = List.generate(256, (d) => 1.0);

      final List<BisindoCandidate> candidates = [];
      final List<double> distances = [];

      for (int i = 0; i < 8; i++) {
        double sumSq = 0.0;
        for (int d = 0; d < 256; d++) {
          final diff = query[d] - prototypes[i][d];
          sumSq += diff * diff;
        }
        final dist = math.sqrt(sumSq);
        distances.add(dist);
      }

      expect(distances[2], equals(0.0)); // Distance to class 2 is 0

      // Softmax
      final minD = distances.reduce(math.min);
      double sumExp = 0.0;
      final expScores = <double>[];
      for (int i = 0; i < 8; i++) {
        final expVal = math.exp((minD - distances[i]) / 2.0);
        expScores.add(expVal);
        sumExp += expVal;
      }

      for (int i = 0; i < 8; i++) {
        candidates.add(
          BisindoCandidate(
            classId: i,
            label: BisindoPrediction.kClassLabels[i],
            distance: distances[i],
            confidence: expScores[i] / sumExp,
          ),
        );
      }

      candidates.sort((a, b) => a.distance.compareTo(b.distance));

      final prediction = BisindoPrediction(
        classId: candidates.first.classId,
        label: candidates.first.label,
        confidence: candidates.first.confidence,
        distance: candidates.first.distance,
        candidates: candidates,
      );

      expect(prediction.classId, equals(2));
      expect(prediction.label, equals('Terima kasih'));
      expect(prediction.distance, equals(0.0));
      expect(prediction.confidence, greaterThan(0.99));
    });

    test('Rejects distant or ambiguous prototype matches', () {
      expect(
        BisindoInferenceService.isReliableMatch(
          winnerDistance: 13.7,
          runnerUpDistance: 15.2,
          nearestPrototypeDistance: 4,
        ),
        isFalse,
      );
      expect(
        BisindoInferenceService.isReliableMatch(
          winnerDistance: 2,
          runnerUpDistance: 2.05,
          nearestPrototypeDistance: 8,
        ),
        isFalse,
      );
      expect(
        BisindoInferenceService.isReliableMatch(
          winnerDistance: 2,
          runnerUpDistance: 3,
          nearestPrototypeDistance: 8,
        ),
        isTrue,
      );
    });

    test('ONNX model asset exists and has valid size', () {
      final modelFile = File('assets/models/hajicare_encoder.onnx');
      expect(modelFile.existsSync(), isTrue);
      // Approximately 17-18 MB
      expect(modelFile.lengthSync(), greaterThan(15 * 1024 * 1024));
    });
  });
}
