import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../state/app_settings_controller.dart';
import 'id.dart';
import 'jv.dart';
import 'su.dart';
import 'en.dart';

class AppTranslations extends Translations {
  static const List<Locale> supportedLocales = [
    Locale('id'),
    Locale('en'),
    Locale('jv'),
    Locale('su'),
  ];

  static const fallbackLocale = Locale('id');

  static final Map<String, Map<String, String>> translationKeys = {
    'id': idTranslations,
    'jv': jvTranslations,
    'su': suTranslations,
    'en': enTranslations,
  };

  @override
  Map<String, Map<String, String>> get keys => translationKeys;

  static String translate(
    String key,
    String langCode, [
    Map<String, dynamic>? params,
  ]) {
    var text =
        translationKeys[langCode]?[key] ??
        translationKeys[fallbackLocale.languageCode]?[key] ??
        key;
    if (params != null && params.isNotEmpty) {
      for (final entry in params.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value.toString());
      }
    }
    return text;
  }

  static String tr(String key, [Map<String, dynamic>? params]) {
    try {
      final lang = Get.isRegistered<AppSettingsController>()
          ? Get.find<AppSettingsController>().currentLocale.languageCode
          : fallbackLocale.languageCode;
      return translate(key, lang, params);
    } catch (_) {
      return translate(key, fallbackLocale.languageCode, params);
    }
  }
}

/// Compatibility extension so that widgets using `context.tr('key')` continue to work seamlessly.
extension TrContextExtension on BuildContext {
  String tr(String key, [Map<String, dynamic>? params]) {
    try {
      // Accessing Localizations.localeOf(this) registers this element
      // as an InheritedWidget dependent so that any locale change
      // automatically triggers a rebuild.
      final loc = Localizations.localeOf(this);
      return AppTranslations.translate(key, loc.languageCode, params);
    } catch (_) {
      final lang = Get.isRegistered<AppSettingsController>()
          ? Get.find<AppSettingsController>().currentLocale.languageCode
          : 'id';
      return AppTranslations.translate(key, lang, params);
    }
  }
}
