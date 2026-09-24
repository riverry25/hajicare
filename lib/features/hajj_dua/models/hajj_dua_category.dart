enum HajjDuaStage {
  ihram,
  masjidAlHaram,
  tawaf,
  zamzam,
  sai,
  arafah,
  muzdalifah,
  mina,
  tahallul,
  tawafIfadah,
  tawafWada,
  madinah,
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
