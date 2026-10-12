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
  static const double maxDialogWidth = 420.0;
  static const double maxSheetWidth = 560.0;

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
  WindowSize get windowSize =>
      AppBreakpoints.of(MediaQuery.sizeOf(this).width);

  /// True if current device window is compact phone portrait (< 600dp).
  bool get isCompact => windowSize == WindowSize.compact;

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
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppBreakpoints.maxContentWidth,
        ),
        child:
            padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}
