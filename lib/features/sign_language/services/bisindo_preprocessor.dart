import 'dart:math' as math;
import 'dart:typed_data';

/// Replicates the Python OpenHands preprocessing pipeline for BISINDO:
/// 1. 543 MediaPipe Holistic landmarks -> 75 combined keypoints (33 body + 21 left hand + 21 right hand)
/// 2. Extract X and Y channels: [2, T, 75]
/// 3. PoseSelect("mediapipe_holistic_minimal_27") -> [2, T, 27]
/// 4. CenterAndScaleNormalize("shoulder_mediapipe_holistic_minimal_27") -> centered & scaled by shoulder distance
/// 5. Temporal adjustment to exactly 100 frames (truncation or zero-padding)
/// 6. Output row-major Float32List of shape [1, 2, 100, 27] (5,400 elements)
class BisindoPreprocessor {
  static const int kNumHolisticLandmarks = 543;
  static const int kNumSelectedKeypoints = 27;
  static const int kTargetFrames = 100;
  static const int kNumChannels = 2; // X, Y

  /// Exact 27 indices selected from the 75 combined keypoints (OpenHands preset: mediapipe_holistic_minimal_27)
  static const List<int> kMinimal27Indices = [
    0,
    2,
    5,
    11,
    12,
    13,
    14, // Body: nose, l_eye, r_eye, l_sh, r_sh, l_elb, r_elb
    33, 37, 38, 41, 42, 45, 46, 49, 50, 53, // Left hand (10 keypoints)
    54, 58, 59, 62, 63, 66, 67, 70, 71, 74, // Right hand (10 keypoints)
  ];

  /// Shoulder reference point indices within the 27 selected keypoints:
  /// Index 3 corresponds to keypoint 11 (left shoulder)
  /// Index 4 corresponds to keypoint 12 (right shoulder)
  static const int kLeftShoulderIdx = 3;
  static const int kRightShoulderIdx = 4;

  /// Transforms raw [T, 543, 3] (or [T, 543, >=2]) landmark sequence into
  /// a contiguous Float32List with shape [1, 2, 100, 27].
  static Float32List processRawLandmarks(List<List<List<double>>> landmarks) {
    final int rawT = landmarks.length;
    if (rawT == 0) {
      // Empty input: return all zeros
      return Float32List(
        1 * kNumChannels * kTargetFrames * kNumSelectedKeypoints,
      );
    }

    // Step 1 - 3: Extract 27 keypoints [T, 27, 2]
    final List<List<List<double>>> filtered = List.generate(rawT, (t) {
      final frame = landmarks[t];
      return List.generate(kNumSelectedKeypoints, (i) {
        final target75Idx = kMinimal27Indices[i];
        final holisticIdx = _map75ToHolisticIndex(target75Idx);

        if (holisticIdx < frame.length) {
          final pt = frame[holisticIdx];
          final x = pt.isNotEmpty ? pt[0] : 0.0;
          final y = pt.length > 1 ? pt[1] : 0.0;
          return [x, y];
        }
        return [0.0, 0.0];
      });
    });

    // Step 4: CenterAndScaleNormalize (clip-level, matching OpenHands frame_level=False)
    // Calculate mean center and mean shoulder distance across all rawT frames
    double sumMidX = 0.0;
    double sumMidY = 0.0;
    double sumDist = 0.0;

    for (int t = 0; t < rawT; t++) {
      final p1 = filtered[t][kLeftShoulderIdx];
      final p2 = filtered[t][kRightShoulderIdx];

      final midX = (p1[0] + p2[0]) / 2.0;
      final midY = (p1[1] + p2[1]) / 2.0;
      sumMidX += midX;
      sumMidY += midY;

      final dx = p1[0] - p2[0];
      final dy = p1[1] - p2[1];
      sumDist += math.sqrt(dx * dx + dy * dy);
    }

    final double centerX = sumMidX / rawT;
    final double centerY = sumMidY / rawT;
    final double meanDist = sumDist / rawT;

    final double scale =
        (meanDist > 1e-6 && !meanDist.isNaN && !meanDist.isInfinite)
        ? (1.0 / meanDist)
        : 1.0;
    final bool applyCentering =
        (meanDist > 1e-6 && !meanDist.isNaN && !meanDist.isInfinite);

    // Apply normalization
    for (int t = 0; t < rawT; t++) {
      for (int v = 0; v < kNumSelectedKeypoints; v++) {
        final pt = filtered[t][v];
        if (applyCentering) {
          pt[0] = (pt[0] - centerX) * scale;
          pt[1] = (pt[1] - centerY) * scale;
        } else {
          pt[0] = pt[0] * scale;
          pt[1] = pt[1] * scale;
        }
      }
    }

    // Step 5: Temporal adjustment to 100 frames and row-major layout [1, 2, 100, 27]
    // Total size: 1 * 2 * 100 * 27 = 5400 floats
    final Float32List tensorData = Float32List(
      1 * kNumChannels * kTargetFrames * kNumSelectedKeypoints,
    );

    // Number of frames to take from filtered (up to 100)
    final int effectiveFrames = math.min(rawT, kTargetFrames);

    // Channel 0: X coordinates
    // Channel 1: Y coordinates
    // Row-major offset: (c * 100 + t) * 27 + v
    for (int t = 0; t < effectiveFrames; t++) {
      for (int v = 0; v < kNumSelectedKeypoints; v++) {
        final x = filtered[t][v][0];
        final y = filtered[t][v][1];

        final int xIndex = (0 * kTargetFrames + t) * kNumSelectedKeypoints + v;
        final int yIndex = (1 * kTargetFrames + t) * kNumSelectedKeypoints + v;

        tensorData[xIndex] = x;
        tensorData[yIndex] = y;
      }
    }
    // Remaining frames (if rawT < 100) are automatically 0.0 because Float32List initializes to 0.

    return tensorData;
  }

