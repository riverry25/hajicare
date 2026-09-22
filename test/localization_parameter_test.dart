import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
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

  group('Parameterized Translation Tests', () {
    test('interpolates single parameter correctly in Indonesian', () {
      final res = AppTranslations.translate('room.syncTime', 'id', {
        'time': '12:30',
      });
      expect(res, equals('Sinkron: 12:30'));
    });

    test('interpolates single parameter correctly in English', () {
      final res = AppTranslations.translate('room.syncTime', 'en', {
        'time': '12:30',
      });
      expect(res, equals('Synced: 12:30'));
    });

    test('interpolates parameter in Javanese and Sundanese', () {
      final resJv = AppTranslations.translate('room.removeConfirmMsg', 'jv', {
        'name': 'Budi',
      });
      expect(resJv, contains('Budi'));

      final resSu = AppTranslations.translate('room.removeConfirmMsg', 'su', {
        'name': 'Budi',
      });
      expect(resSu, contains('Budi'));
    });

    test('safe fallback when key is not found in requested language', () {
      final res = AppTranslations.translate('non_existent_key_xyz', 'jv');
      expect(res, equals('non_existent_key_xyz'));
    });
  });

  group('Reactive Language Switching Widget Test', () {
    testWidgets('context.tr updates reactively when locale changes', (
      tester,
    ) async {
      final settings = Get.put(AppSettingsController(), permanent: true);
      await settings.setLocale(const Locale('id'));

      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('id'),
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
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Text(context.tr('common.statusSafe'));
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Aman & Resmi'), findsOneWidget);

      // Switch language to English via GetX updateLocale
      Get.updateLocale(const Locale('en'));
      await tester.pumpAndSettle();

      expect(find.text('Safe & Official'), findsOneWidget);

      // Switch language to Javanese
      Get.updateLocale(const Locale('jv'));
      await tester.pumpAndSettle();

      expect(find.text('Aman & Resmi'), findsOneWidget);
    });
  });
}
