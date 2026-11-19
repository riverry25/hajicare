import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:hajicare/features/sign_language/controllers/cams_translation_controller.dart';
import 'package:hajicare/features/sign_language/models/sign_token.dart';
import 'package:hajicare/features/sign_language/services/bisindo_tts_service.dart';
import 'package:hajicare/features/sign_language/services/sign_transcript_store.dart';
import 'package:hajicare/services/cams_canonical_frames.dart';
import 'package:hajicare/services/cams_nlp_engine.dart';

class _SilentTtsService extends BisindoTtsService {
  final List<String> spokenTexts = [];
  final List<String?> spokenLangs = [];

  @override
  Future<void> initialize({String? languageCode}) async {}

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    spokenTexts.add(text);
    spokenLangs.add(languageCode);
  }
}

void main() {
  setUpAll(() {
    final file = File('assets/cams/cams_v3_offline_weights.json');
    final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    CamsNlpEngine.instance.loadFromJsonMap(jsonMap);
  });

  group('SignToken Backward & Forward Compatibility', () {
    test('deserializes legacy JSON without sourceModel/confidence and new JSON with metadata', () {
      final legacy = SignToken.tryFromJson({'t': 'word', 'v': 'bantu'});
      expect(legacy, isNotNull);
      expect(legacy!.value, equals('bantu'));
      expect(legacy.sourceModel, isNull);
      expect(legacy.confidence, isNull);

      final modern = SignToken.tryFromJson({
        't': 'word',
        'v': 'dokter',
        'm': 'SIBI',
        'c': '0.920',
      });
      expect(modern, isNotNull);
      expect(modern!.value, equals('dokter'));
      expect(modern.sourceModel, equals('SIBI'));
      expect(modern.confidence, closeTo(0.92, 0.001));
    });
  });

  group('CamsTranslationController Cross-Model Buffer & 1.5s Silent Auto-Translate', () {
    test('chains BISINDO ("Bantu") + SIBI ("Dokter") and translates after 1.5s or manual trigger', () async {
      final tts = _SilentTtsService();
      final recognition = BisindoRecognitionController(
        ttsService: tts,
        transcriptStore: InMemorySignTranscriptStore(),
        autoTick: false,
        autoSpeakOnIdle: false,
      );
      final cams = CamsTranslationController(
        recognitionController: recognition,
        autoDetectGpsOnInit: false,
        autoTranslateDelay: const Duration(milliseconds: 50),
      );
      cams.onInit();

      final t0 = DateTime(2026, 11, 19, 12, 0, 0);
      recognition.commitWord(
        'Bantu',
        sourceModel: 'BISINDO',
        confidence: 0.88,
        now: t0,
      );
      recognition.commitWord(
        'Dokter',
        sourceModel: 'SIBI',
        confidence: 0.91,
        now: t0.add(const Duration(seconds: 2)),
      );

      expect(recognition.tokens.length, equals(2));
      expect(recognition.tokens[0].sourceModel, equals('BISINDO'));
      expect(recognition.tokens[1].sourceModel, equals('SIBI'));

      // Wait for auto-translate debounce (50ms in test)
      await Future<void>.delayed(const Duration(milliseconds: 90));

      final res = cams.latestResult.value;
      expect(res, isNotNull);
      expect(res!.decision, equals(CamsDecision.proceedTranslate));
      expect(res.intent, equals('MEDICAL_EMERGENCY_CRITICAL'));
      expect(res.idC3, equals('Tolong bantu saya memanggil dokter.'));
      expect(res.enText, equals('Please help me call a doctor.'));
      expect(res.arText, equals('من فضلك ساعدني في استدعاء الطبيب.'));
      // Verify silent auto-translate did not trigger unsolicited TTS
      expect(tts.spokenTexts, isEmpty);

      // Manual per-language TTS works for ID, EN, and AR
      await cams.speakLanguage('id');
      await cams.speakLanguage('en');
      await cams.speakLanguage('ar');
      expect(tts.spokenLangs, equals(['id', 'en', 'ar']));

      cams.onClose();
      recognition.onClose();
    });

    test('removeTokenAt removes specific chip and applyClarification resolves ambiguity in 1 tap', () {
      final tts = _SilentTtsService();
      final recognition = BisindoRecognitionController(
        ttsService: tts,
        transcriptStore: InMemorySignTranscriptStore(),
        autoTick: false,
        autoSpeakOnIdle: false,
      );
      final cams = CamsTranslationController(
        recognitionController: recognition,
        autoDetectGpsOnInit: false,
      );
      cams.onInit();

      recognition.commitWord('Saya', sourceModel: 'BISINDO', confidence: 0.85);
      recognition.commitWord('Bantu', sourceModel: 'SIBI', confidence: 0.86);
      cams.translateNow();

      expect(cams.latestResult.value?.decision, equals(CamsDecision.requestClarification));
      final options = cams.latestResult.value!.clarificationOptions;
      expect(options, isNotEmpty);

      // Single-tap clarification immediately resolves to PROCEED_TRANSLATE
      cams.applyClarification(options.first);
      expect(cams.latestResult.value?.decision, equals(CamsDecision.proceedTranslate));

      // Removing a chip updates token list cleanly
      final countBefore = recognition.tokens.length;
      recognition.removeTokenAt(0);
      expect(recognition.tokens.length, equals(countBefore - 1));

      // Reset clears result
      recognition.resetTranscript();
      expect(cams.latestResult.value, isNull);

      cams.onClose();
      recognition.onClose();
    });
  });
}
