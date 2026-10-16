import 'package:flutter/material.dart';
import '../theme/theme_context.dart';

class IconCircle extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool hasBorder;

  const IconCircle({
    super.key,
    required this.icon,
    this.size = 48.0,
    this.backgroundColor,
    this.iconColor,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? hc.surfaceSand,
        border: hasBorder ? Border.all(color: hc.accent, width: 1.5) : null,
      ),
      child: Center(
        child: Icon(icon, size: size * 0.5, color: iconColor ?? hc.primary),
      ),
    );
  }
}
