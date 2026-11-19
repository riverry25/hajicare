import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/services/app_tts_service.dart';

void main() {
  group('AppTtsService Arabic (ar-SA) & Multilingual Resolution', () {
    test('resolves explicit ar / ar-SA to language code ar and locale ar-SA', () {
      expect(AppTtsService.resolveLanguageCode('ar'), equals('ar'));
      expect(AppTtsService.resolveLanguageCode('AR-SA'), equals('ar'));
      expect(AppTtsService.resolveEngineLocale('ar'), equals('ar-SA'));
      expect(AppTtsService.resolveEngineLocale('ar-SA'), equals('ar-SA'));
    });

    test('preserves id, en, jv, and su behavior without regression', () {
      expect(AppTtsService.resolveLanguageCode('en'), equals('en'));
      expect(AppTtsService.resolveEngineLocale('en'), equals('en-US'));
      expect(AppTtsService.resolveLanguageCode('id'), equals('id'));
      expect(AppTtsService.resolveEngineLocale('id'), equals('id-ID'));
      expect(AppTtsService.resolveLanguageCode('jv'), equals('id'));
      expect(AppTtsService.resolveLanguageCode('su'), equals('id'));
    });
  });
}
