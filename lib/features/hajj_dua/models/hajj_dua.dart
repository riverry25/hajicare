import 'hajj_dua_category.dart';

class HajjDua {
  final String id;
  final HajjDuaStage stage;
  final String titleKey;
  final String? subtitleKey;
  final String arabic;
  final String? transliteration;
  final Map<String, String> translations;
  final String? descriptionKey;
  final String? source;
  final String? sourceUrl;
  final int order;
  final bool isRecommended;
  final bool requiresSourceVerification;
  final String? notesKey;
  final List<String> keywords;

  const HajjDua({
    required this.id,
    required this.stage,
    required this.titleKey,
    required this.arabic,
    required this.order,
    this.subtitleKey,
    this.transliteration,
    this.translations = const {},
    this.descriptionKey,
    this.source,
    this.sourceUrl,
    this.isRecommended = false,
    this.requiresSourceVerification = true,
    this.notesKey,
    this.keywords = const [],
  });

  String? translationFor(String languageCode) {
    return translations[languageCode] ?? translations['id'];
  }

  String toClipboardText({
    required String localizedTitle,
    required String meaningLabel,
    required String languageCode,
    required String sourceLabel,
  }) {
    final localizedTranslation = translationFor(languageCode);
    return [
      localizedTitle,
      arabic,
      if (transliteration?.trim().isNotEmpty ?? false) transliteration!.trim(),
      if (localizedTranslation?.trim().isNotEmpty ?? false)
        '$meaningLabel: ${localizedTranslation!.trim()}',
      if (source?.trim().isNotEmpty ?? false) '$sourceLabel: ${source!.trim()}',
    ].join('\n\n');
  }
}
