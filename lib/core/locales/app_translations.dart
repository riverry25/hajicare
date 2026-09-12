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

  static const Map<String, Map<String, String>> translationKeys = {
    'id': idTranslations,
    'jv': jvTranslations,
    'su': suTranslations,
    'en': enTranslations,
  };

  @override
  Map<String, Map<String, String>> get keys => translationKeys;
  
  static String translate(String key, String langCode) {
    return translationKeys[langCode]?[key] ?? translationKeys[fallbackLocale.languageCode]?[key] ?? key;
  }
}

/// Compatibility extension so that widgets using `context.tr('key')` continue to work seamlessly.
extension TrContextExtension on BuildContext {
  String tr(String key) {
    try {
      final lang = Get.isRegistered<AppSettingsController>()
          ? Get.find<AppSettingsController>().currentLocale.languageCode
          : 'id';
      return AppTranslations.translate(key, lang);
    } catch (_) {
      return AppTranslations.translate(key, 'id');
    }
  }
}
