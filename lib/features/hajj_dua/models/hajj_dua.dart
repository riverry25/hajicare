import 'hajj_dua_category.dart';

class HajjDua {
  final String id;
  final HajjDuaStage stage;
  final String title;
  final String? subtitle;
  final String arabic;
  final String? transliteration;
  final String? translation;
  final String? description;
  final String? source;
  final String? sourceUrl;
  final int order;
  final bool isRecommended;
  final bool requiresSourceVerification;
  final String? notes;
  final List<String> keywords;

  const HajjDua({
    required this.id,
    required this.stage,
    required this.title,
    required this.arabic,
    required this.order,
    this.subtitle,
    this.transliteration,
    this.translation,
    this.description,
    this.source,
    this.sourceUrl,
    this.isRecommended = false,
    this.requiresSourceVerification = true,
    this.notes,
    this.keywords = const [],
  });

  String toClipboardText() {
    return [
      title,
      arabic,
      if (transliteration?.trim().isNotEmpty ?? false) transliteration!.trim(),
      if (translation?.trim().isNotEmpty ?? false)
        'Artinya: ${translation!.trim()}',
      if (source?.trim().isNotEmpty ?? false) 'Sumber: ${source!.trim()}',
    ].join('\n\n');
  }
}
