import '../models/hajj_dua.dart';
import '../models/hajj_dua_category.dart';

const List<HajjDuaCategory> hajjDuaCategories = [
  HajjDuaCategory(
    stage: HajjDuaStage.ihram,
    titleKey: 'hajjDuaCategoryIhramTitle',
    descriptionKey: 'hajjDuaCategoryIhramDescription',
    order: 1,
    keywords: ['niat', 'talbiyah', 'perjalanan', 'ihram', 'umrah', 'miqat'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.masjidAlHaram,
    titleKey: 'hajjDuaCategoryMasjidTitle',
    descriptionKey: 'hajjDuaCategoryMasjidDescription',
    order: 2,
    keywords: ['masjid', 'kabah', "ka'bah", 'masjidil haram', 'babussalam'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.tawaf,
    titleKey: 'hajjDuaCategoryTawafTitle',
    descriptionKey: 'hajjDuaCategoryTawafDescription',
    order: 3,
    keywords: [
      'tawaf',
      'thawaf',
      'hajar aswad',
      'rukun yamani',
      'maqam ibrahim',
      'putaran',
    ],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.zamzam,
    titleKey: 'hajjDuaCategoryZamzamTitle',
    descriptionKey: 'hajjDuaCategoryZamzamDescription',
    order: 4,
    keywords: ['zamzam', 'air zamzam', 'minum zamzam', 'kesembuhan'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.sai,
    titleKey: 'hajjDuaCategorySaiTitle',
    descriptionKey: 'hajjDuaCategorySaiDescription',
    order: 5,
    keywords: [
      'sai',
      "sa'i",
      'shafa',
      'safa',
      'marwah',
      'pilar hijau',
      'lampu hijau',
    ],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.arafah,
    titleKey: 'hajjDuaCategoryArafahTitle',
    descriptionKey: 'hajjDuaCategoryArafahDescription',
    order: 6,
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
    order: 7,
    keywords: ['muzdalifah', 'mabit', 'masy\'aril haram', 'kerikil', 'mina'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.mina,
    titleKey: 'hajjDuaCategoryMinaTitle',
    descriptionKey: 'hajjDuaCategoryMinaDescription',
    order: 8,
    keywords: [
      'mina',
      'jamarat',
      'jumrah',
      'aqabah',
      'ula',
      'wustha',
      'takbir',
      'melontar',
    ],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.tahallul,
    titleKey: 'hajjDuaCategoryTahallulTitle',
    descriptionKey: 'hajjDuaCategoryTahallulDescription',
    order: 9,
    keywords: ['tahallul', 'cukur', 'potong rambut', 'gunting'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.tawafIfadah,
    titleKey: 'hajjDuaCategoryTawafIfadahTitle',
    descriptionKey: 'hajjDuaCategoryTawafIfadahDescription',
    order: 10,
    keywords: ['tawaf ifadah', 'thawaf ifadah', 'rukun haji', 'ziyarah'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.tawafWada,
    titleKey: 'hajjDuaCategoryTawafWadaTitle',
    descriptionKey: 'hajjDuaCategoryTawafWadaDescription',
    order: 11,
    keywords: ['tawaf wada', 'thawaf wada', 'perpisahan', 'pamitan', 'makkah'],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.madinah,
    titleKey: 'hajjDuaCategoryMadinahTitle',
    descriptionKey: 'hajjDuaCategoryMadinahDescription',
    order: 12,
    keywords: [
      'madinah',
      'masjid nabawi',
      'raudhah',
      'rasulullah',
      'salam',
      'makam',
    ],
  ),
  HajjDuaCategory(
    stage: HajjDuaStage.general,
    titleKey: 'hajjDuaCategoryGeneralTitle',
    descriptionKey: 'hajjDuaCategoryGeneralDescription',
    order: 13,
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

/// Authentic Hajj Duas and Dhikr sourced from the official Ministry of Religious Affairs (Kemenag RI)
/// references: "Tuntunan Manasik Haji dan Umrah Kemenag RI" & "Buku Doa dan Zikir Manasik Haji dan Umrah Kemenag RI".
/// Existing prayers (talbiyah_existing, masuk_masjid_existing, rukun_yamani_existing) are preserved verbatim.
const List<HajjDua> hajjDuas = [
  // ==========================================
  // 1. IHRAM & TALBIYAH
  // ==========================================
  HajjDua(
    id: 'ihram_niat_haji',
    stage: HajjDuaStage.ihram,
    titleKey: 'ihramNiatHajiTitle',
    title: 'Niat Ihram Haji',
    activity: 'Memulai Ihram',
    contextText:
        'Dibaca di Miqat saat mulai berniat ihram melaksanakan ibadah haji.',
    arabic:
        'نَوَيْتُ الْحَجَّ وَأَحْرَمْتُ بِهِ لِلّٰهِ تَعَالَى لَبَّيْكَ اللّٰهُمَّ حَجًّا',
    transliteration:
        "Nawaitul hajja wa ahramtu bihii lillaahi ta'aalaa, labbaikallaahumma hajjan.",
    translations: {
      'id':
          'Aku niat haji dan berihram karena Allah Ta\'ala. Aku penuhi panggilan-Mu ya Allah untuk berhaji.',
      'en':
          'I intend to perform Hajj and enter into Ihram for the sake of Allah the Almighty. Here I am, O Allah, for Hajj.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['niat', 'ihram', 'miqat', 'haji'],
    tags: ['Niat', 'Miqat', 'Ihram'],
  ),
  HajjDua(
    id: 'talbiyah_existing',
    stage: HajjDuaStage.ihram,
    titleKey: 'hajjDuaTalbiyahTitle',
    title: 'Bacaan Talbiyah',
    subtitleKey: 'hajjDuaTalbiyahSubtitle',
    activity: 'Selama Perjalanan Ihram',
    contextText:
        'Disunnahkan memperbanyak bacaan talbiyah sejak berihram hingga melontar Jumrah Aqabah pada 10 Dzulhijjah.',
    arabic:
        'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لاَ شَرِيكَ لَكَ',
    transliteration:
        'Labbaikallaahumma labbaik, labbaika laa syariika laka labbaik, innal hamda wan ni\'mata laka wal mulk, laa syariika lak.',
    translations: {
      'id': 'Aku penuhi panggilan-Mu ya Allah, aku penuhi panggilan-Mu...',
    },
    descriptionKey: 'hajjDuaExistingContentDescription',
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference:
        'Buku Doa dan Zikir Manasik Haji dan Umrah Kemenag RI (HR. Bukhari & Muslim)',
    order: 2,
    isRecommended: true,
    requiresSourceVerification: true,
    notesKey: 'hajjDuaTalbiyahVerificationNote',
    keywords: ['ihram', 'talbiyah', 'labbaik', 'perjalanan', 'dzikir'],
    tags: ['Talbiyah', 'Perjalanan'],
  ),
  HajjDua(
    id: 'ihram_doa_masuk_makkah',
    stage: HajjDuaStage.ihram,
    titleKey: 'ihramDoaMasukMakkahTitle',
    title: 'Doa Memasuki Kota Makkah',
    activity: 'Tiba di Kota Makkah',
    contextText: 'Dibaca ketika memasuki wilayah Tanah Suci dan kota Makkah.',
    arabic:
        'اللّٰهُمَّ هٰذَا حَرَمُكَ وَأَمْنُكَ فَحَرِّمْ لَحْمِي وَدَمِي وَشَعْرِي وَبَشَرِي عَلَى النَّارِ',
    transliteration:
        "Allaahumma haadzaa haramuka wa amnuka faharrim lahmii wa damii wa sya'rii wa basyarii 'alan naar.",
    translations: {
      'id':
          'Ya Allah, kota ini adalah tanah haram-Mu dan tempat aman-Mu, maka haramkanlah dagingku, darahku, rambutku, dan kulitku dari api neraka.',
      'en':
          'O Allah, this is Your sanctuary and place of security, so forbid my flesh, blood, hair, and skin from the Fire.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI',
    order: 3,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['makkah', 'masuk kota makkah', 'tanah haram', 'perlindungan'],
    tags: ['Perjalanan', 'Makkah'],
  ),

  // ==========================================
  // 2. MASUK MASJIDIL HARAM
  // ==========================================
  HajjDua(
    id: 'masuk_masjid_existing',
    stage: HajjDuaStage.masjidAlHaram,
    titleKey: 'hajjDuaMasjidTitle',
    title: 'Doa Masuk Masjidil Haram',
    subtitleKey: 'hajjDuaMasjidSubtitle',
    activity: 'Masuk Pintu Masjid',
    contextText: 'Dibaca saat melangkahkan kaki kanan memasuki Masjidil Haram.',
    arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
    transliteration: 'Allaahummaftah lii abwaaba rahmatik.',
    translations: {'id': 'Ya Allah, bukalah pintu-pintu rahmat-Mu untukku.'},
    descriptionKey: 'hajjDuaExistingContentDescription',
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference:
        'Buku Doa dan Zikir Manasik Haji dan Umrah Kemenag RI (HR. Muslim)',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: true,
    notesKey: 'hajjDuaMasjidVerificationNote',
    keywords: ['masjid', 'masjidil haram', 'rahmat', 'pintu'],
    tags: ['Masjid', 'Pintu Masuk'],
  ),
  HajjDua(
    id: 'melihat_kabah_doa',
    stage: HajjDuaStage.masjidAlHaram,
    titleKey: 'melihatKabahTitle',
    title: "Doa Ketika Melihat Ka'bah",
    activity: "Melihat Ka'bah Pertama Kali",
    contextText:
        "Dibaca saat pertama kali memandang Ka'bah dengan penuh takzim.",
    arabic:
        'اللّٰهُمَّ زِدْ هٰذَا الْبَيْتَ تَشْرِيفًا وَتَعْظِيمًا وَتَكْرِيمًا وَمَهَابَةً، وَزِدْ مَنْ شَرَّفَهُ وَعَظَّمَهُ مِمَّنْ حَجَّهُ أَوِ اعْتَمَرَهُ تَشْرِيفًا وَتَكْرِيمًا وَتَعْظِيمًا وَبِرًّا',
    transliteration:
        "Allaahumma zid haadzal baita tasyriifan wa ta'zhiiman wa takriiman wa mahaabah, wa zid man syarrafahuu wa 'azzhamahuu mimman hajjahuu awi'tamarahuu tasyriifan wa takriiman wa ta'zhiiman wa birran.",
    translations: {
      'id':
          'Ya Allah, tambahkanlah kemuliaan, keagungan, kehormatan, dan wibawa pada Rumah (Ka\'bah) ini. Dan tambahkanlah pula kemuliaan, kehormatan, keagungan, serta kebaikan bagi orang-orang yang memuliakan dan mengagungkannya dari kalangan mereka yang berhaji atau berumrah.',
      'en':
          'O Allah, increase this House in honor, greatness, reverence, and awe. And increase those who honor and venerate it among those who perform Hajj or Umrah in honor, dignity, greatness, and righteousness.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI',
    order: 2,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['kabah', "ka'bah", 'melihat kabah', 'baitullah', 'keagungan'],
    tags: ["Ka'bah", 'Adab'],
  ),

  // ==========================================
  // 3. THAWAF
  // ==========================================
  HajjDua(
    id: 'thawaf_mulai_hajar_aswad',
    stage: HajjDuaStage.tawaf,
    titleKey: 'thawafMulaiHajarAswadTitle',
    title: 'Memulai Thawaf di Garis Hajar Aswad (Istilam)',
    activity: 'Memulai Thawaf (Putaran 1-7)',
    contextText:
        'Dibaca di awal setiap putaran thawaf sejajar Hajar Aswad sambil melambaikan tangan kanan (istilam).',
    arabic: 'بِسْمِ اللّٰهِ وَاللّٰهُ أَكْبَرُ',
    transliteration: 'Bismillaahi wallaahu akbar.',
    translations: {
      'id': 'Dengan nama Allah, dan Allah Maha Besar.',
      'en': 'In the name of Allah, and Allah is the Greatest.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI (HR. Bukhari)',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: [
      'thawaf',
      'tawaf',
      'hajar aswad',
      'istilam',
      'bismillah',
      'takbir',
    ],
    tags: ['Awal Putaran', 'Istilam'],
  ),
  HajjDua(
    id: 'rukun_yamani_existing',
    stage: HajjDuaStage.tawaf,
    titleKey: 'hajjDuaRukunYamaniTitle',
    title: 'Antara Rukun Yamani dan Hajar Aswad',
    subtitleKey: 'hajjDuaRukunYamaniSubtitle',
    activity: 'Menjelang Akhir Putaran',
    contextText:
        'Dibaca ketika berjalan di antara Rukun Yamani dan Hajar Aswad pada setiap putaran thawaf.',
    arabic:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    transliteration:
        "Rabbanaa aatinaa fid dunyaa hasanah wa fil aakhirati hasanah wa qinaa 'adzaaban naar.",
    translations: {
      'id':
          'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat dan lindungilah kami dari azab neraka.',
    },
    descriptionKey: 'hajjDuaRukunYamaniDescription',
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference:
        'Buku Doa dan Zikir Manasik Haji dan Umrah Kemenag RI (HR. Abu Dawud)',
    order: 2,
    isRecommended: true,
    requiresSourceVerification: true,
    notesKey: 'hajjDuaReferenceMissingNote',
    keywords: [
      'tawaf',
      'thawaf',
      'rukun yamani',
      'hajar aswad',
      'dunia akhirat',
      'sapu jagad',
    ],
    tags: ['Rukun Yamani', 'Doa Sapu Jagad'],
  ),
  HajjDua(
    id: 'thawaf_maqam_ibrahim',
    stage: HajjDuaStage.tawaf,
    titleKey: 'thawafMaqamIbrahimTitle',
    title: 'Setelah Selesai Thawaf (Di Belakang Maqam Ibrahim)',
    activity: 'Selesai 7 Putaran Thawaf',
    contextText:
        'Dibaca saat menuju ke belakang Maqam Ibrahim untuk mendirikan shalat sunnah thawaf 2 rakaat.',
    arabic: 'وَاتَّخِذُوا مِنْ مَقَامِ إِبْرَاهِيمَ مُصَلًّى',
    transliteration: 'Wattakhidzuu mim maqaami Ibraahiima mushallaa.',
    translations: {
      'id':
          'Dan jadikanlah sebagian Maqam Ibrahim sebagai tempat shalat. (QS. Al-Baqarah: 125)',
      'en':
          'And take, [O believers], from the standing place of Abraham a place of prayer. (Surah Al-Baqarah: 125)',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI (HR. Muslim)',
    order: 3,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['thawaf', 'maqam ibrahim', 'shalat sunnah', 'selesai thawaf'],
    tags: ['Selesai Thawaf', 'Maqam Ibrahim'],
  ),

  // ==========================================
  // 4. MINUM AIR ZAMZAM
  // ==========================================
  HajjDua(
    id: 'zamzam_doa_minum',
    stage: HajjDuaStage.zamzam,
    titleKey: 'zamzamDoaMinumTitle',
    title: 'Doa Minum Air Zamzam',
    activity: 'Minum Air Zamzam',
    contextText:
        'Dibaca ketika hendak meminum air Zamzam menghadap kiblat dengan tangan kanan dan membaca bismillah.',
    arabic:
        'اللّٰهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا وَاسِعًا، وَشِفَاءً مِنْ كُلِّ دَاءٍ',
    transliteration:
        "Allaahumma innii as-aluka 'ilman naafi'an, wa rizqan waasi'an, wa syifaa-an min kulli daa-in.",
    translations: {
      'id':
          'Ya Allah, sesungguhnya aku memohon kepada-Mu ilmu yang bermanfaat, rezeki yang luas, dan kesembuhan dari segala macam penyakit.',
      'en':
          'O Allah, I ask You for beneficial knowledge, abundant sustenance, and a cure for every disease.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference:
        'Buku Doa dan Zikir Manasik Haji dan Umrah Kemenag RI (HR. Ad-Daruquthni)',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['zamzam', 'air zamzam', 'minum', 'kesembuhan', 'rezeki', 'ilmu'],
    tags: ['Adab Minum', 'Air Zamzam'],
  ),

  // ==========================================
  // 5. SA'I
  // ==========================================
  HajjDua(
    id: 'sai_menuju_shafa',
    stage: HajjDuaStage.sai,
    titleKey: 'saiMenujuShafaTitle',
    title: 'Menuju Bukit Shafa',
    activity: 'Persiapan Memulai Sa\'i',
    contextText:
        'Dibaca ketika mendekati bukit Shafa sebelum memulai putaran pertama Sa\'i.',
    arabic:
        'إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللّٰهِ ۖ أَبْدَأُ بِمَا بَدَأَ اللّٰهُ بِهِ',
    transliteration:
        "Innash shafaa wal marwata min sya'aa-irillaah. Abda-u bimaa bada-allaahu bih.",
    translations: {
      'id':
          'Sesungguhnya Shafa dan Marwah adalah sebagian dari syiar-syiar Allah. Aku memulai dengan apa yang telah Allah mulai.',
      'en':
          'Indeed, as-Safa and al-Marwah are among the symbols of Allah. I begin with that which Allah began with.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI (HR. Muslim)',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['sai', 'shafa', 'marwah', 'bukit shafa', 'mulai sai'],
    tags: ['Menuju Shafa', 'Awal Sa\'i'],
  ),
  HajjDua(
    id: 'sai_di_shafa_marwah',
    stage: HajjDuaStage.sai,
    titleKey: 'saiDiShafaMarwahTitle',
    title: 'Di Atas Bukit Shafa & Marwah',
    activity: 'Di Puncak Bukit Shafa / Marwah',
    contextText:
        'Dibaca di atas bukit Shafa dan bukit Marwah sambil menghadap Ka\'bah dan mengangkat kedua tangan.',
    arabic:
        'اللّٰهُ أَكْبَرُ، اللّٰهُ أَكْبَرُ، اللّٰهُ أَكْبَرُ، لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ يُحْيِي وَيُمِيتُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ، أَنْجَزَ وَعْدَهُ، وَنَصَرَ عَبْدَهُ، وَهَزَمَ الْأَحْزَابَ وَحْدَهُ',
    transliteration:
        "Allaahu akbar, Allaahu akbar, Allaahu akbar. Laa ilaaha illallaahu wahdahu laa syariika lah, lahul mulku wa lahul hamdu yuhyii wa yumiitu wa huwa 'alaa kulli syai-in qadiir. Laa ilaaha illallaahu wahdah, anjaza wa'dah, wa nashara 'abdah, wa hazamal ahzaaba wahdah.",
    translations: {
      'id':
          'Allah Maha Besar, Allah Maha Besar, Allah Maha Besar. Tiada Tuhan selain Allah Yang Maha Esa, tiada sekutu bagi-Nya. Bagi-Nya segala kerajaan dan segala puji, Dia yang menghidupkan dan mematikan, dan Dia Maha Kuasa atas segala sesuatu. Tiada Tuhan selain Allah semata, Dia menepati janji-Nya, menolong hamba-Nya, dan mengalahkan musuh-musuh sendirian.',
      'en':
          'Allah is the Greatest, Allah is the Greatest, Allah is the Greatest. There is no deity except Allah alone, having no partner. His is the sovereignty and to Him is all praise, He gives life and causes death, and He has power over all things. There is no deity except Allah alone, He fulfilled His promise, granted victory to His servant, and defeated the factions alone.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI (HR. Muslim)',
    order: 2,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['sai', 'takbir', 'tahlil', 'shafa', 'marwah', 'puncak bukit'],
    tags: ['Bukit Shafa & Marwah', 'Dzikir Utama'],
  ),
  HajjDua(
    id: 'sai_lampu_hijau',
    stage: HajjDuaStage.sai,
    titleKey: 'saiLampuHijauTitle',
    title: 'Di Antara Dua Lampu / Pilar Hijau',
    activity: 'Lintasan Dua Pilar Hijau',
    contextText:
        'Dibaca saat melintasi area antara dua lampu hijau (disunnahkan lari-lari kecil bagi jamaah laki-laki).',
    arabic:
        'رَبِّ اغْفِرْ وَارْحَمْ، وَاعْفُ وَتَكَرَّمْ، وَتَجَاوَزْ عَمَّا تَعْلَمُ، إِنَّكَ تَعْلَمُ مَا لَا نَعْلَمُ، إِنَّكَ أَنْتَ اللّٰهُ الْأَعَزُّ الْأَكْرَمُ',
    transliteration:
        "Rabbighfir warham, wa'fu wa takarram, wa tajaawaz 'ammaa ta'lam, innaka ta'lamu maa laa na'lam, innaka antallaahul a'azzul akram.",
    translations: {
      'id':
          'Ya Tuhanku, ampunilah, sayangilah, maafkanlah, muliakanlah, dan hapuslah dosa-dosa yang Engkau ketahui. Sesungguhnya Engkau mengetahui apa yang tidak kami ketahui. Sungguh Engkau adalah Allah Yang Maha Mulia lagi Maha Pemurah.',
      'en':
          'My Lord, forgive, have mercy, pardon, be generous, and overlook what You know. Indeed You know what we know not. Truly You are Allah, the Most Mighty, the Most Generous.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Buku Doa dan Zikir Manasik Haji dan Umrah Kemenag RI',
    order: 3,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['sai', 'lampu hijau', 'pilar hijau', 'lari kecil', 'ampunan'],
    tags: ['Lampu Hijau', 'Sa\'i'],
  ),

  // ==========================================
  // 6. WUKUF DI ARAFAH
  // ==========================================
  HajjDua(
    id: 'arafah_dzikir_terbaik',
    stage: HajjDuaStage.arafah,
    titleKey: 'arafahDzikirTerbaikTitle',
    title: 'Dzikir Utama Hari Arafah',
    activity: 'Waktu Wukuf (Bada Zawal)',
    contextText:
        'Dzikir paling utama yang dianjurkan dibaca berulang-ulang selama wukuf di Arafah.',
    arabic:
        'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    transliteration:
        "Laa ilaaha illallaahu wahdahu laa syariika lah, lahul mulku wa lahul hamdu wa huwa 'alaa kulli syai-in qadiir.",
    translations: {
      'id':
          'Tiada Tuhan selain Allah Yang Maha Esa, tiada sekutu bagi-Nya. Bagi-Nya segala kerajaan dan segala puji, dan Dia Maha Kuasa atas segala sesuatu.',
      'en':
          'There is no deity except Allah alone, having no partner. His is the sovereignty and to Him is all praise, and He has power over all things.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference:
        'Buku Doa dan Zikir Manasik Haji dan Umrah Kemenag RI (HR. At-Tirmidzi)',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['arafah', 'wukuf', 'tahlil', 'dzikir utama', 'hadits'],
    tags: ['Dzikir Utama', 'Wukuf'],
  ),
  HajjDua(
    id: 'arafah_istighfar_taubat',
    stage: HajjDuaStage.arafah,
    titleKey: 'arafahIstighfarTitle',
    title: 'Istighfar & Taubat di Arafah',
    activity: 'Memohon Ampunan di Arafah',
    contextText:
        'Dianjurkan memperbanyak istighfar dengan penuh kerendahan hati saat wukuf.',
    arabic:
        'أَسْتَغْفِرُ اللّٰهَ الْعَظِيمَ الَّذِي لَا إِلٰهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ',
    transliteration:
        "Astaghfirullaahal 'azhiimal ladzii laa ilaaha illaa huwal hayyul qayyuumu wa atuubu ilaih.",
    translations: {
      'id':
          'Aku memohon ampun kepada Allah Yang Maha Agung, tiada Tuhan selain Dia Yang Maha Hidup lagi Berdiri Sendiri, dan aku bertobat kepada-Nya.',
      'en':
          'I seek forgiveness from Allah the Almighty, there is no deity except Him, the Ever-Living, the Sustainer of all existence, and I repent unto Him.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI',
    order: 2,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['arafah', 'istighfar', 'taubat', 'ampunan', 'doa'],
    tags: ['Istighfar', 'Taubat'],
  ),

  // ==========================================
  // 7. MUZDALIFAH
  // ==========================================
  HajjDua(
    id: 'muzdalifah_masyaril_haram',
    stage: HajjDuaStage.muzdalifah,
    titleKey: 'muzdalifahMasyarilHaramTitle',
    title: 'Dzikir di Masy\'aril Haram',
    activity: 'Mabit di Muzdalifah & Waktu Fajar',
    contextText:
        'Dibaca saat mabit dan berdzikir di Masy\'aril Haram (Muzdalifah) setelah shalat Subuh hingga fajar menguning.',
    arabic:
        'اللّٰهُمَّ كَمَا أَوْقَفْتَنَا فِيهِ وَأَرَيْتَنَا إِيَّاهُ فَوَفِّقْنَا لِذِكْرِكَ كَمَا هَدَيْتَنَا',
    transliteration:
        'Allaahumma kamaa awqaftanaa fiihi wa araitanaa iyyaahu fawaffiqnaa lidzikrika kamaa hadaitanaa.',
    translations: {
      'id':
          'Ya Allah, sebagaimana Engkau telah menghentikan kami di tempat ini dan memperlihatkannya kepada kami, maka berilah kami taufiq untuk berdzikir kepada-Mu sebagaimana Engkau telah memberi petunjuk kepada kami.',
      'en':
          'O Allah, just as You caused us to stop here and showed it to us, grant us the ability to remember You as You have guided us.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Buku Doa dan Zikir Manasik Haji dan Umrah Kemenag RI',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['muzdalifah', 'masyaril haram', 'mabit', 'fajar', 'dzikir'],
    tags: ['Masy\'aril Haram', 'Mabit'],
  ),

  // ==========================================
  // 8. MINA & MELONTAR JUMRAH
  // ==========================================
  HajjDua(
    id: 'mina_melontar_jumrah',
    stage: HajjDuaStage.mina,
    titleKey: 'minaMelontarJumrahTitle',
    title: 'Saat Melontar Setiap Butir Kerikil',
    activity: 'Melontar Jumrah (Aqabah, Ula, Wustha)',
    contextText:
        'Dibaca pada setiap butir kerikil yang dilontarkan ke tiang jamarat.',
    arabic:
        'بِسْمِ اللّٰهِ، اللّٰهُ أَكْبَرُ، رَغْمًا لِلشَّيْطَانِ وَرِضًا لِلرَّحْمٰنِ، اللّٰهُمَّ اجْعَلْهُ حَجًّا مَبْرُورًا وَذَنْبًا مَغْفُورًا',
    transliteration:
        "Bismillaahi, Allaahu akbar, raghman lisysyaithaani wa ridhan lirrahmaan, Allaahummaj'alhu hajjan mabruuran wa dzanban maghfuuran.",
    translations: {
      'id':
          'Dengan nama Allah, Allah Maha Besar, sebagai kutukan bagi setan dan keridhaan bagi Allah Yang Maha Pengasih. Ya Allah, jadikanlah hajiku ini haji yang mabrur dan dosa yang terampuni.',
      'en':
          'In the name of Allah, Allah is the Greatest, in defiance of Satan and in seeking the pleasure of the Most Merciful. O Allah, make this a pilgrimage accepted and sins forgiven.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['mina', 'jumrah', 'melontar kerikil', 'aqabah', 'takbir'],
    tags: ['Melontar Jumrah', 'Kerikil'],
  ),
  HajjDua(
    id: 'mina_setelah_ula_wustha',
    stage: HajjDuaStage.mina,
    titleKey: 'minaSetelahUlaWusthaTitle',
    title: 'Doa Setelah Melontar Jumrah Ula & Wustha',
    activity: 'Setelah Melontar Jumrah Ula & Wustha',
    contextText:
        'Disunnahkan bergeser sedikit ke kanan menghadap kiblat lalu berdoa mengangkat tangan setelah melontar Jumrah Ula dan Wustha (tidak ada doa setelah Aqabah).',
    arabic:
        'الْحَمْدُ لِلّٰهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ، اللّٰهُمَّ اجْعَلْهُ حَجًّا مَبْرُورًا وَسَعْيًا مَشْكُورًا وَعَمَلًا صَالِحًا مَقْبُولًا',
    transliteration:
        "Alhamdulillaahi hamdan katsiiran thayyiban mubaarakan fiih, Allaahummaj'alhu hajjan mabruuran wa sa'yan masjkuuran wa 'amalan shaalihan maqbuulan.",
    translations: {
      'id':
          'Segala puji bagi Allah dengan pujian yang banyak, baik, lagi penuh berkah di dalamnya. Ya Allah jadikanlah ini haji yang mabrur, usaha yang disyukuri, dan amal saleh yang diterima.',
      'en':
          'All praise is due to Allah, abundant, pure, and blessed praise. O Allah, make this a pilgrimage accepted, efforts rewarded, and righteous deeds received.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Buku Doa dan Zikir Manasik Haji dan Umrah Kemenag RI',
    order: 2,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['mina', 'doa jumrah', 'jumrah ula', 'jumrah wustha', 'tasyrik'],
    tags: ['Setelah Melontar', 'Hari Tasyrik'],
  ),

  // ==========================================
  // 9. TAHALLUL
  // ==========================================
  HajjDua(
    id: 'tahallul_cukur_rambut',
    stage: HajjDuaStage.tahallul,
    titleKey: 'tahallulCukurRambutTitle',
    title: 'Doa Saat Mencukur / Memotong Rambut',
    activity: 'Bercukur / Gunting Rambut',
    contextText:
        'Dibaca ketika mencukur atau memotong sebagian rambut kepala saat bertahallul.',
    arabic:
        'اللّٰهُ أَكْبَرُ، اللّٰهُ أَكْبَرُ، اللّٰهُ أَكْبَرُ، الْحَمْدُ لِلّٰهِ عَلَى مَا هَدَانَا، اللّٰهُمَّ اجْعَلْ لِكُلِّ شَعْرَةٍ نُورًا يَوْمَ الْقِيَامَةِ',
    transliteration:
        "Allaahu akbar, Allaahu akbar, Allaahu akbar. Alhamdulillaahi 'alaa maa hadaanaa, Allaahummaj'al likulli sya'ratin nuuran yawmal qiyaamah.",
    translations: {
      'id':
          'Allah Maha Besar, Allah Maha Besar, Allah Maha Besar. Segala puji bagi Allah atas petunjuk yang diberikan kepada kami. Ya Allah, jadikanlah untuk setiap helai rambut ini cahaya pada hari kiamat.',
      'en':
          'Allah is the Greatest, Allah is the Greatest, Allah is the Greatest. All praise is due to Allah for what He has guided us to. O Allah, make for every strand of hair a light on the Day of Resurrection.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Buku Doa dan Zikir Manasik Haji dan Umrah Kemenag RI',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: [
      'tahallul',
      'cukur',
      'potong rambut',
      'gunting rambut',
      'cahaya',
    ],
    tags: ['Tahallul', 'Bercukur'],
  ),

  // ==========================================
  // 10. THAWAF IFADAH
  // ==========================================
  HajjDua(
    id: 'thawaf_ifadah_panduan',
    stage: HajjDuaStage.tawafIfadah,
    titleKey: 'thawafIfadahPanduanTitle',
    title: 'Panduan Thawaf Ifadah (Rukun Haji)',
    activity: 'Rukun Thawaf Ifadah',
    contextText:
        'Thawaf Ifadah adalah rukun haji yang wajib dilaksanakan setelah wukuf dan tahallul awal. Rangkaian bacaan dan adabnya sama dengan Thawaf.',
    arabic:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    transliteration:
        "Rabbanaa aatinaa fid dunyaa hasanah wa fil aakhirati hasanah wa qinaa 'adzaaban naar.",
    translations: {
      'id':
          'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat dan lindungilah kami dari azab neraka.',
      'en':
          'Our Lord, give us in this world that which is good and in the Hereafter that which is good, and save us from the torment of the Fire.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['thawaf ifadah', 'tawaf ifadah', 'rukun haji', 'ziyarah'],
    tags: ['Rukun Haji', 'Thawaf Ifadah'],
  ),

  // ==========================================
  // 11. TAWAF WADA
  // ==========================================
  HajjDua(
    id: 'tawaf_wada_doa_selesai',
    stage: HajjDuaStage.tawafWada,
    titleKey: 'tawafWadaDoaSelesaiTitle',
    title: 'Doa Setelah Thawaf Wada\' (Tawaf Perpisahan)',
    activity: 'Selesai Thawaf Wada\'',
    contextText:
        'Dibaca setelah selesai melaksanakan Thawaf Wada\' menjelang meninggalkan kota Makkah.',
    arabic:
        'اللّٰهُمَّ لَا تَجْعَلْ هٰذَا آخِرَ الْعَهْدِ بِبَيْتِكَ الْحَرَامِ، وَإِنْ جَعَلْتَهُ فَاعْوِضْنِي عَنْهُ الْجَنَّةَ بِرَحْمَتِكَ يَا أَرْحَمَ الرَّاحِمِينَ',
    transliteration:
        "Allaahumma laa taj'al haadzaa aakhiral 'ahdi bibaitikal haraam, wa in ja'altahu fa'widhnii 'anhul jannata birahmatika yaa arhamar raahimiin.",
    translations: {
      'id':
          'Ya Allah, janganlah Engkau jadikan kunjungan ini saat terakhir bagiku dengan Rumah-Mu yang suci. Dan jika Engkau menjadikannya yang terakhir, maka gantilah untukku dengan surga berkat rahmat-Mu, wahai Tuhan Yang Maha Pengasih lagi Maha Penyayang.',
      'en':
          'O Allah, do not make this the last visit to Your Sacred House, and if You have decreed it to be the last, then grant me Paradise in its place by Your mercy, O Most Merciful of those who show mercy.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['wada', 'tawaf wada', 'perpisahan', 'doa akhir', 'makkah'],
    tags: ['Tawaf Wada', 'Perpisahan'],
  ),

  // ==========================================
  // 12. MADINAH & MASJID NABAWI
  // ==========================================
  HajjDua(
    id: 'madinah_salam_rasulullah',
    stage: HajjDuaStage.madinah,
    titleKey: 'madinahSalamRasulullahTitle',
    title: 'Salam Kepada Rasulullah ﷺ',
    activity: 'Ziarah Makam Nabi ﷺ',
    contextText:
        'Dibaca saat berdiri dengan tenang dan santun di depan makam Rasulullah ﷺ di Masjid Nabawi.',
    arabic:
        'السَّلَامُ عَلَيْكَ يَا رَسُولَ اللّٰهِ وَرَحْمَةُ اللّٰهِ وَبَرَكَاتُهُ، أَشْهَدُ أَنَّكَ بَلَّغْتَ الرِّسَالَةَ وَأَدَّيْتَ الْأَمَانَةَ وَنَصَحْتَ الْأُمَّةَ',
    transliteration:
        "Assalaamu 'alaika yaa Rasuulallaahi wa rahmatullaahi wa barakaatuh, asyhadu annaka ballaghtar risaalata wa addaital amaanata wa nashahtal ummah.",
    translations: {
      'id':
          'Semoga keselamatan, rahmat Allah, dan berkah-Nya tercurah kepadamu wahai Rasulullah. Aku bersaksi bahwa engkau telah menyampaikan risalah, menunaikan amanah, dan menasihati umat.',
      'en':
          'Peace, mercy, and blessings of Allah be upon you, O Messenger of Allah. I bear witness that you conveyed the message, fulfilled the trust, and advised the nation.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI',
    order: 1,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['madinah', 'salam rasulullah', 'makam nabi', 'masjid nabawi'],
    tags: ['Ziarah', 'Salam Rasulullah'],
  ),
  HajjDua(
    id: 'madinah_salam_sahabat',
    stage: HajjDuaStage.madinah,
    titleKey: 'madinahSalamSahabatTitle',
    title: 'Salam Kepada Abu Bakar & Umar RA',
    activity: 'Ziarah Makam Sahabat',
    contextText:
        'Dibaca saat bergeser ke samping makam Nabi ﷺ di depan makam Sayyidina Abu Bakar Ash-Shiddiq dan Sayyidina Umar Al-Faruq radhiyallahu \'anhuma.',
    arabic:
        'السَّلَامُ عَلَيْكَ يَا أَبَا بَكْرٍ الصِّدِّيقَ، السَّلَامُ عَلَيْكَ يَا عُمَرَ الْفَارُوقَ، جَزَاكُمَا اللّٰهُ عَنْ أُمَّةِ مُحَمَّدٍ خَيْرَ الْجَزَاءِ',
    transliteration:
        "Assalaamu 'alaika yaa Abaa Bakrinish Shiddiiq, assalaamu 'alaika yaa 'Umaral Faaruuq, jazaakumallaahu 'an ummati Muhammadin khairal jazaa'.",
    translations: {
      'id':
          'Semoga keselamatan tercurah kepadamu wahai Abu Bakar Ash-Shiddiq, semoga keselamatan tercurah kepadamu wahai Umar Al-Faruq. Semoga Allah membalas kalian berdua atas umat Muhammad dengan sebaik-baik balasan.',
      'en':
          'Peace be upon you, O Abu Bakr as-Siddiq; peace be upon you, O Umar al-Faruq. May Allah reward both of you on behalf of the nation of Muhammad with the best reward.',
    },
    source: 'Kementerian Agama Republik Indonesia',
    sourceReference: 'Tuntunan Manasik Haji dan Umrah Kemenag RI',
    order: 2,
    isRecommended: true,
    requiresSourceVerification: false,
    keywords: ['madinah', 'abu bakar', 'umar', 'sahabat', 'ziarah'],
    tags: ['Makam Sahabat', 'Madinah'],
  ),
];
