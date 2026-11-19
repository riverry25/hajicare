/// Canonical Frame catalog, context enums (8 Hajj locations & 6 interlocutor roles),
/// and context-aware clarification builder for the offline CAMS NLP v3 engine.
enum CamsDecision {
  proceedTranslate,
  requestClarification,
  rejectOov;

  String get wireCode {
    switch (this) {
      case CamsDecision.proceedTranslate:
        return 'PROCEED_TRANSLATE';
      case CamsDecision.requestClarification:
        return 'REQUEST_CLARIFICATION';
      case CamsDecision.rejectOov:
        return 'REJECT_OOV';
    }
  }
}

/// The 8 Hajj locations trained in `cams_v3_offline_weights.json` (`LOC_<tokenKey>`).
enum CamsLocation {
  unknown(
    tokenKey: 'UNKNOWN',
    labelId: 'Lokasi Umum',
    labelEn: 'General Location',
    shortId: 'Pilih Lokasi',
    shortEn: 'Select Location',
    latitude: null,
    longitude: null,
  ),
  areaTawafMasjidilHaram(
    tokenKey: 'AREA_TAWAF_MASJIDIL_HARAM',
    labelId: 'Area Tawaf Masjidil Haram',
    labelEn: 'Tawaf Area - Masjid al-Haram',
    shortId: 'Area Tawaf',
    shortEn: 'Tawaf Area',
    latitude: 21.4225,
    longitude: 39.8262,
  ),
  pintu79MasjidilHaram(
    tokenKey: 'PINTU_79_MASJIDIL_HARAM',
    labelId: 'Pintu 79 Masjidil Haram (King Fahd)',
    labelEn: 'Gate 79 - Masjid al-Haram',
    shortId: 'Pintu 79 Haram',
    shortEn: 'Gate 79 Haram',
    latitude: 21.4216,
    longitude: 39.8246,
  ),
  bukitSafaMarwah(
    tokenKey: 'BUKIT_SAFA_MARWAH_SA_I_',
    labelId: "Bukit Safa & Marwah (Sa'i)",
    labelEn: "Safa & Marwah Hills (Sa'i)",
    shortId: "Safa - Marwah",
    shortEn: "Safa - Marwah",
    latitude: 21.4233,
    longitude: 39.8273,
  ),
  hotelPemondokanMakkah(
    tokenKey: 'HOTEL_PEMONDOKAN_MAKKAH',
    labelId: 'Hotel Pemondokan Makkah',
    labelEn: 'Makkah Pilgrim Hotel',
    shortId: 'Hotel Makkah',
    shortEn: 'Makkah Hotel',
    latitude: 21.4180,
    longitude: 39.8550,
  ),
  terminalBusShalawatSyibAmir(
    tokenKey: 'TERMINAL_BUS_SHALAWAT_SYIB_AMIR',
    labelId: "Terminal Bus Shalawat Syib Amir",
    labelEn: "Syib Amir Shalawat Bus Terminal",
    shortId: 'Terminal Syib Amir',
    shortEn: 'Syib Amir Terminal',
    latitude: 21.4285,
    longitude: 39.8325,
  ),
  klinikSektorMina(
    tokenKey: 'KLINIK_SEKTOR_MINA',
    labelId: 'Klinik Kesehatan Sektor Mina',
    labelEn: 'Mina Sector Medical Clinic',
    shortId: 'Klinik Mina',
    shortEn: 'Mina Clinic',
    latitude: 21.4133,
    longitude: 39.8933,
  ),
  posKesehatanArafah(
    tokenKey: 'POS_KESEHATAN_ARAFAH',
    labelId: 'Pos Kesehatan Arafah',
    labelEn: 'Arafah Medical Post',
    shortId: 'Pos Arafah',
    shortEn: 'Arafah Post',
    latitude: 21.3549,
    longitude: 39.9841,
  ),
  pelataranMasjidNabawiMadinah(
    tokenKey: 'PELATARAN_MASJID_NABAWI_MADINAH',
    labelId: 'Pelataran Masjid Nabawi Madinah',
    labelEn: 'Masjid an-Nabawi Courtyard',
    shortId: 'Masjid Nabawi',
    shortEn: 'Masjid Nabawi',
    latitude: 24.4672,
    longitude: 39.6111,
  );

  final String tokenKey;
  final String labelId;
  final String labelEn;
  final String shortId;
  final String shortEn;
  final double? latitude;
  final double? longitude;

