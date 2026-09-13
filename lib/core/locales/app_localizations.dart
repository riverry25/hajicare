import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_translations.dart';
import '../state/app_settings_controller.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

export 'app_translations.dart';

/// Legacy adapter for AppLocalizations for backwards compatibility.
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = AppTranslations.supportedLocales;
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        _fallback();
  }

  static AppLocalizations _fallback() {
    try {
      final loc = Get.isRegistered<AppSettingsController>()
          ? Get.find<AppSettingsController>().currentLocale
          : const Locale('id');
      return AppLocalizations(loc);
    } catch (_) {
      return const AppLocalizations(Locale('id'));
    }
  }

  String translate(String key) =>
      AppTranslations.translate(key, locale.languageCode);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppTranslations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Fallback delegate for MaterialLocalizations for locales not natively
/// supported by [GlobalMaterialLocalizations] (e.g. Javanese 'jv', Sundanese 'su').
/// Falls back to Indonesian ('id') Material localizations.
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      !GlobalMaterialLocalizations.delegate.isSupported(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(const Locale('id'));
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

/// Fallback delegate for CupertinoLocalizations for locales not natively
/// supported by [GlobalCupertinoLocalizations] (e.g. Javanese 'jv', Sundanese 'su').
/// Falls back to Indonesian ('id') Cupertino localizations.
class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      !GlobalCupertinoLocalizations.delegate.isSupported(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return GlobalCupertinoLocalizations.delegate.load(const Locale('id'));
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

/// Fallback delegate for WidgetsLocalizations for locales not natively
/// supported by [GlobalWidgetsLocalizations] (e.g. Javanese 'jv', Sundanese 'su').
/// Falls back to Indonesian ('id') Widgets localizations.
class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      !GlobalWidgetsLocalizations.delegate.isSupported(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return GlobalWidgetsLocalizations.delegate.load(const Locale('id'));
  }

  @override
  bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
}
