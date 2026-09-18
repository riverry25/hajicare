import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Text scale options for user-adjustable font size.
enum AppTextScale {
  small(0.9, 'Kecil / Small'),
  normal(1.0, 'Normal'),
  large(1.15, 'Besar / Large'),
  extraLarge(1.20, 'Ekstra Besar / XL');

  const AppTextScale(this.factor, this.label);
  final double factor;
  final String label;
}

/// Centralized GetX controller for persistent user preferences:
/// - Locale (language)
/// - ThemeMode (light / dark / system)
/// - Text scale factor (0.9 / 1.0 / 1.15 / 1.20)
class AppSettingsController extends GetxController {
  static const _kLocaleKey = 'hajicare_locale';
  static const _kThemeKey = 'hajicare_theme';
  static const _kTextScaleKey = 'hajicare_text_scale';

  final _locale = const Locale('id').obs;
  final _themeMode = ThemeMode.system.obs;
  final _textScale = AppTextScale.normal.obs;

  // ── Getters ─────────────────────────────────────────────────────────────────
  Locale get currentLocale => _locale.value;
  ThemeMode get currentThemeMode => _themeMode.value;
  AppTextScale get currentTextScale => _textScale.value;
  double get textScaleFactor => _textScale.value.factor;

  Rx<Locale> get rxLocale => _locale;
  Rx<ThemeMode> get rxThemeMode => _themeMode;
  Rx<AppTextScale> get rxTextScale => _textScale;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  // ── Load from SharedPreferences ─────────────────────────────────────────────
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Language
    final savedLocale = prefs.getString(_kLocaleKey) ?? 'id';
    _locale.value = Locale(savedLocale);

    // Theme mode
    final savedTheme = prefs.getString(_kThemeKey) ?? 'system';
    _themeMode.value = _themeFromString(savedTheme);

    // Text scale
    final savedScale = prefs.getDouble(_kTextScaleKey) ?? 1.0;
    _textScale.value = _textScaleFromFactor(savedScale);
  }

  // ── Setters ─────────────────────────────────────────────────────────────────
  Future<void> setLocale(Locale newLocale) async {
    if (_locale.value == newLocale) return;
    _locale.value = newLocale;
    if (Get.context != null) {
      Get.updateLocale(newLocale);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, newLocale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode.value == mode) return;
    _themeMode.value = mode;
    if (Get.context != null) {
      Get.changeThemeMode(mode);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, _stringFromTheme(mode));
  }

  Future<void> setTextScale(AppTextScale scale) async {
    if (_textScale.value == scale) return;
    _textScale.value = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTextScaleKey, scale.factor);
  }

  // ── Convenience helpers ──────────────────────────────────────────────────────
  bool get isIdLocale => _locale.value.languageCode == 'id';
  bool get isJvLocale => _locale.value.languageCode == 'jv';
  bool get isSuLocale => _locale.value.languageCode == 'su';
  bool get isEnLocale => _locale.value.languageCode == 'en';

  String get localeName {
    switch (_locale.value.languageCode) {
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
    switch (_themeMode.value) {
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
    if (factor <= 1.17) return AppTextScale.large;
    return AppTextScale.extraLarge;
  }
}
