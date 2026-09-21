import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// A distance-reactive sparkline widget for the Jamaah dashboard hero section.
///
/// Replaces the static [RotatingSyncButton] with a continuously animated wave
/// whose shape and colour intensity dynamically reflect the Jamaah's real-time
/// distance from their Pendamping:
///
/// - **Near (< 50 m)**: tall, smooth wave — green tint — "all clear"
/// - **Mid (50–300 m)**: medium wave — gold — normal monitoring range
/// - **Far (> 300 m)**: low, flat wave — orange/red — attention needed
///
/// Tapping triggers a GPS location refresh with a ripple burst animation.
class DistanceSparklineWidget extends StatefulWidget {
  final Future<void> Function() onSync;
  final double distance;
  final String? tooltip;
  final double width;
  final double height;

  const DistanceSparklineWidget({
    super.key,
    required this.onSync,
    required this.distance,
    this.tooltip,
    this.width = 175,
    this.height = 84,
  });

  @override
  State<DistanceSparklineWidget> createState() =>
      _DistanceSparklineWidgetState();
}

class _DistanceSparklineWidgetState extends State<DistanceSparklineWidget>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _syncCtrl;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _syncCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _syncCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    HapticFeedback.lightImpact();
    _syncCtrl.repeat();

    try {
      await Future.wait([
        widget.onSync(),
        Future.delayed(const Duration(milliseconds: 850)),
      ]);
    } finally {
      if (mounted) {
        _syncCtrl.stop();
        _syncCtrl.reset();
        setState(() => _isSyncing = false);
      }
    }
  }

  Color get _waveColor {
    final d = widget.distance;
    if (d <= 0) return AppColors.goldLight.withValues(alpha: 0.7);
    if (d < 50) return const Color(0xFF6CDEA0);
    if (d < 300) return AppColors.accentGoldStar;
    if (d < 1000) return const Color(0xFFFFA040);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    final buttonContent = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _waveColor.withValues(alpha: 0.22),
          highlightColor: _waveColor.withValues(alpha: 0.10),
          onTap: _isSyncing ? null : _handleTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseCtrl, _syncCtrl]),
              builder: (context, _) {
                final opacity = _isSyncing
                    ? 0.55 +
                          0.45 *
                              (0.5 +
                                  0.5 * math.sin(_syncCtrl.value * 2 * math.pi))
                    : 1.0;

                return Opacity(
                  opacity: opacity,
                  child: CustomPaint(
                    painter: _DistanceWavePainter(
                      distance: widget.distance,
                      waveColor: _waveColor,
                      pulsePhase: _pulseCtrl.value,
                      syncPhase: _isSyncing ? _syncCtrl.value : 0.0,
                      isSyncing: _isSyncing,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: buttonContent);
    }
    return buttonContent;
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────

class _DistanceWavePainter extends CustomPainter {
  final double distance;
  final Color waveColor;
  final double pulsePhase;
  final double syncPhase;
  final bool isSyncing;

  const _DistanceWavePainter({
    required this.distance,
    required this.waveColor,
    required this.pulsePhase,
    required this.syncPhase,
    required this.isSyncing,
  });

  double get _proximityFactor {
    if (distance <= 0) return 0.6;
    final clamped = distance.clamp(0.0, 2000.0);
    return 1.0 - (clamped / 2000.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final prox = _proximityFactor;

    final breathe = math.sin(pulsePhase * 2 * math.pi) * 2.5;
    final ripple = isSyncing ? math.sin(syncPhase * 2 * math.pi) * 4.5 : 0.0;

    final amplitude = h * (0.12 + prox * 0.30);
    final midY = h * (0.75 - prox * 0.35);

    final p0 = Offset(
      4,
      (midY + amplitude * 0.6 + breathe + ripple).clamp(h * 0.05, h * 0.95),
    );
    final p1 = Offset(
      w * 0.26,
      (midY - amplitude + breathe - ripple * 0.8).clamp(h * 0.05, h * 0.95),
    );
    final p2 = Offset(
      w * 0.50,
      (midY + amplitude * 0.4 - breathe + ripple * 0.5).clamp(
        h * 0.05,
        h * 0.95,
      ),
    );
    final p3 = Offset(
      w * 0.74,
      (midY - amplitude * 0.8 + breathe - ripple * 0.3).clamp(
        h * 0.05,
        h * 0.95,
      ),
    );
    final p4 = Offset(
      w - 4,
      (midY + amplitude * 0.2 + breathe).clamp(h * 0.05, h * 0.95),
    );

    final strokePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waveColor.withValues(alpha: 0.38),
          waveColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final dotGlowPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final wavePath = Path();
    wavePath.moveTo(p0.dx, p0.dy);
    wavePath.cubicTo(w * 0.09, p0.dy, w * 0.17, p1.dy, p1.dx, p1.dy);
    wavePath.cubicTo(w * 0.35, p1.dy, w * 0.43, p2.dy, p2.dx, p2.dy);
    wavePath.cubicTo(w * 0.59, p2.dy, w * 0.67, p3.dy, p3.dx, p3.dy);
    wavePath.cubicTo(w * 0.83, p3.dy, w * 0.91, p4.dy, p4.dx, p4.dy);

    final fillPath = Path()..addPath(wavePath, Offset.zero);
    fillPath.lineTo(p4.dx, h);
    fillPath.lineTo(p0.dx, h);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(wavePath, strokePaint);

    // Live-position dot at rightmost anchor
    canvas.drawCircle(p4, 5.5, dotGlowPaint);
    canvas.drawCircle(p4, 3.0, dotPaint);

    _drawDistanceLabel(canvas, size);
  }

  void _drawDistanceLabel(Canvas canvas, Size size) {
    final w = size.width;

    String valueText;
    String unitText;
    if (distance <= 0) {
      valueText = '—';
      unitText = '';
    } else if (distance >= 1000) {
      final km = distance / 1000;
      valueText = km >= 10 ? km.round().toString() : km.toStringAsFixed(1);
      unitText = ' km';
    } else {
      valueText = distance.round().toString();
      unitText = ' m';
    }

    final valuePainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: valueText,
            style: TextStyle(
              color: waveColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          TextSpan(
            text: unitText,
            style: TextStyle(
              color: waveColor.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final xPos = w - valuePainter.width - 8;
    const yPos = 6.0;
    valuePainter.paint(canvas, Offset(xPos, yPos));
  }

  @override
  bool shouldRepaint(covariant _DistanceWavePainter old) =>
      old.distance != distance ||
      old.pulsePhase != pulsePhase ||
      old.syncPhase != syncPhase ||
      old.isSyncing != isSyncing ||
      old.waveColor != waveColor;
}