  const CamsLocation({
    required this.tokenKey,
    required this.labelId,
    required this.labelEn,
    required this.shortId,
    required this.shortEn,
    required this.latitude,
    required this.longitude,
  });

  static CamsLocation fromString(String raw) {
    final cleaned = raw
        .trim()
        .toUpperCase()
        .replaceFirst(RegExp(r'^LOC_'), '')
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
    for (final loc in CamsLocation.values) {
      if (loc.tokenKey == cleaned ||
          loc.tokenKey.replaceAll(RegExp(r'_+$'), '') ==
              cleaned.replaceAll(RegExp(r'_+$'), '')) {
        return loc;
      }
    }
    return CamsLocation.unknown;
  }
}

/// The 6 interlocutor roles trained in `cams_v3_offline_weights.json` (`ROLE_<tokenKey>`).
enum CamsInterlocutorRole {
  unknown(
    tokenKey: 'UNKNOWN',
    labelId: 'Lawan Bicara Umum',
    labelEn: 'General Interlocutor',
    shortId: 'Lawan Bicara',
    shortEn: 'Interlocutor',
  ),
  dokterKlinikSaudi(
    tokenKey: 'DOKTER_KLINIK_SAUDI',
    labelId: 'Dokter Klinik Saudi',
    labelEn: 'Saudi Clinic Doctor',
    shortId: 'Dokter',
    shortEn: 'Doctor',
  ),
  petugasMedisTkhi(
    tokenKey: 'PETUGAS_MEDIS_TKHI',
    labelId: 'Petugas Medis TKHI',
    labelEn: 'Indonesian Medical Officer (TKHI)',
    shortId: 'Medis TKHI',
    shortEn: 'Medical TKHI',
  ),
  asykarKeamananSaudi(
    tokenKey: 'ASYKAR_KEAMANAN_SAUDI',
    labelId: 'Asykar / Keamanan Masjid',
    labelEn: 'Haram Security Officer (Asykar)',
    shortId: 'Asykar',
    shortEn: 'Asykar',
  ),
  pembimbingManasikMutawwif(
    tokenKey: 'PEMBIMBING_MANASIK_MUTAWWIF',
    labelId: 'Mutawwif / Pembimbing Manasik',
    labelEn: 'Mutawwif / Hajj Guide',
    shortId: 'Mutawwif',
    shortEn: 'Mutawwif',
  ),
  petugasLayananJamaah(
    tokenKey: 'PETUGAS_LAYANAN_JAMAAH',
    labelId: 'Petugas Hotel & Layanan Jamaah',
    labelEn: 'Hotel & Pilgrim Service Staff',
    shortId: 'Petugas Hotel',
    shortEn: 'Hotel Staff',
  ),
  petugasTransportasiHaji(
    tokenKey: 'PETUGAS_TRANSPORTASI_HAJI',
    labelId: 'Petugas Transportasi Bus Shalawat',
    labelEn: 'Hajj Bus Transport Officer',
    shortId: 'Transportasi / Jamaah',
    shortEn: 'Transport / Pilgrim',
  );

  final String tokenKey;
  final String labelId;
  final String labelEn;
  final String shortId;
  final String shortEn;

  const CamsInterlocutorRole({
    required this.tokenKey,
    required this.labelId,
    required this.labelEn,
    required this.shortId,
    required this.shortEn,
  });

  static CamsInterlocutorRole fromString(String raw) {
    final cleaned = raw
        .trim()
        .toUpperCase()
        .replaceFirst(RegExp(r'^ROLE_'), '')
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
    for (final role in CamsInterlocutorRole.values) {
      if (role.tokenKey == cleaned) return role;
    }
    return CamsInterlocutorRole.unknown;
  }
}

class CamsCanonicalFrame {
  final String idC0;
  final String idC3;
  final String enText;
  final String arText;

  const CamsCanonicalFrame({
    required this.idC0,
    required this.idC3,
    required this.enText,
    required this.arText,
  });
}

class CamsClarificationOption {
  final String id;
  final String labelId;
  final String labelEn;
  final List<String> glossTokens;
  final String iconKey;

  const CamsClarificationOption({
    required this.id,
    required this.labelId,
    required this.labelEn,
    required this.glossTokens,
    required this.iconKey,
  });
}

class CamsCanonicalFrameResolver {
  CamsCanonicalFrameResolver._();

