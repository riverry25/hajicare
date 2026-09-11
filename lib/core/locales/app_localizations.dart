import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_translations.dart';

export 'app_translations.dart';

/// Legacy adapter for AppLocalizations for backwards compatibility.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = AppTranslations.supportedLocales;

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(Get.locale ?? const Locale('id'));
  }

  String translate(String key) => key.tr;
}
