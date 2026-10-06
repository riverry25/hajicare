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
    'DashboardPendamping renders Text to Sign header button & chip with sign_language icon',
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

      // Should find the sign language icon in both header and metric chip
      expect(find.byIcon(Icons.sign_language_rounded), findsNWidgets(2));
      expect(find.text('Text to Sign'), findsOneWidget);
      expect(find.text('Bahasa Isyarat'), findsOneWidget);
    },
  );
}
