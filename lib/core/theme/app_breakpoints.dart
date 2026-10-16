import 'package:flutter/material.dart';

/// Screen window classification based on official Flutter responsive guidelines:
/// - [compact]: Phone in portrait (< 600dp)
/// - [medium]: Foldables and tablets in portrait (600..839dp)
/// - [expanded]: Large tablets in landscape, desktops (>= 840dp)
enum WindowSize { compact, medium, expanded }

/// Breakpoints and responsive constraints for HajiCare.
class AppBreakpoints {
  AppBreakpoints._();

  static const double compactMax = 599.0;
  static const double mediumMax = 839.0;

  static const double maxContentWidth = 640.0;
  static const double maxTabletContentWidth = 840.0;
  static const double maxFormWidth = 520.0;
  static const double maxDialogWidth = 420.0;
  static const double maxSheetWidth = 560.0;
  static const double maxNavDockWidth = 580.0;

  /// Classifies width into [WindowSize].
  static WindowSize of(double width) {
    if (width < 600.0) return WindowSize.compact;
    if (width < 840.0) return WindowSize.medium;
    return WindowSize.expanded;
  }
}

/// Responsive extensions on [BuildContext] to adapt layouts seamlessly.
extension WindowSizeContextX on BuildContext {
  /// Window classification for the current screen size.
  WindowSize get windowSize => AppBreakpoints.of(MediaQuery.sizeOf(this).width);

  /// True if current device window is compact phone portrait (< 600dp).
  bool get isCompact => windowSize == WindowSize.compact;

  /// True if current device is a tablet or foldable in portrait (600..839dp).
  bool get isMedium => windowSize == WindowSize.medium;

  /// True if current device is in landscape tablet or desktop (>= 840dp).
  bool get isExpanded => windowSize == WindowSize.expanded;

  /// True if current device is a tablet, foldable, or desktop.
  bool get isMediumOrExpanded => !isCompact;
}

/// Centers and clamps content width to prevent stretched awkward layouts
/// on larger screens (foldables, tablets, landscape), preserving ergonomic readability.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppBreakpoints.maxContentWidth,
        ),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// Adaptive layout builder switching between compact, medium, and expanded widgets.
class AdaptiveLayout extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  const AdaptiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = AppBreakpoints.of(constraints.maxWidth);
        if (window == WindowSize.expanded && expanded != null) {
          return expanded!;
        }
        if (window == WindowSize.medium && medium != null) {
          return medium!;
        }
        if (window == WindowSize.expanded && medium != null) {
          return medium!;
        }
        return compact;
      },
    );
  }
}
