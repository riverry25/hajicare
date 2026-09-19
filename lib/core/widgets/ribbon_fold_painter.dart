import 'package:flutter/material.dart';

/// Painter for the 3D folded ribbon corner flap on the protruding dialog action button.
class RibbonFoldPainter extends CustomPainter {
  final Color color;
  const RibbonFoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(
        0,
        size.height,
      ) // bottom-left (intersection of card wall & button)
      ..lineTo(size.width, size.height) // bottom-right (top-right of button)
      ..lineTo(0, 0) // top-left (on card wall)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RibbonFoldPainter oldDelegate) =>
      oldDelegate.color != color;
}
