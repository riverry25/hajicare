import 'hajj_dua_category.dart';

class HajjDua {
  final String id;
  final HajjDuaStage stage;
  final String titleKey;
  final String? title;
  final String? subtitleKey;
  final String? subtitle;
  final String? activity;
  final String? contextText;
  final String arabic;
  final String? transliteration;
  final Map<String, String> translations;
  final String? descriptionKey;
  final String? description;
  final String? source;
  final String? sourceReference;
  final String? sourceUrl;
  final String? audioPath;
  final int order;
  final bool isRecommended;
  final bool requiresSourceVerification;
  final String? notesKey;
  final List<String> keywords;
  final List<String> tags;

  const HajjDua({
    required this.id,
    required this.stage,
    required this.titleKey,
    required this.arabic,
    required this.order,
    this.title,
    this.subtitleKey,
    this.subtitle,
    this.activity,
    this.contextText,
    this.transliteration,
    this.translations = const {},
    this.descriptionKey,
    this.description,
    this.source,
    this.sourceReference,
    this.sourceUrl,
    this.audioPath,
    this.isRecommended = false,
    this.requiresSourceVerification = true,
    this.notesKey,
    this.keywords = const [],
    this.tags = const [],
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
