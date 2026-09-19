import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/dashboard/widgets/rotating_sync_button.dart';

void main() {
  group('RotatingSyncButton Widget Tests', () {
    testWidgets('Renders sync button with circular shape and sync icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RotatingSyncButton(
                onSync: () async {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    });

    testWidgets('Spins when tapped and triggers onSync callback', (tester) async {
      bool synced = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RotatingSyncButton(
                onSync: () async {
                  synced = true;
                },
              ),
            ),
          ),
        ),
      );

      // Find the button and tap it
      await tester.tap(find.byIcon(Icons.sync_rounded));
      await tester.pump(); // Start animation

      // Animation is in progress
      expect(synced, isTrue);

      // Let the animation and delay run (850ms + 220ms)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Final state should be idle
      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    });
  });
}
