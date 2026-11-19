import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:hajicare/features/sign_language/controllers/cams_translation_controller.dart';
import 'package:hajicare/features/sign_language/services/bisindo_tts_service.dart';
import 'package:hajicare/features/sign_language/services/sign_transcript_store.dart';
import 'package:hajicare/features/sign_language/widgets/cams_context_bar.dart';
import 'package:hajicare/features/sign_language/widgets/cams_fullscreen_display_page.dart';
import 'package:hajicare/features/sign_language/widgets/cams_gloss_buffer_strip.dart';
import 'package:hajicare/features/sign_language/widgets/cams_translation_result_card.dart';
import 'package:hajicare/services/cams_canonical_frames.dart';
import 'package:hajicare/services/cams_nlp_engine.dart';

class _TestTts extends BisindoTtsService {
  @override
  Future<void> initialize({String? languageCode}) async {}
  @override
  Future<void> speak(String text, {String? languageCode}) async {}
}

void main() {
  setUpAll(() {
    final file = File('assets/cams/cams_v3_offline_weights.json');
    final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    CamsNlpEngine.instance.loadFromJsonMap(jsonMap);
  });

  group('CAMS UI Modular Widgets (Light/Dark & Responsive Compact 360px)', () {
    testWidgets('renders Context Bar, Gloss Buffer Strip with model badges, and 3-Language Result Card without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final recognition = BisindoRecognitionController(
        ttsService: _TestTts(),
        transcriptStore: InMemorySignTranscriptStore(),
        autoTick: false,
        autoSpeakOnIdle: false,
      );
      final cams = CamsTranslationController(
        recognitionController: recognition,
        autoDetectGpsOnInit: false,
      );
      cams.onInit();

      recognition.commitWord('Bantu', sourceModel: 'BISINDO', confidence: 0.90);
      recognition.commitWord('Dokter', sourceModel: 'SIBI', confidence: 0.92);
      cams.translateNow();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  CamsContextBar(controller: cams),
                  CamsGlossBufferStrip(
                    recognitionController: recognition,
                    camsController: cams,
                  ),
                  CamsTranslationResultCard(controller: cams),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify model badges in Gloss Buffer Strip
      expect(find.textContaining('BISINDO'), findsWidgets);
      expect(find.textContaining('SIBI'), findsWidgets);

      // Verify 3-language output in Result Card
      expect(find.text('Tolong bantu saya memanggil dokter.'), findsOneWidget);
      expect(find.text('Please help me call a doctor.'), findsOneWidget);
      expect(find.text('من فضلك ساعدني في استدعاء الطبيب.'), findsOneWidget);

      cams.onClose();
      recognition.onClose();
    });

    testWidgets('renders REQUEST_CLARIFICATION quick-tap buttons and resolves on single tap', (tester) async {
      final recognition = BisindoRecognitionController(
        ttsService: _TestTts(),
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
      recognition.commitWord('Bantu', sourceModel: 'SIBI', confidence: 0.85);
      cams.translateNow();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CamsTranslationResultCard(controller: cams),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(cams.latestResult.value?.decision, equals(CamsDecision.requestClarification));
      final firstOptionLabel = cams.latestResult.value!.clarificationOptions.first.labelId;
      expect(find.text(firstOptionLabel), findsOneWidget);

      await tester.tap(find.text(firstOptionLabel));
      await tester.pumpAndSettle();

      expect(cams.latestResult.value?.decision, equals(CamsDecision.proceedTranslate));

      cams.onClose();
      recognition.onClose();
    });

    testWidgets('renders CamsFullscreenDisplayPage for 1-meter readability with RTL Arabic', (tester) async {
      final recognition = BisindoRecognitionController(
        ttsService: _TestTts(),
        transcriptStore: InMemorySignTranscriptStore(),
        autoTick: false,
        autoSpeakOnIdle: false,
      );
      final cams = CamsTranslationController(
        recognitionController: recognition,
        autoDetectGpsOnInit: false,
      );
      cams.onInit();
      recognition.commitWord('Bantu', sourceModel: 'BISINDO', confidence: 0.90);
      recognition.commitWord('Dokter', sourceModel: 'SIBI', confidence: 0.92);
      final res = cams.translateNow()!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CamsFullscreenDisplayPage(
            result: res,
            controller: cams,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('من فضلك ساعدني في استدعاء الطبيب.'), findsOneWidget);
      expect(find.text('Tolong bantu saya memanggil dokter.'), findsOneWidget);
      expect(find.text('Please help me call a doctor.'), findsOneWidget);

      cams.onClose();
      recognition.onClose();
    });
  });
}
