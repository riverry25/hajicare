import 'dart:math' as math;

import '../models/landmark_frame.dart';

/// Tunable thresholds for automatic BISINDO sign segmentation (sign spotting).
///
/// The MotionGRU model is trained on *isolated* gestures resampled to 48
/// timesteps, so continuous recognition works by detecting where a single
/// gesture starts and ends, then classifying exactly that segment.
class BisindoSegmenterConfig {
  /// Consecutive hand-present frames required to open a segment.
  final int startHandFrames;

  /// Number of frames kept before the segment start (captures onset motion).
  final int preRollFrames;

  /// Hands absent for this long closes the segment.
  final Duration endAbsence;

  /// Hands present but motionless for this long closes the segment.
  final Duration endStillness;

  /// Hard cap; segment is force-closed at this duration.
  final Duration maxDuration;

  /// Segments shorter than this are discarded as noise.
  final Duration minDuration;

  /// Segments with fewer frames than this are discarded as noise.
  final int minFrames;

  /// Normalized per-frame hand motion (relative to hand size) considered
  /// "moving".
  final double motionThreshold;

  /// Exponential smoothing factor applied to motion energy (0..1).
  final double motionSmoothing;

  const BisindoSegmenterConfig({
    this.startHandFrames = 3,
    this.preRollFrames = 4,
    this.endAbsence = const Duration(milliseconds: 450),
    this.endStillness = const Duration(milliseconds: 750),
    this.maxDuration = const Duration(milliseconds: 3500),
    this.minDuration = const Duration(milliseconds: 450),
    this.minFrames = 8,
    this.motionThreshold = 0.06,
    this.motionSmoothing = 0.5,
  }) : assert(startHandFrames > 0),
       assert(preRollFrames >= 0),
       assert(minFrames >= 2),
       assert(motionSmoothing > 0 && motionSmoothing <= 1);
}

enum BisindoSegmentEndReason { handsAbsent, handsStill, maxDuration, flushed }

/// A finished gesture segment ready for classification.
class BisindoSegment {
  final List<LandmarkFrame> frames;
  final int startMs;
  final int endMs;
  final BisindoSegmentEndReason reason;

  const BisindoSegment({
    required this.frames,
    required this.startMs,
    required this.endMs,
    required this.reason,
  });

  Duration get duration => Duration(milliseconds: endMs - startMs);
}

enum BisindoSegmenterPhase {
  /// Waiting for hands to appear.
  idle,

  /// A gesture is being collected.
  active,

  /// A segment was just closed while hands are still visible and still.
  /// A new segment opens only after motion resumes or hands leave.
  rearm,
}

/// Pure-Dart, Flutter-free segmenter. Feed every [LandmarkFrame] via [add];
/// it returns a [BisindoSegment] whenever a gesture is complete.
class BisindoSegmenter {
  final BisindoSegmenterConfig config;

  BisindoSegmenter({this.config = const BisindoSegmenterConfig()});

  BisindoSegmenterPhase _phase = BisindoSegmenterPhase.idle;
  final List<LandmarkFrame> _preRoll = [];
  final List<LandmarkFrame> _active = [];
  int _consecutiveHandFrames = 0;
  int _segmentStartMs = 0;
  int? _lastHandSeenMs;
  int? _lastMotionMs;
  int? _lastHandFrameIndexInActive;
  LandmarkFrame? _previousFrame;
  double _smoothedMotion = 0.0;

  BisindoSegmenterPhase get phase => _phase;
  bool get isActive => _phase == BisindoSegmenterPhase.active;
  int get activeFrameCount => _active.length;
  List<LandmarkFrame> get activeFrames => List.unmodifiable(_active);
  double get smoothedMotion => _smoothedMotion;

  void reset() {
    _phase = BisindoSegmenterPhase.idle;
    _preRoll.clear();
    _active.clear();
    _consecutiveHandFrames = 0;
    _segmentStartMs = 0;
    _lastHandSeenMs = null;
    _lastMotionMs = null;
    _lastHandFrameIndexInActive = null;
    _previousFrame = null;
    _smoothedMotion = 0.0;
  }

