import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
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

  group('TextToSignController Pagination Tests', () {
    test('Calculates total pages correctly with 5 items per page', () {
      expect(controller.totalVocabPages, 1);

      // Add 12 dummy video entries
      final dummyList = List.generate(
        12,
        (i) => SignVideoEntry(
          id: 'sibi_$i',
          language: 'sibi',
          type: 'word',
          label: 'Kata $i',
          aliases: const [],
          category: 'health',
          version: 1,
          path: 'assets/video_$i.mp4',
          source: SignVideoSource.asset,
        ),
      );

      controller.availableVideos.assignAll(dummyList);

      // 12 items / 5 per page = 3 pages
      expect(controller.totalVocabPages, 3);
      expect(controller.currentVocabPage.value, 1);

      // First page contains 5 items
      expect(controller.paginatedVocabulary.length, 5);
      expect(controller.paginatedVocabulary.first.label, 'Kata 0');
      expect(controller.paginatedVocabulary.last.label, 'Kata 4');

      // Navigate to next page
      controller.nextVocabPage();
      expect(controller.currentVocabPage.value, 2);
      expect(controller.paginatedVocabulary.length, 5);
      expect(controller.paginatedVocabulary.first.label, 'Kata 5');
      expect(controller.paginatedVocabulary.last.label, 'Kata 9');

      // Navigate to last page
      controller.nextVocabPage();
      expect(controller.currentVocabPage.value, 3);
      expect(controller.paginatedVocabulary.length, 2);
      expect(controller.paginatedVocabulary.first.label, 'Kata 10');
      expect(controller.paginatedVocabulary.last.label, 'Kata 11');

      // nextVocabPage at end should not exceed total pages
      controller.nextVocabPage();
      expect(controller.currentVocabPage.value, 3);

      // Previous page
      controller.previousVocabPage();
      expect(controller.currentVocabPage.value, 2);

      // goToVocabPage
      controller.goToVocabPage(1);
      expect(controller.currentVocabPage.value, 1);
    });

    test('Resets page to 1 when language changes', () {
      controller.currentVocabPage.value = 3;
      controller.setLanguage('bisindo');
      expect(controller.currentVocabPage.value, 1);
    });
  });
}
