import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Text scale options for user-adjustable font size.
enum AppTextScale {
  small(0.9, 'Kecil / Small'),
  normal(1.0, 'Normal'),
  large(1.15, 'Besar / Large'),
  extraLarge(1.3, 'Ekstra Besar / XL');

  const AppTextScale(this.factor, this.label);
  final double factor;
  final String label;
}

/// Centralized GetX controller for persistent user preferences:
/// - Locale (language)
/// - ThemeMode (light / dark / system)
/// - Text scale factor (0.9 / 1.0 / 1.15 / 1.3)
///
/// Registered once via `Get.put(AppSettingsController(), permanent: true)` in `main()`.
class AppSettingsController extends GetxController {
  static const _kLocaleKey = 'hajicare_locale';
  static const _kThemeKey = 'hajicare_theme';
  static const _kTextScaleKey = 'hajicare_text_scale';

  // ── Observables ─────────────────────────────────────────────────────────────
  final Rx<Locale> locale = const Locale('id').obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final Rx<AppTextScale> textScale = AppTextScale.normal.obs;

  // ── Getters ─────────────────────────────────────────────────────────────────
  Locale get currentLocale => locale.value;
  ThemeMode get currentThemeMode => themeMode.value;
  AppTextScale get currentTextScale => textScale.value;
  double get textScaleFactor => textScale.value.factor;

  // ── Load from SharedPreferences ─────────────────────────────────────────────
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Language
    final savedLocale = prefs.getString(_kLocaleKey) ?? 'id';
    locale.value = Locale(savedLocale);

    // Theme mode
    final savedTheme = prefs.getString(_kThemeKey) ?? 'system';
    themeMode.value = _themeFromString(savedTheme);

    // Text scale
    final savedScale = prefs.getDouble(_kTextScaleKey) ?? 1.0;
    textScale.value = _textScaleFromFactor(savedScale);

    // Apply to GetX if UI is attached
    if (Get.context != null) {
      Get.updateLocale(locale.value);
      Get.changeThemeMode(themeMode.value);
    }
  }

  // ── Setters ─────────────────────────────────────────────────────────────────
  Future<void> setLocale(Locale newLocale) async {
    if (locale.value == newLocale) return;
    locale.value = newLocale;
    if (Get.context != null) {
      Get.updateLocale(newLocale);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, newLocale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    if (Get.context != null) {
      Get.changeThemeMode(mode);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, _stringFromTheme(mode));
  }

  Future<void> setTextScale(AppTextScale scale) async {
    if (textScale.value == scale) return;
    textScale.value = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTextScaleKey, scale.factor);
  }

  // ── Convenience helpers ──────────────────────────────────────────────────────
  bool get isIdLocale => locale.value.languageCode == 'id';
  bool get isJvLocale => locale.value.languageCode == 'jv';
  bool get isSuLocale => locale.value.languageCode == 'su';
  bool get isEnLocale => locale.value.languageCode == 'en';

  String get localeName {
    switch (locale.value.languageCode) {
      case 'jv':
        return 'Basa Jawi';
      case 'su':
        return 'Basa Sunda';
      case 'en':
        return 'English';
      default:
        return 'Bahasa Indonesia';
    }
  }

  String get themeModeName {
    switch (themeMode.value) {
      case ThemeMode.light:
        return 'Mode Terang';
      case ThemeMode.dark:
        return 'Mode Gelap';
      default:
        return 'Otomatis (Sistem)';
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────
  static String _stringFromTheme(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  static ThemeMode _themeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static AppTextScale _textScaleFromFactor(double factor) {
    if (factor <= 0.92) return AppTextScale.small;
    if (factor <= 1.07) return AppTextScale.normal;
    if (factor <= 1.22) return AppTextScale.large;
    return AppTextScale.extraLarge;
  }
}