  static CamsCanonicalFrame resolve({
    required String intent,
    required List<String> normalizedTokens,
    required CamsLocation location,
    required CamsInterlocutorRole role,
  }) {
    final tokenSet = normalizedTokens.toSet();

    // Exact canonical overrides based on core concept pairs
    if (tokenSet.contains('DOKTER') &&
        (tokenSet.contains('BANTU') ||
            intent == 'MEDICAL_EMERGENCY_CRITICAL' ||
            intent == 'FIND_MEDICAL_FACILITY')) {
      return const CamsCanonicalFrame(
        idC0: 'Bantu saya dokter.',
        idC3: 'Tolong bantu saya memanggil dokter.',
        enText: 'Please help me call a doctor.',
        arText: 'من فضلك ساعدني في استدعاء الطبيب.',
      );
    }

    if (tokenSet.contains('SESAK') || tokenSet.contains('NAFAS')) {
      return const CamsCanonicalFrame(
        idC0: 'Saya sesak napas, butuh bantuan medis darurat.',
        idC3: 'Tolong saya, saya mengalami sesak napas dan membutuhkan pertolongan medis segera.',
        enText: 'Please help me, I am having difficulty breathing and need urgent medical attention.',
        arText: 'أرجوك ساعدني، أعاني من ضيق في التنفس وأحتاج إلى مساعدة طبية عاجلة.',
      );
    }

    if (tokenSet.contains('WUDHU')) {
      return const CamsCanonicalFrame(
        idC0: 'Di mana tempat wudhu?',
        idC3: 'Permisi, mohon petunjuk di mana lokasi tempat wudhu terdekat?',
        enText: 'Excuse me, could you please show me where the nearest ablution (wudu) area is?',
        arText: 'عفواً، هل يمكنك إرشادي إلى أقرب مكان للوضوء؟',
      );
    }

    if (tokenSet.contains('MASJID') &&
        (tokenSet.contains('MANA') ||
            tokenSet.contains('DIMANA') ||
            tokenSet.contains('ARAH') ||
            intent == 'WORSHIP_FACILITY_ACCESS')) {
      return const CamsCanonicalFrame(
        idC0: 'Di mana arah pintu masjid?',
        idC3: 'Permisi, mohon petunjuk arah menuju pintu masuk masjid terdekat.',
        enText: 'Excuse me, please guide me to the nearest mosque entrance.',
        arText: 'عفواً، من فضلك أرشدني إلى أقرب مدخل للمسجد.',
      );
    }

    if (tokenSet.contains('MINUM') ||
        tokenSet.contains('AIR') ||
        tokenSet.contains('HAUS')) {
      return const CamsCanonicalFrame(
        idC0: 'Saya haus, minta air minum.',
        idC3: 'Permisi, saya merasa haus. Bolehkah saya meminta air minum?',
        enText: 'Excuse me, I am thirsty. May I please have some drinking water?',
        arText: 'عفواً، أنا عطشان. هل يمكنني الحصول على ماء للشرب من فضلك؟',
      );
    }

    if (tokenSet.contains('MAKAN')) {
      return const CamsCanonicalFrame(
        idC0: 'Saya butuh makanan.',
        idC3: 'Permisi, mohon bantuan di mana saya bisa mendapatkan makanan jamaah?',
        enText: 'Excuse me, could you help me find where to get pilgrim meals?',
        arText: 'عفواً، هل يمكنك مساعدتي في معرفة مكان الحصول على وجبات الطعام؟',
      );
    }

    if (tokenSet.contains('BUS')) {
      return const CamsCanonicalFrame(
        idC0: 'Di mana bus menuju hotel saya?',
        idC3: 'Permisi, mohon petunjuk terminal atau bus Shalawat menuju hotel pemondokan saya.',
        enText: 'Excuse me, please direct me to the shuttle bus going to my hotel.',
        arText: 'عفواً، من فضلك أرشدني إلى حافلة الترددية المتجهة إلى فندقي.',
      );
    }

    if (tokenSet.contains('TERIMA_KASIH') ||
        (tokenSet.contains('TERIMA') && tokenSet.contains('KASIH'))) {
      return const CamsCanonicalFrame(
        idC0: 'Terima kasih banyak.',
        idC3: 'Terima kasih banyak atas bantuan dan kebaikan Anda.',
        enText: 'Thank you very much for your kind help and assistance.',
        arText: 'شكراً جزيلاً لك على مساعدتك ولطفك.',
      );
    }

    switch (intent) {
      case 'MEDICAL_EMERGENCY_CRITICAL':
        return const CamsCanonicalFrame(
          idC0: 'Darurat medis, tolong bantu saya segera.',
          idC3: 'Tolong bantu saya segera, saya sedang dalam kondisi darurat medis.',
          enText: 'Please help me immediately, I am experiencing a medical emergency.',
          arText: 'من فضلك ساعدني فوراً، أنا في حالة طبية طارئة.',
        );
      case 'FIND_MEDICAL_FACILITY':
        return const CamsCanonicalFrame(
          idC0: 'Di mana klinik kesehatan terdekat?',
          idC3: 'Permisi, mohon petunjuk arah ke klinik atau pos kesehatan terdekat.',
          enText: 'Excuse me, please guide me to the nearest medical clinic or health post.',
          arText: 'عفواً، من فضلك أرشدني إلى أقرب عيادة طبية أو مركز صحي.',
        );
      case 'MEDICAL_SYMPTOM_CONSULT':
        return const CamsCanonicalFrame(
          idC0: 'Saya merasa sakit dan pusing.',
          idC3: 'Dokter, saya adalah jamaah Tuli. Saya merasa sakit, lemas, dan pusing.',
          enText: 'Doctor, I am a Deaf pilgrim. I am feeling sick, weak, and dizzy.',
          arText: 'يا دكتور، أنا حاج أصم. أشعر بالألم والدوار والإرهاق.',
        );
      case 'MEDICATION_PHARMACY':
        return const CamsCanonicalFrame(
          idC0: 'Saya membutuhkan obat.',
          idC3: 'Permisi Dokter, saya membutuhkan obat untuk meredakan keluhan sakit dan pusing saya.',
          enText: 'Excuse me Doctor, I need medication to relieve my pain and dizziness.',
          arText: 'عفواً يا دكتور، أحتاج إلى دواء لتخفيف الألم والدوار.',
        );
      case 'WORSHIP_FACILITY_ACCESS':
        return const CamsCanonicalFrame(
          idC0: 'Di mana fasilitas masjid dan tempat wudhu?',
          idC3: 'Permisi, mohon petunjuk arah menuju ruang shalat dan tempat wudhu di masjid ini.',
          enText: 'Excuse me, please show me the way to the prayer area and ablution facility.',
          arText: 'عفواً، من فضلك أرشدني إلى مصلى المسجد ومكان الوضوء.',
        );
      case 'MANASIK_AND_WORSHIP_GUIDANCE':
        return const CamsCanonicalFrame(
          idC0: 'Mohon bimbingan arah ibadah dan shalat.',
          idC3: 'Permisi Pembimbing, mohon petunjuk arah kiblat dan tata cara pelaksanaan ibadah di sini.',
          enText: 'Excuse me Guide, please help me with the Qibla direction and worship guidance here.',
          arText: 'عفواً يا مرشد، أرجو إرشادي إلى اتجاه القبلة وكيفية أداء المناسك هنا.',
        );
      case 'LOST_AND_NAVIGATION':
        return const CamsCanonicalFrame(
          idC0: 'Saya terpisah dari rombongan, bantu arah ke hotel.',
          idC3: 'Permisi, saya jamaah Tuli dan terpisah dari rombongan. Mohon bantu saya kembali ke hotel pemondokan.',
          enText: 'Excuse me, I am a Deaf pilgrim separated from my group. Please help me return to my hotel.',
          arText: 'عفواً، أنا حاج أصم وقد انفصلت عن مجموعتي. أرجو مساعدتي للعودة إلى الفندق.',
        );
      case 'ACCOMMODATION_AND_LOGISTICS':
        return const CamsCanonicalFrame(
          idC0: 'Mohon bantuan kamar hotel saya.',
          idC3: 'Permisi Petugas Hotel, mohon bantuan informasi mengenai kamar pemondokan dan fasilitas saya.',
          enText: 'Excuse me Hotel Staff, please assist me with my hotel room and accommodation.',
          arText: 'عفواً موظف الفندق، أرجو مساعدتي بخصوص غرفتي وخدمات السكن.',
        );
      case 'COMPANION_AND_COMMUNICATION':
        return const CamsCanonicalFrame(
          idC0: 'Saya jamaah Tuli, mohon bicara perlahan atau hubungi pendamping.',
          idC3: 'Permisi, saya adalah jamaah Tuli. Mohon bantu hubungi pendamping rombongan saya atau gunakan teks di layar ini.',
          enText: 'Excuse me, I am a Deaf pilgrim. Please help contact my group companion or communicate via this screen.',
          arText: 'عفواً، أنا حاج أصم. أرجو المساعدة في الاتصال بمرافق مجموعتي أو التواصل عبر هذه الشاشة.',
        );
      case 'DAILY_ASSISTANCE':
        return const CamsCanonicalFrame(
          idC0: 'Mohon bantuan kebutuhan harian saya.',
          idC3: 'Permisi, mohon bantuan untuk kebutuhan makan, air minum, atau istirahat saya.',
          enText: 'Excuse me, could you please assist me with drinking water, food, or a place to rest?',
          arText: 'عفواً، هل يمكنك مساعدتي في الحصول على ماء للشرب أو طعام أو مكان للراحة؟',
        );
      case 'GENERAL_SOCIAL_AND_DAILY':
      default:
        return const CamsCanonicalFrame(
          idC0: 'Assalamualaikum, semoga Anda sehat dan baik.',
          idC3: 'Assalamualaikum, halo! Saya jamaah Haji Tuli dari Indonesia. Terima kasih atas bantuan Anda.',
          enText: 'Peace be upon you, hello! I am a Deaf Hajj pilgrim from Indonesia. Thank you for your help.',
          arText: 'السلام عليكم، مرحباً! أنا حاج أصم من إندونيسيا. شكراً جزيلاً لمساعدتكم.',
        );
    }
  }

