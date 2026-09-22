import 'dart:math' as math;
import 'dart:typed_data';

/// Preprocessing pipeline for BISINDO models:
/// 1. Word Model (`bisindo_wl_model.tflite`):
///    - Shape: [1, 30, 300]
///    - 30 temporal frames.
///    - 100 position features per frame (50 keypoints: 8 upper-body pose + 21 left hand + 21 right hand).
///    - Normalization: nose-centered + per-sequence std.
///    - Temporal features: 100 positions + 100 velocities (dt) + 100 accelerations (d2t) = 300 features.
///
/// 2. Alphabet Model (`bisindo_alphabet_model_f32.tflite`):
///    - Shape: [1, 86]
///    - Single frame.
///    - 42 coordinates for Left Hand (21 points x 2 [x, y], wrist-centered).
///    - 42 coordinates for Right Hand (21 points x 2 [x, y], wrist-centered).
///    - 2 hand presence indicators [hasLeftHand, hasRightHand].
///    - Absence of hands produces 86 zeros, leading the model to predict "NOTHING" (index 14).
class BisindoPreprocessor {
  // Sequence and feature dimension constants for Word Model
  static const int kWordSequenceLen = 30;
  static const int kWordKeypointsCount =
      50; // 8 pose + 21 left hand + 21 right hand
  static const int kWordFeatureDim = 100; // 50 keypoints * 2 (x, y)
  static const int kWordTemporalDim = 300; // 100 pos + 100 vel + 100 acc

  // Alphabet Model constant
  static const int kAlphabetFeatureDim = 86; // 42 left + 42 right + 2 presence

  // Backwards-compatible constants for synthetic generation & test suite
  static const int kNumHolisticLandmarks = 543;
  static const int kNumSelectedKeypoints = 27;
  static const int kTargetFrames = 100;
  static const int kNumChannels = 2; // X, Y
  static const int kLeftShoulderIdx = 3;
  static const int kRightShoulderIdx = 4;

  static const List<int> kMinimal27Indices = [
    0,
    2,
    5,
    11,
    12,
    13,
    14, // Body: nose, l_eye, r_eye, l_sh, r_sh, l_elb, r_elb
    33, 37, 38, 41, 42, 45, 46, 49, 50, 53, // Left hand
    54, 58, 59, 62, 63, 66, 67, 70, 71, 74, // Right hand
  ];

  /// 8 Upper-body Pose landmark indices from MediaPipe Holistic (0..32):
  /// 0: Nose (centering reference)
  /// 2: Left Eye
  /// 5: Right Eye
  /// 11: Left Shoulder
  /// 12: Right Shoulder
  /// 13: Left Elbow
  /// 14: Right Elbow
  /// 15: Left Wrist
  static const List<int> kUpperBodyPoseIndices = [0, 2, 5, 11, 12, 13, 14, 15];

  /// Left Hand landmarks in MediaPipe Holistic: 501..521 (21 points)
  static const int kLeftHandStartIdx = 501;
  static const int kLeftHandEndIdx = 521;

  /// Right Hand landmarks in MediaPipe Holistic: 522..542 (21 points)
  static const int kRightHandStartIdx = 522;
  static const int kRightHandEndIdx = 542;

  /// Checks whether a hand landmark set is valid and not all zeros.
  static bool isHandDetected(
    List<List<double>> frame,
    int startIdx,
    int endIdx,
  ) {
    if (frame.length <= endIdx) return false;
    double sumAbs = 0.0;
    for (int i = startIdx; i <= endIdx; i++) {
      final pt = frame[i];
      if (pt.isNotEmpty) {
        sumAbs += pt[0].abs() + (pt.length > 1 ? pt[1].abs() : 0.0);
      }
    }
    return sumAbs > 0.01;
  }

