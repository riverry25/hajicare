import 'package:flutter/material.dart';
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

/// Centralized Provider controller for persistent user preferences:
/// - Locale (language)
/// - ThemeMode (light / dark / system)
/// - Text scale factor (0.9 / 1.0 / 1.15 / 1.3)
class AppSettingsController extends ChangeNotifier {
  static const _kLocaleKey = 'hajicare_locale';
  static const _kThemeKey = 'hajicare_theme';
  static const _kTextScaleKey = 'hajicare_text_scale';

  Locale _locale = const Locale('id');
  ThemeMode _themeMode = ThemeMode.system;
  AppTextScale _textScale = AppTextScale.normal;

  // ── Getters ─────────────────────────────────────────────────────────────────
  Locale get currentLocale => _locale;
  ThemeMode get currentThemeMode => _themeMode;
  AppTextScale get currentTextScale => _textScale;
  double get textScaleFactor => _textScale.factor;

  // ── Load from SharedPreferences ─────────────────────────────────────────────
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Language
    final savedLocale = prefs.getString(_kLocaleKey) ?? 'id';
    _locale = Locale(savedLocale);

    // Theme mode
    final savedTheme = prefs.getString(_kThemeKey) ?? 'system';
    _themeMode = _themeFromString(savedTheme);

    // Text scale
    final savedScale = prefs.getDouble(_kTextScaleKey) ?? 1.0;
    _textScale = _textScaleFromFactor(savedScale);

    notifyListeners();
  }

  // ── Setters ─────────────────────────────────────────────────────────────────
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, newLocale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, _stringFromTheme(mode));
  }

  Future<void> setTextScale(AppTextScale scale) async {
    if (_textScale == scale) return;
    _textScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTextScaleKey, scale.factor);
  }

  // ── Convenience helpers ──────────────────────────────────────────────────────
  bool get isIdLocale => _locale.languageCode == 'id';
  bool get isJvLocale => _locale.languageCode == 'jv';
  bool get isSuLocale => _locale.languageCode == 'su';
  bool get isEnLocale => _locale.languageCode == 'en';

  String get localeName {
    switch (_locale.languageCode) {
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
    switch (_themeMode) {
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
