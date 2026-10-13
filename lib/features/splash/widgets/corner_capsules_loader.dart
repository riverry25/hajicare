import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';

enum CornerPosition { topLeft, bottomRight }

/// Diagonal capsule stripes that decorate the splash screen corners.
///
/// * Entrance: each capsule (staggered) grows from 20% → 100% length while
///   fading 35% → 100% opacity and sliding in from the screen edge.
/// * Loop: a soft "loading sweep" — capsules brighten one after another
///   (opacity only, no scale, no glow).
///
/// Everything is drawn by a single [CustomPainter] that repaints directly from
/// the animations (`repaint:`), so no widgets are rebuilt per frame.
class CornerCapsulesLoader extends StatelessWidget {
  final CornerPosition position;
  final Animation<double> entranceAnim;
  final Animation<double> shimmerAnim;

  /// Canvas size reserved in the corner. Capsules may extend past it and are
  /// clipped by the screen edges, mimicking stripes entering from off-screen.
  static const Size canvasSize = Size(220, 170);

  const CornerCapsulesLoader({
    super.key,
    required this.position,
    required this.entranceAnim,
    required this.shimmerAnim,
  });

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: canvasSize,
          painter: _CornerCapsulesPainter(
            isTopLeft: position == CornerPosition.topLeft,
            // Brand palette combination taken from the theme.
            colors: [hc.islamic, hc.accent, hc.primary, hc.info],
            entrance: entranceAnim,
            sweep: shimmerAnim,
          ),
        ),
      ),
    );
  }
}

class _CapsuleSpec {
  final double length;
  final double thickness;

  const _CapsuleSpec(this.length, this.thickness);
}

class _CornerCapsulesPainter extends CustomPainter {
  _CornerCapsulesPainter({
    required this.isTopLeft,
    required this.colors,
    required this.entrance,
    required this.sweep,
  }) : super(repaint: Listenable.merge([entrance, sweep]));

  final bool isTopLeft;
  final List<Color> colors;
  final Animation<double> entrance;
  final Animation<double> sweep;

  static const double _angle = -36 * math.pi / 180;
  static final double _cos = math.cos(_angle);
  static final double _sin = math.sin(_angle);

  static const double _firstOffset = 34; // distance of 1st stripe from corner
  static const double _gap = 10;
  static const double _edgeInset = 6; // start cap hidden just past the edge
  static const double _slideDistance = 16;

  static const List<_CapsuleSpec> _topLeftSpecs = [
    _CapsuleSpec(90, 13),
    _CapsuleSpec(150, 14),
    _CapsuleSpec(205, 15),
    _CapsuleSpec(140, 13),
  ];

  static const List<_CapsuleSpec> _bottomRightSpecs = [
    _CapsuleSpec(110, 13),
    _CapsuleSpec(165, 14),
    _CapsuleSpec(205, 15),
    _CapsuleSpec(100, 13),
  ];

  // Stagger timing (fractions of the entrance controller).
  static const double _staggerStep = 0.12;
  static const double _itemSpan = 0.55;

  final Paint _paint = Paint()..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final specs = isTopLeft ? _topLeftSpecs : _bottomRightSpecs;
    final entranceValue = entrance.value;
    final sweepValue = sweep.value;

    canvas.save();
    if (!isTopLeft) {
      // Mirror the top-left geometry around the bottom-right corner.
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }
    canvas.rotate(_angle);

    // Centre of the sweep highlight travels across all capsules (+ margins).
    final sweepCentre = sweepValue * (specs.length + 1) - 0.5;

    double localY = _firstOffset;
    for (var i = 0; i < specs.length; i++) {
      final spec = specs[i];
      if (i > 0) localY += _gap + spec.thickness / 2;

      final start = i * _staggerStep;
      final raw = ((entranceValue - start) / _itemSpan).clamp(0.0, 1.0);
      final p = Curves.easeOutCubic.transform(raw);

      // Local-x where the stripe crosses the screen edge (screen X = -inset).
      // Screen X = x·cos − y·sin  →  x = (X + y·sin) / cos
      final edgeX = (-_edgeInset + localY * _sin) / _cos;
      final startX = edgeX - (1 - p) * _slideDistance;
      final length = spec.length * (0.20 + 0.80 * p);

      // Soft loading sweep, only after the capsule has fully entered.
      final distance = (i - sweepCentre).abs();
      final highlight = (1 - distance).clamp(0.0, 1.0);
      final sweepAlpha = 0.78 + 0.22 * highlight;
      final alpha = (0.35 + 0.65 * p) * (1 - p + p * sweepAlpha);

      _paint.color = colors[i % colors.length].withValues(alpha: alpha);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX,
            localY - spec.thickness / 2,
            length,
            spec.thickness,
          ),
          Radius.circular(spec.thickness / 2),
        ),
        _paint,
      );

      localY += spec.thickness / 2;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CornerCapsulesPainter old) {
    return old.isTopLeft != isTopLeft ||
        old.entrance != entrance ||
        old.sweep != sweep ||
        !_sameColors(old.colors, colors);
  }

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