  /// Transforms a sequence of frames [T, 543, 3] into a `Float32List` of shape `[1, 30, 300]`.
  static Float32List processWordSequence(List<List<List<double>>> rawFrames) {
    final int rawT = rawFrames.length;
    if (rawT == 0) {
      return Float32List(1 * kWordSequenceLen * kWordTemporalDim);
    }

    // 1. Resample / window to exactly 30 frames
    final List<List<List<double>>> frames = [];
    if (rawT >= kWordSequenceLen) {
      // Take the most recent 30 frames
      frames.addAll(rawFrames.sublist(rawT - kWordSequenceLen));
    } else {
      // Pad with repetition of the first frame
      final padCount = kWordSequenceLen - rawT;
      for (int i = 0; i < padCount; i++) {
        frames.add(rawFrames.first);
      }
      frames.addAll(rawFrames);
    }

    // 2. Extract 50 keypoints [30, 50, 2]
    // Order: 8 upper body pose, 21 left hand, 21 right hand
    final List<List<double>> positions = List.generate(kWordSequenceLen, (t) {
      final frame = frames[t];
      final List<double> framePositions = [];

      // Nose point for nose-centering (pose index 0)
      double noseX = 0.0;
      double noseY = 0.0;
      if (frame.isNotEmpty && frame[0].length >= 2) {
        noseX = frame[0][0];
        noseY = frame[0][1];
      }

      // Add 8 pose points (nose-centered)
      for (final poseIdx in kUpperBodyPoseIndices) {
        if (poseIdx < frame.length && frame[poseIdx].length >= 2) {
          framePositions.add(frame[poseIdx][0] - noseX);
          framePositions.add(frame[poseIdx][1] - noseY);
        } else {
          framePositions.add(0.0);
          framePositions.add(0.0);
        }
      }

      // Add 21 left hand points (nose-centered)
      for (int i = kLeftHandStartIdx; i <= kLeftHandEndIdx; i++) {
        if (i < frame.length && frame[i].length >= 2) {
          framePositions.add(frame[i][0] - noseX);
          framePositions.add(frame[i][1] - noseY);
        } else {
          framePositions.add(0.0);
          framePositions.add(0.0);
        }
      }

      // Add 21 right hand points (nose-centered)
      for (int i = kRightHandStartIdx; i <= kRightHandEndIdx; i++) {
        if (i < frame.length && frame[i].length >= 2) {
          framePositions.add(frame[i][0] - noseX);
          framePositions.add(frame[i][1] - noseY);
        } else {
          framePositions.add(0.0);
          framePositions.add(0.0);
        }
      }

      return framePositions; // length 100
    });

    // 3. Per-sequence standard deviation normalization
    double sum = 0.0;
    int totalCount = kWordSequenceLen * kWordFeatureDim;
    for (int t = 0; t < kWordSequenceLen; t++) {
      for (int f = 0; f < kWordFeatureDim; f++) {
        sum += positions[t][f];
      }
    }
    final double mean = sum / totalCount;

    double sumSq = 0.0;
    for (int t = 0; t < kWordSequenceLen; t++) {
      for (int f = 0; f < kWordFeatureDim; f++) {
        final diff = positions[t][f] - mean;
        sumSq += diff * diff;
      }
    }
    final double std = math.sqrt(sumSq / totalCount);
    final double scale = (std > 1e-6 && !std.isNaN && !std.isInfinite)
        ? (1.0 / std)
        : 1.0;

    // Apply scaling
    for (int t = 0; t < kWordSequenceLen; t++) {
      for (int f = 0; f < kWordFeatureDim; f++) {
        positions[t][f] = positions[t][f] * scale;
      }
    }

    // 4. Calculate Velocity (V) and Acceleration (A)
    final List<List<double>> velocities = List.generate(kWordSequenceLen, (t) {
      if (t == 0) {
        return List<double>.filled(kWordFeatureDim, 0.0);
      }
      return List.generate(kWordFeatureDim, (f) {
        return positions[t][f] - positions[t - 1][f];
      });
    });

    final List<List<double>> accelerations = List.generate(kWordSequenceLen, (
      t,
    ) {
      if (t <= 1) {
        return List<double>.filled(kWordFeatureDim, 0.0);
      }
      return List.generate(kWordFeatureDim, (f) {
        return velocities[t][f] - velocities[t - 1][f];
      });
    });

    // 5. Flatten into [1, 30, 300] Float32List
    final result = Float32List(1 * kWordSequenceLen * kWordTemporalDim);
    int offset = 0;
    for (int t = 0; t < kWordSequenceLen; t++) {
      // 100 positions
      for (int f = 0; f < kWordFeatureDim; f++) {
        result[offset++] = positions[t][f];
      }
      // 100 velocities
      for (int f = 0; f < kWordFeatureDim; f++) {
        result[offset++] = velocities[t][f];
      }
      // 100 accelerations
      for (int f = 0; f < kWordFeatureDim; f++) {
        result[offset++] = accelerations[t][f];
      }
    }

    return result;
  }

