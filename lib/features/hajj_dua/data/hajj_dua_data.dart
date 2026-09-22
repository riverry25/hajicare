import '../models/hajj_dua.dart';
import '../models/hajj_dua_category.dart';

/// Offline category structure for the Hajj dua and dhikr guide.
const List<HajjDuaCategory> hajjDuaCategories = [
  HajjDuaCategory(
    stage: HajjDuaStage.ihram,
    title: 'Ihram & Talbiyah',
    description:
        'Panduan bacaan ketika memulai ihram, bertalbiyah, dan selama perjalanan.',
    order: 1,
    keywords: ['niat', 'talbiyah', 'perjalanan', 'ihram', 'umrah'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.masjidAlHaram,
    title: 'Masuk Masjidil Haram',
    description:
        'Bacaan yang dapat dibaca ketika memasuki masjid dan mendekati Ka\'bah.',
    order: 2,
    keywords: ['masjid', 'kabah', "ka'bah", 'masjidil haram'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.tawaf,
    title: 'Thawaf',
    description: 'Bacaan dan dzikir yang dapat dibaca selama rangkaian thawaf.',
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
    title: "Sa'i",
    description: 'Panduan bacaan sepanjang perjalanan antara Shafa dan Marwah.',
    order: 4,
    keywords: ['sai', "sa'i", 'shafa', 'safa', 'marwah', 'pilar hijau'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.arafah,
    title: 'Wukuf di Arafah',
    description: 'Panduan memperbanyak doa dan beragam dzikir selama wukuf.',
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
    title: 'Muzdalifah',
    description:
        'Panduan dzikir dan doa selama berada di Muzdalifah menuju Mina.',
    order: 6,
    keywords: ['muzdalifah', 'mabit', 'mina', 'talbiyah'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.mina,
    title: 'Mina & Jamarat',
    description:
        'Panduan bacaan saat berada di Mina dan menjalani rangkaian jamarat.',
    order: 7,
    keywords: ['mina', 'jamarat', 'jumrah', 'takbir', 'melontar'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.tahallul,
    title: 'Tahallul',
    description: 'Panduan bacaan terkait tahallul setelah rangkaian ibadah.',
    order: 8,
    keywords: ['tahallul', 'cukur', 'rambut'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.general,
    title: 'Doa Umum',
    description:
        'Kumpulan doa untuk kebutuhan pribadi, keluarga, dan kebaikan umum.',
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

/// These are the only prayer texts found in the previous implementation.
/// Their wording is preserved verbatim and their provenance remains flagged
/// until a trusted reviewer supplies a source.
const List<HajjDua> hajjDuas = [
  HajjDua(
    id: 'talbiyah_existing',
    stage: HajjDuaStage.ihram,
    title: 'Bacaan Talbiyah',
    subtitle: 'Dzikir dan bacaan selama ihram',
    arabic:
        'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ',
    transliteration:
        'Labbaikallaahumma labbaik, labbaika laa syariika laka labbaik...',
    translation: 'Aku penuhi panggilan-Mu ya Allah, aku penuhi panggilan-Mu...',
    description:
        'Teks ini berasal dari implementasi Hajicare sebelumnya dan belum memiliki sumber yang dicantumkan.',
    order: 1,
    isRecommended: true,
    notes:
        'Perlu pemeriksaan kelengkapan teks dan rujukan oleh penelaah agama.',
    keywords: ['ihram', 'talbiyah', 'labbaik', 'perjalanan'],
  ),
  HajjDua(
    id: 'masuk_masjid_existing',
    stage: HajjDuaStage.masjidAlHaram,
    title: 'Doa Masuk Masjidil Haram',
    subtitle: 'Bacaan ketika memasuki masjid',
    arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
    transliteration: 'Allaahummaftah lii abwaaba rahmatik',
    translation: 'Ya Allah, bukalah pintu-pintu rahmat-Mu untukku.',
    description:
        'Teks ini berasal dari implementasi Hajicare sebelumnya dan belum memiliki sumber yang dicantumkan.',
    order: 1,
    isRecommended: true,
    notes: 'Perlu verifikasi transliterasi dan rujukan oleh penelaah agama.',
    keywords: ['masjid', 'masjidil haram', 'rahmat'],
  ),
  HajjDua(
    id: 'rukun_yamani_existing',
    stage: HajjDuaStage.tawaf,
    title: 'Antara Rukun Yamani dan Hajar Aswad',
    subtitle: 'Bacaan yang dapat dibaca selama thawaf',
    arabic:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    transliteration:
        "Rabbanaa aatinaa fid dunyaa hasanah wa fil aakhirati hasanah wa qinaa 'adzaaban naar",
    translation:
        'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat dan lindungilah kami dari azab neraka.',
    description:
        'Tidak ada doa tetap yang ditampilkan untuk setiap putaran. Bacaan ini diposisikan sebagai panduan yang dapat dibaca.',
    order: 1,
    isRecommended: true,
    notes: 'Rujukan belum dicantumkan pada implementasi sebelumnya.',
    keywords: [
      'tawaf',
      'thawaf',
      'rukun yamani',
      'hajar aswad',
      'dunia akhirat',
    ],
  ),
];
