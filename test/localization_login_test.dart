import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/widgets/app_text_field.dart';
import 'package:hajicare/features/auth/bindings/login_binding.dart';
import 'package:hajicare/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({required Locale locale, required Widget child}) {
  return GetMaterialApp(
    locale: locale,
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
    localeResolutionCallback: (locale, supportedLocales) {
      for (final supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode == locale?.languageCode) {
          return supportedLocale;
        }
      }
      return AppTranslations.fallbackLocale;
    },
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('MaterialLocalizations Availability Tests', () {
    for (final langCode in ['id', 'en', 'jv', 'su']) {
      testWidgets('MaterialLocalizations is available for $langCode', (
        tester,
      ) async {
        final loc = Locale(langCode);
        MaterialLocalizations? foundMatLoc;

        await tester.pumpWidget(
          _buildTestApp(
            locale: loc,
            child: Builder(
              builder: (context) {
                foundMatLoc = MaterialLocalizations.of(context);
                return Scaffold(body: Text('Lang: $langCode'));
              },
            ),
          ),
        );

        expect(foundMatLoc, isNotNull);
      });
    }
  });

  group('LoginScreen TextFormField Rendering Tests', () {
    for (final langCode in ['id', 'en', 'jv', 'su']) {
      testWidgets(
        'LoginScreen renders AppTextField without error for $langCode',
        (tester) async {
          final loc = Locale(langCode);
          final settings = Get.put(AppSettingsController(), permanent: true);
          await settings.setLocale(loc);
          LoginBinding().dependencies();

          await tester.pumpWidget(
            _buildTestApp(locale: loc, child: const LoginScreen()),
          );

          await tester.pump();

          expect(find.byType(AppTextField), findsWidgets);
          expect(find.byType(TextFormField), findsWidgets);
        },
      );
    }

    testWidgets(
      'LoginScreen header does not overflow on narrow screens with large text scale',
      (tester) async {
        tester.view.physicalSize = const Size(340 * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final loc = const Locale('id');
        final settings = Get.put(AppSettingsController(), permanent: true);
        await settings.setLocale(loc);
        LoginBinding().dependencies();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(340, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: _buildTestApp(locale: loc, child: const LoginScreen()),
          ),
        );

        await tester.pump();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
