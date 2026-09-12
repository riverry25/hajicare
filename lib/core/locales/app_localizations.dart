import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_translations.dart';
import '../state/app_settings_controller.dart';

export 'app_translations.dart';

/// Legacy adapter for AppLocalizations for backwards compatibility.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = AppTranslations.supportedLocales;

  static AppLocalizations of(BuildContext context) {
    try {
      return AppLocalizations(context.read<AppSettingsController>().currentLocale);
    } catch (_) {
      return AppLocalizations(const Locale('id'));
    }
  }

  String translate(String key) => AppTranslations.translate(key, locale.languageCode);
}
