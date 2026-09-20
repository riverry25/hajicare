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
