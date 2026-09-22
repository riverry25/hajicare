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
  final String title;
  final String description;
  final int order;
  final List<String> keywords;

  const HajjDuaCategory({
    required this.stage,
    required this.title,
    required this.description,
    required this.order,
    this.keywords = const [],
  });
}
