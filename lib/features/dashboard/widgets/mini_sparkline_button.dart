import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// An enlarged, transparent mini sparkline wave chart button that blends
/// seamlessly into the hero card background, featuring a glowing Mecca gold
/// wave with gradient fill matching AppColors.
class MiniSparklineButton extends StatefulWidget {
  final Future<void> Function() onSync;
  final String? tooltip;
  final double width;
  final double height;
  final Color waveColor;

  const MiniSparklineButton({
    super.key,
    required this.onSync,
    this.tooltip,
    this.width = 150,
    this.height = 74,
    this.waveColor = AppColors.accentGoldStar,
  });

  @override
  State<MiniSparklineButton> createState() => _MiniSparklineButtonState();
}

class _MiniSparklineButtonState extends State<MiniSparklineButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    HapticFeedback.lightImpact();
    _animCtrl.repeat();

    try {
      await Future.wait([
        widget.onSync(),
        Future.delayed(const Duration(milliseconds: 700)),
      ]);
    } finally {
      if (mounted) {
        _animCtrl.stop();
        _animCtrl.reset();
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonContent = Container(
      width: widget.width,
      height: widget.height,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: widget.waveColor.withValues(alpha: 0.25),
          highlightColor: widget.waveColor.withValues(alpha: 0.12),
          onTap: _isSyncing ? null : _handleTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) {
                return Opacity(
                  opacity: _isSyncing
                      ? 0.45 +
                            0.55 *
                                (0.5 +
                                    0.5 *
                                        math.sin(_animCtrl.value * 2 * math.pi))
                      : 1.0,
                  child: CustomPaint(
                    painter: _SparklineWavePainter(waveColor: widget.waveColor),
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

class _SparklineWavePainter extends CustomPainter {
  final Color waveColor;

  const _SparklineWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waveColor.withValues(alpha: 0.42),
          waveColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // ── Smooth Bezier Wave Points matching Reference Image 2 ──
    final p0 = Offset(4, h * 0.65);
    final p1 = Offset(w * 0.28, h * 0.26);
    final p2 = Offset(w * 0.52, h * 0.58);
    final p3 = Offset(w * 0.76, h * 0.16);
    final p4 = Offset(w - 4, h * 0.36);

    path.moveTo(p0.dx, p0.dy);

    // Curve 1: up to peak 1
    path.cubicTo(w * 0.10, h * 0.65, w * 0.18, h * 0.26, p1.dx, p1.dy);

    // Curve 2: down to trough
    path.cubicTo(w * 0.36, h * 0.26, w * 0.44, h * 0.58, p2.dx, p2.dy);

    // Curve 3: up to peak 2
    path.cubicTo(w * 0.60, h * 0.58, w * 0.68, h * 0.16, p3.dx, p3.dy);

    // Curve 4: down to end
    path.cubicTo(w * 0.84, h * 0.16, w * 0.92, h * 0.36, p4.dx, p4.dy);

    // Fill underneath the wave
    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(p4.dx, h);
    fillPath.lineTo(p0.dx, h);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklineWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}
