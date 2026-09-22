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

  int countForStage(HajjDuaStage stage) =>
      _duas.where((dua) => dua.stage == stage).length;

  List<HajjDuaCategory> searchCategories(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return getCategories();

    return getCategories()
        .where((category) {
          final searchableText = [
            category.title,
            category.description,
            ...category.keywords,
          ].join(' ').toLowerCase();
          return searchableText.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  List<HajjDua> searchDuas(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return const [];

    final results = _duas.where((dua) {
      final category = categoryFor(dua.stage);
      final searchableText = [
        dua.title,
        dua.subtitle ?? '',
        dua.transliteration ?? '',
        dua.translation ?? '',
        dua.description ?? '',
        category?.title ?? '',
        ...dua.keywords,
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
