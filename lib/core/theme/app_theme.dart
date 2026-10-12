import 'package:flutter/material.dart';
import 'app_radius.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'haji_colors.dart';

/// Centralized Material 3 Theme Configuration for HajiCare.
/// Integrates the "White Sand" aesthetic:
/// - 60% warm-white canvas (#FBF9F6) and pure white cards (#FFFFFF)
/// - 30% refined desert sand and subtle tonal surfaces
/// - 10% rich espresso (#3B2A1F) and desert gold (#B08A57) primary actions
/// with high accessibility, large readable typography, and tactile touch targets.
class AppTheme {
  AppTheme._();

  /// Light Theme (Warm White, Sand & Rich Espresso)
  static ThemeData get lightTheme =>
      _buildTheme(HajiColors.light, Brightness.light);

  /// Dark Theme (Warm Charcoal-Espresso & Desert Amber)
  static ThemeData get darkTheme =>
      _buildTheme(HajiColors.dark, Brightness.dark);

  static ThemeData _buildTheme(HajiColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.accent,
      onSecondary: c.onPrimary,
      secondaryContainer: c.surfaceSand,
      onSecondaryContainer: c.textPrimary,
      tertiary: c.accent,
      onTertiary: c.onPrimary,
      tertiaryContainer: c.surfaceSand,
      onTertiaryContainer: c.textPrimary,
      error: c.danger,
      onError: c.onDanger,
      errorContainer: c.dangerContainer,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerLowest: c.canvas,
      surfaceContainerLow: c.canvas,
      surfaceContainer: c.surfaceSubtle,
      surfaceContainerHigh: c.surfaceSand,
      surfaceContainerHighest: c.borderStrong,
      outline: c.borderStrong,
      outlineVariant: c.border,
      shadow: c.shadow,
      scrim: c.scrim,
    );

    final textTheme = AppTypography.buildTextTheme(c);
    final textStyles = HajiTextStyles.forBrightness(c, brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.canvas,
      fontFamily: AppTypography.bodyFontFamily,
      textTheme: textTheme,
      extensions: [c, textStyles],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: textStyles.button,
          elevation: isDark ? 0 : 1,
          shadowColor: c.shadow,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.borderStrong, width: 1.5),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: textStyles.button.copyWith(color: c.textPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accentText,
          textStyle: textStyles.button.copyWith(color: c.accentText),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: c.border, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        elevation: 6,
        shadowColor: c.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: c.border, width: 1.0),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: c.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.textSecondary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1.0,
        space: 1.0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: c.primary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: c.danger, width: 1.2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: c.textSecondary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: c.textTertiary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: c.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.onPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
