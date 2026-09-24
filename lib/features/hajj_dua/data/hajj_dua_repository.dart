import '../../../core/locales/app_translations.dart';
import '../models/hajj_dua.dart';
import '../models/hajj_dua_category.dart';
import 'hajj_dua_data.dart';

class HajjDuaRepository {
  final List<HajjDuaCategory> _categories;
  final List<HajjDua> _duas;

  const HajjDuaRepository({
    List<HajjDuaCategory> categories = hajjDuaCategories,
    List<HajjDua> duas = hajjDuas,
  }) : _categories = categories,
       _duas = duas;

  List<HajjDuaCategory> getCategories() {
    final categories = List<HajjDuaCategory>.of(_categories);
    categories.sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(categories);
  }

  List<HajjDuaCategory> getAvailableCategories() {
    return getCategories()
        .where((category) => countForStage(category.stage) > 0)
        .toList(growable: false);
  }

  HajjDuaCategory? categoryFor(HajjDuaStage stage) {
    for (final category in _categories) {
      if (category.stage == stage) return category;
    }
    return null;
  }

  List<HajjDua> getDuasForStage(HajjDuaStage stage) {
    final duas = _duas.where((dua) => dua.stage == stage).toList();
    duas.sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(duas);
  }

  List<String> getActivitiesForStage(HajjDuaStage stage) {
    final activities = <String>{};
    for (final dua in getDuasForStage(stage)) {
      if (dua.activity != null && dua.activity!.trim().isNotEmpty) {
        activities.add(dua.activity!.trim());
      }
    }
    return activities.toList(growable: false);
  }

  List<HajjDua> getDuasForActivity(HajjDuaStage stage, String activity) {
    return getDuasForStage(stage)
        .where((dua) => dua.activity?.trim() == activity.trim())
        .toList(growable: false);
  }

  HajjDua? getDuaById(String id) {
    for (final dua in _duas) {
      if (dua.id == id) return dua;
    }
    return null;
  }

  List<HajjDua> getDuasByIds(Iterable<String> ids) {
    final idSet = ids.toSet();
    return _duas.where((dua) => idSet.contains(dua.id)).toList(growable: false);
  }

  int countForStage(HajjDuaStage stage) =>
      _duas.where((dua) => dua.stage == stage).length;

  List<HajjDuaCategory> searchCategories(
    String query, {
    String languageCode = 'id',
  }) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return getAvailableCategories();

    return getAvailableCategories()
        .where((category) {
          final searchableText = [
            AppTranslations.translate(category.titleKey, languageCode),
            AppTranslations.translate(category.descriptionKey, languageCode),
            ...category.keywords,
          ].join(' ').toLowerCase();
          return searchableText.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  List<HajjDua> searchDuas(String query, {String languageCode = 'id'}) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return const [];

    final results = _duas.where((dua) {
      final category = categoryFor(dua.stage);
      final searchableText = [
        AppTranslations.translate(dua.titleKey, languageCode),
        if (dua.title != null) dua.title!,
        if (dua.subtitleKey != null)
          AppTranslations.translate(dua.subtitleKey!, languageCode),
        if (dua.subtitle != null) dua.subtitle!,
        if (dua.activity != null) dua.activity!,
        if (dua.contextText != null) dua.contextText!,
        dua.arabic,
        dua.transliteration ?? '',
        ...dua.translations.values,
        if (dua.descriptionKey != null)
          AppTranslations.translate(dua.descriptionKey!, languageCode),
        if (dua.description != null) dua.description!,
        if (category != null) ...[
          AppTranslations.translate(category.titleKey, languageCode),
          ...category.keywords,
        ],
        ...dua.keywords,
        ...dua.tags,
      ].join(' ').toLowerCase();
      return searchableText.contains(normalizedQuery);
    }).toList();

    results.sort((a, b) {
      final stageComparison = a.stage.index.compareTo(b.stage.index);
      return stageComparison != 0
          ? stageComparison
          : a.order.compareTo(b.order);
    });
    return List.unmodifiable(results);
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