  /// Transforms a single frame of 543 landmarks into a `Float32List` of shape `[1, 86]`.
  static Float32List processAlphabetFrame(List<List<double>> frame) {
    final result = Float32List(kAlphabetFeatureDim);
    if (frame.length < 543) {
      return result; // all zeros -> model outputs NOTHING
    }

    final bool hasLeft = isHandDetected(
      frame,
      kLeftHandStartIdx,
      kLeftHandEndIdx,
    );
    final bool hasRight = isHandDetected(
      frame,
      kRightHandStartIdx,
      kRightHandEndIdx,
    );

    if (!hasLeft && !hasRight) {
      return result; // all zeros
    }

    int offset = 0;

    // 1. Left Hand (21 points x 2 = 42 floats), wrist-centered
    if (hasLeft) {
      final wristX = frame[kLeftHandStartIdx][0];
      final wristY = frame[kLeftHandStartIdx][1];

      for (int i = kLeftHandStartIdx; i <= kLeftHandEndIdx; i++) {
        final pt = frame[i];
        result[offset++] = (pt.isNotEmpty ? pt[0] - wristX : 0.0);
        result[offset++] = (pt.length > 1 ? pt[1] - wristY : 0.0);
      }
    } else {
      offset += 42; // leave as 0.0
    }

    // 2. Right Hand (21 points x 2 = 42 floats), wrist-centered
    if (hasRight) {
      final wristX = frame[kRightHandStartIdx][0];
      final wristY = frame[kRightHandStartIdx][1];

      for (int i = kRightHandStartIdx; i <= kRightHandEndIdx; i++) {
        final pt = frame[i];
        result[offset++] = (pt.isNotEmpty ? pt[0] - wristX : 0.0);
        result[offset++] = (pt.length > 1 ? pt[1] - wristY : 0.0);
      }
    } else {
      offset += 42; // leave as 0.0
    }

    // 3. Presence flags (2 floats)
    result[offset++] = hasLeft ? 1.0 : 0.0;
    result[offset++] = hasRight ? 1.0 : 0.0;

    return result;
  }

  // --------------------------------------------------------------------------
  // Legacy / Test Compatibility Methods
  // --------------------------------------------------------------------------

  static Float32List processRawLandmarks(List<List<List<double>>> landmarks) {
    final int rawT = landmarks.length;
    if (rawT == 0) {
      return Float32List(
        1 * kNumChannels * kTargetFrames * kNumSelectedKeypoints,
      );
    }

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

    for (int t = 0; t < rawT; t++) {
      for (int v = 0; v < kNumSelectedKeypoints; v++) {
        final pt = filtered[t][v];
        if (applyCentering) {
          pt[0] = (pt[0] - centerX) * scale;
          pt[1] = (pt[1] - centerY) * scale;
        }
      }
    }

    final int effectiveT = math.min(rawT, kTargetFrames);
    final result = Float32List(
      1 * kNumChannels * kTargetFrames * kNumSelectedKeypoints,
    );

    for (int t = 0; t < effectiveT; t++) {
      for (int v = 0; v < kNumSelectedKeypoints; v++) {
        final pt = filtered[t][v];
        final xIdx = (0 * kTargetFrames + t) * kNumSelectedKeypoints + v;
        final yIdx = (1 * kTargetFrames + t) * kNumSelectedKeypoints + v;
        result[xIdx] = pt[0];
        result[yIdx] = pt[1];
      }
    }

    return result;
  }

  static int _map75ToHolisticIndex(int idx75) {
    if (idx75 < 33) return idx75;
    if (idx75 < 54) return 501 + (idx75 - 33);
    return 522 + (idx75 - 54);
  }

  static List<List<List<double>>> generateSyntheticSequence({
    int frames = 60,
    double noiseMagnitude = 0.05,
    int? seed,
  }) {
    final random = seed != null ? math.Random(seed) : math.Random();
    return List.generate(frames, (t) {
      final double angle = (t / frames) * 2 * math.pi;
      return List.generate(kNumHolisticLandmarks, (i) {
        if (i < 33) {
          double baseX = 0.5;
          double baseY = 0.5;
          if (i == 11) {
            baseX = 0.35;
            baseY = 0.40;
          } else if (i == 12) {
            baseX = 0.65;
            baseY = 0.40;
          } else if (i == 0) {
            baseX = 0.50;
            baseY = 0.25;
          }
          final noiseX = (random.nextDouble() - 0.5) * noiseMagnitude;
          final noiseY = (random.nextDouble() - 0.5) * noiseMagnitude;
          return [baseX + noiseX, baseY + noiseY, 0.0];
        } else if (i >= 501 && i <= 542) {
          final isLeft = i <= 521;
          final centerCenterX = isLeft ? 0.30 : 0.70;
          final x = centerCenterX + 0.1 * math.cos(angle);
          final y = 0.6 + 0.1 * math.sin(angle);
          final noiseX = (random.nextDouble() - 0.5) * noiseMagnitude;
          final noiseY = (random.nextDouble() - 0.5) * noiseMagnitude;
          return [x + noiseX, y + noiseY, 0.0];
        }
        return [0.0, 0.0, 0.0];
      });
    });
  }
}
