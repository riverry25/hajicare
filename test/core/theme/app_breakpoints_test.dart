import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/theme/app_breakpoints.dart';
import 'package:hajicare/core/theme/app_spacing.dart';

void main() {
  group('AppBreakpoints window size classification', () {
    test('classifies width < 600 as compact', () {
      expect(AppBreakpoints.of(360), WindowSize.compact);
      expect(AppBreakpoints.of(599), WindowSize.compact);
    });

    test('classifies width 600..839 as medium (foldable / portrait tablet)', () {
      expect(AppBreakpoints.of(600), WindowSize.medium);
      expect(AppBreakpoints.of(839), WindowSize.medium);
    });

    test('classifies width >= 840 as expanded (landscape tablet / desktop)', () {
      expect(AppBreakpoints.of(840), WindowSize.expanded);
      expect(AppBreakpoints.of(1200), WindowSize.expanded);
    });
  });

  group('ResponsiveCenter layout constraints', () {
    testWidgets('constrains child width on expanded screens (1200dp)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCenter(
              child: SizedBox(key: Key('content'), width: double.infinity, height: 100),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byKey(const Key('content')));
      expect(size.width, lessThanOrEqualTo(AppBreakpoints.maxContentWidth));
    });
  });

  group('AppSpacing on-grid tokens', () {
    test('on-grid spacing scale constants are multiples of 4', () {
      for (final s in [
        AppSpacing.s4,
        AppSpacing.s8,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s20,
        AppSpacing.s24,
        AppSpacing.s32,
        AppSpacing.s40,
        AppSpacing.s48,
      ]) {
        expect(s % 4.0, 0.0);
      }
    });
  });
}