  /// Adds a frame. [nowMs] is a monotonic timestamp in milliseconds.
  BisindoSegment? add(LandmarkFrame frame, {required int nowMs}) {
    final motion = _computeMotion(_previousFrame, frame);
    _previousFrame = frame;
    _smoothedMotion =
        config.motionSmoothing * motion +
        (1 - config.motionSmoothing) * _smoothedMotion;
    final isMoving = _smoothedMotion >= config.motionThreshold;
    final hasHand = frame.hasAnyHand;

    if (hasHand) {
      _consecutiveHandFrames++;
      _lastHandSeenMs = nowMs;
    } else {
      _consecutiveHandFrames = 0;
    }
    if (hasHand && isMoving) _lastMotionMs = nowMs;

    switch (_phase) {
      case BisindoSegmenterPhase.idle:
        _pushPreRoll(frame);
        if (_consecutiveHandFrames >= config.startHandFrames) {
          _openSegment(nowMs);
        }
        return null;

      case BisindoSegmenterPhase.rearm:
        _pushPreRoll(frame);
        if (!hasHand) {
          _phase = BisindoSegmenterPhase.idle;
        } else if (isMoving) {
          _openSegment(nowMs);
        }
        return null;

      case BisindoSegmenterPhase.active:
        _active.add(frame);
        if (hasHand) _lastHandFrameIndexInActive = _active.length - 1;

        final elapsed = nowMs - _segmentStartMs;
        final lastHand = _lastHandSeenMs ?? _segmentStartMs;
        final lastMotion = _lastMotionMs ?? _segmentStartMs;

        if (!hasHand && nowMs - lastHand >= config.endAbsence.inMilliseconds) {
          return _closeSegment(
            nowMs,
            BisindoSegmentEndReason.handsAbsent,
            nextPhase: BisindoSegmenterPhase.idle,
          );
        }
        if (hasHand &&
            elapsed >= config.minDuration.inMilliseconds &&
            nowMs - lastMotion >= config.endStillness.inMilliseconds) {
          return _closeSegment(
            nowMs,
            BisindoSegmentEndReason.handsStill,
            nextPhase: BisindoSegmenterPhase.rearm,
          );
        }
        if (elapsed >= config.maxDuration.inMilliseconds) {
          return _closeSegment(
            nowMs,
            BisindoSegmentEndReason.maxDuration,
            nextPhase: hasHand
                ? BisindoSegmenterPhase.rearm
                : BisindoSegmenterPhase.idle,
          );
        }
        return null;
    }
  }

  /// Force-closes an in-progress segment (e.g. when the user stops detection).
  BisindoSegment? flush({required int nowMs}) {
    if (_phase != BisindoSegmenterPhase.active) return null;
    return _closeSegment(
      nowMs,
      BisindoSegmentEndReason.flushed,
      nextPhase: BisindoSegmenterPhase.idle,
    );
  }

  void _pushPreRoll(LandmarkFrame frame) {
    if (config.preRollFrames == 0) return;
    _preRoll.add(frame);
    while (_preRoll.length > config.preRollFrames) {
      _preRoll.removeAt(0);
    }
  }

  void _openSegment(int nowMs) {
    _phase = BisindoSegmenterPhase.active;
    _active
      ..clear()
      ..addAll(_preRoll);
    _preRoll.clear();
    _segmentStartMs = nowMs;
    _lastMotionMs = nowMs;
    _lastHandFrameIndexInActive = null;
    for (var i = 0; i < _active.length; i++) {
      if (_active[i].hasAnyHand) _lastHandFrameIndexInActive = i;
    }
  }

  BisindoSegment? _closeSegment(
    int nowMs,
    BisindoSegmentEndReason reason, {
    required BisindoSegmenterPhase nextPhase,
  }) {
    // Trim trailing hand-less frames, keeping at most 2 for natural release.
    final lastHandIdx = _lastHandFrameIndexInActive;
    final keepUntil = lastHandIdx == null
        ? -1
        : math.min(_active.length - 1, lastHandIdx + 2);
    final frames = keepUntil < 0
        ? <LandmarkFrame>[]
        : List<LandmarkFrame>.of(_active.sublist(0, keepUntil + 1));

    final startMs = _segmentStartMs;
    _active.clear();
    _preRoll.clear();
    _lastHandFrameIndexInActive = null;
    _phase = nextPhase;
    _consecutiveHandFrames = 0;

    final duration = nowMs - startMs;
    if (frames.length < config.minFrames ||
        duration < config.minDuration.inMilliseconds) {
      return null;
    }
    return BisindoSegment(
      frames: frames,
      startMs: startMs,
      endMs: nowMs,
      reason: reason,
    );
  }

  /// Mean hand landmark displacement between frames, normalized by hand size.
  /// Hand appearing/disappearing counts as strong motion.
  static double computeMotion(LandmarkFrame? previous, LandmarkFrame current) =>
      _computeMotion(previous, current);

  static double _computeMotion(LandmarkFrame? previous, LandmarkFrame current) {
    if (previous == null) return 0.0;
    var total = 0.0;
    var count = 0;

    void compare(List<List<double>>? a, List<List<double>>? b) {
      final aOk = a != null && a.length >= 21;
      final bOk = b != null && b.length >= 21;
      if (!aOk && !bOk) return;
      if (aOk != bOk) {
        total += 1.0;
        count++;
        return;
      }
      final scale = math.max(_dist(b![0], b[9]), 0.02);
      var sum = 0.0;
      for (var i = 0; i < 21; i++) {
        sum += _dist(a![i], b[i]);
      }
      total += (sum / 21) / scale;
      count++;
    }

    compare(previous.leftHand, current.leftHand);
    compare(previous.rightHand, current.rightHand);
    if (count == 0) return 0.0;
    final value = total / count;
    return value.isFinite ? value : 0.0;
  }

  static double _dist(List<double> a, List<double> b) {
    final dx = a[0] - b[0];
    final dy = a[1] - b[1];
    return math.sqrt(dx * dx + dy * dy);
  }
}
