import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../models/landmark_frame.dart';

/// Body reference frame used for global landmark normalization.
class BodyReference {
  final double centerX;
  final double centerY;
  final double centerZ;
  final double scale;

  const BodyReference({
    required this.centerX,
    required this.centerY,
    required this.centerZ,
    required this.scale,
  });

  List<double> get center => [centerX, centerY, centerZ];

  @override
  String toString() =>
      'BodyReference(center: [$centerX, $centerY, $centerZ], scale: $scale)';
}

/// Computes the exact 353-dimensional base feature vector per timestep
/// matching the training MediaPipe Holistic representation 1:1:
/// - 0..62:    LEFT_HAND_GLOBAL (21 * 3 = 63)
/// - 63..125:  LEFT_HAND_LOCAL (21 * 3 = 63)
/// - 126..188: RIGHT_HAND_GLOBAL (21 * 3 = 63)
/// - 189..251: RIGHT_HAND_LOCAL (21 * 3 = 63)
/// - 252..296: SELECTED_POSE_GLOBAL (15 * 3 = 45)
/// - 297..348: FACE_BLENDSHAPES (52 values)
/// - 349..352: PRESENCE_MASKS (4 values: [left, right, pose, face])
/// Total: 353 float32 values.
class BisindoFeatureExtractor {
  static const int kBaseFeatureDim = 353;
  static const int kModelInputFeatureDim = 706;

  static const List<int> kSelectedPoseIndices = [
    0,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
  ];

  static const List<int> kMcpIndices = [5, 9, 13, 17];

  static const List<String> kFaceBlendshapeNames = [
    "_neutral",
    "browDownLeft",
    "browDownRight",
    "browInnerUp",
    "browOuterUpLeft",
    "browOuterUpRight",
    "cheekPuff",
    "cheekSquintLeft",
    "cheekSquintRight",
    "eyeBlinkLeft",
    "eyeBlinkRight",
    "eyeLookDownLeft",
    "eyeLookDownRight",
    "eyeLookInLeft",
    "eyeLookInRight",
    "eyeLookOutLeft",
    "eyeLookOutRight",
    "eyeLookUpLeft",
    "eyeLookUpRight",
    "eyeSquintLeft",
    "eyeSquintRight",
    "eyeWideLeft",
    "eyeWideRight",
    "jawForward",
    "jawLeft",
    "jawOpen",
    "jawRight",
    "mouthClose",
    "mouthDimpleLeft",
    "mouthDimpleRight",
    "mouthFrownLeft",
    "mouthFrownRight",
    "mouthFunnel",
    "mouthLeft",
    "mouthLowerDownLeft",
    "mouthLowerDownRight",
    "mouthPressLeft",
    "mouthPressRight",
    "mouthPucker",
    "mouthRight",
    "mouthRollLower",
    "mouthRollUpper",
    "mouthShrugLower",
    "mouthShrugUpper",
    "mouthSmileLeft",
    "mouthSmileRight",
    "mouthStretchLeft",
    "mouthStretchRight",
    "mouthUpperUpLeft",
    "mouthUpperUpRight",
    "noseSneerLeft",
    "noseSneerRight",
  ];

