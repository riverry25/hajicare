part of 'dashboard_jamaah_screen.dart';

class _CircularGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final Color arcColor;
  final Color dotColor;

  const _CircularGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.42;
    canvas.drawCircle(center, radius, trackPaint);

    // Foreground arc
    final sweepAngle = (2 * math.pi * 0.72) * progress.clamp(0.05, 1.0);
    const startAngle = -math.pi * 0.5; // Starts at 12 o'clock

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // End handle dot
    final endAngle = startAngle + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    // Outer white dot with shadow
    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 5.0, dotOuterPaint);

    // Inner dot
    final dotInnerPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 2.5, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.arcColor != arcColor ||
        oldDelegate.dotColor != dotColor;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTIVE HEARTBEAT ECG WAVEFORM (Lansia / Senior Friendly & Accessible)
// ─────────────────────────────────────────────────────────────────────────────

class _InteractiveHeartbeatWave extends StatefulWidget {
  final bool isConnected;
  final bool hasPriorData;
  final String? priorTime;
  final VoidCallback? onConnectTap;

  const _InteractiveHeartbeatWave({
    required this.isConnected,
    required this.hasPriorData,
    this.priorTime,
    this.onConnectTap,
  });

  @override
  State<_InteractiveHeartbeatWave> createState() =>
      _InteractiveHeartbeatWaveState();
}

