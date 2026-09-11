import 'package:flutter/material.dart';

/// Custom [CustomPainter] that renders a stylized top-down map
/// of the Mina tent city (Makkah), used as the background canvas
/// on the interactive map screen.
///
/// Draws:
/// - Tent sector blocks with cross-hatch patterns
/// - Main pedestrian boulevards (East-West and North-South)
/// - Secondary alleys
/// - Walking path from companion to jamaah marker
class MinaMapPainter extends CustomPainter {
  const MinaMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Base map background
    final basePaint = Paint()..color = const Color(0xFFEFE5D5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Tent block paints
    final tentPaint = Paint()
      ..color = const Color(0xFFE8DEC9)
      ..style = PaintingStyle.fill;
    final tentBorderPaint = Paint()
      ..color = const Color(0xFFDACDB5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw tent sectors
    _drawRoundedRect(canvas, 20, 80, 160, 140, tentPaint, tentBorderPaint);
    _drawRoundedRect(canvas, 230, 70, 170, 160, tentPaint, tentBorderPaint);
    _drawRoundedRect(canvas, 20, 270, 140, 190, tentPaint, tentBorderPaint);
    _drawRoundedRect(canvas, 250, 280, 150, 180, tentPaint, tentBorderPaint);
    _drawRoundedRect(canvas, 40, 500, 340, 130, tentPaint, tentBorderPaint);

    // Pedestrian boulevards
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    final roadDashPaint = Paint()
      ..color = const Color(0xFFD8C3A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Main boulevard East-West
    final pathEW = Path()
      ..moveTo(0, 245)
      ..quadraticBezierTo(size.width / 2, 235, size.width, 255);
    canvas.drawPath(pathEW, roadPaint);
    canvas.drawPath(pathEW, roadDashPaint);

    // North-South walkway
    final pathNS = Path()
      ..moveTo(200, 0)
      ..lineTo(195, size.height);
    canvas.drawPath(pathNS, roadPaint..strokeWidth = 22);
    canvas.drawPath(pathNS, roadDashPaint);

    // Secondary alleys
    final smallRoadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        const Offset(90, 240), const Offset(90, 460), smallRoadPaint);
    canvas.drawLine(
        const Offset(310, 250), const Offset(310, 480), smallRoadPaint);

    // Walking path (companion → jamaah)
    final walkPathPaint = Paint()
      ..color = const Color(0xFF3D2B1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final walkPath = Path()
      ..moveTo(145, 405)
      ..lineTo(200, 405)
      ..lineTo(202, 290)
      ..lineTo(250, 280);
    canvas.drawPath(walkPath, walkPathPaint);

    final walkAccentPaint = Paint()
      ..color = const Color(0xFFD4A857)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(walkPath, walkAccentPaint);
  }

  void _drawRoundedRect(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    Paint fill,
    Paint stroke,
  ) {
    final rrect =
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(8));
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);

    // Cross-hatch pattern inside tent block
    final crossPaint = Paint()
      ..color = const Color(0xFFDACDB5).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (double i = x; i < x + w; i += 34) {
      for (double j = y; j < y + h; j += 34) {
        canvas.drawLine(Offset(i, j), Offset(i + 28, j + 28), crossPaint);
        canvas.drawLine(Offset(i + 28, j), Offset(i, j + 28), crossPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
