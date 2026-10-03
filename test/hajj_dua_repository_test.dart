import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/hajj_dua/data/hajj_dua_repository.dart';
import 'package:hajicare/features/hajj_dua/models/hajj_dua_category.dart';

void main() {
  const repository = HajjDuaRepository();

  group('HajjDuaRepository', () {
    test('loads all Hajj stage categories in order', () {
      final categories = repository.getCategories();

      expect(categories, hasLength(13));
      expect(categories.first.stage, HajjDuaStage.ihram);
      expect(categories.last.stage, HajjDuaStage.general);
      expect(
        categories.map((category) => category.order),
        orderedEquals(List<int>.generate(13, (index) => index + 1)),
      );
    });

    test('preserves the three existing prayer entries', () {
      final existingIds = [
        'talbiyah_existing',
        'masuk_masjid_existing',
        'rukun_yamani_existing',
      ];

      for (final id in existingIds) {
        final dua = repository.getDuaById(id);
        expect(dua, isNotNull, reason: '$id must be preserved');
        expect(dua!.arabic.trim(), isNotEmpty);
        expect(dua.transliteration?.trim(), isNotEmpty);
        expect(dua.translationFor('id')?.trim(), isNotEmpty);
        expect(dua.translationFor('en')?.trim(), isNotEmpty);
        expect(dua.requiresSourceVerification, isTrue);
      }
    });

    test('all 12 Hajj stages have authentic Kemenag prayers available', () {
      final availableStages = repository.getAvailableCategories().map(
        (category) => category.stage,
      );

      expect(availableStages, contains(HajjDuaStage.ihram));
      expect(availableStages, contains(HajjDuaStage.masjidAlHaram));
      expect(availableStages, contains(HajjDuaStage.tawaf));
      expect(availableStages, contains(HajjDuaStage.zamzam));
      expect(availableStages, contains(HajjDuaStage.sai));
      expect(availableStages, contains(HajjDuaStage.arafah));
      expect(availableStages, contains(HajjDuaStage.muzdalifah));
      expect(availableStages, contains(HajjDuaStage.mina));
      expect(availableStages, contains(HajjDuaStage.tahallul));
      expect(availableStages, contains(HajjDuaStage.tawafIfadah));
      expect(availableStages, contains(HajjDuaStage.tawafWada));
      expect(availableStages, contains(HajjDuaStage.madinah));
    });

    test(
      'search covers title, category, meaning, transliteration, and keywords',
      () {
        expect(repository.searchDuas('talbiyah'), isNotEmpty);
        expect(repository.searchDuas('labbaik'), isNotEmpty);
        expect(repository.searchDuas('kebaikan di dunia'), isNotEmpty);
        expect(
          repository.searchCategories('zamzam').map((c) => c.stage),
          contains(HajjDuaStage.zamzam),
        );
        expect(repository.searchCategories('orang tua'), isEmpty);
        expect(
          repository.searchCategories('arafah').map((c) => c.stage),
          contains(HajjDuaStage.arafah),
        );
        expect(
          repository
              .searchDuas('Entering Masjid', languageCode: 'en')
              .first
              .stage,
          HajjDuaStage.masjidAlHaram,
        );
      },
    );

    test('unknown search returns empty results', () {
      expect(repository.searchDuas('teks-yang-tidak-ada'), isEmpty);
      expect(repository.searchCategories('teks-yang-tidak-ada'), isEmpty);
    });

    test(
      'every category can be selected safely even when it has no prayers',
      () {
        for (final category in repository.getCategories()) {
          expect(repository.getDuasForStage(category.stage), isA<List>());
        }
      },
    );

    test('supports activities lookup and filtering by ID', () {
      final tawafActivities = repository.getActivitiesForStage(
        HajjDuaStage.tawaf,
      );
      expect(tawafActivities, isNotEmpty);

      final byId = repository.getDuaById('ihram_niat_haji');
      expect(byId, isNotNull);
      expect(byId?.stage, HajjDuaStage.ihram);

      final batch = repository.getDuasByIds([
        'ihram_niat_haji',
        'zamzam_doa_minum',
      ]);
      expect(batch, hasLength(2));
    });
  });
}
