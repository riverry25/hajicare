import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/map/bindings/map_binding.dart';
import 'package:hajicare/features/map/screens/interactive_map_screen.dart';
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

  group('InteractiveMapScreen Widget Rendering Tests', () {
    testWidgets('Renders InteractiveMapScreen in Light Mode without error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      MapBinding().dependencies();

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
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: const InteractiveMapScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(InteractiveMapScreen), findsOneWidget);
      expect(find.text('Pelacakan Aktif'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
    });

    testWidgets('Renders InteractiveMapScreen in Dark Mode without error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      MapBinding().dependencies();

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
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: const InteractiveMapScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(InteractiveMapScreen), findsOneWidget);
      expect(find.text('Pelacakan Aktif'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
    });
  });
}
