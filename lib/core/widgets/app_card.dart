import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.lg);
    final effectiveRadius = borderRadius ?? AppRadius.lg;
    final isDark = AppColors.isDark(context);

    final content = Container(
      margin: margin,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceColor(context),
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? AppColors.darkOutlineVariant
                  : AppColors.canvasCreamSubtle),
          width: 1.0,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}
