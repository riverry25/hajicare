import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/hajj_dua/data/hajj_dua_repository.dart';
import 'package:hajicare/features/hajj_dua/models/hajj_dua_category.dart';

void main() {
  const repository = HajjDuaRepository();

  group('HajjDuaRepository', () {
    test('loads all Hajj stage categories in order', () {
      final categories = repository.getCategories();

      expect(categories, hasLength(9));
      expect(categories.first.stage, HajjDuaStage.ihram);
      expect(categories.last.stage, HajjDuaStage.general);
      expect(
        categories.map((category) => category.order),
        orderedEquals(List<int>.generate(9, (index) => index + 1)),
      );
    });

    test('preserves the three existing prayer entries', () {
      final allDuas = HajjDuaStage.values
          .expand(repository.getDuasForStage)
          .toList();

      expect(allDuas, hasLength(3));
      for (final dua in allDuas) {
        expect(dua.arabic.trim(), isNotEmpty);
        expect(dua.transliteration?.trim(), isNotEmpty);
        expect(dua.translationFor('id')?.trim(), isNotEmpty);
        expect(dua.translationFor('en'), dua.translationFor('id'));
        expect(dua.requiresSourceVerification, isTrue);
      }
    });

    test('only categories with usable entries are exposed to the UI', () {
      final availableStages = repository.getAvailableCategories().map(
        (category) => category.stage,
      );

      expect(
        availableStages,
        orderedEquals([
          HajjDuaStage.ihram,
          HajjDuaStage.masjidAlHaram,
          HajjDuaStage.tawaf,
        ]),
      );
    });

    test(
      'search covers title, category, meaning, transliteration, and keywords',
      () {
        expect(repository.searchDuas('talbiyah'), hasLength(1));
        expect(repository.searchDuas('labbaik'), hasLength(1));
        expect(repository.searchDuas('kebaikan di dunia'), hasLength(1));
        expect(
          repository.searchCategories('zamzam').single.stage,
          HajjDuaStage.tawaf,
        );
        expect(repository.searchCategories('orang tua'), isEmpty);
        expect(repository.searchCategories('arafah'), isEmpty);
        expect(
          repository
              .searchDuas('Entering Masjid', languageCode: 'en')
              .single
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
  });
}
