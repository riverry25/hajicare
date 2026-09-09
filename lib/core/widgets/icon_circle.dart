import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.canvasCream,
        border: hasBorder
            ? Border.withConfiguration(
                color: AppColors.goldLight.withOpacity(0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Center(
        child: Icon(
          icon,
          size: size * 0.5,
          color: iconColor ?? AppColors.espressoDark,
        ),
      ),
    );
  }
}
