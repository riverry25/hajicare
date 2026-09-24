import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

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
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge.copyWith(
              color:
                  textColor ??
                  (isOutline
                      ? (color ?? AppColors.primaryContainer)
                      : AppColors.surfaceWhite),
            ),
          ),
        ),
      ],
    );

    if (isOutline) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color ?? AppColors.goldLight, width: 1.5),
          foregroundColor: textColor ?? AppColors.primaryContainer,
          minimumSize: Size(
            isFullWidth ? double.infinity : AppSizes.touchTargetMin,
            AppSizes.buttonHeightSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
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
          isFullWidth ? double.infinity : AppSizes.touchTargetMin,
          AppSizes.buttonHeightPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
      ),
      child: buttonChild,
    );
  }
}
