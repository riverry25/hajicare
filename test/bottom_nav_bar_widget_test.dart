import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/core/widgets/bottom_nav_bar.dart';
import 'package:hajicare/features/dashboard/controllers/dashboard_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('HajiCareBottomNavBar Widget Tests', () {
    testWidgets('Renders all 4 navigation tabs and center mic action', (
      tester,
    ) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: Scaffold(
            bottomNavigationBar: HajiCareBottomNavBar(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check all nav items exist
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.near_me_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      // Tap on map tab (index 1)
      await tester.tap(find.byIcon(Icons.near_me_rounded));
      expect(tappedIndex, equals(1));

      // Tap on prayer tab (index 2)
      await tester.tap(find.byIcon(Icons.schedule_rounded));
      expect(tappedIndex, equals(2));

      // Tap on profile tab (index 3)
      await tester.tap(find.byIcon(Icons.person_rounded));
      expect(tappedIndex, equals(3));
    });

    testWidgets('Renders in Dark Mode without layout overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: Scaffold(
            bottomNavigationBar: HajiCareBottomNavBar(
              currentIndex: 1,
              onTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HajiCareBottomNavBar), findsOneWidget);
    });

    testWidgets(
      'Navigates and switches DashboardController tab when onTap is null (e.g. Map screen)',
      (tester) async {
        final dashCtrl = Get.put(DashboardController());
        Get.put(HajiCareController());

        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              FallbackWidgetsLocalizationsDelegate(),
            ],
            home: const Scaffold(
              bottomNavigationBar: HajiCareBottomNavBar(
                currentIndex: 1, // On Map screen
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap Jadwal Salat (tab 2)
        await tester.tap(find.byIcon(Icons.schedule_rounded));
        await tester.pump();
        expect(dashCtrl.currentIndex.value, equals(2));

        // Tap Profil (tab 3)
        await tester.tap(find.byIcon(Icons.person_rounded));
        await tester.pump();
        expect(dashCtrl.currentIndex.value, equals(3));

        // Tap Beranda (tab 0)
        await tester.tap(find.byIcon(Icons.home_rounded));
        await tester.pump();
        expect(dashCtrl.currentIndex.value, equals(0));
      },
    );

    testWidgets(
      'HajiCareBottomNavBar has compact height and does NOT block body tap or scroll gestures',
      (tester) async {
        bool bodyButtonTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              FallbackWidgetsLocalizationsDelegate(),
            ],
            home: Scaffold(
              extendBody: true,
              body: ListView(
                children: [
                  const SizedBox(height: 100),
                  ElevatedButton(
                    key: const Key('body_button'),
                    onPressed: () => bodyButtonTapped = true,
                    child: const Text('Body Action'),
                  ),
                  const SizedBox(height: 800),
                  const Text('Bottom Element'),
                ],
              ),
              bottomNavigationBar: const HajiCareBottomNavBar(currentIndex: 0),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify height is compact (less than 150dp), NOT full-screen (800dp+)
        final navBarFinder = find.byType(HajiCareBottomNavBar);
        final navBarSize = tester.getSize(navBarFinder);
        expect(navBarSize.height, lessThan(150.0));

        // 2. Verify button on body can be tapped
        await tester.tap(find.byKey(const Key('body_button')));
        await tester.pump();
        expect(bodyButtonTapped, isTrue);

        // 3. Verify list can be scrolled
        await tester.scrollUntilVisible(find.text('Bottom Element'), 200);
        expect(find.text('Bottom Element'), findsOneWidget);
      },
    );
  });
}
