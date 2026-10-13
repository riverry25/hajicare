import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/theme/theme_context.dart';

/// WCAG 2.x relative contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final schemes = <String, HajiColors>{
    'light': HajiColors.light,
    'dark': HajiColors.dark,
  };

  schemes.forEach((name, c) {
    group('HajiColors.$name contrast (WCAG)', () {
      test('textPrimary on canvas >= 7:1 (AAA)', () {
        expect(contrast(c.textPrimary, c.canvas), greaterThanOrEqualTo(7));
      });
      test('textPrimary on surface >= 7:1 (AAA)', () {
        expect(contrast(c.textPrimary, c.surface), greaterThanOrEqualTo(7));
      });
      test('textSecondary on surface >= 4.5:1', () {
        expect(contrast(c.textSecondary, c.surface), greaterThanOrEqualTo(4.5));
      });
      test('textSecondary on surfaceSand >= 4.5:1', () {
        expect(
          contrast(c.textSecondary, c.surfaceSand),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('textTertiary on canvas >= 4.5:1', () {
        expect(contrast(c.textTertiary, c.canvas), greaterThanOrEqualTo(4.5));
      });
      test('textTertiary on surfaceSubtle >= 4.5:1', () {
        expect(
          contrast(c.textTertiary, c.surfaceSubtle),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('accentText on surface >= 4.5:1', () {
        expect(contrast(c.accentText, c.surface), greaterThanOrEqualTo(4.5));
      });
      test('onPrimary on primary >= 4.5:1', () {
        expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
      });
      test('onPrimaryContainer on primaryContainer >= 4.5:1', () {
        expect(
          contrast(c.onPrimaryContainer, c.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
      });

      for (final tone in StatusTone.values) {
        test('tone($tone) readable on its container >= 4.5:1', () {
          expect(
            contrast(c.tone(tone), c.toneContainer(tone)),
            greaterThanOrEqualTo(4.5),
          );
        });
        test('tone($tone) readable on surface >= 3:1 (icons/large)', () {
          expect(contrast(c.tone(tone), c.surface), greaterThanOrEqualTo(3));
        });
        test('onTone($tone) readable on solid tone >= 4.5:1', () {
          expect(
            contrast(c.onTone(tone), c.tone(tone)),
            greaterThanOrEqualTo(4.5),
          );
        });
      }

      test('every POI category color visible on surface >= 3:1', () {
        for (final entry in c.poi.entries) {
          expect(
            contrast(entry.value, c.surface),
            greaterThanOrEqualTo(3),
            reason: 'poi ${entry.key}',
          );
        }
      });
    });
  });

  group('HajiColors anti-neon guard', () {
    test('semantic tones are muted (HSV saturation <= 0.80)', () {
      for (final c in schemes.values) {
        for (final tone in StatusTone.values) {
          final hsv = HSVColor.fromColor(c.tone(tone));
          expect(
            hsv.saturation,
            lessThanOrEqualTo(0.80),
            reason: '$tone is too saturated (neon)',
          );
        }
      }
    });
  });

  group('HajiColors ThemeExtension', () {
    test('lerp at t=0 returns light values', () {
      final r = HajiColors.light.lerp(HajiColors.dark, 0);
      expect(r.canvas, HajiColors.light.canvas);
      expect(r.textPrimary, HajiColors.light.textPrimary);
    });

    test('lerp at t=1 returns dark values', () {
      final r = HajiColors.light.lerp(HajiColors.dark, 1);
      expect(r.canvas, HajiColors.dark.canvas);
      expect(r.primary, HajiColors.dark.primary);
    });

    test('copyWith overrides a single field', () {
      final r = HajiColors.light.copyWith(canvas: const Color(0xFF000000));
      expect(r.canvas, const Color(0xFF000000));
      expect(r.surface, HajiColors.light.surface);
    });

    test('light canvas is the agreed warm white #FBF9F6', () {
      expect(HajiColors.light.canvas, const Color(0xFFFBF9F6));
      expect(HajiColors.light.surface, const Color(0xFFFFFFFF));
    });
  });

  group('ThemeContextX', () {
    testWidgets('context.hc falls back to light when no extension', (
      tester,
    ) async {
      late HajiColors resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              resolved = context.hc;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved.canvas, HajiColors.light.canvas);
    });

    testWidgets('context.hc resolves dark extension from theme', (
      tester,
    ) async {
      late HajiColors resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: const [HajiColors.dark],
          ),
          home: Builder(
            builder: (context) {
              resolved = context.hc;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved.canvas, HajiColors.dark.canvas);
    });
  });
}
