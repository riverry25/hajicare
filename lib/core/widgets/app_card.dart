import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

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
    final hc = context.hc;
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.s16);
    final effectiveRadius = borderRadius ?? AppRadius.card;

    final content = Container(
      margin: margin,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? hc.surface,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(color: borderColor ?? hc.border, width: 1.0),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: hc.shadow,
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
