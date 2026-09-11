import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hajicare/core/locales/app_translations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  group('AppSettingsController & AppTranslations Tests', () {
    test('AppTranslations contains 4 supported languages with valid dictionaries', () {
      final translations = AppTranslations();
      final keys = translations.keys;

      expect(keys.containsKey('id'), isTrue);
      expect(keys.containsKey('jv'), isTrue);
      expect(keys.containsKey('su'), isTrue);
      expect(keys.containsKey('en'), isTrue);

      // Verify appName exists in all 4 dictionaries
      expect(keys['id']!['appName'], 'HajiCare');
      expect(keys['jv']!['appName'], 'HajiCare');
      expect(keys['su']!['appName'], 'HajiCare');
      expect(keys['en']!['appName'], 'HajiCare');
    });

    test('AppSettingsController loads default values correctly', () async {
      final settings = Get.put(AppSettingsController());
      await settings.loadSettings();

      expect(settings.currentLocale.languageCode, 'id');
      expect(settings.currentThemeMode, ThemeMode.system);
      expect(settings.currentTextScale, AppTextScale.normal);
      expect(settings.textScaleFactor, 1.0);
    });

    test('AppSettingsController updates and persists locale', () async {
      final settings = Get.put(AppSettingsController());
      await settings.loadSettings();

      await settings.setLocale(const Locale('en'));
      expect(settings.currentLocale.languageCode, 'en');
      expect(settings.isEnLocale, isTrue);
      expect(settings.localeName, 'English');

      await settings.setLocale(const Locale('jv'));
      expect(settings.currentLocale.languageCode, 'jv');
      expect(settings.isJvLocale, isTrue);
      expect(settings.localeName, 'Basa Jawi');
    });

    test('AppSettingsController updates theme mode and text scale', () async {
      final settings = Get.put(AppSettingsController());
      await settings.loadSettings();

      await settings.setThemeMode(ThemeMode.dark);
      expect(settings.currentThemeMode, ThemeMode.dark);
      expect(settings.themeModeName, 'Mode Gelap');

      await settings.setTextScale(AppTextScale.extraLarge);
      expect(settings.currentTextScale, AppTextScale.extraLarge);
      expect(settings.textScaleFactor, 1.3);
    });
  });

  group('HajiCareController Tests', () {
    test('HajiCareController initializes role and jamaah list', () {
      final controller = Get.put(HajiCareController());

      expect(controller.role, UserRole.jamaah);
      expect(controller.jamaahList.length, 2);
      expect(controller.self.name, contains('Ahmad Dahlan'));
      expect(controller.anySosActive, isFalse);
    });

    test('HajiCareController updates user role', () {
      final controller = Get.put(HajiCareController());

      controller.setRole(UserRole.pendamping);
      expect(controller.role, UserRole.pendamping);

      controller.setRole(UserRole.jamaah);
      expect(controller.role, UserRole.jamaah);
    });

    test('HajiCareController triggers and dismisses SOS', () {
      final controller = Get.put(HajiCareController());

      controller.triggerSos();
      expect(controller.anySosActive, isTrue);

      controller.dismissSos('j1');
      expect(controller.anySosActive, isFalse);
    });
  });

  group('PrayerTimesController Tests', () {
    test('PrayerTimesController initializes prayer schedule and countdown', () {
      final controller = Get.put(PrayerTimesController());

      expect(controller.prayers.length, 6);
      expect(controller.nextPrayerName.value, isNotEmpty);
      expect(controller.nextPrayerTime.value, isNotEmpty);
      expect(controller.countdownText.value, isNotEmpty);
      expect(controller.compassHeading.value, greaterThan(0));
    });
  });
}
