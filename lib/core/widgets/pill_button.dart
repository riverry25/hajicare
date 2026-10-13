import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

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
    final hc = context.hc;
    final textTheme = context.text;

    final effectiveTextColor =
        textColor ?? (isOutline ? (color ?? hc.textPrimary) : hc.onPrimary);

    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.s8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge.copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    if (isOutline) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color ?? hc.borderStrong, width: 1.5),
          foregroundColor: effectiveTextColor,
          minimumSize: Size(
            isFullWidth ? double.infinity : AppSizes.touchTargetMin,
            AppSizes.buttonHeightSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
        ),
        child: buttonChild,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? hc.primary,
        foregroundColor: effectiveTextColor,
        minimumSize: Size(
          isFullWidth ? double.infinity : AppSizes.touchTargetMin,
          AppSizes.buttonHeightPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      ),
      child: buttonChild,
    );
  }
}
