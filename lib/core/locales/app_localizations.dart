import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      final loc = Get.isRegistered<AppSettingsController>()
          ? Get.find<AppSettingsController>().currentLocale
          : const Locale('id');
      return AppLocalizations(loc);
    } catch (_) {
      return AppLocalizations(const Locale('id'));
    }
  }

  String translate(String key) => AppTranslations.translate(key, locale.languageCode);
}
