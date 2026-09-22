import re
import os

ADDITIONAL_KEYS = {
    'profile.passportCountry': {
        'id': 'Paspor: {country}',
        'en': 'Passport: {country}',
        'jv': 'Paspor: {country}',
        'su': 'Paspor: {country}',
    },
    'profile.defaultUser': {
        'id': 'Pengguna HajiCare',
        'en': 'HajiCare User',
        'jv': 'Panganggo HajiCare',
        'su': 'Pamaké HajiCare',
    },
    'profile.kloterNumber': {
        'id': 'Kloter {kloter}',
        'en': 'Flight {kloter}',
        'jv': 'Kloter {kloter}',
        'su': 'Kloter {kloter}',
    },
    'profile.maktabNumber': {
        'id': 'Maktab {maktab}',
        'en': 'Maktab {maktab}',
        'jv': 'Maktab {maktab}',
        'su': 'Maktab {maktab}',
    },
    'profile.user': {
        'id': 'Pengguna',
        'en': 'User',
        'jv': 'Panganggo',
        'su': 'Pamaké',
    },
    'profile.userIdentityBadge': {
        'id': 'IDENTITAS PENGGUNA',
        'en': 'USER IDENTITY',
        'jv': 'IDENTITAS PANGANGGO',
        'su': 'IDÉNTITAS PAMAKÉ',
    },
    'profile.healthDataBadge': {
        'id': 'DATA KESEHATAN JAMAAH',
        'en': 'PILGRIM HEALTH DATA',
        'jv': 'DATA KASARASAN JAMAAH',
        'su': 'DATA KASÉHATAN JAMAAH',
    },
    'profile.logoutConfirmAction': {
        'id': 'Ya, Keluar',
        'en': 'Yes, Sign Out',
        'jv': 'Inggih, Miyos',
        'su': 'Muhun, Kaluar',
    },
    'profile.desc': {
        'id': 'Kelola akun dan preferensi Hajicare Anda',
        'en': 'Manage your HajiCare account and preferences',
        'jv': 'Atur akun lan preferensi HajiCare panjenengan',
        'su': 'Atur akun sareng pilihan HajiCare anjeun',
    },
    'profile.trackingRoom': {
        'id': 'Room Pemantauan',
        'en': 'Monitoring Room',
        'jv': 'Room Pamantauan',
        'su': 'Room Pamantauan',
    },
    'profile.companionRoom': {
        'id': 'Pendamping Room',
        'en': 'Room Companion',
        'jv': 'Pendamping Room',
        'su': 'Pendamping Room',
    },
    'profile.companionAndActiveRoom': {
        'id': 'Pendamping & Room Aktif',
        'en': 'Companion & Active Room',
        'jv': 'Pendamping & Room Aktif',
        'su': 'Pendamping & Room Aktif',
    },
    'profile.connectedToMonitoring': {
        'id': 'Terhubung ke pengawasan rombongan Anda',
        'en': 'Connected to your group monitoring',
        'jv': 'Sambung dhateng pamantauan rombongan panjenengan',
        'su': 'Nyambung kana pangawasan rombongan anjeun',
    },
    'profile.notConnectedToRoom': {
        'id': 'Anda belum terhubung ke room rombongan manapun',
        'en': 'You are not connected to any group room yet',
        'jv': 'Panjenengan dèrèng sambung dhateng room rombongan pundi kemawon',
        'su': 'Anjeun teu acan nyambung kana room rombongan mana waé',
    },
    'profile.noRoomConnected': {
        'id': 'Belum Ada Room Terhubung',
        'en': 'No Room Connected Yet',
        'jv': 'Dèrèng Wonten Room Sambung',
        'su': 'Teu Acan Aya Room Nyambung',
    },
    'profile.joinRoomNow': {
        'id': 'Gabung Room Sekarang',
        'en': 'Join Room Now',
        'jv': 'Gathuk Room Sakmenika',
        'su': 'Gabung Room Ayeuna',
    },
    'profile.leader': {
        'id': 'Ketua Rombongan',
        'en': 'Group Leader',
        'jv': 'Pangarsa Rombongan',
        'su': 'Pupuhu Rombongan',
    },
    'profile.connectionStatus': {
        'id': 'Status Sambungan',
        'en': 'Connection Status',
        'jv': 'Kahanan Sambungan',
        'su': 'Status Sambungan',
    },
    'profile.realtimeConnected': {
        'id': 'Terkoneksi Realtime',
        'en': 'Realtime Connected',
        'jv': 'Sambung Realtime',
        'su': 'Nyambung Realtime',
    },
    'profile.done': {
        'id': 'Selesai',
        'en': 'Done',
        'jv': 'Rampung',
        'su': 'Rengsé',
    },
    'profile.nik': {
        'id': 'NIK',
        'en': 'NIK',
        'jv': 'NIK',
        'su': 'NIK',
    },
    'profile.portionNumber': {
        'id': 'Nomor Porsi',
        'en': 'Portion Number',
        'jv': 'Nomer Porsi',
        'su': 'Nomer Porsi',
    },
    'profile.bloodType': {
        'id': 'Golongan Darah',
        'en': 'Blood Type',
        'jv': 'Golongan Getih',
        'su': 'Golongan Darah',
    },
    'profile.allergyHistory': {
        'id': 'Riwayat Alergi',
        'en': 'Allergy History',
        'jv': 'Riwayat Alergi',
        'su': 'Riwayat Alérgi',
    },
    'profile.specialConditions': {
        'id': 'Kondisi Khusus',
        'en': 'Special Conditions',
        'jv': 'Kahanan Kusus',
        'su': 'Kaayaan Khusus',
    },
    'profile.emergencyContact': {
        'id': 'Kontak Darurat',
        'en': 'Emergency Contact',
        'jv': 'Kontak Darurat',
        'su': 'Kontak Darurat',
    },
    'profile.passportNumber': {
        'id': 'Nomor Paspor',
        'en': 'Passport Number',
        'jv': 'Nomer Paspor',
        'su': 'Nomer Paspor',
    },
    'common.close': {
        'id': 'Tutup',
        'en': 'Close',
        'jv': 'Tutup',
        'su': 'Tutup',
    },
    'common.save': {
        'id': 'SIMPAN',
        'en': 'SAVE',
        'jv': 'SIMPEN',
        'su': 'SIMPEN',
    },
    'common.tryAgain': {
        'id': 'Coba Lagi',
        'en': 'Try Again',
        'jv': 'Cobi Malih',
        'su': 'Cobian Deui',
    },
    'auth.roleAdmin': {
        'id': 'Admin',
        'en': 'Admin',
        'jv': 'Admin',
        'su': 'Admin',
    },
    # Onboarding
    'onboarding.skip': {
        'id': 'Lewati',
        'en': 'Skip',
        'jv': 'Langkahi',
        'su': 'Liwat',
    },
    'onboarding.stepProgress': {
        'id': 'Langkah {current} dari {total} • Menuju Perjalanan Aman Anda',
        'en': 'Step {current} of {total} • Towards Your Safe Journey',
        'jv': 'Jangkah {current} saking {total} • Tumuju Lampah Aman Panjenengan',
        'su': 'Lengkah {current} tina {total} • Nuju Lalampahan Aman Anjeun',
    },
    'onboarding.chooseLanguageTitle': {
        'id': 'Pilih Bahasa Kenyamanan',
        'en': 'Choose Preferred Language',
        'jv': 'Pilih Basa Kapenak',
        'su': 'Pilih Basa Merenah',
    },
    'onboarding.chooseLanguageDesc': {
        'id': 'Pilih bahasa yang paling mudah dipahami untuk kenyamanan ibadah dan komunikasi darurat Anda.',
        'en': 'Choose the language you understand best for comfortable worship and emergency communication.',
        'jv': 'Pilih basa ingkang paling gampil dipunmangertosi kagem katentreman ibadah lan komunikasi darurat.',
        'su': 'Pilih basa anu paling gampil kahartos pikeun kanyamanan ibadah sareng komunikasi darurat.',
    },
    'onboarding.audioGuideHint': {
        'id': 'Ukuran teks dan panduan audio akan otomatis disesuaikan dengan bahasa yang dipilih.',
        'en': 'Text size and audio guides will automatically adjust to the selected language.',
        'jv': 'Ukuran tulisan lan pandhuan swanten badhé otomatis trep kaliyan basa ingkang dipunpilih.',
        'su': 'Ukuran téks sareng pituduh audio bakal otomatis nyaluyukeun sareng basa anu dipilih.',
    },
    'onboarding.introTitle': {
        'id': 'Bahasa Pengantar',
        'en': 'Introductory Language',
        'jv': 'Basa Pambuka',
        'su': 'Basa Panganteur',
    },
    'onboarding.introDesc': {
        'id': 'Pilih bahasa yang paling mudah dipahami selama ibadah.',
        'en': 'Choose the language most easily understood during pilgrimage.',
        'jv': 'Pilih basa ingkang paling gampil dipunmangertosi nalika ibadah.',
        'su': 'Pilih basa anu paling gampang kaharti salila ibadah.',
    },
    'onboarding.indonesiaSubtitle': {
        'id': 'Baku & Lengkap',
        'en': 'Standard & Complete',
        'jv': 'Baku & Jangkep',
        'su': 'Baku & Lengkep',
    },
    'onboarding.jawiSubtitle': {
        'id': 'Unggah-ungguh',
        'en': 'Polite & Traditional',
        'jv': 'Unggah-ungguh',
        'su': 'Tata Titi',
    },
    'onboarding.sundaSubtitle': {
        'id': 'Lemes & Santun',
        'en': 'Polite & Gentle',
        'jv': 'Alus & Santun',
        'su': 'Lemes & Santun',
    },
    'onboarding.englishSubtitle': {
        'id': 'Global Standard',
        'en': 'Global Standard',
        'jv': 'Standar Internasional',
        'su': 'Standar Internasional',
    },
    'onboarding.safetySlideTitle': {
        'id': 'Jaga Jarak Aman & Terpantau',
        'en': 'Keep Safe Distance & Stay Monitored',
        'jv': 'Jagi Jarak Aman & Kapantau',
        'su': 'Jaga Jarak Aman & Kapantau',
    },
    'onboarding.safetySystemBadge': {
        'id': 'Sistem Keselamatan Jamaah',
        'en': 'Pilgrim Safety System',
        'jv': 'Sistem Kaslametan Jamaah',
        'su': 'Sistem Kasalametan Jamaah',
    },
    'onboarding.stage2Of3': {
        'id': '2 DARI 3 TAHAP AWAL',
        'en': '2 OF 3 INITIAL STAGES',
        'jv': '2 SAKING 3 TAHAP WIWITAN',
        'su': '2 TINA 3 TAHAP MIMITI',
    },
    'onboarding.safetyFeaturesHeader': {
        'id': 'Fitur Keselamatan Jamaah',
        'en': 'Pilgrim Safety Features',
        'jv': 'Fitur Kaslametan Jamaah',
        'su': 'Fitur Kasalametan Jamaah',
    },
    'onboarding.safetyFeaturesSub': {
        'id': 'Teknologi pendampingan cerdas agar jamaah tetap aman dan terhubung selama ibadah.',
        'en': 'Smart guiding technology to keep pilgrims safe and connected throughout worship.',
        'jv': 'Tèknologi pamomong pinter supados jamaah tetep aman lan sambung nalika ibadah.',
        'su': 'Téknologi pendampingan palinter supados jamaah tetep aman sareng nyambung salila ibadah.',
    },
    'onboarding.safeCompanion': {
        'id': 'Pendamping Aman',
        'en': 'Safe Companion',
        'jv': 'Pendamping Aman',
        'su': 'Pendamping Aman',
    },
    'onboarding.safeCompanionDesc': {
        'id': 'Pantau rombongan secara real-time dan terima peringatan otomatis saat terpisah melebihi batas aman.',
        'en': 'Monitor groups in real-time and get automated alerts when separated beyond safe boundaries.',
        'jv': 'Pantau rombongan kanthi wekdal nyata lan nampi pepènget nalika pisah langkung wates aman.',
        'su': 'Pantau rombongan sacara réall-time sareng nampi pépéling nalika papisah ngaleuwihan wates aman.',
    },
    'onboarding.radarActive': {
        'id': 'Radar Aktif',
        'en': 'Active Radar',
        'jv': 'Radar Aktif',
        'su': 'Radar Aktif',
    },
    'onboarding.integratedMapSos': {
        'id': 'Peta Terpadu & SOS',
        'en': 'Integrated Map & SOS',
        'jv': 'Peta Manunggal & SOS',
        'su': 'Peta Terpadu & SOS',
    },
    'onboarding.integratedMapSosDesc': {
        'id': 'Temukan pos kesehatan, hotel, dan hubungi bantuan darurat hanya dengan satu sentuhan.',
        'en': 'Find health posts, hotels, and reach emergency assistance with a single touch.',
        'jv': 'Panggihaken pos kasarasen, hotèl, lan hubungi pitulungan darurat namung sakéntokan.',
        'su': 'Panggiheun pos kaséhatan, hotél, sareng kontak bantosan darurat ngan ku sakali toél.',
    },
    'onboarding.sos24h': {
        'id': 'SOS 24 Jam',
        'en': '24/7 SOS',
        'jv': 'SOS 24 Jam',
        'su': 'SOS 24 Jam',
    },
    'onboarding.elderlyFriendly': {
        'id': 'Ramah Jamaah Lansia',
        'en': 'Elderly-Friendly',
        'jv': 'Mirunggan Jamaah Sepuh',
        'su': 'Ramah Jamaah Sepuh',
    },
    'onboarding.elderlyFriendlyDesc': {
        'id': 'Ukuran tombol besar, kontras tinggi, dan mudah digunakan di bawah terik matahari.',
        'en': 'Large buttons, high contrast, and easy to use under bright sunlight.',
        'jv': 'Tombol ageng, kontras inggil, lan gampil kaginakaken ing sangandhaping srengéngé.',
        'su': 'Tombol ageung, kontras luhur, sareng gampil dianggo dina handapeun panonpoé.',
    },
    'onboarding.safetyFooterNote': {
        'id': 'Notifikasi getar dan suara otomatis aktif untuk membantu jamaah tetap aman selama perjalanan.',
        'en': 'Vibration and audio notifications are automatically active to keep pilgrims safe during travel.',
        'jv': 'Notifikasi kedher lan swanten otomatis aktif kagem mbiyantu jamaah tetep aman ing lampah.',
        'su': 'Wawaran geter sareng sora otomatis aktif pikeun mantuan jamaah tetep aman dina lalampahan.',
    },
    'onboarding.accessSlideBadge': {
        'id': 'Aksesibilitas Ramah Lansia & Disabilitas',
        'en': 'Elderly & Disability Accessibility',
        'jv': 'Aksesibilitas Mirunggan Lansia & Disabilitas',
        'su': 'Aksésibilitas Ramah Lansia & Disabilitas',
    },
    'onboarding.accessSlideTitle': {
        'id': 'Mudah Diakses Siapa Saja',
        'en': 'Accessible to Everyone',
        'jv': 'Gampil Dipun-aksès Sinten Kemawon',
        'su': 'Gampil Diaksés Ku Saha Wae',
    },
    'onboarding.stage3Of3': {
        'id': '3 DARI 3 TAHAP AWAL',
        'en': '3 OF 3 INITIAL STAGES',
        'jv': '3 SAKING 3 TAHAP WIWITAN',
        'su': '3 TINA 3 TAHAP MIMITI',
    },
    'onboarding.accessFeaturesHeader': {
        'id': 'Fitur Kemudahan',
        'en': 'Accessibility Features',
        'jv': 'Fitur Kagampilan',
        'su': 'Fitur Kamudahan',
    },
    'onboarding.accessFeaturesSub': {
        'id': 'Membantu jamaah lansia dan disabilitas beribadah lebih nyaman.',
        'en': 'Assisting elderly and disabled pilgrims to worship more comfortably.',
        'jv': 'Mbiyantu jamaah sepuh lan disabilitas nglampahi ibadah kanthi kapenak.',
        'su': 'Mantuan jamaah sepuh sareng disabilitas ibadah langkung merenah.',
    },
    'onboarding.accessIntro': {
        'id': 'Bantuan cerdas deteksi uang riyal dan komunikasi suara & isyarat untuk kelancaran ibadah jamaah lansia dan berkebutuhan khusus.',
        'en': 'Smart assistance for riyal currency detection and voice & sign communication for elderly and special needs pilgrims.',
        'jv': 'Pitulungan pinter deteksi arta riyal lan komunikasi swanten & sasmita kagem kalancaran ibadah jamaah sepuh lan kabetahan kusus.',
        'su': 'Bantosan pinter deteksi artos riyal sareng komunikasi sora & isarat pikeun kalancaran ibadah jamaah sepuh sareng kabutuhan khusus.',
    },
    'onboarding.scanRiyal': {
        'id': 'Scan Uang Riyal',
        'en': 'Scan Saudi Riyal',
        'jv': 'Scan Arta Riyal',
        'su': 'Scan Artos Riyal',
    },
    'onboarding.scanRiyalDesc': {
        'id': 'Arahkan kamera ke lembaran riyal, nominal langsung terdeteksi dan dibacakan otomatis via suara (Text-to-Speech).',
        'en': 'Point the camera at riyal notes; value is instantly detected and read aloud via voice (Text-to-Speech).',
        'jv': 'Arahaken kodhak dhateng lembaran riyal, nominal langsung kawaca lan kasebat otomatis liwat swanten.',
        'su': 'Arahkeun kaméra kana lambaran riyal, nominal langsung katiténan sareng dibacakeun otomatis ku sora.',
    },
    'onboarding.commGestures': {
        'id': 'Komunikasi & Isyarat',
        'en': 'Communication & Gestures',
        'jv': 'Komunikasi & Sasmita',
        'su': 'Komunikasi & Isarat',
    },
    'onboarding.commGesturesDesc': {
        'id': 'Konversi bicara ke teks besar serta ungkapan darurat cepat (Tolong, Sakit, Air) yang mudah dimengerti warga lokal.',
        'en': 'Speech to large text conversion and fast emergency phrases (Help, Pain, Water) easily understood by locals.',
        'jv': 'Ngarubah caturan dados tulisan ageng lan tembung darurat cepet (Pitulung, Gerah, Toya) ingkang gampil dipunpahami warga lokal.',
        'su': 'Ngarobih caritaan kana téks ageung sareng ungkapan darurat gancang (Tulung, Teu Damang, Cai) anu gampil kahartos ku warga lokal.',
    },
    'onboarding.voiceAndText': {
        'id': 'SUARA & TEKS',
        'en': 'VOICE & TEXT',
        'jv': 'SWANTEN & TULISAN',
        'su': 'SORA & TEKS',
    },
    'onboarding.ttsReady': {
        'id': 'Text-to-Speech dan bantuan suara siap digunakan untuk membantu jamaah selama perjalanan ibadah.',
        'en': 'Text-to-Speech and voice aids are ready to assist pilgrims during worship.',
        'jv': 'Text-to-Speech lan pitulungan swanten sumadya kagem mbiyantu jamaah nalika lampah ibadah.',
        'su': 'Text-to-Speech sareng bantosan sora sayaga dianggo pikeun mantuan jamaah dina ibadah.',
    },

    # Profile Extra Keys
    'profile.groupAccountData': {
        'id': 'Data Jamaah & Rombongan',
        'en': 'Pilgrim & Group Data',
        'jv': 'Data Jamaah & Rombongan',
        'su': 'Data Jamaah & Rombongan',
    },
    'profile.medicalData': {
        'id': 'Data Medis & Riwayat',
        'en': 'Medical Data & History',
        'jv': 'Data Medis & Riwayat',
        'su': 'Data Médis & Sajarah',
    },
    'profile.view': {
        'id': 'Lihat',
        'en': 'View',
        'jv': 'Tingali',
        'su': 'Tingal',
    },
    'profile.manageCompanion': {
        'id': 'Kontak Pendamping & Room',
        'en': 'Companion Contact & Room',
        'jv': 'Kontak Pendamping & Room',
        'su': 'Kontak Pendamping & Room',
    },
    'profile.active': {
        'id': 'Aktif',
        'en': 'Active',
        'jv': 'Aktif',
        'su': 'Aktif',
    },
    'profile.accessibility': {
        'id': 'Aksesibilitas',
        'en': 'Accessibility',
        'jv': 'Aksesibilitas',
        'su': 'Aksésibilitas',
    },
    'profile.textSize': {
        'id': 'Ukuran Teks',
        'en': 'Text Size',
        'jv': 'Ukuran Tulisan',
        'su': 'Ukuran Teks',
    },
    'profile.preferencesAndDisplay': {
        'id': 'Preferensi & Tampilan',
        'en': 'Preferences & Display',
        'jv': 'Pilihan & Tampilan',
        'su': 'Pilihan & Pidangan',
    },
    'profile.language': {
        'id': 'Bahasa Aplikasi',
        'en': 'App Language',
        'jv': 'Basa Aplikasi',
        'su': 'Basa Aplikasi',
    },
    'profile.theme': {
        'id': 'Tema Tampilan',
        'en': 'Display Theme',
        'jv': 'Tèma Tampilan',
        'su': 'Téma Pidangan',
    },
    'profile.helpAndInfo': {
        'id': 'Bantuan & Informasi',
        'en': 'Help & Information',
        'jv': 'Pitulungan & Katrangan',
        'su': 'Bantosan & Émbaran',
    },
    'profile.helpCenter': {
        'id': 'Pusat Bantuan & FAQ',
        'en': 'Help Center & FAQ',
        'jv': 'Pusat Pitulungan & FAQ',
        'su': 'Puseur Bantosan & FAQ',
    },
    'profile.aboutApp': {
        'id': 'Tentang HajiCare',
        'en': 'About HajiCare',
        'jv': 'Babagan HajiCare',
        'su': 'Ngeunaan HajiCare',
    },
    'profile.nameChangedSuccess': {
        'id': 'Nama Berhasil Diubah',
        'en': 'Name Changed Successfully',
        'jv': 'Asma Kasil Dipunéwahi',
        'su': 'Nami Parantos Dirobih',
    },
    'profile.nameChangedError': {
        'id': 'Nama Belum Diubah',
        'en': 'Name Not Changed',
        'jv': 'Asma Dèrèng Dipunéwahi',
        'su': 'Nami Teu Acan Dirobih',
    },
    'profile.yourFullName': {
        'id': 'Nama lengkap Anda',
        'en': 'Your full name',
        'jv': 'Asma jangkep panjenengan',
        'su': 'Nami lengkep anjeun',
    },

    # Room Keys
    'room.removeMemberTitle': {
        'id': 'Keluarkan Jamaah?',
        'en': 'Remove Pilgrim?',
        'jv': 'Keluarken Jamaah?',
        'su': 'Kaluarkeun Jamaah?',
    },
    'room.memberRemoved': {
        'id': 'Jamaah Dikeluarkan',
        'en': 'Pilgrim Removed',
        'jv': 'Jamaah Sampun Dikeluarken',
        'su': 'Jamaah Parantos Dikaluarkeun',
    },
    'room.memberRemoveFailed': {
        'id': 'Belum Dapat Dikeluarkan',
        'en': 'Failed to Remove Pilgrim',
        'jv': 'Dèrèng Saged Dikeluarken',
        'su': 'Teu Acan Tiasa Dikaluarkeun',
    },
    'room.attention': {
        'id': 'Perhatian',
        'en': 'Attention',
        'jv': 'Kawigatosan',
        'su': 'Perhatosan',
    },
    'room.nameTooLong': {
        'id': 'Nama Terlalu Panjang',
        'en': 'Name Is Too Long',
        'jv': 'Asma Kedawanen',
        'su': 'Nami Panjang Teuing',
    },
    'room.roomCreated': {
        'id': 'Rombongan Berhasil Dibuat',
        'en': 'Group Created Successfully',
        'jv': 'Rombongan Kasil Dipundamel',
        'su': 'Rombongan Parantos Didamel',
    },
    'room.roomCreateFailed': {
        'id': 'Belum Berhasil',
        'en': 'Operation Failed',
        'jv': 'Dèrèng Kasil',
        'su': 'Teu Acan Hasil',
    },
    'room.roomNameChanged': {
        'id': 'Nama Berhasil Diubah',
        'en': 'Name Updated Successfully',
        'jv': 'Nama Kasil Dipunéwahi',
        'su': 'Nami Parantos Dirobih',
    },
    'room.roomNameChangeFailed': {
        'id': 'Nama Belum Diubah',
        'en': 'Name Not Updated',
        'jv': 'Nama Dèrèng Dipunéwahi',
        'su': 'Nami Teu Acan Dirobih',
    },
    'room.deactivateRoomTitle': {
        'id': 'Nonaktifkan Rombongan?',
        'en': 'Deactivate Group?',
        'jv': 'Nonaktifaken Rombongan?',
        'su': 'Nonaktifkeun Rombongan?',
    },
    'room.statusUpdated': {
        'id': 'Status Diperbarui',
        'en': 'Status Updated',
        'jv': 'Kahanan Dipunéwahi',
        'su': 'Status Diropéa',
    },
    'room.statusUpdateFailed': {
        'id': 'Status Belum Diubah',
        'en': 'Status Not Updated',
        'jv': 'Kahanan Dèrèng Dipunéwahi',
        'su': 'Status Teu Acan Diropéa',
    },
    'room.deleteRoomTitle': {
        'id': 'Hapus Rombongan?',
        'en': 'Delete Group?',
        'jv': 'Busek Rombongan?',
        'su': 'Hapus Rombongan?',
    },
    'room.roomDeleted': {
        'id': 'Rombongan Dihapus',
        'en': 'Group Deleted',
        'jv': 'Rombongan Sampun Kabusek',
        'su': 'Rombongan Dihapus',
    },
    'room.deleteFailed': {
        'id': 'Belum Dapat Dihapus',
        'en': 'Failed to Delete',
        'jv': 'Dèrèng Saged Kabusek',
        'su': 'Teu Acan Tiasa Dihapus',
    },
    'room.exitAdminTitle': {
        'id': 'Keluar dari Admin?',
        'en': 'Exit Admin Mode?',
        'jv': 'Miyos saking Admin?',
        'su': 'Kaluar tina Admin?',
    },
    'room.joinedSuccess': {
        'id': 'Berhasil Bergabung',
        'en': 'Joined Successfully',
        'jv': 'Kasil Gathuk',
        'su': 'Parantos Gabung',
    },
    'room.codeCopied': {
        'id': 'Kode Disalin',
        'en': 'Code Copied',
        'jv': 'Kode Katurun',
        'su': 'Kode Kasalin',
    },
    'room.searchMember': {
        'id': 'Cari nama atau peran anggota...',
        'en': 'Search member name or role...',
        'jv': 'Padosi asma utawi peran anggota...',
        'su': 'Milarian nami atanapi peran anggota...',
    },
    'room.allMembers': {
        'id': 'Semua',
        'en': 'All',
        'jv': 'Sedanten',
        'su': 'Sadaya',
    },
    'room.roleJamaah': {
        'id': 'Jamaah',
        'en': 'Pilgrim',
        'jv': 'Jamaah',
        'su': 'Jamaah',
    },
    'room.roleCompanion': {
        'id': 'Pendamping',
        'en': 'Companion',
        'jv': 'Pendamping',
        'su': 'Pendamping',
    },
    'room.resetFilter': {
        'id': 'Reset Filter & Pencarian',
        'en': 'Reset Filter & Search',
        'jv': 'Wangsulaken Saringan & Padosan',
        'su': 'Balikeun Saringan & Palarian',
    },
    'room.attendanceStatus': {
        'id': 'Status Kehadiran',
        'en': 'Attendance Status',
        'jv': 'Kahanan Rawuh',
        'su': 'Status Kahadiran',
    },
    'room.joinDate': {
        'id': 'Tanggal Bergabung',
        'en': 'Joined Date',
        'jv': 'Tanggal Gathuk',
        'su': 'Tanggal Gabung',
    },
    'room.locationCoordinates': {
        'id': 'Koordinat Lokasi',
        'en': 'Location Coordinates',
        'jv': 'Kordinat Papan Dunung',
        'su': 'Koordinat Lokasi',
    },
    'room.viewOnMap': {
        'id': 'Lihat di Peta',
        'en': 'View on Map',
        'jv': 'Tingali ing Peta',
        'su': 'Tingal dina Peta',
    },
    'room.removeAction': {
        'id': 'Keluarkan',
        'en': 'Remove',
        'jv': 'Keluarken',
        'su': 'Kaluarkeun',
    },
    'room.roomCode': {
        'id': 'Kode Room',
        'en': 'Room Code',
        'jv': 'Kode Room',
        'su': 'Kode Room',
    },
    'room.radarRadius': {
        'id': 'Radius Radar',
        'en': 'Radar Radius',
        'jv': 'Radius Radar',
        'su': 'Radius Radar',
    },
    'room.invitePilgrimNow': {
        'id': 'Undang Jamaah Sekarang',
        'en': 'Invite Pilgrim Now',
        'jv': 'Aturi Jamaah Sakmenika',
        'su': 'Ulem Jamaah Ayeuna',
    },
    'room.invitationSent': {
        'id': 'Undangan Terkirim',
        'en': 'Invitation Sent',
        'jv': 'Uleman Kakintun',
        'su': 'Uleman Kakintun',
    },
    'room.invitationFailed': {
        'id': 'Undangan Belum Terkirim',
        'en': 'Failed to Send Invitation',
        'jv': 'Uleman Dèrèng Kakintun',
        'su': 'Uleman Teu Acan Kakintun',
    },
    'room.invitationCopied': {
        'id': 'Teks Undangan Disalin',
        'en': 'Invitation Text Copied',
        'jv': 'Serat Uleman Katurun',
        'su': 'Téks Uleman Kasalin',
    },
    'room.searchJamaahOrMaktab': {
        'id': 'Cari jamaah atau maktab...',
        'en': 'Search pilgrim or maktab...',
        'jv': 'Padosi jamaah utawi maktab...',
        'su': 'Milarian jamaah atanapi maktab...',
    },
    'room.activeRooms': {
        'id': 'Room Aktif',
        'en': 'Active Rooms',
        'jv': 'Room Aktif',
        'su': 'Room Aktif',
    },
    'room.officerDuty': {
        'id': 'Siaga Maktab',
        'en': 'Maktab On Duty',
        'jv': 'Siaga Maktab',
        'su': 'Siaga Maktab',
    },
    'room.alertCenter': {
        'id': 'Pusat Alert',
        'en': 'Alert Center',
        'jv': 'Pusat Pèngetan',
        'su': 'Puseur Pépéling',
    },
    'room.sendBroadcast': {
        'id': 'Kirim Siaran',
        'en': 'Broadcast Message',
        'jv': 'Kintun Wara-wara',
        'su': 'Kintun Wawaran',
    },
    'room.broadcastSub': {
        'id': 'Notifikasi broadcast',
        'en': 'Broadcast notification',
        'jv': 'Notifikasi wara-wara',
        'su': 'Wawaran siaran',
    },
    'room.perimeterRadar': {
        'id': 'Perimeter Radar',
        'en': 'Radar Perimeter',
        'jv': 'Wates Radar',
        'su': 'Wates Radar',
    },
    'room.safeRadiusSub': {
        'id': 'Radius aman jamaah',
        'en': 'Safe radius for pilgrims',
        'jv': 'Radius aman jamaah',
        'su': 'Radius aman jamaah',
    },
    'room.manageTrackingRoom': {
        'id': 'Kelola Room Pantau',
        'en': 'Manage Monitoring Room',
        'jv': 'Atur Room Pantau',
        'su': 'Atur Room Pantau',
    },
    'room.manageTrackingRoomSub': {
        'id': 'Delegasi & Monitoring Maktab Jamaah',
        'en': 'Pilgrim Maktab Delegation & Monitoring',
        'jv': 'Delegasi & Monitoring Maktab Jamaah',
        'su': 'Delegasi & Monitoring Maktab Jamaah',
    },
    'room.syncing': {
        'id': 'Menyinkronkan',
        'en': 'Syncing',
        'jv': 'Saweg nyinkronaken',
        'su': 'Nuju nyinkronkeun',
    },
    'room.totalRooms': {
        'id': 'Total Room',
        'en': 'Total Rooms',
        'jv': 'Gunggung Room',
        'su': 'Jumlah Room',
    },
    'room.pilgrimsMonitored': {
        'id': 'Jamaah Pantau',
        'en': 'Monitored Pilgrims',
        'jv': 'Jamaah Kapantau',
        'su': 'Jamaah Kapantau',
    },
    'room.searchRoomOrCode': {
        'id': 'Cari nama room atau 6-digit kode...',
        'en': 'Search room name or 6-digit code...',
        'jv': 'Padosi nama room utawi kode 6 digit...',
        'su': 'Milarian nami room atanapi kode 6 digit...',
    },
    'room.openMonitorRoom': {
        'id': 'Buka Ruang Pantau & Anggota',
        'en': 'Open Monitoring Room & Members',
        'jv': 'Bikak Ruang Pantau & Anggota',
        'su': 'Buka Ruang Pantau & Anggota',
    },
    'room.openMonitorRoomSub': {
        'id': 'Pantau posisi live jamaah dan pendamping',
        'en': 'Monitor live positions of pilgrims and guides',
        'jv': 'Pantau posisi langsung jamaah lan pendamping',
        'su': 'Pantau posisi langsung jamaah sareng pendamping',
    },
    'room.viewQrCode': {
        'id': 'Lihat QR Code Room',
        'en': 'View Room QR Code',
        'jv': 'Tingali QR Code Room',
        'su': 'Tingal QR Code Room',
    },
    'room.shareCodeSub': {
        'id': 'Bagikan kode ke jamaah agar dapat bergabung',
        'en': 'Share code with pilgrims so they can join',
        'jv': 'Bagiaken kode dhateng jamaah supados saged gathuk',
        'su': 'Bagikeun kode ka jamaah supados tiasa gabung',
    },
    'room.renameRoom': {
        'id': 'Ubah Nama Ruang',
        'en': 'Rename Room',
        'jv': 'Éwah Nama Ruang',
        'su': 'Robi Nami Ruang',
    },
    'room.renameRoomSub': {
        'id': 'Perbarui label maktab atau kelompok',
        'en': 'Update maktab label or group',
        'jv': 'Anyari label maktab utawi kelompok',
        'su': 'Ropéa labél maktab atanapi kelompok',
    },
    'room.deleteMonitorRoom': {
        'id': 'Hapus Ruang Pantau',
        'en': 'Delete Monitoring Room',
        'jv': 'Busek Ruang Pantau',
        'su': 'Hapus Ruang Pantau',
    },
    'room.deleteMonitorRoomSub': {
        'id': 'Hapus permanen room dan daftar delegasi anggota',
        'en': 'Permanently delete room and member delegation list',
        'jv': 'Busek permanèn room lan daptar delegasi anggota',
        'su': 'Hapus permanén room sareng daptar delegasi anggota',
    },
    'room.changesSaved': {
        'id': 'Perubahan Disimpan',
        'en': 'Changes Saved',
        'jv': 'Éwah-éwahan Kasimpen',
        'su': 'Parobihan Disimpen',
    },
    'room.roomNameField': {
        'id': 'Nama Room / Rombongan *',
        'en': 'Room / Group Name *',
        'jv': 'Nama Room / Rombongan *',
        'su': 'Nami Room / Rombongan *',
    },
    'room.safeRadiusLimit': {
        'id': 'Batas Radius Aman (Meter) *',
        'en': 'Safe Radius Boundary (Meters) *',
        'jv': 'Wates Radius Aman (Mèter) *',
        'su': 'Wates Radius Aman (Méter) *',
    },
    'room.sampleMaktab': {
        'id': 'Misal: Maktab 48 Kloter 12',
        'en': 'E.g.: Maktab 48 Flight 12',
        'jv': 'Tuladha: Maktab 48 Kloter 12',
        'su': 'Conto: Maktab 48 Kloter 12',
    },
    'room.sampleRoomName': {
        'id': 'Contoh: Rombongan Maktab 48',
        'en': 'Example: Maktab 48 Group',
        'jv': 'Tuladha: Rombongan Maktab 48',
        'su': 'Conto: Rombongan Maktab 48',
    },
    'room.sampleMaktabNumber': {
        'id': 'Contoh: Maktab 48',
        'en': 'Example: Maktab 48',
        'jv': 'Tuladha: Maktab 48',
        'su': 'Conto: Maktab 48',
    },
    'room.sampleKloter': {
        'id': 'Contoh: SOC-12',
        'en': 'Example: SOC-12',
        'jv': 'Tuladha: SOC-12',
        'su': 'Conto: SOC-12',
    },

    # Dashboard Keys
    'dashboard.prayerSchedule': {
        'id': 'Jadwal Salat',
        'en': 'Prayer Schedule',
        'jv': 'Jadwal Salat',
        'su': 'Jadwal Salat',
    },
    'dashboard.locationStatus': {
        'id': 'Status Lokasi',
        'en': 'Location Status',
        'jv': 'Kahanan Lokasi',
        'su': 'Status Lokasi',
    },
    'dashboard.quickComm': {
        'id': 'Komunikasi Cepat',
        'en': 'Quick Communication',
        'jv': 'Komunikasi Cepet',
        'su': 'Komunikasi Gancang',
    },
    'dashboard.smartband': {
        'id': 'Smart Band',
        'en': 'Smart Band',
        'jv': 'Gelang Pinter',
        'su': 'Gelang Pinter',
    },
    'dashboard.medicalPost': {
        'id': 'Pos Medis',
        'en': 'Medical Post',
        'jv': 'Pos Medis',
        'su': 'Pos Médis',
    },
    'dashboard.moneyDetection': {
        'id': 'Deteksi Uang',
        'en': 'Money Detection',
        'jv': 'Deteksi Arta',
        'su': 'Deteksi Artos',
    },
    'dashboard.statusAndAlert': {
        'id': 'Status & Peringatan',
        'en': 'Status & Alerts',
        'jv': 'Kahanan & Pèngetan',
        'su': 'Status & Pépéling',
    },
    'dashboard.gpsMonitoringSub': {
        'id': 'Koneksi GPS & pemantauan rombongan',
        'en': 'GPS connection & group monitoring',
        'jv': 'Sambungan GPS & pamantauan rombongan',
        'su': 'Sambungan GPS & pamantauan rombongan',
    },
    'dashboard.roomAndMaktab': {
        'id': 'Kamar & Maktab',
        'en': 'Room & Maktab',
        'jv': 'Kamar & Maktab',
        'su': 'Kamar & Maktab',
    },
    'dashboard.hotelRoomSub': {
        'id': 'Informasi room & rombongan hotel',
        'en': 'Hotel room & group info',
        'jv': 'Katrangan room & rombongan hotèl',
        'su': 'Émbaran room & rombongan hotél',
    },
    'dashboard.worshipTips': {
        'id': 'Tips & Panduan Ibadah',
        'en': 'Worship Tips & Guide',
        'jv': 'Pituduh & Pandhuan Ibadah',
        'su': 'Pituduh & Panduan Ibadah',
    },
    'dashboard.worshipTipsSub': {
        'id': 'Doa harian, rukun & info penting',
        'en': 'Daily prayers, pillars & vital info',
        'jv': 'Donga sabendina, rukun & katrangan wigati',
        'su': 'Doa sapopoé, rukun & émbaran penting',
    },
    'dashboard.signLanguage': {
        'id': 'Bahasa Isyarat',
        'en': 'Sign Language',
        'jv': 'Basa Sasmita',
        'su': 'Basa Isarat',
    },
    'dashboard.openCamera': {
        'id': 'Buka Kamera',
        'en': 'Open Camera',
        'jv': 'Bikak Kodhak',
        'su': 'Buka Kaméra',
    },
    'dashboard.prayerGuide': {
        'id': 'Panduan Doa',
        'en': 'Prayer Guide',
        'jv': 'Pandhuan Donga',
        'su': 'Panduan Doa',
    },
    'dashboard.prayerAndDhikr': {
        'id': 'Doa & Dzikir',
        'en': 'Prayer & Dhikr',
        'jv': 'Donga & Dzikir',
        'su': 'Doa & Dzikir',
    },
    'dashboard.scheduleAndPillars': {
        'id': 'Jadwal & Rukun',
        'en': 'Schedule & Pillars',
        'jv': 'Jadwal & Rukun',
        'su': 'Jadwal & Rukun',
    },
    'dashboard.viewSeries': {
        'id': 'Lihat Rangkaian',
        'en': 'View Sequence',
        'jv': 'Tingali Reroncèn',
        'su': 'Tingal Runtuyan',
    },
    'dashboard.companion': {
        'id': 'Pendamping',
        'en': 'Companion',
        'jv': 'Pendamping',
        'su': 'Pendamping',
    },
    'dashboard.messageAndLocation': {
        'id': 'Pesan & Lokasi',
        'en': 'Messages & Location',
        'jv': 'Pesen & Papan Dunung',
        'su': 'Pesen & Lokasi',
    },
    'dashboard.notInRoom': {
        'id': 'Belum Tergabung Rombongan',
        'en': 'Not in a Group Yet',
        'jv': 'Dèrèng Gathuk Rombongan',
        'su': 'Teu Acan Gabung Rombongan',
    },
    'dashboard.companionLoadFailed': {
        'id': 'Pendamping Belum Dapat Dimuat',
        'en': 'Failed to Load Companion',
        'jv': 'Pendamping Dèrèng Saged Kamot',
        'su': 'Pendamping Teu Acan Tiasa Dimuat',
    },
    'dashboard.locationUnavailable': {
        'id': 'Lokasi Belum Tersedia',
        'en': 'Location Not Available',
        'jv': 'Papan Dunung Dèrèng Sumadya',
        'su': 'Lokasi Teu Acan Sayaga',
    },
    'dashboard.manageRoom': {
        'id': 'Kelola Room',
        'en': 'Manage Room',
        'jv': 'Atur Room',
        'su': 'Atur Room',
    },
    'dashboard.invitePilgrim': {
        'id': 'Undang Jamaah',
        'en': 'Invite Pilgrim',
        'jv': 'Aturi Jamaah',
        'su': 'Ulem Jamaah',
    },
    'dashboard.noGroupYet': {
        'id': 'Belum Ada Rombongan',
        'en': 'No Group Yet',
        'jv': 'Dèrèng Wonten Rombongan',
        'su': 'Teu Acan Aya Rombongan',
    },
    'dashboard.emergencySos': {
        'id': 'Darurat SOS',
        'en': 'Emergency SOS',
        'jv': 'Darurat SOS',
        'su': 'Darurat SOS',
    },
    'dashboard.emergencyStatus': {
        'id': 'Status Darurat',
        'en': 'Emergency Status',
        'jv': 'Kahanan Darurat',
        'su': 'Status Darurat',
    },
    'dashboard.sosSeparatedSub': {
        'id': 'Peringatan SOS & jamaah terpisah',
        'en': 'SOS alert & separated pilgrim',
        'jv': 'Pèngetan SOS & jamaah pisah',
        'su': 'Pépéling SOS & jamaah papisah',
    },
    'dashboard.endSos': {
        'id': 'Akhiri Darurat SOS',
        'en': 'End Emergency SOS',
        'jv': 'Pungkasi Darurat SOS',
        'su': 'Pungkas Darurat SOS',
    },
    'dashboard.sosEnded': {
        'id': 'SOS Diakhiri',
        'en': 'SOS Ended',
        'jv': 'SOS Dipunpungkasi',
        'su': 'SOS Dipungkas',
    },
    'dashboard.sosEndFailed': {
        'id': 'SOS Belum Diakhiri',
        'en': 'Failed to End SOS',
        'jv': 'SOS Dèrèng Dipunpungkasi',
        'su': 'SOS Teu Acan Dipungkas',
    },
    'dashboard.positionDetail': {
        'id': 'Detail Posisi',
        'en': 'Position Details',
        'jv': 'Rincian Posisi',
        'su': 'Wincikan Posisi',
    },
    'dashboard.positionDetailSub': {
        'id': 'Arah navigasi ke jamaah terpilih',
        'en': 'Navigation guidance to selected pilgrim',
        'jv': 'Pener navigasi dhateng jamaah kapilih',
        'su': 'Pituduh navigasi ka jamaah kapilih',
    },
    'dashboard.taskGuidance': {
        'id': 'Tips & Panduan Tugas',
        'en': 'Tips & Duty Guide',
        'jv': 'Pituduh & Pandhuan Tugas',
        'su': 'Pituduh & Panduan Tugas',
    },
    'dashboard.taskGuidanceSub': {
        'id': 'Pedoman dan checklist muthawif',
        'en': 'Guide checklist & instructions',
        'jv': 'Pandom lan dhaptar priksa muthawif',
        'su': 'Pituduh sareng daptar mariksa muthawif',
    },
    'dashboard.searchPilgrim': {
        'id': 'Cari jamaah...',
        'en': 'Search pilgrim...',
        'jv': 'Padosi jamaah...',
        'su': 'Milarian jamaah...',
    },
    'dashboard.locationNotFound': {
        'id': 'Lokasi Belum Ditemukan',
        'en': 'Location Not Found',
        'jv': 'Papan Dunung Dèrèng Pinanggih',
        'su': 'Lokasi Teu Acan Kapendak',
    },
    'dashboard.selectCompanion': {
        'id': 'Pilih Pendamping',
        'en': 'Select Companion',
        'jv': 'Pilih Pendamping',
        'su': 'Pilih Pendamping',
    },
    'dashboard.sendMessage': {
        'id': 'Kirim Pesan',
        'en': 'Send Message',
        'jv': 'Kintun Pesen',
        'su': 'Kintun Pesen',
    },
    'dashboard.sendMessageSub': {
        'id': 'Seperti chat',
        'en': 'Chat-style message',
        'jv': 'Kados pacelathon',
        'su': 'Sapertos obrolan',
    },
    'dashboard.giveInfo': {
        'id': 'Beri Informasi',
        'en': 'Give Information',
        'jv': 'Paring Katrangan',
        'su': 'Pasihkeun Émbaran',
    },
    'dashboard.giveInfoSub': {
        'id': 'Ke semua pendamping',
        'en': 'To all companions',
        'jv': 'Dhateng sedanten pendamping',
        'su': 'Ka sadaya pendamping',
    },
    'dashboard.sendFailed': {
        'id': 'Belum Berhasil Dikirim',
        'en': 'Failed to Send',
        'jv': 'Dèrèng Kasil Kakintun',
        'su': 'Teu Acan Hasil Kakintun',
    },
    'dashboard.messageSampleHint': {
        'id': 'Contoh: Saya menunggu di depan pintu masjid.',
        'en': 'Example: I am waiting in front of the mosque gate.',
        'jv': 'Tuladha: Kula nengga wonten sangajengipun kori masjid.',
        'su': 'Conto: Sim kuring ngantosan di payuneun panto masjid.',
    },
    'dashboard.recipientAllCompanions': {
        'id': 'Penerima: Semua Pendamping',
        'en': 'Recipient: All Companions',
        'jv': 'Panampi: Sedanten Pendamping',
        'su': 'Panampi: Sadaya Pendamping',
    },
    'dashboard.tapToSelect': {
        'id': 'Ketuk untuk memilih',
        'en': 'Tap to select',
        'jv': 'Tutul kagem milih',
        'su': 'Toél kanggo milih',
    },
    'dashboard.waiting': {
        'id': 'Menunggu',
        'en': 'Waiting',
        'jv': 'Nengga',
        'su': 'Ngentosan',
    },
    'dashboard.battery': {
        'id': 'Baterai',
        'en': 'Battery',
        'jv': 'Batré',
        'su': 'Batré',
    },
    'dashboard.heartRate': {
        'id': 'Detak Jantung',
        'en': 'Heart Rate',
        'jv': 'Keteg Manah',
        'su': 'Keteg Jajantung',
    },
    'dashboard.steps': {
        'id': 'Langkah',
        'en': 'Steps',
        'jv': 'Jangkah',
        'su': 'Lengkah',
    },
    'dashboard.connectBand': {
        'id': 'Hubungkan Gelang',
        'en': 'Connect Band',
        'jv': 'Sambungaken Gelang',
        'su': 'Sambungkeun Gelang',
    },
    'dashboard.contactCompanion': {
        'id': 'Hubungi Pendamping',
        'en': 'Contact Companion',
        'jv': 'Hubungi Pendamping',
        'su': 'Kontak Pendamping',
    },
    'dashboard.sosSignalSent': {
        'id': 'Sinyal Darurat Terkirim',
        'en': 'Emergency Signal Sent',
        'jv': 'Sinyal Darurat Kakintun',
        'su': 'Sinyal Darurat Kakintun',
    },
    'dashboard.sosSendFailed': {
        'id': 'SOS Belum Terkirim',
        'en': 'Failed to Send SOS',
        'jv': 'SOS Dèrèng Kakintun',
        'su': 'SOS Teu Acan Kakintun',
    },
    'dashboard.custom': {
        'id': 'Kustom',
        'en': 'Custom',
        'jv': 'Kustom',
        'su': 'Kustom',
    },
    'dashboard.safeDistanceUpdated': {
        'id': 'Jarak Aman Diperbarui',
        'en': 'Safe Distance Updated',
        'jv': 'Tebih Aman Dipunéwahi',
        'su': 'Jarak Aman Diropéa',
    },
    'dashboard.safeDistanceFailed': {
        'id': 'Jarak Aman Belum Diubah',
        'en': 'Failed to Update Safe Distance',
        'jv': 'Tebih Aman Dèrèng Dipunéwahi',
        'su': 'Jarak Aman Teu Acan Diropéa',
    },
    'dashboard.hotlineKemenag': {
        'id': 'Hotline Krisis Kemenag RI',
        'en': 'Indonesian Ministry Crisis Hotline',
        'jv': 'Hotline Krisis Kemenag RI',
        'su': 'Hotline Krisis Kemenag RI',
    },
    'dashboard.redCrescent': {
        'id': 'Ambulans Arab Saudi (Red Crescent)',
        'en': 'Saudi Ambulance (Red Crescent)',
        'jv': 'Ambulans Arab Saudi (Red Crescent)',
        'su': 'Ambulans Arab Saudi (Red Crescent)',
    },
    'dashboard.saudiPolice': {
        'id': 'Polisi Darurat Arab Saudi',
        'en': 'Saudi Emergency Police',
        'jv': 'Pulisi Darurat Arab Saudi',
        'su': 'Pulisi Darurat Arab Saudi',
    },

    # Maps Keys
    'maps.all': {
        'id': 'Semua',
        'en': 'All',
        'jv': 'Sedanten',
        'su': 'Sadaya',
    },
    'maps.pilgrims': {
        'id': 'Jamaah',
        'en': 'Pilgrim',
        'jv': 'Jamaah',
        'su': 'Jamaah',
    },
    'maps.companions': {
        'id': 'Pendamping',
        'en': 'Companion',
        'jv': 'Pendamping',
        'su': 'Pendamping',
    },
    'maps.medicalPostPoi': {
        'id': 'Posko Medis',
        'en': 'Medical Post',
        'jv': 'Posko Medis',
        'su': 'Posko Médis',
    },
    'maps.toiletAndWudhu': {
        'id': 'Toilet & Wudhu',
        'en': 'Restroom & Wudhu',
        'jv': 'Toilet & Papan Wudhu',
        'su': 'Toilet & Fasilitas Wudhu',
    },
    'maps.maktabPoi': {
        'id': 'Maktab',
        'en': 'Maktab',
        'jv': 'Maktab',
        'su': 'Maktab',
    },
    'maps.guardPost': {
        'id': 'Pos Pantau',
        'en': 'Monitoring Post',
        'jv': 'Pos Pantau',
        'su': 'Pos Pantau',
    },
    'maps.hotelPoi': {
        'id': 'Hotel',
        'en': 'Hotel',
        'jv': 'Hotèl',
        'su': 'Hotél',
    },
    'maps.locationCopied': {
        'id': 'Lokasi Disalin',
        'en': 'Location Copied',
        'jv': 'Papan Dunung Katurun',
        'su': 'Lokasi Kasalin',
    },
    'maps.locationUnavailable': {
        'id': 'Lokasi Belum Tersedia',
        'en': 'Location Not Available',
        'jv': 'Papan Dunung Dèrèng Sumadya',
        'su': 'Lokasi Teu Acan Sayaga',
    },
    'maps.phoneUnavailable': {
        'id': 'Nomor Telepon Belum Tersedia',
        'en': 'Phone Number Not Available',
        'jv': 'Nomer Telepon Dèrèng Sumadya',
        'su': 'Nomer Telepon Teu Acan Sayaga',
    },
    'maps.bandDisconnected': {
        'id': 'Gelang Belum Terhubung',
        'en': 'Smartband Not Connected',
        'jv': 'Gelang Dèrèng Sambung',
        'su': 'Gelang Teu Acan Nyambung',
    },
    'maps.direct': {
        'id': 'Langsung',
        'en': 'Direct',
        'jv': 'Langsung',
        'su': 'Langsung',
    },
    'maps.walking': {
        'id': 'Jalan Kaki',
        'en': 'Walking',
        'jv': 'Tindak Suku',
        'su': 'Leumpang',
    },
    'maps.estimate': {
        'id': 'Estimasi',
        'en': 'Estimated',
        'jv': 'Kinten-kinten',
        'su': 'Kira-kira',
    },
    'maps.searchNameOrStatus': {
        'id': 'Cari nama atau status...',
        'en': 'Search name or status...',
        'jv': 'Padosi asma utawi kahanan...',
        'su': 'Milarian nami atanapi status...',
    },
    'maps.phoneGpsInactive': {
        'id': 'Lokasi Ponsel Belum Aktif',
        'en': 'Phone Location Not Active',
        'jv': 'Papan Dunung Ponsel Dèrèng Aktif',
        'su': 'Lokasi HP Teu Acan Aktif',
    },
    'maps.locationPermissionRequired': {
        'id': 'Izin Lokasi Diperlukan',
        'en': 'Location Permission Required',
        'jv': 'Idin Papan Dunung Dibetahaken',
        'su': 'Idin Lokasi Peryogi',
    },
    'maps.openLocationSettings': {
        'id': 'Buka Pengaturan Lokasi',
        'en': 'Open Location Settings',
        'jv': 'Bikak Pangaturan Papan Dunung',
        'su': 'Buka Setélan Lokasi',
    },
    'maps.mapViewChanged': {
        'id': 'Tampilan Peta Diubah',
        'en': 'Map View Changed',
        'jv': 'Tampilan Peta Dipunéwahi',
        'su': 'Pidangan Peta Dirobih',
    },
}

