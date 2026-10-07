import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/dashboard/bindings/dashboard_binding.dart';
import 'package:hajicare/features/dashboard/screens/dashboard_pendamping_screen.dart';
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

  testWidgets(
    'DashboardPendamping renders broadcast header button & Text to Sign chip',
    (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id', 'ID'),
          supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: const DashboardPendampingScreen(),
        ),
      );
      await tester.pump();

      // Broadcast button in header
      expect(find.byIcon(Icons.campaign_rounded), findsWidgets);
      // Text to sign chip
      expect(find.byIcon(Icons.sign_language_rounded), findsOneWidget);
      expect(find.text('Text to Sign'), findsOneWidget);
      expect(find.text('Bahasa Isyarat'), findsOneWidget);
    },
  );
}