  /// Computes body reference center and scale:
  /// Primary: shoulders center + Euclidean shoulder width (X/Y only).
  /// Fallback #1: wrists center + wrist distance (clamped >= 0.15).
  /// Fallback #2: single wrist center + 0.25 scale.
  /// Final Fallback: center = [0.5, 0.5, 0.0], scale = 1.0.
  static BodyReference computeBodyReference({
    List<List<double>>? pose,
    List<List<double>>? leftHand,
    List<List<double>>? rightHand,
  }) {
    // Primary Reference: Pose Shoulders (indices 11 and 12)
    if (pose != null && pose.length > 12) {
      final leftShoulder = pose[11];
      final rightShoulder = pose[12];
      final cx = (leftShoulder[0] + rightShoulder[0]) / 2.0;
      final cy = (leftShoulder[1] + rightShoulder[1]) / 2.0;
      final cz = (leftShoulder[2] + rightShoulder[2]) / 2.0;

      final dx = leftShoulder[0] - rightShoulder[0];
      final dy = leftShoulder[1] - rightShoulder[1];
      final scale = math.sqrt(dx * dx + dy * dy);

      if (scale > 1e-4) {
        return BodyReference(
          centerX: cx,
          centerY: cy,
          centerZ: cz,
          scale: scale,
        );
      }
    }

    // Fallback #1: Both hand wrists exist
    final bool hasLeftWrist = leftHand != null && leftHand.isNotEmpty;
    final bool hasRightWrist = rightHand != null && rightHand.isNotEmpty;

    if (hasLeftWrist && hasRightWrist) {
      final lw = leftHand[0];
      final rw = rightHand[0];
      final cx = (lw[0] + rw[0]) / 2.0;
      final cy = (lw[1] + rw[1]) / 2.0;
      final cz = (lw[2] + rw[2]) / 2.0;

      final dx = lw[0] - rw[0];
      final dy = lw[1] - rw[1];
      final dist = math.sqrt(dx * dx + dy * dy);
      final scale = math.max(dist, 0.15);

      return BodyReference(centerX: cx, centerY: cy, centerZ: cz, scale: scale);
    }

    // Fallback #2: Single wrist exists
    if (hasLeftWrist) {
      final lw = leftHand[0];
      return BodyReference(
        centerX: lw[0],
        centerY: lw[1],
        centerZ: lw[2],
        scale: 0.25,
      );
    }

    if (hasRightWrist) {
      final rw = rightHand[0];
      return BodyReference(
        centerX: rw[0],
        centerY: rw[1],
        centerZ: rw[2],
        scale: 0.25,
      );
    }

    // Final Fallback
    return const BodyReference(
      centerX: 0.5,
      centerY: 0.5,
      centerZ: 0.0,
      scale: 1.0,
    );
  }

  /// Extracts the exact 353-D base feature vector for a single frame.
  static Float32List extractBaseFeature(LandmarkFrame frame) {
    final Float32List feature = Float32List(kBaseFeatureDim);

    final bool hasLeft = frame.hasLeftHand;
    final bool hasRight = frame.hasRightHand;
    final bool hasPose = frame.hasPose;
    final bool hasFace = frame.hasFaceBlendshapes;

    final bodyRef = computeBodyReference(
      pose: frame.pose,
      leftHand: frame.leftHand,
      rightHand: frame.rightHand,
    );

    // 1. LEFT_HAND_GLOBAL (0..62)
    if (hasLeft) {
      _writeGlobalLandmarks(
        landmarks: frame.leftHand!,
        count: 21,
        ref: bodyRef,
        output: feature,
        startOffset: 0,
      );
    }

    // 2. LEFT_HAND_LOCAL (63..125)
    if (hasLeft) {
      _writeLocalHandLandmarks(
        hand: frame.leftHand!,
        output: feature,
        startOffset: 63,
      );
    }

    // 3. RIGHT_HAND_GLOBAL (126..188)
    if (hasRight) {
      _writeGlobalLandmarks(
        landmarks: frame.rightHand!,
        count: 21,
        ref: bodyRef,
        output: feature,
        startOffset: 126,
      );
    }

    // 4. RIGHT_HAND_LOCAL (189..251)
    if (hasRight) {
      _writeLocalHandLandmarks(
        hand: frame.rightHand!,
        output: feature,
        startOffset: 189,
      );
    }

    // 5. SELECTED_POSE_GLOBAL (252..296: 15 landmarks * 3 = 45)
    if (hasPose) {
      _writeSelectedPoseGlobal(
        pose: frame.pose!,
        ref: bodyRef,
        output: feature,
        startOffset: 252,
      );
    }

    // 6. FACE_BLENDSHAPES (297..348: 52 values)
    if (hasFace) {
      final blendshapes = frame.faceBlendshapes!;
      for (int i = 0; i < kFaceBlendshapeNames.length; i++) {
        final name = kFaceBlendshapeNames[i];
        final score = blendshapes[name] ?? 0.0;
        feature[297 + i] = score.toDouble();
      }
    }

    // 7. PRESENCE_MASKS (349..352: 4 values)
    feature[349] = hasLeft ? 1.0 : 0.0;
    feature[350] = hasRight ? 1.0 : 0.0;
    feature[351] = hasPose ? 1.0 : 0.0;
    feature[352] = hasFace ? 1.0 : 0.0;

    assert(
      feature.length == kBaseFeatureDim,
      'Base feature length must be $kBaseFeatureDim but got ${feature.length}',
    );

    return feature;
  }

