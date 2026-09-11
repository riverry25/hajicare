import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'id.dart';
import 'jv.dart';
import 'su.dart';
import 'en.dart';

class AppTranslations extends Translations {
  static const List<Locale> supportedLocales = [
    Locale('id'),
    Locale('jv'),
    Locale('su'),
    Locale('en'),
  ];

  static const fallbackLocale = Locale('id');

  @override
  Map<String, Map<String, String>> get keys => {
        'id': idTranslations,
        'jv': jvTranslations,
        'su': suTranslations,
        'en': enTranslations,
      };
}

/// Compatibility extension so that widgets using `context.tr('key')` continue to work seamlessly.
extension TrContextExtension on BuildContext {
  String tr(String key) => key.tr;
}
