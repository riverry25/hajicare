import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppStatusType {
  safe,
  warning,
  danger,
  neutral,
  custom,
}

class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusType statusType;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool showDot;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.statusType = AppStatusType.safe,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, text) = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm2 / 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor ?? text,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm2),
          ] else if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: textColor ?? text,
            ),
            const SizedBox(width: AppSpacing.sm2),
          ],
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: textColor ?? text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getColors() {
    switch (statusType) {
      case AppStatusType.safe:
        return (
          AppColors.statusPositive.withValues(alpha: 0.15),
          AppColors.statusPositive,
        );
      case AppStatusType.warning:
        return (
          AppColors.distanceWarning.withValues(alpha: 0.15),
          AppColors.distanceWarning,
        );
      case AppStatusType.danger:
        return (
          AppColors.sosEmergency.withValues(alpha: 0.15),
          AppColors.sosEmergency,
        );
      case AppStatusType.neutral:
        return (
          AppColors.canvasCream,
          AppColors.espressoDark,
        );
      case AppStatusType.custom:
        return (
          backgroundColor ?? AppColors.canvasCream,
          textColor ?? AppColors.espressoDark,
        );
    }
  }
}
