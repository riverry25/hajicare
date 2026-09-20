import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/locales/en.dart';
import 'package:hajicare/core/locales/id.dart';
import 'package:hajicare/core/locales/jv.dart';
import 'package:hajicare/core/locales/su.dart';

void main() {
  test(
    'all supported languages expose the same non-empty translation keys',
    () {
      final translations = <String, Map<String, String>>{
        'id': idTranslations,
        'en': enTranslations,
        'jv': jvTranslations,
        'su': suTranslations,
      };
      final canonicalKeys = idTranslations.keys.toSet();

      for (final entry in translations.entries) {
        expect(
          entry.value.keys.toSet(),
          canonicalKeys,
          reason:
              '${entry.key} must stay in parity with the Indonesian catalog',
        );
        expect(
          entry.value.entries.where((item) => item.value.trim().isEmpty),
          isEmpty,
          reason: '${entry.key} must not contain empty translations',
        );
      }
    },
  );
}
