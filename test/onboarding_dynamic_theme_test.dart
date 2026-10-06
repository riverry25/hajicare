import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/theme/app_colors.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/onboarding/controllers/onboarding_controller.dart';
import 'package:hajicare/features/onboarding/screens/onboarding_screen.dart';
import 'package:hajicare/features/onboarding/widgets/onboarding_hero_banner.dart';
import 'package:hajicare/features/onboarding/widgets/onboarding_slide_accessibility.dart';
import 'package:hajicare/features/onboarding/widgets/onboarding_slide_language.dart';
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

  Widget buildTestWidget({required ThemeMode themeMode}) {
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('id', 'ID'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackWidgetsLocalizationsDelegate(),
      ],
      home: const OnboardingScreen(),
    );
  }

  group('Onboarding Dynamic Theme Tests', () {
    testWidgets(
      'Renders OnboardingScreen in Light Mode with light background',
      (tester) async {
        Get.put(AppSettingsController(), permanent: true);
        Get.put(OnboardingController(), permanent: true);

        await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.light));
        await tester.pump();

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(OnboardingSlideLanguage), findsOneWidget);
        expect(find.text('HajiCare'), findsOneWidget);

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.canvasCream);
      },
    );

    testWidgets('Renders OnboardingScreen in Dark Mode with dark background', (
      tester,
    ) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(OnboardingController(), permanent: true);

      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.dark));
      await tester.pump();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(OnboardingSlideLanguage), findsOneWidget);
      expect(find.text('HajiCare'), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.darkScaffold);
    });

    testWidgets(
      'Renders OnboardingSlideLanguage, OnboardingSlideSafety, and OnboardingSlideAccessibility in Dark Mode',
      (tester) async {
        Get.put(AppSettingsController(), permanent: true);

        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            locale: const Locale('id', 'ID'),
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
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    OnboardingSlideLanguage(),
                    OnboardingSlideSafety(),
                    OnboardingSlideAccessibility(),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingHeroBanner), findsNWidgets(3));
        expect(find.byType(OnboardingSlideLanguage), findsOneWidget);
        expect(find.byType(OnboardingSlideSafety), findsOneWidget);
        expect(find.byType(OnboardingSlideAccessibility), findsOneWidget);
      },
    );

    testWidgets(
      'Renders OnboardingSlideLanguage under 1.4x text scaling without overflow',
      (tester) async {
        Get.put(AppSettingsController(), permanent: true);
        Get.put(OnboardingController(), permanent: true);

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            locale: const Locale('id', 'ID'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              FallbackWidgetsLocalizationsDelegate(),
            ],
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.4),
                size: Size(360, 800),
              ),
              child: const Scaffold(
                body: SingleChildScrollView(child: OnboardingSlideLanguage()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingSlideLanguage), findsOneWidget);
        expect(find.text('Indonesia'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
