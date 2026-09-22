import '../models/hajj_dua.dart';
import '../models/hajj_dua_category.dart';

const List<HajjDuaCategory> hajjDuaCategories = [
  HajjDuaCategory(
    stage: HajjDuaStage.ihram,
    titleKey: 'hajjDuaCategoryIhramTitle',
    descriptionKey: 'hajjDuaCategoryIhramDescription',
    order: 1,
    keywords: ['niat', 'talbiyah', 'perjalanan', 'ihram', 'umrah'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.masjidAlHaram,
    titleKey: 'hajjDuaCategoryMasjidTitle',
    descriptionKey: 'hajjDuaCategoryMasjidDescription',
    order: 2,
    keywords: ['masjid', 'kabah', "ka'bah", 'masjidil haram'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.tawaf,
    titleKey: 'hajjDuaCategoryTawafTitle',
    descriptionKey: 'hajjDuaCategoryTawafDescription',
    order: 3,
    keywords: [
      'tawaf',
      'hajar aswad',
      'rukun yamani',
      'maqam ibrahim',
      'zamzam',
      'putaran',
    ],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.sai,
    titleKey: 'hajjDuaCategorySaiTitle',
    descriptionKey: 'hajjDuaCategorySaiDescription',
    order: 4,
    keywords: ['sai', "sa'i", 'shafa', 'safa', 'marwah', 'pilar hijau'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.arafah,
    titleKey: 'hajjDuaCategoryArafahTitle',
    descriptionKey: 'hajjDuaCategoryArafahDescription',
    order: 5,
    keywords: [
      'arafah',
      'wukuf',
      'tahlil',
      'tahmid',
      'takbir',
      'istighfar',
      'shalawat',
    ],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.muzdalifah,
    titleKey: 'hajjDuaCategoryMuzdalifahTitle',
    descriptionKey: 'hajjDuaCategoryMuzdalifahDescription',
    order: 6,
    keywords: ['muzdalifah', 'mabit', 'mina', 'talbiyah'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.mina,
    titleKey: 'hajjDuaCategoryMinaTitle',
    descriptionKey: 'hajjDuaCategoryMinaDescription',
    order: 7,
    keywords: ['mina', 'jamarat', 'jumrah', 'takbir', 'melontar'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.tahallul,
    titleKey: 'hajjDuaCategoryTahallulTitle',
    descriptionKey: 'hajjDuaCategoryTahallulDescription',
    order: 8,
    keywords: ['tahallul', 'cukur', 'rambut'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.general,
    titleKey: 'hajjDuaCategoryGeneralTitle',
    descriptionKey: 'hajjDuaCategoryGeneralDescription',
    order: 9,
    keywords: [
      'ampunan',
      'orang tua',
      'keluarga',
      'kesehatan',
      'rezeki',
      'keselamatan',
      'kemudahan ibadah',
      'dunia akhirat',
    ],
  ),
];

/// Only content found in the previous implementation is retained here.
/// Canonical Arabic and transliteration stay independent from localized UI.
const List<HajjDua> hajjDuas = [
  HajjDua(
    id: 'talbiyah_existing',
    stage: HajjDuaStage.ihram,
    titleKey: 'hajjDuaTalbiyahTitle',
    subtitleKey: 'hajjDuaTalbiyahSubtitle',
    arabic:
        'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ',
    transliteration:
        'Labbaikallaahumma labbaik, labbaika laa syariika laka labbaik...',
    translations: {
      'id': 'Aku penuhi panggilan-Mu ya Allah, aku penuhi panggilan-Mu...',
    },
    descriptionKey: 'hajjDuaExistingContentDescription',
    order: 1,
    isRecommended: true,
    notesKey: 'hajjDuaTalbiyahVerificationNote',
    keywords: ['ihram', 'talbiyah', 'labbaik', 'perjalanan'],
  ),
  HajjDua(
    id: 'masuk_masjid_existing',
    stage: HajjDuaStage.masjidAlHaram,
    titleKey: 'hajjDuaMasjidTitle',
    subtitleKey: 'hajjDuaMasjidSubtitle',
    arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
    transliteration: 'Allaahummaftah lii abwaaba rahmatik',
    translations: {'id': 'Ya Allah, bukalah pintu-pintu rahmat-Mu untukku.'},
    descriptionKey: 'hajjDuaExistingContentDescription',
    order: 1,
    isRecommended: true,
    notesKey: 'hajjDuaMasjidVerificationNote',
    keywords: ['masjid', 'masjidil haram', 'rahmat'],
  ),
  HajjDua(
    id: 'rukun_yamani_existing',
    stage: HajjDuaStage.tawaf,
    titleKey: 'hajjDuaRukunYamaniTitle',
    subtitleKey: 'hajjDuaRukunYamaniSubtitle',
    arabic:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    transliteration:
        "Rabbanaa aatinaa fid dunyaa hasanah wa fil aakhirati hasanah wa qinaa 'adzaaban naar",
    translations: {
      'id':
          'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat dan lindungilah kami dari azab neraka.',
    },
    descriptionKey: 'hajjDuaRukunYamaniDescription',
    order: 1,
    isRecommended: true,
    notesKey: 'hajjDuaReferenceMissingNote',
    keywords: [
      'tawaf',
      'thawaf',
      'rukun yamani',
      'hajar aswad',
      'dunia akhirat',
    ],
  ),
];
