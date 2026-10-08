import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/models/landmark_frame.dart';
import 'package:hajicare/features/sign_language/services/bisindo_segmenter.dart';

/// Builds a 21-point hand centered at ([cx], [cy]) with a fixed hand size.
List<List<double>> _hand(double cx, double cy) {
  return List.generate(21, (i) {
    // Point 9 (middle MCP) sits 0.1 above wrist -> hand scale = 0.1
    if (i == 0) return [cx, cy, 0.0];
    if (i == 9) return [cx, cy - 0.1, 0.0];
    return [cx + (i % 5) * 0.01, cy - (i ~/ 5) * 0.02, 0.0];
  });
}

LandmarkFrame _withHand(double cx, double cy) =>
    LandmarkFrame(rightHand: _hand(cx, cy));

const LandmarkFrame _noHand = LandmarkFrame();

void main() {
  const frameMs = 66; // ~15 FPS
  late BisindoSegmenter segmenter;
  late int clock;

  setUp(() {
    segmenter = BisindoSegmenter();
    clock = 0;
  });

  BisindoSegment? feed(LandmarkFrame frame) {
    clock += frameMs;
    return segmenter.add(frame, nowMs: clock);
  }

  List<BisindoSegment> feedAll(Iterable<LandmarkFrame> frames) {
    final out = <BisindoSegment>[];
    for (final f in frames) {
      final s = feed(f);
      if (s != null) out.add(s);
    }
    return out;
  }

  test('no hands never opens a segment', () {
    final segments = feedAll(List.filled(60, _noHand));
    expect(segments, isEmpty);
    expect(segmenter.phase, BisindoSegmenterPhase.idle);
  });

  test('moving gesture then hands down yields one segment', () {
    final segments = feedAll([
      ...List.filled(5, _noHand),
      // ~1.3s moving gesture
      for (var i = 0; i < 20; i++) _withHand(0.3 + i * 0.02, 0.5),
      ...List.filled(12, _noHand),
    ]);

    expect(segments, hasLength(1));
    final segment = segments.single;
    expect(segment.reason, BisindoSegmentEndReason.handsAbsent);
    // Trailing hand-less frames are trimmed to at most 2.
    final trailingEmpty = segment.frames.reversed
        .takeWhile((f) => !f.hasAnyHand)
        .length;
    expect(trailingEmpty, lessThanOrEqualTo(2));
    expect(segmenter.phase, BisindoSegmenterPhase.idle);
  });

  test('pre-roll frames are included at segment start', () {
    final segments = feedAll([
      ...List.filled(6, _noHand),
      for (var i = 0; i < 15; i++) _withHand(0.3 + i * 0.02, 0.5),
      ...List.filled(10, _noHand),
    ]);
    expect(segments, hasLength(1));
    // Pre-roll (4) contains no-hand frames preceding the gesture.
    expect(segments.single.frames.first.hasAnyHand, isFalse);
  });

  test('static hold closes on stillness and re-arms until motion', () {
    final segments = feedAll([
      // Static letter held for ~2s.
      for (var i = 0; i < 30; i++) _withHand(0.5, 0.5),
    ]);
    expect(segments, hasLength(1));
    expect(segments.single.reason, BisindoSegmentEndReason.handsStill);
    expect(segmenter.phase, BisindoSegmenterPhase.rearm);

    // Holding still longer must NOT spawn more segments.
    expect(
      feedAll([for (var i = 0; i < 30; i++) _withHand(0.5, 0.5)]),
      isEmpty,
    );

    // Motion resumes -> new segment opens.
    feedAll([for (var i = 0; i < 6; i++) _withHand(0.5 + i * 0.03, 0.5)]);
    expect(segmenter.isActive, isTrue);
  });

  test('too-short blips are discarded', () {
    final segments = feedAll([
      ...List.filled(5, _noHand),
      for (var i = 0; i < 3; i++) _withHand(0.3 + i * 0.03, 0.5),
      ...List.filled(12, _noHand),
    ]);
    expect(segments, isEmpty);
  });

  test('max duration force-closes a long continuous motion', () {
    final segments = feedAll([
      for (var i = 0; i < 70; i++)
        _withHand(0.3 + (i.isEven ? 0.05 : 0.0), 0.5 + (i % 3) * 0.02),
    ]);
    expect(segments, isNotEmpty);
    expect(segments.first.reason, BisindoSegmentEndReason.maxDuration);
    expect(
      segments.first.duration.inMilliseconds,
      lessThanOrEqualTo(3500 + frameMs),
    );
  });

  test('flush closes an active segment', () {
    feedAll([for (var i = 0; i < 12; i++) _withHand(0.3 + i * 0.02, 0.5)]);
    expect(segmenter.isActive, isTrue);
    final segment = segmenter.flush(nowMs: clock + frameMs);
    expect(segment, isNotNull);
    expect(segment!.reason, BisindoSegmentEndReason.flushed);
    expect(segmenter.phase, BisindoSegmenterPhase.idle);
  });

  test('motion metric is scale-normalized and handles appearance', () {
    final a = _withHand(0.5, 0.5);
    final b = _withHand(0.51, 0.5); // moved 0.01 with hand scale 0.1
    expect(BisindoSegmenter.computeMotion(a, b), closeTo(0.1, 1e-6));
    expect(BisindoSegmenter.computeMotion(_noHand, a), 1.0);
    expect(BisindoSegmenter.computeMotion(null, a), 0.0);
  });
}
