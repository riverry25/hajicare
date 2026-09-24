import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/core/theme/app_typography.dart';
import 'package:hajicare/features/hajj_dua/presentation/hajj_dua_typography.dart';

void main() {
  group('AppTypography Centralized Service Tests', () {
    test('font family constants match HajjDuaTypography benchmark', () {
      expect(AppTypography.headingFontFamily, 'Poppins');
      expect(AppTypography.bodyFontFamily, 'Montserrat');
      expect(AppTypography.arabicFontFamily, 'NotoNaskhArabic');

      expect(
        HajjDuaTypography.headingFontFamily,
        AppTypography.headingFontFamily,
      );
      expect(HajjDuaTypography.bodyFontFamily, AppTypography.bodyFontFamily);
      expect(
        HajjDuaTypography.arabicFontFamily,
        AppTypography.arabicFontFamily,
      );
    });

    test('heading and display scales use Poppins', () {
      expect(AppTypography.heroNumberLarge.fontFamily, 'Poppins');
      expect(AppTypography.displayLarge.fontFamily, 'Poppins');
      expect(AppTypography.displayMedium.fontFamily, 'Poppins');
      expect(AppTypography.titleLarge.fontFamily, 'Poppins');
      expect(AppTypography.titleMedium.fontFamily, 'Poppins');
      expect(AppTypography.button.fontFamily, 'Poppins');
      expect(AppTypography.labelLarge.fontFamily, 'Poppins');
    });

    test('body and caption scales use Montserrat', () {
      expect(AppTypography.bodyLarge.fontFamily, 'Montserrat');
      expect(AppTypography.bodyMedium.fontFamily, 'Montserrat');
      expect(AppTypography.bodySmall.fontFamily, 'Montserrat');
      expect(AppTypography.caption.fontFamily, 'Montserrat');
      expect(AppTypography.captionSmall.fontFamily, 'Montserrat');
    });

    test('arabic scales use NotoNaskhArabic', () {
      expect(AppTypography.arabicLarge.fontFamily, 'NotoNaskhArabic');
      expect(AppTypography.arabic.fontFamily, 'NotoNaskhArabic');
      expect(AppTypography.arabicMedium.fontFamily, 'NotoNaskhArabic');
      expect(AppTypography.arabicSmall.fontFamily, 'NotoNaskhArabic');
    });

    test(
      'dynamic generators create customizable styles with correct font families',
      () {
        final customHeading = AppTypography.heading(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.amber,
        );
        expect(customHeading.fontFamily, 'Poppins');
        expect(customHeading.fontSize, 20);
        expect(customHeading.fontWeight, FontWeight.w800);
        expect(customHeading.color, Colors.amber);

        final customBody = AppTypography.bodyText(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        );
        expect(customBody.fontFamily, 'Montserrat');
        expect(customBody.fontSize, 15);
        expect(customBody.fontWeight, FontWeight.w500);
        expect(customBody.color, Colors.black87);

        final customArabic = AppTypography.arabicText(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: Colors.green,
        );
        expect(customArabic.fontFamily, 'NotoNaskhArabic');
        expect(customArabic.fontSize, 26);
        expect(customArabic.fontWeight, FontWeight.w600);
        expect(customArabic.color, Colors.green);
      },
    );

    test(
      'AppTheme registers AppTypography font families in light and dark themes',
      () {
        final light = AppTheme.lightTheme;
        final dark = AppTheme.darkTheme;

        expect(light.textTheme.bodyLarge?.fontFamily, 'Montserrat');
        expect(light.textTheme.displayLarge?.fontFamily, 'Poppins');
        expect(light.textTheme.titleLarge?.fontFamily, 'Poppins');

        expect(dark.textTheme.bodyLarge?.fontFamily, 'Montserrat');
        expect(dark.textTheme.displayLarge?.fontFamily, 'Poppins');
        expect(dark.textTheme.titleLarge?.fontFamily, 'Poppins');
      },
    );
  });
}
