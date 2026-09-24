import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:hajicare/features/sign_language/models/bisindo_prediction.dart';
import 'package:hajicare/features/sign_language/models/sign_token.dart';

const _config = BisindoRecognitionConfig(
  confidenceThreshold: 0.78,
  stablePredictionsRequired: 4,
  duplicateCooldown: Duration(milliseconds: 1200),
  handPresenceTimeout: Duration(milliseconds: 1000),
);

BisindoPrediction prediction(String label, [double confidence = 0.94]) {
  return BisindoPrediction(
    classId: 0,
    label: label,
    confidence: confidence,
    distance: 1,
    candidates: const [],
    isRecognized: true,
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
  TestWidgetsFlutterBinding.ensureInitialized();
  late BisindoRecognitionController controller;
  late DateTime origin;

  setUp(() {
    controller = BisindoRecognitionController(config: _config, autoTick: false);
    controller.onInit();
    origin = DateTime(2026);
    controller.setCameraActive(true, now: origin);
  });

  tearDown(() => controller.onClose());

  test('stable gesture commits after 4 identical predictions', () {
    for (var i = 0; i < 3; i++) {
      controller.handlePrediction(
        prediction('Air'),
        now: origin.add(Duration(milliseconds: i * 100)),
      );
    }
    expect(controller.tokens, isEmpty);
    expect(controller.stabilityStreak.value, 3);
    expect(controller.recognitionState.value, SignRecognitionState.analyzing);

    controller.handlePrediction(
      prediction('Air'),
      now: origin.add(const Duration(milliseconds: 300)),
    );

    expect(controller.tokens.length, 1);
    expect(controller.rawTranscript.value, 'air');
    expect(controller.recognitionState.value, SignRecognitionState.recognized);
  });

  test('consecutive duplicates within 1200ms cooldown are rejected', () {
    feedStable(controller, 'Air', origin);
    expect(controller.tokens.length, 1);

    // Feed another 4 frames within 1200ms
    feedStable(
      controller,
      'Air',
      origin.add(const Duration(milliseconds: 500)),
    );
    expect(controller.tokens.length, 1);

    // After cooldown, gesture can commit again
    feedStable(
      controller,
      'Air',
      origin.add(const Duration(milliseconds: 1800)),
    );
    expect(controller.tokens.length, 2);
  });

  test('absence of hands resets streak and sets idle state', () {
    for (var i = 0; i < 2; i++) {
      controller.handlePrediction(
        prediction('Air'),
        now: origin.add(Duration(milliseconds: i * 100)),
      );
    }
    expect(controller.stabilityStreak.value, 2);

    controller.handleNoHand(now: origin.add(const Duration(milliseconds: 300)));
    expect(controller.stabilityStreak.value, 0);
    expect(controller.recognitionState.value, SignRecognitionState.idle);
  });

  test('deleteLast, insertSpace, and resetTranscript work as expected', () {
    feedStable(controller, 'Air', origin);
    expect(controller.rawTranscript.value, 'air');

    controller.insertSpace();
    feedStable(
      controller,
      'Minum',
      origin.add(const Duration(milliseconds: 1500)),
    );
    expect(controller.rawTranscript.value, 'air minum');

    controller.deleteLast();
    expect(controller.rawTranscript.value, 'air');

    controller.resetTranscript();
    expect(controller.rawTranscript.value, isEmpty);
  });

  test('multi-word phrase like Apa Kabar parsed as single token', () {
    const parser = SignLabelParser();
    const composer = SignTokenComposer();
    final token = parser.parse('Apa Kabar').toToken();

    expect(token.type, SignTokenType.word);
    expect(token.value, 'apa kabar');
    expect(composer.compose([token]), 'apa kabar');
  });
}
