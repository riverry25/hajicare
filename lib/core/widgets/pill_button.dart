import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isOutline;
  final IconData? icon;
  final bool isFullWidth;
  final Color? color;
  final Color? textColor;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutline = false,
    this.icon,
    this.isFullWidth = true,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppConstants.spaceXs),
        ],
        Text(label),
      ],
    );

    if (isOutline) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: color ?? AppColors.goldLight,
            width: 1.5,
          ),
          foregroundColor: textColor ?? AppColors.primaryContainer,
          minimumSize: Size(
            isFullWidth ? double.infinity : AppConstants.touchTargetMin,
            AppConstants.buttonHeightSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceXl),
        ),
        child: buttonChild,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primaryContainer,
        foregroundColor: textColor ?? AppColors.surfaceWhite,
        minimumSize: Size(
          isFullWidth ? double.infinity : AppConstants.touchTargetMin,
          AppConstants.buttonHeightPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceXl),
      ),
      child: buttonChild,
    );
  }
}
