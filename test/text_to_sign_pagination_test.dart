import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:hajicare/features/sign_language/models/sign_video_entry.dart';
import 'package:hajicare/features/sign_language/screens/text_to_sign_screen.dart';

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

    test(
      'Computes dynamicPackageCategories correctly from available videos',
      () {
        final dummyList = [
          const SignVideoEntry(
            id: 'v1',
            language: 'sibi',
            type: 'word',
            label: 'Dokter',
            aliases: [],
            category: 'health',
            version: 1,
            path: 'https://remote.com/dokter.mp4',
            source: SignVideoSource.remote,
          ),
          const SignVideoEntry(
            id: 'v2',
            language: 'sibi',
            type: 'word',
            label: 'Obat',
            aliases: [],
            category: 'health',
            version: 1,
            path: 'assets/obat.mp4',
            source: SignVideoSource.asset,
          ),
          const SignVideoEntry(
            id: 'v3',
            language: 'sibi',
            type: 'word',
            label: 'Berapa',
            aliases: [],
            category: 'question',
            version: 1,
            path: 'https://remote.com/berapa.mp4',
            source: SignVideoSource.remote,
          ),
        ];

        controller.availableVideos.assignAll(dummyList);

        final packages = controller.dynamicPackageCategories;
        expect(packages.length, 2);

        final healthPkg = packages.firstWhere((p) => p.category == 'health');
        expect(healthPkg.title, 'Paket Kesehatan');
        expect(healthPkg.totalCount, 2);
        expect(healthPkg.remoteCount, 1);
        expect(healthPkg.isFullyDownloaded, false);

        final questionPkg = packages.firstWhere(
          (p) => p.category == 'question',
        );
        expect(questionPkg.title, 'Paket Tanya Jawab');
        expect(questionPkg.totalCount, 1);
        expect(questionPkg.remoteCount, 1);
        expect(questionPkg.isFullyDownloaded, false);
      },
    );

    test('selectVocabularyItem updates textController and currentQuery', () {
      const entry = SignVideoEntry(
        id: 'v_dok',
        language: 'sibi',
        type: 'word',
        label: 'Dokter',
        aliases: [],
        category: 'health',
        version: 1,
        path: 'assets/dok.mp4',
        source: SignVideoSource.asset,
      );

      controller.selectVocabularyItem(entry);

      expect(controller.textController.text, 'Dokter');
      expect(controller.currentQuery.value, 'Dokter');
      expect(controller.currentEntry.value?.id, 'v_dok');
    });

    test('cancelCategoryPackageDownload resets downloading state', () {
      controller.categoryDownloading['health'] = true;
      controller.categoryDownloadProgress['health'] = 0.5;

      controller.cancelCategoryPackageDownload('health');

      expect(controller.categoryDownloading['health'], false);
      expect(controller.categoryDownloadProgress['health'], 0.0);
    });

    testWidgets('UI renders pagination and responds to next/prev buttons', (
      tester,
    ) async {
      final dummyList = List.generate(
        12,
        (i) => SignVideoEntry(
          id: 'test_$i',
          language: 'sibi',
          type: 'word',
          label: 'ItemKata_$i',
          aliases: const [],
          category: 'health',
          version: 1,
          path: 'assets/video_$i.mp4',
          source: SignVideoSource.asset,
        ),
      );

      controller.availableVideos.assignAll(dummyList);
      controller.currentVocabPage.value = 1;

      // Pump a widget that displays the paginated list using controller
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Obx(() {
              final paginated = controller.paginatedVocabulary;
              final total = controller.totalVocabPages;
              final current = controller.currentVocabPage.value;
              return Column(
                children: [
                  for (final item in paginated) Text(item.label),
                  Text('Hal $current dari $total'),
                  ElevatedButton(
                    onPressed: current < total
                        ? () => controller.nextVocabPage()
                        : null,
                    child: const Text('Selanjutnya'),
                  ),
                  ElevatedButton(
                    onPressed: current > 1
                        ? () => controller.previousVocabPage()
                        : null,
                    child: const Text('Sebelumnya'),
                  ),
                ],
              );
            }),
          ),
        ),
      );

      expect(find.text('ItemKata_0'), findsOneWidget);
      expect(find.text('ItemKata_4'), findsOneWidget);
      expect(find.text('ItemKata_5'), findsNothing);
      expect(find.text('Hal 1 dari 3'), findsOneWidget);

      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();

      expect(find.text('ItemKata_0'), findsNothing);
      expect(find.text('ItemKata_5'), findsOneWidget);
      expect(find.text('ItemKata_9'), findsOneWidget);
      expect(find.text('Hal 2 dari 3'), findsOneWidget);
    });

    testWidgets(
      'TextToSignScreen pumps and vocabulary pagination is verified',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final dummyList = List.generate(
          12,
          (i) => SignVideoEntry(
            id: 'test_$i',
            language: 'sibi',
            type: 'word',
            label: 'ItemKata_$i',
            aliases: const [],
            category: 'health',
            version: 1,
            path: 'assets/video_$i.mp4',
            source: SignVideoSource.asset,
          ),
        );

        controller.availableVideos.assignAll(dummyList);
        controller.currentVocabPage.value = 1;
        Get.put<TextToSignController>(controller);

        await tester.pumpWidget(const GetMaterialApp(home: TextToSignScreen()));
        await tester.pump(const Duration(seconds: 1));
        controller.isLoadingVideos.value = false;
        controller.availableVideos.assignAll(dummyList);
        controller.currentVocabPage.value = 1;
        await tester.pump(const Duration(milliseconds: 300));

        // Vocabulary header and video count badge
        expect(find.text('Daftar Kosakata'), findsOneWidget);
        expect(find.text('12 Video'), findsOneWidget);

        // Pagination indicators
        expect(find.textContaining('Halaman 1 dari 3'), findsOneWidget);

        // Click next page button
        final nextButton = find.byTooltip('Halaman Berikutnya');
        expect(nextButton, findsOneWidget);
        await tester.tap(nextButton);
        await tester.pump(const Duration(milliseconds: 300));

        expect(controller.currentVocabPage.value, 2);
        expect(find.textContaining('Halaman 2 dari 3'), findsOneWidget);
      },
    );

    test('filteredVocabulary reacts to currentQuery and resets page to 1', () {
      final dummyList = [
        const SignVideoEntry(
          id: 'v1',
          language: 'sibi',
          type: 'word',
          label: 'Dokter',
          aliases: ['tabib'],
          category: 'health',
          version: 1,
          path: 'assets/dok.mp4',
          source: SignVideoSource.asset,
        ),
        const SignVideoEntry(
          id: 'v2',
          language: 'sibi',
          type: 'word',
          label: 'Rumah Sakit',
          aliases: ['rs'],
          category: 'health',
          version: 1,
          path: 'assets/rs.mp4',
          source: SignVideoSource.asset,
        ),
        const SignVideoEntry(
          id: 'v3',
          language: 'sibi',
          type: 'word',
          label: 'Makan',
          aliases: [],
          category: 'activity',
          version: 1,
          path: 'assets/makan.mp4',
          source: SignVideoSource.asset,
        ),
      ];

      controller.availableVideos.assignAll(dummyList);
      controller.currentVocabPage.value = 2;

      // When query is empty, all 3 are returned
      expect(controller.filteredVocabulary.length, 3);

      // Searching 'dok' matches 'Dokter'
      controller.updateSearchQuery('dok');
      expect(controller.currentVocabPage.value, 1);
      expect(controller.filteredVocabulary.length, 1);
      expect(controller.filteredVocabulary.first.label, 'Dokter');

      // Clear search restores all
      controller.clearSearch();
      expect(controller.currentVocabPage.value, 1);
      expect(controller.filteredVocabulary.length, 3);
    });
  });
}
