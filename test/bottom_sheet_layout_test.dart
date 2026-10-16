import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/theme/app_breakpoints.dart';
import 'package:hajicare/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Modal bottom sheet stays anchored at bottom and respects maxSheetWidth',
    (tester) async {
      // Set a tall screen (phone viewport: 400x800)
      tester.view.physicalSize = const Size(400 * 3.0, 800 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        constraints: const BoxConstraints(
                          maxWidth: AppBreakpoints.maxSheetWidth,
                        ),
                        builder: (ctx) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Container(
                                key: const ValueKey('sheet_card'),
                                height: 350,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: const Center(
                                  child: Text('Member Detail Sheet'),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet card exists
      final cardFinder = find.byKey(const ValueKey('sheet_card'));
      expect(cardFinder, findsOneWidget);

      // Verify that the card is positioned at the BOTTOM of the screen (not at the top)
      final cardRect = tester.getRect(cardFinder);
      const screenHeight = 800.0;

      // On an 800dp high screen with a 350dp card + 16dp bottom padding,
      // cardRect.bottom should be around 800 - 16 = 784dp.
      // And cardRect.top should be around 784 - 350 = 434dp.
      // It MUST be in the bottom half of the screen (top > screenHeight * 0.4).
      expect(
        cardRect.top,
        greaterThan(screenHeight * 0.4),
        reason:
            'Card should be anchored near the bottom, not floating at the top under the notch',
      );
      expect(
        cardRect.bottom,
        lessThanOrEqualTo(screenHeight),
        reason: 'Card bottom should fit within the screen',
      );
    },
  );

  testWidgets(
    'Modal bottom sheet clamps width to maxSheetWidth on tablet/desktop landscape',
    (tester) async {
      // Set wide tablet viewport: 1024x768
      tester.view.physicalSize = const Size(1024 * 2.0, 768 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        constraints: const BoxConstraints(
                          maxWidth: AppBreakpoints.maxSheetWidth,
                        ),
                        builder: (ctx) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Container(
                                key: const ValueKey('tablet_sheet_card'),
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: const Center(
                                  child: Text('Tablet Sheet'),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const ValueKey('tablet_sheet_card'));
      expect(cardFinder, findsOneWidget);

      final cardRect = tester.getRect(cardFinder);

      // Card width + 32 padding should not exceed maxSheetWidth (560dp)
      expect(
        cardRect.width,
        lessThanOrEqualTo(AppBreakpoints.maxSheetWidth),
        reason: 'Sheet width must be clamped on wide screens',
      );

      // Card should be horizontally centered on the 1024 screen:
      // screen center is 512, card center should be around 512
      final cardCenterX = cardRect.center.dx;
      expect(
        (cardCenterX - 512.0).abs(),
        lessThan(5.0),
        reason: 'Sheet should be centered horizontally on wide screens',
      );
    },
  );
}
