import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:hajicare/features/sign_language/models/sign_video_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TextToSignController controller;

  setUp(() {
    controller = TextToSignController();
  });

  tearDown(() {
    controller.onClose();
  });

  group('TextToSign Video Switching & State Transition Tests', () {
    const entryDokter = SignVideoEntry(
      id: 'sibi_dokter',
      language: 'sibi',
      type: 'word',
      label: 'Dokter',
      aliases: ['dokter'],
      category: 'health',
      version: 1,
      path: 'videos/sibi/dokter_v1.mp4',
      source: SignVideoSource.remote,
    );

    const entryObat = SignVideoEntry(
      id: 'sibi_obat',
      language: 'sibi',
      type: 'word',
      label: 'Obat',
      aliases: ['obat'],
      category: 'health',
      version: 1,
      path: 'videos/sibi/obat_v1.mp4',
      source: SignVideoSource.remote,
    );

    test('Initial state has no active playing video', () {
      expect(controller.activePlayingVideoId, isNull);
      expect(controller.currentEntry.value, isNull);
      expect(controller.isVideoInitialized.value, isFalse);
    });

    test(
      'searchSign for Dokter then searchSign for Obat updates currentEntry correctly',
      () async {
        controller.setLanguage('sibi');

        // 1. Search Dokter
        await controller.searchSign('Dokter', force: true);
        expect(controller.currentEntry.value?.label, 'Dokter');
        expect(controller.currentEntry.value?.id, 'sibi_dokter');

        // 2. Search Obat - previously this would fail to switch if a video was active
        await controller.searchSign('Obat', force: true);
        expect(controller.currentEntry.value?.label, 'Obat');
        expect(controller.currentEntry.value?.id, 'sibi_obat');
      },
    );

    test(
      'selectVocabularyItem updates currentEntry and _lastSearchedQuery',
      () async {
        controller.setLanguage('sibi');

        await controller.selectVocabularyItem(entryDokter);
        expect(controller.currentEntry.value?.id, 'sibi_dokter');
        expect(controller.textController.text, 'Dokter');

        await controller.selectVocabularyItem(entryObat);
        expect(controller.currentEntry.value?.id, 'sibi_obat');
        expect(controller.textController.text, 'Obat');
      },
    );

    test(
      'clearSearch disposes player and resets activePlayingVideoId',
      () async {
        controller.setLanguage('sibi');
        await controller.searchSign('Dokter', force: true);

        controller.clearSearch();

        expect(controller.currentEntry.value, isNull);
        expect(controller.activePlayingVideoId, isNull);
        expect(controller.textController.text, isEmpty);
        expect(controller.currentQuery.value, isEmpty);
      },
    );

    test('setLanguage resets currentEntry and activePlayingVideoId', () async {
      controller.setLanguage('sibi');
      await controller.searchSign('Dokter', force: true);

      controller.setLanguage('bisindo');

      expect(controller.currentEntry.value, isNull);
      expect(controller.activePlayingVideoId, isNull);
      expect(controller.selectedLanguage.value, 'bisindo');
    });
  });
}