class _InteractiveHeartbeatWaveState extends State<_InteractiveHeartbeatWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final activeColor = widget.isConnected
        ? (isDark ? AppColors.emeraldLight : const Color(0xFF059669))
        : (widget.hasPriorData
              ? const Color(0xFFD97706)
              : (isDark ? Colors.white38 : const Color(0xFF94A3B8)));

    final heartColor = widget.isConnected
        ? const Color(0xFFE11D48)
        : (widget.hasPriorData
              ? const Color(0xFFD97706)
              : const Color(0xFF94A3B8));

    final bpmText = widget.isConnected
        ? '76'
        : (widget.hasPriorData ? '72*' : '-');

    final bpmSubText = widget.isConnected
        ? 'Irama Jantung Normal'
        : (widget.hasPriorData
              ? 'Tersimpan Sebelumnya'
              : 'Sensor Detak Belum Terhubung');

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (!widget.isConnected && widget.onConnectTap != null) {
          widget.onConnectTap!();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A24) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isConnected
                ? (isDark
                      ? AppColors.emeraldLight.withValues(alpha: 0.3)
                      : const Color(0xFFA7F3D0))
                : (isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0)),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Heart Icon + Large Readable Title + Status Pill
            Row(
              children: [
                // Animated Pulsing Heart Icon
                AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, child) {
                    final scale = widget.isConnected
                        ? 1.0 + 0.18 * math.sin(_animCtrl.value * 2 * math.pi)
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: heartColor.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: heartColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detak Jantung & Gelombang',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: headingColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        bpmSubText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.isConnected
                              ? (isDark
                                    ? AppColors.emeraldLight
                                    : const Color(0xFF059669))
                              : (widget.hasPriorData
                                    ? const Color(0xFFD97706)
                                    : (isDark
                                          ? Colors.white54
                                          : const Color(0xFF64748B))),
                        ),
                      ),
                    ],
                  ),
                ),
                // BPM Large Label for Elderly
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      bpmText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: headingColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'BPM',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Oscilloscope ECG Screen
            Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF090D14)
                    : const Color(0xFF0B1320),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF1E293B),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _HeartbeatWavePainter(
                        progress: _animCtrl.value,
                        isConnected: widget.isConnected,
                        hasPriorData: widget.hasPriorData,
                        waveColor: activeColor,
                      ),
                    );
                  },
                ),
              ),
            ),

            if (!widget.isConnected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.hasPriorData
                          ? '*Data rekaman terakhir sebelum terputus'
                          : 'Hubungkan gelang untuk pantau langsung',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onConnectTap != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onConnectTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bluetooth_searching_rounded,
                            size: 13,
                            color: isDark
                                ? AppColors.goldLight
                                : AppColors.espressoDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hubungkan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.goldLight
                                  : AppColors.espressoDark,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ECG OSCILLOSCOPE PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _HeartbeatWavePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 from animation
  final bool isConnected;
  final bool hasPriorData;
  final Color waveColor;

  const _HeartbeatWavePainter({
    required this.progress,
    required this.isConnected,
    required this.hasPriorData,
    required this.waveColor,
  });

  /// Mathematical approximation of a physiological P-Q-R-S-T ECG wave cycle.
  /// Normalized to cycle length 1.0; returns amplitude from -0.4 to +1.0
  double _ecgCycle(double t) {
    final phase = t - t.floorToDouble(); // 0.0 to 1.0 within cycle
    if (phase < 0.12) {
      return 0.0; // Baseline
    } else if (phase < 0.22) {
      // P wave: small smooth upward dome (atrial depolarization)
      return 0.22 * math.sin((phase - 0.12) / 0.10 * math.pi);
    } else if (phase < 0.28) {
      // PR segment: flat baseline
      return 0.0;
    } else if (phase < 0.32) {
      // Q wave: small downward deflection
      return -0.22 * math.sin((phase - 0.28) / 0.04 * math.pi);
    } else if (phase < 0.37) {
      // R peak: sharp high ventricular spike
      return 1.0 * math.sin((phase - 0.32) / 0.05 * math.pi);
    } else if (phase < 0.42) {
      // S wave: downward deflection below baseline
      return -0.38 * math.sin((phase - 0.37) / 0.05 * math.pi);
    } else if (phase < 0.50) {
      // ST segment: returns to baseline
      return 0.0;
    } else if (phase < 0.68) {
      // T wave: broad smooth upward dome (ventricular repolarization)
      return 0.35 * math.sin((phase - 0.50) / 0.18 * math.pi);
    } else {
      // TP interval: resting baseline before next beat
      return 0.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h * 0.52;

    // 1. Draw subtle medical oscilloscope grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.6)
      ..strokeWidth = 0.6;

    // Vertical grid lines
    const gridSpacing = 16.0;
    for (double x = 0; x <= w; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    // Horizontal grid lines
    for (double y = 0; y <= h; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    if (!isConnected) {
      // Disconnected: Gentle dashed/flatline with slow resting idle wave
      final flatPaint = Paint()
        ..color = hasPriorData
            ? const Color(0xFFD97706).withValues(alpha: 0.8)
            : const Color(0xFF64748B).withValues(alpha: 0.5)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      double startX = 0.0;
      while (startX < w) {
        path.moveTo(startX, midY);
        path.lineTo(math.min(startX + dashWidth, w), midY);
        startX += dashWidth + dashSpace;
      }
      canvas.drawPath(path, flatPaint);
      return;
    }

    // 2. Connected: Dynamic Animated ECG Wave
    final wavePaint = Paint()
      ..color = waveColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.35)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const cycleCount = 2.5; // Number of heartbeats visible across screen width
    final maxAmp = h * 0.40;

    // Head of the scanning sweep
    final headX = w * progress;
    Offset? headPoint;

    bool isFirst = true;
    for (double x = 0; x <= w; x += 1.8) {
      // Normalized time traversing the waveform
      final t = (x / w) * cycleCount - (progress * cycleCount);
      final amp = _ecgCycle(t);
      final y = midY - (amp * maxAmp);

      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }

      if ((x - headX).abs() < 2.0) {
        headPoint = Offset(x, y);
      }
    }

    // Draw glowing trace and main wave
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, wavePaint);

    // 3. Draw active scanning head pulse dot
    headPoint ??= Offset(headX, midY);
    final dotGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final dotCenter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(headPoint, 4.5, dotGlow);
    canvas.drawCircle(headPoint, 2.5, dotCenter);
  }

  @override
  bool shouldRepaint(covariant _HeartbeatWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isConnected != isConnected ||
        oldDelegate.hasPriorData != hasPriorData ||
        oldDelegate.waveColor != waveColor;
  }
}
