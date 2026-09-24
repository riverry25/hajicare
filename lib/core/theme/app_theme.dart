import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Centralized Material 3 Theme Configuration for HajiCare.
/// Integrates the Islamic premium aesthetic (warm espresso, cream canvas, sand, and Mecca gold)
/// with high accessibility, large readable typography, and tactile touch targets.
class AppTheme {
  AppTheme._();

  // ── Light Theme (Warm Cream & Rich Espresso) ───────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.bodyFontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryContainer, // Deep warm espresso
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primary,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.goldPrimary,
        onTertiary: AppColors.surfaceWhite,
        tertiaryContainer: AppColors.tertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.surface,
        onSurface: AppColors.textHeading,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.canvasCream,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.textHeading,
        ),
        headlineLarge: AppTypography.displayMedium.copyWith(
          color: AppColors.textHeading,
        ),
        headlineMedium: AppTypography.titleLarge.copyWith(
          color: AppColors.textHeading,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.textHeading,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.textHeading,
        ),
        titleSmall: AppTypography.titleMedium.copyWith(
          color: AppColors.textHeading,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textBody),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.textBody,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textBody),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.textHeading,
        ),
        labelSmall: AppTypography.captionSmall.copyWith(
          color: AppColors.textBody,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.surfaceWhite,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTypography.labelLarge,
          elevation: 2,
          shadowColor: AppColors.espressoDark.withValues(alpha: 0.25),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.espressoDark,
          side: const BorderSide(color: AppColors.goldLight, width: 1.5),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.lightCardBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textHeading,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textBody,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightCardBorder,
        thickness: 1.0,
        space: 1.0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.lightCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.lightCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.primaryContainer,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textBody,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textCaption,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvasCream,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textHeading,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
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

  // ── Dark Theme (Warm Charcoal-Espresso & Desert Amber) ──────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.bodyFontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnPrimary,
        tertiary: AppColors.accentGoldStar,
        onTertiary: AppColors.darkOnPrimary,
        error: AppColors.statusDanger,
        onError: AppColors.surfaceWhite,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextHeading,
        surfaceContainerLow: AppColors.darkScaffold,
        surfaceContainer: AppColors.darkSurfaceContainer,
        surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
        surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkOutlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.darkScaffold,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.darkTextHeading,
        ),
        headlineLarge: AppTypography.displayMedium.copyWith(
          color: AppColors.darkTextHeading,
        ),
        headlineMedium: AppTypography.titleLarge.copyWith(
          color: AppColors.darkTextHeading,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.darkTextHeading,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.darkTextHeading,
        ),
        titleSmall: AppTypography.titleMedium.copyWith(
          color: AppColors.darkTextHeading,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.darkTextBody,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextBody,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.darkTextBody,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.darkTextHeading,
        ),
        labelSmall: AppTypography.captionSmall.copyWith(
          color: AppColors.darkTextBody,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTypography.labelLarge,
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.darkOutline, width: 1.5),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.darkCardBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.darkTextHeading,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextBody,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkCardBorder,
        thickness: 1.0,
        space: 1.0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.darkCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.darkCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.darkPrimary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.statusDanger,
            width: 1.2,
          ),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextBody,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkOutline,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkScaffold,
        foregroundColor: AppColors.darkTextHeading,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.darkTextHeading,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
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
