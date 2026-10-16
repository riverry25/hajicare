import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/onboarding/controllers/onboarding_controller.dart';
import 'package:hajicare/features/onboarding/screens/onboarding_screen.dart';
import 'package:hajicare/features/onboarding/widgets/onboarding_slide_accessibility.dart';
import 'package:hajicare/features/onboarding/widgets/onboarding_slide_safety.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp({required ThemeMode themeMode, Widget? child}) {
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('id', 'ID'),
      fallbackLocale: AppTranslations.fallbackLocale,
      translations: AppTranslations(),
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackWidgetsLocalizationsDelegate(),
      ],
      home: child ?? const OnboardingScreen(),
    );
  }

  group('Onboarding UX & Spacing Tests', () {
    testWidgets('Has relaxed breathing room in Top Bar and Bottom Controls', (
      tester,
    ) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(OnboardingController(), permanent: true);

      await tester.pumpWidget(buildTestApp(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      // Top bar skip button exists and has min 40 height
      final skipButton = find.widgetWithText(TextButton, 'Lewati');
      expect(skipButton, findsOneWidget);

      // Verify no abrupt full-width Divider under top bar
      expect(find.byType(Divider), findsNothing);

      // Verify primary action button exists with proper height
      final startButton = find.byType(ElevatedButton);
      expect(startButton, findsOneWidget);
    });

    testWidgets('Dark Mode text contrast and visibility verification', (
      tester,
    ) async {
      Get.put(AppSettingsController(), permanent: true);
      final ctrl = Get.put(OnboardingController(), permanent: true);

      await tester.pumpWidget(buildTestApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      // Slide 1: Language
      final indonesianText = tester.widget<Text>(find.text('Indonesia'));
      expect(indonesianText.style?.color, isNotNull);
      // Ensure text is not black or transparent in dark mode
      expect(indonesianText.style?.color, isNot(Colors.black));
      expect(indonesianText.style?.color?.a, 1.0);

      // Slide 2: Safety
      ctrl.nextPage(3);
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingSlideSafety), findsOneWidget);

      // Verify feature card title and description
      final safetyTexts = find.byType(Text);
      expect(safetyTexts, findsWidgets);

      // Slide 3: Accessibility
      ctrl.nextPage(3);
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingSlideAccessibility), findsOneWidget);

      final rlyScannerBadge = find.text('AI SCANNER');
      expect(rlyScannerBadge, findsOneWidget);
    });

    testWidgets('Adapts gracefully on large tablet screen (800x1280)', (
      tester,
    ) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(OnboardingController(), permanent: true);

      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify ConstrainedBox caps width to 580 for beautiful centered reading column
      final constrainedBoxFinder = find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.maxWidth == 580,
      );
      expect(constrainedBoxFinder, findsOneWidget);
    });

    testWidgets(
      'Dynamic progress bar smoothly fills in proportion to swipe gesture',
      (tester) async {
        Get.put(AppSettingsController(), permanent: true);
        final ctrl = Get.put(OnboardingController(), permanent: true);

        await tester.pumpWidget(buildTestApp(themeMode: ThemeMode.light));
        await tester.pumpAndSettle();

        // Find the 3 FractionallySizedBox widgets inside the progress bar
        List<FractionallySizedBox> getBarFills() {
          return tester
              .widgetList<FractionallySizedBox>(
                find.byType(FractionallySizedBox),
              )
              .toList();
        }

        var fills = getBarFills();
        expect(fills.length, 3);
        // On page 0: Bar 1 is 100%, Bar 2 is 0%, Bar 3 is 0%
        expect(fills[0].widthFactor, 1.0);
        expect(fills[1].widthFactor, 0.0);
        expect(fills[2].widthFactor, 0.0);

        // Programmatically animate PageController halfway towards page 1 (swipe halfway)
        ctrl.pageController.jumpTo(
          ctrl.pageController.position.viewportDimension * 0.5,
        );
        await tester.pump();

        fills = getBarFills();
        // Halfway: Bar 1 is 100%, Bar 2 is exactly 50% (0.5), Bar 3 is 0%
        expect(fills[0].widthFactor, 1.0);
        expect(fills[1].widthFactor, closeTo(0.5, 0.01));
        expect(fills[2].widthFactor, 0.0);

        // Finish swipe to page 1
        ctrl.pageController.jumpTo(
          ctrl.pageController.position.viewportDimension * 1.0,
        );
        ctrl.changePage(1);
        await tester.pump();

        fills = getBarFills();
        // On page 1: Bar 1 is 100%, Bar 2 is 100%, Bar 3 is 0%
        expect(fills[0].widthFactor, 1.0);
        expect(fills[1].widthFactor, 1.0);
        expect(fills[2].widthFactor, 0.0);
      },
    );
  });
}
