import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/dashboard/widgets/mini_sparkline_button.dart';

void main() {
  group('MiniSparklineButton Widget Tests', () {
    testWidgets('Renders MiniSparklineButton with wave painter and tooltip', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiniSparklineButton(
                tooltip: 'Perbarui Statistik Jamaah',
                onSync: () async {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MiniSparklineButton), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('Tapping MiniSparklineButton triggers onSync callback', (
      tester,
    ) async {
      bool synced = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiniSparklineButton(
                onSync: () async {
                  synced = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MiniSparklineButton));
      await tester.pump();

      expect(synced, isTrue);

      // Settle animations
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
    });
  });
}