  /// Maps a 0..74 index to the 0..542 MediaPipe Holistic index:
  /// - 0..32: Pose / Body (0..32)
  /// - 33..53: Left Hand (501..521) -> 501 + (index - 33)
  /// - 54..74: Right Hand (522..542) -> 522 + (index - 54)
  static int _map75ToHolisticIndex(int idx75) {
    if (idx75 < 33) {
      return idx75;
    } else if (idx75 < 54) {
      return 501 + (idx75 - 33);
    } else {
      return 522 + (idx75 - 54);
    }
  }

  /// Generates a synthetic landmark sequence for self-test and debugging purposes.
  /// Simulates a human figure with normal shoulder distance and arm movements.
  static List<List<List<double>>> generateSyntheticSequence({int frames = 60}) {
    return List.generate(frames, (t) {
      final double progress = t / frames;
      final double wave = math.sin(progress * math.pi * 2);

      return List.generate(kNumHolisticLandmarks, (i) {
        if (i == 0) {
          // Nose
          return [0.5, 0.2, 0.0];
        } else if (i == 2) {
          // Left eye
          return [0.48, 0.18, 0.0];
        } else if (i == 5) {
          // Right eye
          return [0.52, 0.18, 0.0];
        } else if (i == 11) {
          // Left shoulder
          return [0.40, 0.35, 0.0];
        } else if (i == 12) {
          // Right shoulder
          return [0.60, 0.35, 0.0];
        } else if (i == 13) {
          // Left elbow
          return [0.35, 0.50 + 0.05 * wave, 0.0];
        } else if (i == 14) {
          // Right elbow
          return [0.65, 0.50 - 0.05 * wave, 0.0];
        } else if (i >= 501 && i < 522) {
          // Left hand
          return [0.30 + 0.05 * wave, 0.65, 0.0];
        } else if (i >= 522 && i < 543) {
          // Right hand
          return [0.70 - 0.05 * wave, 0.65, 0.0];
        }
        return [0.0, 0.0, 0.0];
      });
    });
  }
}
