enum HajjDuaStage {
  ihram,
  masjidAlHaram,
  tawaf,
  sai,
  arafah,
  muzdalifah,
  mina,
  tahallul,
  general,
}

class HajjDuaCategory {
  final HajjDuaStage stage;
  final String titleKey;
  final String descriptionKey;
  final int order;
  final List<String> keywords;

  const HajjDuaCategory({
    required this.stage,
    required this.titleKey,
    required this.descriptionKey,
    required this.order,
    this.keywords = const [],
  });
}
