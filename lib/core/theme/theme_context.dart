import 'package:flutter/material.dart';
import 'app_typography.dart';
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

/// Convenience accessor for the inherited Material 3 [TextTheme] with guaranteed non-null styles.
  HajiSafeTextTheme get text => HajiSafeTextTheme(Theme.of(this).textTheme, hc);

  /// Resolves the active [HajiTextStyles] extension for Quranic Arabic, hero metrics, etc.
  HajiTextStyles get textX {
    final ext = Theme.of(this).extension<HajiTextStyles>();
    if (ext != null) return ext;
    return isDarkTheme
        ? HajiTextStyles.dark(hc)
        : HajiTextStyles.light(hc);
  }
}

/// Guaranteed non-null [TextTheme] proxy wrapper for ergonomic syntax without nullable checks.
class HajiSafeTextTheme {
  final TextTheme _t;
  final HajiColors _c;

  const HajiSafeTextTheme(this._t, this._c);

  TextStyle get displayLarge => _t.displayLarge ?? TextStyle(color: _c.textPrimary);
  TextStyle get displayMedium => _t.displayMedium ?? TextStyle(color: _c.textPrimary);
  TextStyle get displaySmall => _t.displaySmall ?? TextStyle(color: _c.textPrimary);
  TextStyle get headlineLarge => _t.headlineLarge ?? TextStyle(color: _c.textPrimary);
  TextStyle get headlineMedium => _t.headlineMedium ?? TextStyle(color: _c.textPrimary);
  TextStyle get headlineSmall => _t.headlineSmall ?? TextStyle(color: _c.textPrimary);
  TextStyle get titleLarge => _t.titleLarge ?? TextStyle(color: _c.textPrimary);
  TextStyle get titleMedium => _t.titleMedium ?? TextStyle(color: _c.textPrimary);
  TextStyle get titleSmall => _t.titleSmall ?? TextStyle(color: _c.textPrimary);
  TextStyle get bodyLarge => _t.bodyLarge ?? TextStyle(color: _c.textPrimary);
  TextStyle get bodyMedium => _t.bodyMedium ?? TextStyle(color: _c.textPrimary);
  TextStyle get bodySmall => _t.bodySmall ?? TextStyle(color: _c.textSecondary);
  TextStyle get labelLarge => _t.labelLarge ?? TextStyle(color: _c.textPrimary);
  TextStyle get labelMedium => _t.labelMedium ?? TextStyle(color: _c.textSecondary);
  TextStyle get labelSmall => _t.labelSmall ?? TextStyle(color: _c.textTertiary);
}
