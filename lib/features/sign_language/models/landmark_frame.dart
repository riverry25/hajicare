import 'package:flutter/foundation.dart';

/// Single-frame container for MediaPipe landmarks & blendshapes.
/// - [leftHand]: 21 3D points [x, y, z] normalized [0, 1]
/// - [rightHand]: 21 3D points [x, y, z] normalized [0, 1]
/// - [pose]: 33 (or >=25) 3D points [x, y, z] normalized [0, 1]
/// - [faceBlendshapes]: Map of blendshape category name to score [0, 1]
@immutable
class LandmarkFrame {
  final List<List<double>>? leftHand;
  final List<List<double>>? rightHand;
  final List<List<double>>? pose;
  final Map<String, double>? faceBlendshapes;
  final int timestampMs;

  const LandmarkFrame({
    this.leftHand,
    this.rightHand,
    this.pose,
    this.faceBlendshapes,
    this.timestampMs = 0,
  });

  bool get hasLeftHand => leftHand != null && leftHand!.length >= 21;
  bool get hasRightHand => rightHand != null && rightHand!.length >= 21;
  bool get hasAnyHand => hasLeftHand || hasRightHand;
  bool get hasPose => pose != null && pose!.length > 24;
  bool get hasFaceBlendshapes =>
      faceBlendshapes != null && faceBlendshapes!.isNotEmpty;

  /// Parses landmarks from native Android EventChannel event payload.
  /// Supports:
  /// 1. New structured dictionary: { 'left_hand': ..., 'right_hand': ..., 'pose': ..., 'face_blendshapes': ... }
  /// 2. 42 hand landmarks list: 0..20 left hand, 21..41 right hand
  /// 3. 543 holistic landmarks list: 0..32 pose, 33..499 face, 500..520 left, 521..541 right
  factory LandmarkFrame.fromEvent(dynamic event) {
    if (event is! Map) {
      return const LandmarkFrame();
    }

    // 1. Structured payload
    if (event.containsKey('left_hand') ||
        event.containsKey('right_hand') ||
        event.containsKey('pose') ||
        event.containsKey('face_blendshapes')) {
      final leftRaw = event['left_hand'] as List?;
      final rightRaw = event['right_hand'] as List?;
      final poseRaw = event['pose'] as List?;
      final blendshapesRaw = event['face_blendshapes'] as Map?;
      final timestamp = (event['timestamp'] as num?)?.toInt() ?? 0;

      final leftHand = _parsePoints(leftRaw);
      final rightHand = _parsePoints(rightRaw);
      final pose = _parsePoints(poseRaw);

      Map<String, double>? blendshapes;
      if (blendshapesRaw != null) {
        blendshapes = {};
        blendshapesRaw.forEach((k, v) {
          if (k is String && v is num) {
            blendshapes![k] = v.toDouble();
          }
        });
      }

      return LandmarkFrame(
        leftHand: leftHand,
        rightHand: rightHand,
        pose: pose,
        faceBlendshapes: blendshapes,
        timestampMs: timestamp,
      );
    }

    // 2. Flat landmarks list under 'landmarks'
    final rawLandmarks = event['landmarks'];
    if (rawLandmarks is List) {
      final points = _parsePoints(rawLandmarks);
      if (points == null) return const LandmarkFrame();

      if (points.length == 42) {
        // 0..20 left hand, 21..41 right hand
        final left = points.sublist(0, 21);
        final right = points.sublist(21, 42);
        final hasLeft = left.any((pt) => pt[0] != 0.0 || pt[1] != 0.0);
        final hasRight = right.any((pt) => pt[0] != 0.0 || pt[1] != 0.0);
        return LandmarkFrame(
          leftHand: hasLeft ? left : null,
          rightHand: hasRight ? right : null,
        );
      } else if (points.length >= 542) {
        // Legacy 543 layout:
        // 0..32: Pose (33 points)
        // 468/500..: Left hand (21 points)
        // Right hand (21 points)
        final pose = points.sublist(0, 33);
        final left = points.length >= 522 ? points.sublist(501, 522) : null;
        final right = points.length >= 543 ? points.sublist(522, 543) : null;
        return LandmarkFrame(leftHand: left, rightHand: right, pose: pose);
      }
    }

    return const LandmarkFrame();
  }

  static List<List<double>>? _parsePoints(List? raw) {
    if (raw == null || raw.isEmpty) return null;
    final List<List<double>> points = [];
    for (final item in raw) {
      if (item is List && item.length >= 3) {
        final x = (item[0] as num).toDouble();
        final y = (item[1] as num).toDouble();
        final z = (item[2] as num).toDouble();
        if (x.isNaN ||
            x.isInfinite ||
            y.isNaN ||
            y.isInfinite ||
            z.isNaN ||
            z.isInfinite) {
          points.add([0.0, 0.0, 0.0]);
        } else {
          points.add([x, y, z]);
        }
      }
    }
    return points.isNotEmpty ? points : null;
  }
}