def extract_map(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    # Find all 'key': 'value' pairs
    pattern = re.compile(r"'([a-zA-Z0-9_.]+)':\s*'((?:\\'|[^'])*)'")
    result = {}
    for match in pattern.finditer(content):
        k, v = match.group(1), match.group(2)
        # unescape
        v_clean = v.replace("\\'", "'")
        result[k] = v_clean
    return result

def write_locale_file(file_path, var_name, data):
    keys = sorted(data.keys())
    lines = [
        "// AUTO-GENERATED - HAJICARE LOCALIZATION",
        "// Key parity strictly enforced across all supported locales.",
        f"const Map<String, String> {var_name} = {{",
    ]
    current_prefix = None
    for k in keys:
        prefix = k.split('.')[0] if '.' in k else 'core'
        if prefix != current_prefix:
            current_prefix = prefix
            lines.append(f"\n  // --- {prefix.upper()} ---")
        val = data[k].replace("'", "\\'").replace("\n", "\\n")
        lines.append(f"  '{k}': '{val}',")
    lines.append("};")
    lines.append("")
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f"Wrote {len(keys)} keys to {file_path}")

def main():
    id_map = extract_map('lib/core/locales/id.dart')
    en_map = extract_map('lib/core/locales/en.dart')
    jv_map = extract_map('lib/core/locales/jv.dart')
    su_map = extract_map('lib/core/locales/su.dart')

    print(f"Initial keys: id={len(id_map)}, en={len(en_map)}, jv={len(jv_map)}, su={len(su_map)}")

    # Add new keys
    for k, trans in ADDITIONAL_KEYS.items():
        id_map[k] = trans['id']
        en_map[k] = trans['en']
        jv_map[k] = trans['jv']
        su_map[k] = trans['su']

    # Ensure 100% parity across all keys
    all_keys = set(id_map.keys()) | set(en_map.keys()) | set(jv_map.keys()) | set(su_map.keys())
    for k in all_keys:
        if k not in id_map:
            id_map[k] = en_map.get(k, k)
        if k not in en_map:
            en_map[k] = id_map.get(k, k)
        if k not in jv_map:
            jv_map[k] = id_map.get(k, k)
        if k not in su_map:
            su_map[k] = id_map.get(k, k)

    write_locale_file('lib/core/locales/id.dart', 'idTranslations', id_map)
    write_locale_file('lib/core/locales/en.dart', 'enTranslations', en_map)
    write_locale_file('lib/core/locales/jv.dart', 'jvTranslations', jv_map)
    write_locale_file('lib/core/locales/su.dart', 'suTranslations', su_map)
    print("All files updated successfully with 100% key parity!")

if __name__ == '__main__':
    main()