  /// Writes globally normalized landmarks: (pt - center) / (scale + 1e-6), clipped to [-6.0, 6.0].
  static void _writeGlobalLandmarks({
    required List<List<double>> landmarks,
    required int count,
    required BodyReference ref,
    required Float32List output,
    required int startOffset,
  }) {
    final denom = ref.scale + 1e-6;
    for (int i = 0; i < count && i < landmarks.length; i++) {
      final pt = landmarks[i];
      final normX = ((pt[0] - ref.centerX) / denom).clamp(-6.0, 6.0);
      final normY = ((pt[1] - ref.centerY) / denom).clamp(-6.0, 6.0);
      final normZ = ((pt[2] - ref.centerZ) / denom).clamp(-6.0, 6.0);

      output[startOffset + i * 3] = normX.toDouble();
      output[startOffset + i * 3 + 1] = normY.toDouble();
      output[startOffset + i * 3 + 2] = normZ.toDouble();
    }
  }

  /// Writes local hand landmarks: (pt - wrist) / scale, clipped to [-5.0, 5.0].
  /// Scale = mean(XYZ distance(MCP_i, wrist)) + 1e-6 for MCP in [5, 9, 13, 17].
  static void _writeLocalHandLandmarks({
    required List<List<double>> hand,
    required Float32List output,
    required int startOffset,
  }) {
    if (hand.isEmpty) return;
    final wrist = hand[0];
    final wx = wrist[0];
    final wy = wrist[1];
    final wz = wrist[2];

    double sumDist = 0.0;
    for (final mcpIdx in kMcpIndices) {
      if (mcpIdx < hand.length) {
        final pt = hand[mcpIdx];
        final dx = pt[0] - wx;
        final dy = pt[1] - wy;
        final dz = pt[2] - wz;
        sumDist += math.sqrt(dx * dx + dy * dy + dz * dz);
      }
    }
    final scale = (sumDist / kMcpIndices.length) + 1e-6;

    for (int i = 0; i < 21 && i < hand.length; i++) {
      final pt = hand[i];
      final locX = ((pt[0] - wx) / scale).clamp(-5.0, 5.0);
      final locY = ((pt[1] - wy) / scale).clamp(-5.0, 5.0);
      final locZ = ((pt[2] - wz) / scale).clamp(-5.0, 5.0);

      output[startOffset + i * 3] = locX.toDouble();
      output[startOffset + i * 3 + 1] = locY.toDouble();
      output[startOffset + i * 3 + 2] = locZ.toDouble();
    }
  }

  /// Writes 15 selected pose landmarks globally normalized.
  static void _writeSelectedPoseGlobal({
    required List<List<double>> pose,
    required BodyReference ref,
    required Float32List output,
    required int startOffset,
  }) {
    final denom = ref.scale + 1e-6;
    for (int i = 0; i < kSelectedPoseIndices.length; i++) {
      final poseIdx = kSelectedPoseIndices[i];
      if (poseIdx < pose.length) {
        final pt = pose[poseIdx];
        final normX = ((pt[0] - ref.centerX) / denom).clamp(-6.0, 6.0);
        final normY = ((pt[1] - ref.centerY) / denom).clamp(-6.0, 6.0);
        final normZ = ((pt[2] - ref.centerZ) / denom).clamp(-6.0, 6.0);

        output[startOffset + i * 3] = normX.toDouble();
        output[startOffset + i * 3 + 1] = normY.toDouble();
        output[startOffset + i * 3 + 2] = normZ.toDouble();
      }
    }
  }

  /// DEBUG-only inspection helper for logging and parity testing with Colab.
  static Map<String, dynamic> debugInspectFeature(Float32List baseFeature) {
    if (!kDebugMode) return {};
    return {
      'base_feature_len': baseFeature.length,
      'left_global_slice': baseFeature.sublist(0, 6),
      'left_local_slice': baseFeature.sublist(63, 69),
      'right_global_slice': baseFeature.sublist(126, 132),
      'right_local_slice': baseFeature.sublist(189, 195),
      'pose_global_slice': baseFeature.sublist(252, 258),
      'blendshapes_slice': baseFeature.sublist(297, 303),
      'presence_masks': baseFeature.sublist(349, 353),
    };
  }
}
