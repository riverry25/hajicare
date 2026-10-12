import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/core/theme/app_typography.dart';
import 'package:hajicare/core/theme/haji_colors.dart';
import 'package:hajicare/core/theme/theme_context.dart';
import 'package:hajicare/features/dashboard/presentation/dashboard_typography.dart';
import 'package:hajicare/features/hajj_dua/presentation/hajj_dua_typography.dart';

void main() {
  group('AppTheme light & dark integration', () {
    testWidgets('lightTheme registers HajiColors.light and HajiTextStyles', (
      tester,
    ) async {
      late HajiColors resolvedColors;
      late HajiTextStyles resolvedStyles;
      late HajiSafeTextTheme resolvedText;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              resolvedColors = context.hc;
              resolvedStyles = context.textX;
              resolvedText = context.text;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedColors.canvas, const Color(0xFFFBF9F6));
      expect(resolvedColors.surface, const Color(0xFFFFFFFF));
      expect(resolvedStyles.arabic.fontFamily, 'NotoNaskhArabic');
      expect(resolvedText.bodyMedium?.fontFamily, 'Montserrat');
      expect(resolvedText.titleMedium?.fontFamily, 'Poppins');
      expect(resolvedText.bodyMedium?.color, resolvedColors.textSecondary);
      expect(resolvedText.titleMedium?.color, resolvedColors.textPrimary);
    });

    testWidgets('darkTheme registers HajiColors.dark and HajiTextStyles', (
      tester,
    ) async {
      late HajiColors resolvedColors;
      late HajiTextStyles resolvedStyles;
      late HajiSafeTextTheme resolvedText;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              resolvedColors = context.hc;
              resolvedStyles = context.textX;
              resolvedText = context.text;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedColors.canvas, const Color(0xFF15100C));
      expect(resolvedColors.surface, const Color(0xFF1F1813));
      expect(resolvedStyles.arabic.fontFamily, 'NotoNaskhArabic');
      expect(resolvedText.bodyMedium?.fontFamily, 'Montserrat');
      expect(resolvedText.titleMedium?.fontFamily, 'Poppins');
      expect(resolvedText.bodyMedium?.color, resolvedColors.textSecondary);
      expect(resolvedText.titleMedium?.color, resolvedColors.textPrimary);
    });

    test('lightTheme scaffoldBackgroundColor matches HajiColors.light.canvas', () {
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        HajiColors.light.canvas,
      );
    });

    test('darkTheme scaffoldBackgroundColor matches HajiColors.dark.canvas', () {
      expect(
        AppTheme.darkTheme.scaffoldBackgroundColor,
        HajiColors.dark.canvas,
      );
    });
  });

  group('Typography unification without drift', () {
    test('DashboardTypography aliases match AppTypography', () {
      expect(
        DashboardTypography.headingFontFamily,
        AppTypography.headingFontFamily,
      );
      expect(DashboardTypography.bodyFontFamily, AppTypography.bodyFontFamily);
      expect(DashboardTypography.titleMedium.fontSize, AppTypography.titleMedium.fontSize);
      expect(DashboardTypography.bodyMedium.fontSize, AppTypography.bodyMedium.fontSize);
    });

    test('HajjDuaTypography aliases match AppTypography', () {
      expect(
        HajjDuaTypography.headingFontFamily,
        AppTypography.headingFontFamily,
      );
      expect(HajjDuaTypography.bodyFontFamily, AppTypography.bodyFontFamily);
      expect(HajjDuaTypography.arabicFontFamily, AppTypography.arabicFontFamily);
    });
  });
}
