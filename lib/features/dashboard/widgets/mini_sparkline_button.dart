import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/locales/app_localizations.dart';
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
  final bool animate;

  const MiniSparklineButton({
    super.key,
    required this.onSync,
    this.tooltip,
    this.width = 175,
    this.height = 84,
    this.waveColor = AppColors.accentGoldStar,
    this.jamaahList,
    this.animate = true,
  });

  @override
  State<MiniSparklineButton> createState() => _MiniSparklineButtonState();
}

class _MiniSparklineButtonState extends State<MiniSparklineButton>
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
    );

    final inTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (widget.animate && !inTest) {
      _pulseCtrl.repeat();
    }

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

  Color get _effectiveColor {
    final list = widget.jamaahList;
    if (list == null || list.isEmpty) {
      return widget.waveColor;
    }
    // High priority: SOS active
    if (list.any((j) => j.sosActive)) {
      return const Color(0xFFFF4D4D);
    }
    // Any member in danger distance tier
    if (list.any((j) => j.tier == DistanceTier.terlalujJauh)) {
      return const Color(0xFFFF7A59);
    }
    // Any member in warning tier
    if (list.any((j) => j.tier == DistanceTier.waspada)) {
      return const Color(0xFFFFB84D);
    }
    // All members safe
    if (widget.waveColor == AppColors.accentGoldStar) {
      return const Color(0xFF6CDEA0);
    }
    return widget.waveColor;
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _effectiveColor;

    final buttonContent = AnimatedScale(
      scale: _isSyncing ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: activeColor.withValues(alpha: 0.22),
            highlightColor: activeColor.withValues(alpha: 0.10),
            onTap: _isSyncing ? null : _handleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseCtrl, _syncCtrl]),
                builder: (context, _) {
                  final opacity = _isSyncing
                      ? 0.60 +
                            0.40 *
                                (0.5 +
                                    0.5 *
                                        math.sin(_syncCtrl.value * 2 * math.pi))
                      : 1.0;

                  return Opacity(
                    opacity: opacity,
                    child: CustomPaint(
                      painter: _SparklineWavePainter(
                        waveColor: widget.waveColor,
                        effectiveColor: activeColor,
                        jamaahList: widget.jamaahList,
                        pulsePhase: _pulseCtrl.value,
                        syncPhase: _isSyncing ? _syncCtrl.value : 0.0,
                        isSyncing: _isSyncing,
                        syncLabel: context.tr('dashboard.syncShort'),
                        groupLabel: context.tr('dashboard.groupShort'),
                        safeLabel: context.tr('dashboard.safe'),
                      ),
                    ),
                  );
                },
              ),
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
  final Color effectiveColor;
  final List<JamaahData>? jamaahList;
  final double pulsePhase;
  final double syncPhase;
  final bool isSyncing;
  final String syncLabel;
  final String groupLabel;
  final String safeLabel;

  const _SparklineWavePainter({
    required this.waveColor,
    required this.effectiveColor,
    this.jamaahList,
    required this.pulsePhase,
    required this.syncPhase,
    required this.isSyncing,
    required this.syncLabel,
    required this.groupLabel,
    required this.safeLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Elevation offset based on safety ratio
    double elevationOffset = 0.0;
    if (jamaahList != null && jamaahList!.isNotEmpty) {
      final safeCount = jamaahList!
          .where((j) => j.tier == DistanceTier.aman)
          .length;
      final ratio = safeCount / jamaahList!.length;
      elevationOffset = (1.0 - ratio) * (h * 0.14);
    }

    // Continuous breathing harmonic wave
    final breathe1 = math.sin(pulsePhase * 2 * math.pi) * 3.2;
    final breathe2 = math.cos(pulsePhase * 2 * math.pi) * 2.8;
    final ripple = isSyncing ? math.sin(syncPhase * 2 * math.pi) * 5.0 : 0.0;

    // ── 1. Secondary Ambient Echo Wave (Background Depth) ──
    final echoPaint = Paint()
      ..color = effectiveColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ep0 = Offset(
      4,
      (h * 0.68 + elevationOffset - breathe2 * 0.8).clamp(h * 0.08, h * 0.94),
    );
    final ep1 = Offset(
      w * 0.27,
      (h * 0.32 + elevationOffset + breathe1 * 0.9).clamp(h * 0.08, h * 0.94),
    );
    final ep2 = Offset(
      w * 0.51,
      (h * 0.62 + elevationOffset - breathe1 * 0.7).clamp(h * 0.08, h * 0.94),
    );
    final ep3 = Offset(
      w * 0.75,
      (h * 0.22 + elevationOffset + breathe2 * 0.8).clamp(h * 0.08, h * 0.94),
    );
    final ep4 = Offset(
      w - 4,
      (h * 0.40 + elevationOffset - breathe2 * 0.5).clamp(h * 0.08, h * 0.94),
    );

    final echoPath = Path()
      ..moveTo(ep0.dx, ep0.dy)
      ..cubicTo(w * 0.10, ep0.dy, w * 0.18, ep1.dy, ep1.dx, ep1.dy)
      ..cubicTo(w * 0.35, ep1.dy, w * 0.43, ep2.dy, ep2.dx, ep2.dy)
      ..cubicTo(w * 0.59, ep2.dy, w * 0.67, ep3.dy, ep3.dx, ep3.dy)
      ..cubicTo(w * 0.83, ep3.dy, w * 0.91, ep4.dy, ep4.dx, ep4.dy);

    canvas.drawPath(echoPath, echoPaint);

    // ── 2. Primary Foreground Hero Wave ──
    final p0 = Offset(
      4,
      (h * 0.64 + elevationOffset + breathe1 + ripple).clamp(
        h * 0.06,
        h * 0.94,
      ),
    );
    final p1 = Offset(
      w * 0.28,
      (h * 0.25 + elevationOffset - breathe2 - ripple * 0.8).clamp(
        h * 0.06,
        h * 0.94,
      ),
    );
    final p2 = Offset(
      w * 0.52,
      (h * 0.56 + elevationOffset + breathe2 * 0.6 + ripple * 0.6).clamp(
        h * 0.06,
        h * 0.94,
      ),
    );
    final p3 = Offset(
      w * 0.76,
      (h * 0.15 + elevationOffset - breathe1 * 0.7 - ripple * 0.5).clamp(
        h * 0.06,
        h * 0.94,
      ),
    );
    final p4 = Offset(
      w - 4,
      (h * 0.35 + elevationOffset + breathe1 * 0.4).clamp(h * 0.06, h * 0.94),
    );

    final strokePaint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          effectiveColor.withValues(alpha: 0.38),
          effectiveColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final heroPath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(w * 0.10, p0.dy, w * 0.18, p1.dy, p1.dx, p1.dy)
      ..cubicTo(w * 0.36, p1.dy, w * 0.44, p2.dy, p2.dx, p2.dy)
      ..cubicTo(w * 0.60, p2.dy, w * 0.68, p3.dy, p3.dx, p3.dy)
      ..cubicTo(w * 0.84, p3.dy, w * 0.92, p4.dy, p4.dx, p4.dy);

    final fillPath = Path()
      ..addPath(heroPath, Offset.zero)
      ..lineTo(p4.dx, h)
      ..lineTo(p0.dx, h)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(heroPath, strokePaint);

    // ── 3. Live Glowing Beacon Point with Expanding Sonar Halo ──
    final haloPulse = 6.0 + 3.0 * math.sin(pulsePhase * 2 * math.pi);
    final haloPaint = Paint()
      ..color = effectiveColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()
      ..color = effectiveColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(p4, haloPulse, haloPaint);
    canvas.drawCircle(p4, 3.4, dotPaint);
    canvas.drawCircle(p4, 1.2, centerPaint);

    // Dynamic Sync Ripple Ring
    if (isSyncing) {
      final rippleRadius = 5.0 + syncPhase * 18.0;
      final rippleAlpha = (1.0 - syncPhase).clamp(0.0, 1.0) * 0.45;
      final ripplePaint = Paint()
        ..color = effectiveColor.withValues(alpha: rippleAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(p4, rippleRadius, ripplePaint);
    }

    // ── 4. Metric / Status Badge Label in Corner ──
    _drawMetricLabel(canvas, size);
  }

  void _drawMetricLabel(Canvas canvas, Size size) {
    final w = size.width;

    String primaryText;
    String secondaryText;

    if (isSyncing) {
      primaryText = syncLabel;
      secondaryText = '...';
    } else if (jamaahList == null || jamaahList!.isEmpty) {
      primaryText = '—';
      secondaryText = ' $groupLabel';
    } else {
      final safeCount = jamaahList!
          .where((j) => j.tier == DistanceTier.aman)
          .length;
      final total = jamaahList!.length;
      if (safeCount == total) {
        primaryText = '100%';
        secondaryText = ' $safeLabel';
      } else {
        primaryText = '$safeCount/$total';
        secondaryText = ' $safeLabel';
      }
    }

    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: primaryText,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          TextSpan(
            text: secondaryText,
            style: TextStyle(
              color: effectiveColor.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final xPos = w - textPainter.width - 8;
    const yPos = 6.0;
    textPainter.paint(canvas, Offset(xPos, yPos));
  }

  @override
  bool shouldRepaint(covariant _SparklineWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor ||
      oldDelegate.effectiveColor != effectiveColor ||
      oldDelegate.pulsePhase != pulsePhase ||
      oldDelegate.syncPhase != syncPhase ||
      oldDelegate.isSyncing != isSyncing ||
      oldDelegate.syncLabel != syncLabel ||
      oldDelegate.groupLabel != groupLabel ||
      oldDelegate.safeLabel != safeLabel ||
      oldDelegate.jamaahList?.length != jamaahList?.length;
}
