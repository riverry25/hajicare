import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/jamaah_data.dart';
import '../../../core/theme/app_colors.dart';

/// An enlarged, transparent mini sparkline wave chart button that blends
/// seamlessly into the hero card background, featuring a glowing Mecca gold
/// wave with gradient fill matching AppColors.
///
/// Synchronizes visually with the room's live jamaah data (distance & status)
/// and triggers full location & room synchronization on tap.
class MiniSparklineButton extends StatefulWidget {
  final Future<void> Function() onSync;
  final String? tooltip;
  final double width;
  final double height;
  final Color waveColor;
  final List<JamaahData>? jamaahList;

  const MiniSparklineButton({
    super.key,
    required this.onSync,
    this.tooltip,
    this.width = 175,
    this.height = 84,
    this.waveColor = AppColors.accentGoldStar,
    this.jamaahList,
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
      duration: const Duration(milliseconds: 1200),
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
                      ? 0.55 +
                            0.45 *
                                (0.5 +
                                    0.5 *
                                        math.sin(_animCtrl.value * 2 * math.pi))
                      : 1.0,
                  child: CustomPaint(
                    painter: _SparklineWavePainter(
                      waveColor: widget.waveColor,
                      jamaahList: widget.jamaahList,
                      syncPhase: _isSyncing ? _animCtrl.value : 0.0,
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

class _SparklineWavePainter extends CustomPainter {
  final Color waveColor;
  final List<JamaahData>? jamaahList;
  final double syncPhase;
  final bool isSyncing;

  const _SparklineWavePainter({
    required this.waveColor,
    this.jamaahList,
    this.syncPhase = 0.0,
    this.isSyncing = false,
  });

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

    // ── Generate Smooth Bezier Wave Points (Adaptive to room jamaah data) ──
    // Determine dynamic elevation factor based on room jamaah status
    double elevationOffset = 0.0;
    if (jamaahList != null && jamaahList!.isNotEmpty) {
      final safeCount = jamaahList!
          .where((j) => j.tier == DistanceTier.aman)
          .length;
      final ratio = safeCount / jamaahList!.length;
      // High safe ratio -> wave sits higher (healthy), lower -> sits deeper
      elevationOffset = (1.0 - ratio) * (h * 0.12);
    }

    // Sync animation ripple
    final ripple = isSyncing ? math.sin(syncPhase * 2 * math.pi) * 3.5 : 0.0;

    final p0 = Offset(
      4,
      (h * 0.65 + elevationOffset + ripple).clamp(h * 0.1, h * 0.9),
    );
    final p1 = Offset(
      w * 0.28,
      (h * 0.26 + elevationOffset - ripple).clamp(h * 0.1, h * 0.9),
    );
    final p2 = Offset(
      w * 0.52,
      (h * 0.58 + elevationOffset + ripple * 0.7).clamp(h * 0.1, h * 0.9),
    );
    final p3 = Offset(
      w * 0.76,
      (h * 0.16 + elevationOffset - ripple * 0.7).clamp(h * 0.1, h * 0.9),
    );
    final p4 = Offset(
      w - 4,
      (h * 0.36 + elevationOffset).clamp(h * 0.1, h * 0.9),
    );

    path.moveTo(p0.dx, p0.dy);

    // Curve 1: up to peak 1
    path.cubicTo(w * 0.10, p0.dy, w * 0.18, p1.dy, p1.dx, p1.dy);

    // Curve 2: down to trough
    path.cubicTo(w * 0.36, p1.dy, w * 0.44, p2.dy, p2.dx, p2.dy);

    // Curve 3: up to peak 2
    path.cubicTo(w * 0.60, p2.dy, w * 0.68, p3.dy, p3.dx, p3.dy);

    // Curve 4: down to end
    path.cubicTo(w * 0.84, p3.dy, w * 0.92, p4.dy, p4.dx, p4.dy);

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
      oldDelegate.waveColor != waveColor ||
      oldDelegate.syncPhase != syncPhase ||
      oldDelegate.isSyncing != isSyncing ||
      oldDelegate.jamaahList?.length != jamaahList?.length;
}
