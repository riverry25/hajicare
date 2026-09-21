import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:hajicare/features/sign_language/models/bisindo_prediction.dart';
import 'package:hajicare/features/sign_language/models/sign_token.dart';

const _config = BisindoRecognitionConfig(
  minimumConfidence: 0.85,
  confirmationDuration: Duration(milliseconds: 1000),
  predictionInterval: Duration(milliseconds: 100),
  predictionWindowSize: 4,
  minimumStableRatio: 0.75,
  releaseDuration: Duration(milliseconds: 300),
  duplicateCooldown: Duration(milliseconds: 200),
  handPresenceTimeout: Duration(seconds: 10),
  predictionFreshness: Duration(milliseconds: 350),
);

BisindoPrediction prediction(String label, [double confidence = 0.94]) {
  return BisindoPrediction(
    classId: 0,
    label: label,
    confidence: confidence,
    distance: 1,
    candidates: const [],
  );
}

void feedStable(
  BisindoRecognitionController controller,
  String label,
  DateTime start,
) {
  for (var i = 0; i < 4; i++) {
    controller.handlePrediction(
      prediction(label),
      now: start.add(Duration(milliseconds: i * 100)),
    );
  }
}

void main() {
  late BisindoRecognitionController controller;
  late DateTime origin;

  setUp(() {
    controller = BisindoRecognitionController(config: _config, autoTick: false);
    controller.onInit();
    origin = DateTime(2026);
    controller.setCameraActive(true, now: origin);
  });

  tearDown(() => controller.onClose());

  test('stable gesture commits exactly once after real hold duration', () {
    feedStable(controller, 'LETTER_A', origin);
    expect(controller.tokens, isEmpty);
    expect(controller.recognitionState.value, SignRecognitionState.holding);

    controller.handlePrediction(
      prediction('LETTER_A'),
      now: origin.add(const Duration(milliseconds: 1300)),
    );

    expect(controller.rawTranscript.value, 'A');
    expect(controller.tokens.length, 1);
  });

  test('held gesture stays locked and never duplicates', () {
    feedStable(controller, 'LETTER_A', origin);
    controller.handlePrediction(
      prediction('LETTER_A'),
      now: origin.add(const Duration(milliseconds: 1300)),
    );

    for (var i = 14; i < 60; i++) {
      controller.handlePrediction(
        prediction('LETTER_A'),
        now: origin.add(Duration(milliseconds: i * 100)),
      );
      controller.tick(now: origin.add(Duration(milliseconds: i * 100)));
    }

    expect(controller.rawTranscript.value, 'A');
    expect(controller.tokens.length, 1);
  });

  test('same gesture can be committed again after a real release', () {
    feedStable(controller, 'LETTER_A', origin);
    controller.handlePrediction(
      prediction('LETTER_A'),
      now: origin.add(const Duration(milliseconds: 1300)),
    );

    controller.handleNoHand(
      now: origin.add(const Duration(milliseconds: 1400)),
    );
    controller.handleNoHand(
      now: origin.add(const Duration(milliseconds: 1750)),
    );
    feedStable(controller, 'LETTER_A', origin.add(const Duration(seconds: 2)));
    controller.handlePrediction(
      prediction('LETTER_A'),
      now: origin.add(const Duration(milliseconds: 3300)),
    );

    expect(controller.rawTranscript.value, 'AA');
    expect(controller.tokens.length, 2);
  });

  test('stable changed gesture releases lock before starting its own hold', () {
    feedStable(controller, 'LETTER_A', origin);
    controller.handlePrediction(
      prediction('LETTER_A'),
      now: origin.add(const Duration(milliseconds: 1300)),
    );

    for (var i = 14; i <= 31; i++) {
      controller.handlePrediction(
        prediction('LETTER_K'),
        now: origin.add(Duration(milliseconds: i * 100)),
      );
    }

    expect(controller.rawTranscript.value, 'AK');
    expect(controller.tokens.length, 2);
  });

  test('flickering labels never begin confirmation or commit', () {
    final labels = [
      'LETTER_A',
      'LETTER_A',
      'LETTER_K',
      'LETTER_A',
      'LETTER_K',
      'LETTER_K',
    ];
    for (var i = 0; i < labels.length; i++) {
      controller.handlePrediction(
        prediction(labels[i]),
        now: origin.add(Duration(milliseconds: i * 100)),
      );
    }
    controller.tick(now: origin.add(const Duration(milliseconds: 1700)));

    expect(controller.tokens, isEmpty);
    expect(controller.confirmationProgress.value, 0);
  });

  test('low confidence interrupts an active hold', () {
    feedStable(controller, 'LETTER_A', origin);
    controller.handlePrediction(
      prediction('LETTER_A', 0.4),
      now: origin.add(const Duration(milliseconds: 500)),
    );
    controller.tick(now: origin.add(const Duration(milliseconds: 1500)));

    expect(controller.tokens, isEmpty);
    expect(controller.confirmationProgress.value, 0);
  });

  test(
    'word and consecutive letters compose without spaces between letters',
    () {
      const parser = SignLabelParser();
      const composer = SignTokenComposer();
      final tokens = [
        parser.parse('WORD_BELAJAR').toToken(),
        parser.parse('LETTER_A').toToken(),
        parser.parse('LETTER_K').toToken(),
        parser.parse('LETTER_U').toToken(),
      ];

      expect(composer.compose(tokens), 'belajar AKU');
    },
  );

  test('manual space separates letter runs and rejects duplicate spaces', () {
    controller.tokens.addAll(const [
      SignToken.letter('S'),
      SignToken.letter('A'),
      SignToken.letter('Y'),
      SignToken.letter('A'),
    ]);
    controller.insertSpace();
    controller.insertSpace();
    controller.tokens.add(const SignToken.word('belajar'));
    // Trigger the public composer behavior after the externally seeded fixture.
    expect(
      const SignTokenComposer().compose(controller.tokens),
      'SAYA belajar',
    );
    expect(
      controller.tokens.where((t) => t.type == SignTokenType.space).length,
      1,
    );
  });

  test(
    'AI result remains separate from deterministic raw transcript',
    () async {
      final aiController = BisindoRecognitionController(
        config: _config,
        autoTick: false,
        aiProcessor: (raw) async {
          expect(raw, 'belajar');
          return 'Saya belajar.';
        },
      );
      aiController.onInit();
      aiController.setCameraActive(true, now: origin);
      feedStable(aiController, 'WORD_BELAJAR', origin);
      aiController.handlePrediction(
        prediction('WORD_BELAJAR'),
        now: origin.add(const Duration(milliseconds: 1300)),
      );

      expect(await aiController.sendToAi(), isTrue);
      expect(aiController.rawTranscript.value, 'belajar');
      expect(aiController.aiTranscript.value, 'Saya belajar.');
      aiController.onClose();
    },
  );
}
