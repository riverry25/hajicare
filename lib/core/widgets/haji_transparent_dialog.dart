import 'package:flutter/material.dart';

/// Transparent Dialog wrapper for custom HajiCare stacked/floating card dialogs.
///
/// Completely strips default Material 3 dialog shapes, elevations, borders, and
/// surface tints so that inner floating hero cards, translucent cutouts, and
/// protruding ribbon buttons render seamlessly without any ghost outer borders.
class HajiTransparentDialog extends StatelessWidget {
  final Widget child;
  final EdgeInsets insetPadding;

  const HajiTransparentDialog({
    super.key,
    required this.child,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 24,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      insetPadding: insetPadding,
      child: child,
    );
  }
}
