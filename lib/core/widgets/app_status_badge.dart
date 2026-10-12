import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

enum AppStatusType { safe, warning, danger, neutral, custom }

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
    final (bg, text) = _getColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: 3.0,
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
            const SizedBox(width: AppSpacing.s4),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: textColor ?? text),
            const SizedBox(width: AppSpacing.s4),
          ],
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: textColor ?? text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getColors(BuildContext context) {
    final hc = context.hc;

    switch (statusType) {
      case AppStatusType.safe:
        return (hc.successContainer, hc.success);
      case AppStatusType.warning:
        return (hc.warningContainer, hc.warning);
      case AppStatusType.danger:
        return (hc.dangerContainer, hc.danger);
      case AppStatusType.neutral:
        return (hc.surfaceSubtle, hc.textPrimary);
      case AppStatusType.custom:
        return (
          backgroundColor ?? hc.surfaceSubtle,
          textColor ?? hc.textPrimary,
        );
    }
  }
}
