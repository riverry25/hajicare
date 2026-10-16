import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/services/app_tts_service.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/features/map/services/navigation_voice_service.dart';
import 'package:hajicare/features/money/models/currency_code.dart';
import 'package:hajicare/features/money/models/money_detection.dart';
import 'package:hajicare/features/money/services/money_currency_helper.dart';
import 'package:hajicare/features/money/services/money_tts_service.dart';
import 'package:hajicare/features/sign_language/services/bisindo_tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTtsService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
    });

    tearDown(() {
      Get.reset();
    });

    test(
      'resolveLanguageCode prioritizes explicitCode and handles fallbacks',
      () {
        expect(AppTtsService.resolveLanguageCode('en'), equals('en'));
        expect(AppTtsService.resolveLanguageCode('EN'), equals('en'));
        expect(AppTtsService.resolveLanguageCode('id'), equals('id'));
        expect(AppTtsService.resolveLanguageCode('ID'), equals('id'));
        // Regional languages fallback to id for TTS engine compatibility
        expect(AppTtsService.resolveLanguageCode('jv'), equals('id'));
        expect(AppTtsService.resolveLanguageCode('su'), equals('id'));
        expect(AppTtsService.resolveLanguageCode(null), equals('id'));
      },
    );

    test('resolveEngineLocale returns en-US or id-ID', () {
      expect(AppTtsService.resolveEngineLocale('en'), equals('en-US'));
      expect(AppTtsService.resolveEngineLocale('id'), equals('id-ID'));
      expect(AppTtsService.resolveEngineLocale('jv'), equals('id-ID'));
      expect(AppTtsService.resolveEngineLocale('su'), equals('id-ID'));
    });

    test(
      'resolveLanguageCode respects AppSettingsController active locale',
      () {
        final settings = Get.put(AppSettingsController());
        settings.setLocale(const Locale('en'));
        expect(AppTtsService.resolveLanguageCode(), equals('en'));
        expect(AppTtsService.isEnglish, isTrue);

        settings.setLocale(const Locale('id'));
        expect(AppTtsService.resolveLanguageCode(), equals('id'));
        expect(AppTtsService.isEnglish, isFalse);
      },
    );

    test(
      'translateSignWord translates BISINDO words to English when in en mode',
      () {
        // Indonesian mode returns original text
        expect(
          AppTtsService.translateSignWord('Terima kasih', explicitCode: 'id'),
          equals('Terima kasih'),
        );
        expect(
          AppTtsService.translateSignWord('sakit', explicitCode: 'id'),
          equals('sakit'),
        );

        // English mode translates words
        expect(
          AppTtsService.translateSignWord('Terima kasih', explicitCode: 'en'),
          equals('thank you'),
        );
        expect(
          AppTtsService.translateSignWord('Tolong', explicitCode: 'en'),
          equals('help'),
        );
        expect(
          AppTtsService.translateSignWord('sakit', explicitCode: 'en'),
          equals('pain'),
        );
        expect(
          AppTtsService.translateSignWord('dokter', explicitCode: 'en'),
          equals('doctor'),
        );
        expect(
          AppTtsService.translateSignWord('kamar mandi', explicitCode: 'en'),
          equals('bathroom'),
        );

        // Multi-word phrase translation fallback
        expect(
          AppTtsService.translateSignWord('tolong sakit', explicitCode: 'en'),
          equals('help pain'),
        );

        // Uppercase preservation
        expect(
          AppTtsService.translateSignWord('TERIMA KASIH', explicitCode: 'en'),
          equals('THANK YOU'),
        );

        // Unknown words pass through unchanged
        expect(
          AppTtsService.translateSignWord('xyz123', explicitCode: 'en'),
          equals('xyz123'),
        );
      },
    );
  });

  group('Bilingual Money TTS & Helpers', () {
    test('numberToEnglishWords produces accurate English wording', () {
      expect(MoneySpeechFormatter.numberToEnglishWords(0), equals('zero'));
      expect(MoneySpeechFormatter.numberToEnglishWords(1), equals('one'));
      expect(MoneySpeechFormatter.numberToEnglishWords(14), equals('fourteen'));
      expect(MoneySpeechFormatter.numberToEnglishWords(20), equals('twenty'));
      expect(
        MoneySpeechFormatter.numberToEnglishWords(35),
        equals('thirty-five'),
      );
      expect(
        MoneySpeechFormatter.numberToEnglishWords(100),
        equals('one hundred'),
      );
      expect(
        MoneySpeechFormatter.numberToEnglishWords(105),
        equals('one hundred and five'),
      );
      expect(
        MoneySpeechFormatter.numberToEnglishWords(500),
        equals('five hundred'),
      );
      expect(
        MoneySpeechFormatter.numberToEnglishWords(1000),
        equals('one thousand'),
      );
      expect(
        MoneySpeechFormatter.numberToEnglishWords(100000),
        equals('one hundred thousand'),
      );
    });

    test('CurrencyCode spokenNameIn supports English and Indonesian', () {
      expect(CurrencyCode.sar.spokenNameIn('en'), equals('Saudi Riyal'));
      expect(CurrencyCode.sar.spokenNameIn('id'), equals('Riyal Saudi'));
      expect(CurrencyCode.idr.spokenNameIn('en'), equals('Indonesian Rupiah'));
      expect(CurrencyCode.idr.spokenNameIn('id'), equals('Rupiah'));
      expect(CurrencyCode.usd.spokenNameIn('en'), equals('US Dollar'));
      expect(CurrencyCode.usd.spokenNameIn('id'), equals('Dolar Amerika'));
    });

    test('joinNaturalSpoken handles English "and" vs Indonesian "dan"', () {
      expect(
        MoneySpeechFormatter.joinNaturalSpoken([
          '50 SAR',
          '100 USD',
        ], languageCode: 'en'),
        equals('50 SAR and 100 USD'),
      );
      expect(
        MoneySpeechFormatter.joinNaturalSpoken([
          'A',
          'B',
          'C',
        ], languageCode: 'en'),
        equals('A, B, and C'),
      );
      expect(
        MoneySpeechFormatter.joinNaturalSpoken([
          '50 SAR',
          '100 USD',
        ], languageCode: 'id'),
        equals('50 SAR dan 100 USD'),
      );
    });

    test(
      'MoneyTtsService buildSpeechSentence generates natural English speech',
      () {
        final tts = MoneyTtsService();
        final detections = [
          const MoneyDetection(
            className: 'fifty riyal',
            currency: CurrencyCode.sar,
            displayName: '50 SAR',
            spokenName: 'lima puluh Riyal Saudi',
            amount: 50.0,
            confidence: 0.95,
            box: Rect.zero,
            normalizedBox: Rect.zero,
          ),
        ];

        final englishSentence = tts.buildSpeechSentence(
          detections: detections,
          totalsByCurrency: {CurrencyCode.sar: 50.0},
          targetCurrency: CurrencyCode.idr,
          languageCode: 'en',
        );

        expect(englishSentence, contains('Detected one banknote'));
        expect(englishSentence, contains('fifty Saudi Riyal'));
        expect(englishSentence, contains('Equivalent to approximately'));
        expect(englishSentence, contains('Indonesian Rupiah'));

        // Indonesian sentence check
        final indonesianSentence = tts.buildSpeechSentence(
          detections: detections,
          totalsByCurrency: {CurrencyCode.sar: 50.0},
          targetCurrency: CurrencyCode.idr,
          languageCode: 'id',
        );
        expect(indonesianSentence, contains('Terdeteksi satu uang'));
        expect(indonesianSentence, contains('Riyal Saudi'));
        expect(indonesianSentence, contains('Setara sekitar'));
      },
    );
  });

  group('NavigationVoiceService Bilingual Voice Prompts', () {
    test(
      'announceManeuver and speak adapt to English and Indonesian',
      () async {
        final voice = NavigationVoiceService();
        voice.setMuted(false);

        // Near turn in English
        await voice.announceManeuver(
          instruction: 'Belok kanan',
          distanceMeters: 50.0,
          languageCode: 'en',
        );

        // Immediate turn in English
        await voice.announceManeuver(
          instruction: 'Turn left',
          distanceMeters: 15.0,
          languageCode: 'en',
        );

        // Distance 100m in English
        await voice.announceManeuver(
          instruction: 'Lurus terus',
          distanceMeters: 100.0,
          languageCode: 'en',
        );

        // ETA cue in English
        await voice.announceManeuver(
          instruction: 'Turn right',
          durationSeconds: 180,
          languageCode: 'en',
        );

        // Arrival in English
        await voice.speak(
          'Anda telah sampai di tujuan.',
          force: true,
          languageCode: 'en',
        );

        // Start navigation in English
        await voice.speak(
          'Memulai navigasi menuju Maktab 12',
          force: true,
          languageCode: 'en',
        );

        voice.reset();
        expect(voice.isMuted, isFalse);
      },
    );
  });

  group('BisindoTtsService Bilingual TTS', () {
    test(
      'BisindoTtsService handles English and Indonesian speaking calls',
      () async {
        final signTts = BisindoTtsService();
        await signTts.initialize(languageCode: 'en');
        expect(signTts.isSpeaking, isFalse);

        await signTts.speak('Terima kasih', languageCode: 'en');
        await signTts.speak('Sakit', languageCode: 'en');
        await signTts.speak('Terima kasih', languageCode: 'id');

        await signTts.stop();
        await signTts.dispose();
        expect(signTts.isSpeaking, isFalse);
      },
    );
  });
}
