import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:hajicare/features/sign_language/models/sign_token.dart';
import 'package:hajicare/features/sign_language/services/bisindo_tts_service.dart';
import 'package:hajicare/features/sign_language/services/sign_transcript_store.dart';

class _FakeTts extends BisindoTtsService {
  final List<String> spoken = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTts tts;
  late InMemorySignTranscriptStore store;
  late BisindoRecognitionController controller;
  final origin = DateTime(2026);

  BisindoRecognitionController build() {
    final c = BisindoRecognitionController(
      ttsService: tts,
      transcriptStore: store,
      autoTick: false,
    );
    c.onInit();
    return c;
  }

  Future<void> drain() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() async {
    tts = _FakeTts();
    store = InMemorySignTranscriptStore();
    controller = build();
    await controller.restored;
  });

  tearDown(() => controller.onClose());

  test('resetRecognitionState keeps transcript (model switch)', () {
    controller.commitWord('Halo', now: origin);
    controller.insertLetter('B');
    expect(controller.rawTranscript.value, 'halo B');

    controller.setCameraActive(true, now: origin);
    controller.resetRecognitionState();
    controller.setCameraActive(false);

    expect(controller.rawTranscript.value, 'halo B');
    expect(controller.tokens, hasLength(2));
  });

  test('BISINDO word is spoken immediately when speak=true', () async {
    controller.commitWord('Apa Kabar', speak: true, now: origin);
    await drain();
    expect(tts.spoken, ['apa kabar']);
  });

  test(
    'letters are not spoken individually; spoken as word on SPASI',
    () async {
      for (final (i, l) in ['B', 'U', 'D', 'I'].indexed) {
        controller.commitWord(
          l,
          speak: true,
          now: origin.add(Duration(milliseconds: i * 300)),
        );
      }
      await drain();
      expect(tts.spoken, isEmpty);

      controller.insertSpace();
      await drain();
      expect(tts.spoken, ['BUDI']);
      expect(controller.rawTranscript.value, 'BUDI');
    },
  );

  test('letters are spoken as word after idle period', () async {
    controller.commitWord('A', now: origin);
    controller.commitWord(
      'L',
      now: origin.add(const Duration(milliseconds: 400)),
    );
    controller.commitWord(
      'I',
      now: origin.add(const Duration(milliseconds: 800)),
    );

    controller.tick(now: origin.add(const Duration(milliseconds: 1500)));
    await drain();
    expect(tts.spoken, isEmpty);

    controller.tick(now: origin.add(const Duration(milliseconds: 2400)));
    await drain();
    expect(tts.spoken, ['ALI']);

    // No repeat on subsequent ticks.
    controller.tick(now: origin.add(const Duration(milliseconds: 5000)));
    await drain();
    expect(tts.spoken, ['ALI']);
  });

  test('a word after spelled letters speaks the letters first', () async {
    controller.commitWord('B', now: origin);
    controller.commitWord(
      'U',
      now: origin.add(const Duration(milliseconds: 300)),
    );
    controller.commitWord(
      'Halo',
      speak: true,
      now: origin.add(const Duration(milliseconds: 600)),
    );
    await drain();
    expect(tts.spoken, ['BU', 'halo']);
  });

  test('duplicate word within cooldown is suppressed', () {
    expect(controller.commitWord('Air', now: origin), isTrue);
    expect(
      controller.commitWord(
        'Air',
        now: origin.add(const Duration(milliseconds: 500)),
      ),
      isFalse,
    );
    expect(
      controller.commitWord(
        'Air',
        now: origin.add(const Duration(milliseconds: 1500)),
      ),
      isTrue,
    );
    expect(controller.rawTranscript.value, 'air air');
  });

  test(
    'transcript persists and restores in a new controller instance',
    () async {
      controller.commitWord('Halo', now: origin);
      controller.insertLetter('A');
      await drain();
      expect(store.saved, hasLength(2));

      controller.onClose();
      controller = build(); // simulates leaving and re-entering the screen
      await controller.restored;

      expect(controller.rawTranscript.value, 'halo A');
      expect(controller.tokens.last, const SignToken.letter('A'));
    },
  );

  test('RESET clears transcript and persisted copy', () async {
    controller.commitWord('Halo', now: origin);
    await drain();
    controller.resetTranscript();
    await drain();
    expect(controller.rawTranscript.value, isEmpty);
    expect(store.saved, isEmpty);
  });

  test('restore never overwrites input produced while loading', () async {
    store = InMemorySignTranscriptStore([const SignToken.word('lama')]);
    controller.onClose();
    controller = build();
    controller.commitWord('Baru', now: origin); // before restore completes
    await controller.restored;
    expect(controller.rawTranscript.value, 'baru');
  });

  test('SignToken JSON round-trip tolerates malformed entries', () {
    const tokens = [
      SignToken.word('halo'),
      SignToken.letter('A'),
      SignToken.space(),
    ];
    final decoded = tokens
        .map((t) => SignToken.tryFromJson(t.toJson()))
        .toList();
    expect(decoded, tokens);
    expect(SignToken.tryFromJson({'t': 'nope', 'v': 'x'}), isNull);
    expect(SignToken.tryFromJson('garbage'), isNull);
  });
}
