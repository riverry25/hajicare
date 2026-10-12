import 'package:flutter/material.dart';
import 'haji_colors.dart';

/// Ergonomic syntax extensions on [BuildContext] to access centralized theme tokens
/// safely, concisely, and with guaranteed fallbacks across both production and tests.
extension ThemeContextX on BuildContext {
  /// Resolves the active [HajiColors] semantic palette.
  /// Falls back smoothly to [HajiColors.dark] or [HajiColors.light] if the widget tree
  /// is rendered without an explicit [ThemeExtension] registration (e.g. isolated unit tests).
  HajiColors get hc {
    final ext = Theme.of(this).extension<HajiColors>();
    if (ext != null) return ext;
    return isDarkTheme ? HajiColors.dark : HajiColors.light;
  }

  /// Convenience boolean to check if the current inherited theme is Dark.
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  /// Convenience accessor for the inherited Material 3 [TextTheme].
  TextTheme get text => Theme.of(this).textTheme;
}