  static List<CamsClarificationOption> buildClarifications({
    required List<String> normalizedTokens,
    required CamsLocation location,
    required CamsInterlocutorRole role,
    String? topIntent,
  }) {
    final tokenSet = normalizedTokens.toSet();

    if (tokenSet.contains('AIR') ||
        tokenSet.contains('MINUM') ||
        tokenSet.contains('WUDHU') ||
        tokenSet.contains('MANDI')) {
      return const [
        CamsClarificationOption(
          id: 'clarify_wudhu',
          labelId: 'Cari Tempat Wudhu',
          labelEn: 'Find Ablution (Wudu) Area',
          glossTokens: ['MANA', 'WUDHU'],
          iconKey: 'water_drop',
        ),
        CamsClarificationOption(
          id: 'clarify_minum',
          labelId: 'Minta Air Minum',
          labelEn: 'Ask for Drinking Water',
          glossTokens: ['MINUM', 'AIR'],
          iconKey: 'local_drink',
        ),
        CamsClarificationOption(
          id: 'clarify_masjid',
          labelId: 'Arah Pintu Masjid',
          labelEn: 'Mosque Entrance Direction',
          glossTokens: ['MANA', 'MASJID'],
          iconKey: 'mosque',
        ),
      ];
    }

    if (role == CamsInterlocutorRole.dokterKlinikSaudi ||
        role == CamsInterlocutorRole.petugasMedisTkhi ||
        location == CamsLocation.klinikSektorMina ||
        location == CamsLocation.posKesehatanArafah) {
      return const [
        CamsClarificationOption(
          id: 'clarify_dokter',
          labelId: 'Panggil Dokter / Darurat',
          labelEn: 'Call a Doctor / Emergency',
          glossTokens: ['BANTU', 'DOKTER'],
          iconKey: 'medical_services',
        ),
        CamsClarificationOption(
          id: 'clarify_obat',
          labelId: 'Minta Obat Sakit / Pusing',
          labelEn: 'Request Medicine for Pain/Dizziness',
          glossTokens: ['OBAT', 'PUSING'],
          iconKey: 'medication',
        ),
        CamsClarificationOption(
          id: 'clarify_sesak',
          labelId: 'Sesak Napas / Butuh Oksigen',
          labelEn: 'Shortness of Breath / Urgent Help',
          glossTokens: ['SAKIT', 'SESAK', 'NAFAS'],
          iconKey: 'emergency',
        ),
      ];
    }

    return const [
      CamsClarificationOption(
        id: 'clarify_dokter',
        labelId: 'Panggil Dokter / Bantuan Medis',
        labelEn: 'Call a Doctor / Medical Help',
        glossTokens: ['BANTU', 'DOKTER'],
        iconKey: 'medical_services',
      ),
      CamsClarificationOption(
        id: 'clarify_tersesat',
        labelId: 'Tersesat / Cari Arah Hotel',
        labelEn: 'Lost / Find Hotel Direction',
        glossTokens: ['HILANG', 'HOTEL'],
        iconKey: 'explore',
      ),
      CamsClarificationOption(
        id: 'clarify_wudhu',
        labelId: 'Cari Tempat Wudhu / Masjid',
        labelEn: 'Find Wudu / Mosque Entrance',
        glossTokens: ['MANA', 'WUDHU'],
        iconKey: 'mosque',
      ),
    ];
  }
}
