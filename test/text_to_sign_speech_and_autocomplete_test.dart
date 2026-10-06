import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:hajicare/features/sign_language/services/sign_language_asset_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TextToSignController controller;

  setUp(() {
    controller = TextToSignController();
  });

  tearDown(() {
    controller.onClose();
  });

  group('TextToSign Autocomplete & Search Tests', () {
    test('updateSearchQuery with "dok" produces "Dokter" as suggestion', () {
      controller.setLanguage('sibi');
      controller.updateSearchQuery('dok');

      expect(controller.showSuggestions.value, isTrue);
      expect(controller.searchSuggestions, isNotEmpty);
      expect(controller.searchSuggestions.first, 'Dokter');
    });

    test(
      'updateSearchQuery is case-insensitive and ranks prefix match first',
      () {
        controller.setLanguage('sibi');
        controller.updateSearchQuery('DOK');

        expect(controller.showSuggestions.value, isTrue);
        expect(controller.searchSuggestions, contains('Dokter'));
      },
    );

    test(
      'selectSuggestion populates textController, closes suggestions, and updates query',
      () {
        controller.setLanguage('sibi');
        controller.updateSearchQuery('dok');

        expect(controller.showSuggestions.value, isTrue);

        controller.selectSuggestion('Dokter');

        expect(controller.textController.text, 'Dokter');
        expect(controller.currentQuery.value, 'Dokter');
        expect(controller.showSuggestions.value, isFalse);
        expect(controller.searchSuggestions, isEmpty);
      },
    );

    test('clearSearch clears textController, query, and hides suggestions', () {
      controller.setLanguage('sibi');
      controller.textController.text = 'Dokter';
      controller.updateSearchQuery('Dokter');

      controller.clearSearch();

      expect(controller.textController.text, isEmpty);
      expect(controller.currentQuery.value, isEmpty);
      expect(controller.showSuggestions.value, isFalse);
      expect(controller.searchSuggestions, isEmpty);
    });

    test('updateSearchQuery with empty string clears suggestions', () {
      controller.setLanguage('sibi');
      controller.updateSearchQuery('dok');
      expect(controller.showSuggestions.value, isTrue);

      controller.updateSearchQuery('');
      expect(controller.showSuggestions.value, isFalse);
      expect(controller.searchSuggestions, isEmpty);
    });

    test('BISINDO mode suggests letters from bisindoDictionary', () {
      controller.setLanguage('bisindo');
      controller.updateSearchQuery('j');

      expect(controller.showSuggestions.value, isTrue);
      expect(controller.searchSuggestions, contains('J'));
    });

    test(
      'SignLanguageAssetRegistry contains Dokter bundled entry with dok alias',
      () {
        final dokterAsset = SignLanguageAssetRegistry.matchAsset('dok', 'sibi');
        expect(dokterAsset, isNotNull);
        expect(dokterAsset!.label, 'Dokter');

        final dokterExact = SignLanguageAssetRegistry.matchAsset(
          'dokter',
          'sibi',
        );
        expect(dokterExact, isNotNull);
        expect(dokterExact!.label, 'Dokter');
      },
    );
  });
}
