import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/core/widgets/bottom_nav_bar.dart';
import 'package:hajicare/features/prayer/bindings/prayer_binding.dart';
import 'package:hajicare/features/prayer/screens/prayer_times_screen.dart';
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

  group('PrayerTimesScreen and BottomNavBar Dark/Light Dynamic Theme Tests', () {
    testWidgets('Renders PrayerTimesScreen in Light Mode without error', (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      PrayerBinding().dependencies();

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: const PrayerTimesScreen(showBottomNav: true),
        ),
      );

      await tester.pump();
      expect(find.byType(HajiCareBottomNavBar), findsOneWidget);
      expect(find.byType(PrayerTimesScreen), findsOneWidget);
    });

    testWidgets('Renders PrayerTimesScreen in Dark Mode without error', (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      PrayerBinding().dependencies();

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
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
          home: const PrayerTimesScreen(showBottomNav: true),
        ),
      );

      await tester.pump();
      expect(find.byType(HajiCareBottomNavBar), findsOneWidget);
      expect(find.byType(PrayerTimesScreen), findsOneWidget);
    });
  });
}
