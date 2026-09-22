import re

def migrate_dashboard():
    # 1. dashboard_jamaah_screen.dart: add import
    p = 'lib/features/dashboard/screens/dashboard_jamaah_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()
    if "import '../../../core/locales/app_localizations.dart';" not in c:
        c = "import '../../../core/locales/app_localizations.dart';\n" + c
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

    # 2. dashboard_jamaah_header.dart
    p2 = 'lib/features/dashboard/screens/dashboard_jamaah_header.dart'
    with open(p2, 'r', encoding='utf-8') as f:
        c2 = f.read()
    c2 = c2.replace("label: 'Jadwal Salat',", "label: context.tr('dashboard.prayerSchedule'),")
    c2 = c2.replace("label: 'Status Lokasi')", "label: context.tr('dashboard.locationStatus'))")
    with open(p2, 'w', encoding='utf-8') as f:
        f.write(c2)

    # 3. dashboard_jamaah_sections.dart
    p3 = 'lib/features/dashboard/screens/dashboard_jamaah_sections.dart'
    with open(p3, 'r', encoding='utf-8') as f:
        c3 = f.read()

    replacements_sections = [
        ("title: 'Komunikasi Cepat',", "title: context.tr('dashboard.quickComm'),"),
        ("title: 'Smart Band',", "title: context.tr('dashboard.smartband'),"),
        ("title: 'Pos Medis',", "title: context.tr('dashboard.medicalPost'),"),
        ("title: 'Deteksi Uang',", "title: context.tr('dashboard.moneyDetection'),"),
        ("title: 'Status & Peringatan',", "title: context.tr('dashboard.statusAndAlert'),"),
        ("subtitle: 'Koneksi GPS & pemantauan rombongan',", "subtitle: context.tr('dashboard.gpsMonitoringSub'),"),
        ("title: 'Kamar & Maktab',", "title: context.tr('dashboard.roomAndMaktab'),"),
        ("subtitle: 'Informasi room & rombongan hotel',", "subtitle: context.tr('dashboard.hotelRoomSub'),"),
        ("title: 'Tips & Panduan Ibadah',", "title: context.tr('dashboard.worshipTips'),"),
        ("subtitle: 'Doa harian, rukun & info penting',", "subtitle: context.tr('dashboard.worshipTipsSub'),"),
        ("title: 'Bahasa Isyarat',", "title: context.tr('dashboard.signLanguage'),"),
        ("action: 'Buka Kamera',", "action: context.tr('dashboard.openCamera'),"),
        ("title: 'Panduan Doa',", "title: context.tr('dashboard.prayerGuide'),"),
        ("action: 'Doa & Dzikir',", "action: context.tr('dashboard.prayerAndDhikr'),"),
        ("title: 'Jadwal & Rukun',", "title: context.tr('dashboard.scheduleAndPillars'),"),
        ("action: 'Lihat Rangkaian',", "action: context.tr('dashboard.viewSeries'),"),
        ("title: 'Pendamping',", "title: context.tr('dashboard.companion'),"),
        ("action: 'Pesan & Lokasi',", "action: context.tr('dashboard.messageAndLocation'),"),
        ("Text('Belum Tergabung Rombongan')", "Text(context.tr('dashboard.notInRoom'))"),
        ("Text('Pendamping Belum Dapat Dimuat')", "Text(context.tr('dashboard.companionLoadFailed'))"),
    ]
    for old, new in replacements_sections:
        c3 = c3.replace(old, new)
    with open(p3, 'w', encoding='utf-8') as f:
        f.write(c3)

    # 4. dashboard_pendamping_screen.dart
    p4 = 'lib/features/dashboard/screens/dashboard_pendamping_screen.dart'
    with open(p4, 'r', encoding='utf-8') as f:
        c4 = f.read()

    if "import '../../../core/locales/app_localizations.dart';" not in c4:
        c4 = "import '../../../core/locales/app_localizations.dart';\n" + c4

    replacements_pendamping = [
        ("'Lokasi Belum Tersedia'", "context.tr('dashboard.locationUnavailable')"),
        ("label: 'Jadwal Salat',", "label: context.tr('dashboard.prayerSchedule'),"),
        ("label: 'Status Lokasi')", "label: context.tr('dashboard.locationStatus'))"),
        ("label: 'Kelola Room',", "label: context.tr('dashboard.manageRoom'),"),
        ("label: 'Undang Jamaah',", "label: context.tr('dashboard.invitePilgrim'),"),
        ("'Belum Ada Rombongan'", "context.tr('dashboard.noGroupYet')"),
        ("label: 'Darurat SOS',", "label: context.tr('dashboard.emergencySos'),"),
        ("title: 'Status Darurat',", "title: context.tr('dashboard.emergencyStatus'),"),
        ("subtitle: 'Peringatan SOS & jamaah terpisah',", "subtitle: context.tr('dashboard.sosSeparatedSub'),"),
        ("label: 'Akhiri Darurat SOS',", "label: context.tr('dashboard.endSos'),"),
        ("'SOS Diakhiri'", "context.tr('dashboard.sosEnded')"),
        ("'SOS Belum Diakhiri'", "context.tr('dashboard.sosEndFailed')"),
        ("title: 'Detail Posisi',", "title: context.tr('dashboard.positionDetail'),"),
        ("subtitle: 'Arah navigasi ke jamaah terpilih',", "subtitle: context.tr('dashboard.positionDetailSub'),"),
        ("title: 'Kamar & Maktab',", "title: context.tr('dashboard.roomAndMaktab'),"),
        ("subtitle: 'Pengaturan room & kode pemantauan',", "subtitle: context.tr('dashboard.hotelRoomSub'),"),
        ("title: 'Tips & Panduan Tugas',", "title: context.tr('dashboard.taskGuidance'),"),
        ("subtitle: 'Pedoman dan checklist muthawif',", "subtitle: context.tr('dashboard.taskGuidanceSub'),"),
    ]
    for old, new in replacements_pendamping:
        c4 = c4.replace(old, new)
    with open(p4, 'w', encoding='utf-8') as f:
        f.write(c4)

    # 5. companion_contact_sheet.dart
    p5 = 'lib/features/dashboard/widgets/companion_contact_sheet.dart'
    with open(p5, 'r', encoding='utf-8') as f:
        c5 = f.read()

    if "import '../../../core/locales/app_localizations.dart';" not in c5:
        c5 = "import '../../../core/locales/app_localizations.dart';\n" + c5

    replacements_sheet = [
        ("'Lokasi Belum Ditemukan'", "context.tr('dashboard.locationNotFound')"),
        ("title: 'Pilih Pendamping',", "title: context.tr('dashboard.selectCompanion'),"),
        ("title: 'Belum Berhasil Dikirim',", "title: context.tr('dashboard.sendFailed'),"),
        ("title: 'Kirim Pesan',", "title: context.tr('dashboard.sendMessage'),"),
        ("subtitle: 'Seperti chat',", "subtitle: context.tr('dashboard.sendMessageSub'),"),
        ("title: 'Beri Informasi',", "title: context.tr('dashboard.giveInfo'),"),
        ("subtitle: 'Ke semua pendamping',", "subtitle: context.tr('dashboard.giveInfoSub'),"),
        ("hintText: 'Contoh: Saya menunggu di depan pintu masjid.',", "hintText: context.tr('dashboard.messageSampleHint'),"),
        ("cancelText: 'Batal',", "cancelText: context.tr('common.cancel'),"),
        ("label: 'Penerima: Semua Pendamping',", "label: context.tr('dashboard.recipientAllCompanions'),"),
        ("label: 'Ketuk untuk memilih',", "label: context.tr('dashboard.tapToSelect'),"),
    ]
    for old, new in replacements_sheet:
        c5 = c5.replace(old, new)
    with open(p5, 'w', encoding='utf-8') as f:
        f.write(c5)

    # 6. jamaah_distance_card.dart
    p6 = 'lib/features/dashboard/widgets/jamaah_distance_card.dart'
    with open(p6, 'r', encoding='utf-8') as f:
        c6 = f.read()
    if "import '../../../core/locales/app_localizations.dart';" not in c6:
        c6 = "import '../../../core/locales/app_localizations.dart';\n" + c6
    c6 = c6.replace("'Menunggu'", "context.tr('dashboard.waiting')")
    with open(p6, 'w', encoding='utf-8') as f:
        f.write(c6)

    # 7. jamaah_service_grid.dart
    p7 = 'lib/features/dashboard/widgets/jamaah_service_grid.dart'
    with open(p7, 'r', encoding='utf-8') as f:
        c7 = f.read()
    if "import '../../../core/locales/app_localizations.dart';" not in c7:
        c7 = "import '../../../core/locales/app_localizations.dart';\n" + c7
    c7 = c7.replace("label: 'Baterai',", "label: context.tr('dashboard.battery'),")
    c7 = c7.replace("label: 'Detak Jantung',", "label: context.tr('dashboard.heartRate'),")
    c7 = c7.replace("label: 'Langkah',", "label: context.tr('dashboard.steps'),")
    c7 = c7.replace("title: 'Hubungkan Gelang',", "title: context.tr('dashboard.connectBand'),")
    c7 = c7.replace("title: 'Hubungi Pendamping',", "title: context.tr('dashboard.contactCompanion'),")
    with open(p7, 'w', encoding='utf-8') as f:
        f.write(c7)

    # 8. jamaah_sos_banner.dart
    p8 = 'lib/features/dashboard/widgets/jamaah_sos_banner.dart'
    with open(p8, 'r', encoding='utf-8') as f:
        c8 = f.read()
    if "import '../../../core/locales/app_localizations.dart';" not in c8:
        c8 = "import '../../../core/locales/app_localizations.dart';\n" + c8
    c8 = c8.replace("'Sinyal Darurat Terkirim'", "context.tr('dashboard.sosSignalSent')")
    c8 = c8.replace("'SOS Belum Terkirim'", "context.tr('dashboard.sosSendFailed')")
    with open(p8, 'w', encoding='utf-8') as f:
        f.write(c8)

    # 9. pendamping_radar_card.dart
    p9 = 'lib/features/dashboard/widgets/pendamping_radar_card.dart'
    with open(p9, 'r', encoding='utf-8') as f:
        c9 = f.read()
    if "import '../../../core/locales/app_localizations.dart';" not in c9:
        c9 = "import '../../../core/locales/app_localizations.dart';\n" + c9
    c9 = c9.replace("label: 'Custom',", "label: context.tr('dashboard.custom'),")
    c9 = c9.replace("title: 'Jarak Aman Diperbarui',", "title: context.tr('dashboard.safeDistanceUpdated'),")
    c9 = c9.replace("title: 'Jarak Aman Belum Diubah',", "title: context.tr('dashboard.safeDistanceFailed'),")
    with open(p9, 'w', encoding='utf-8') as f:
        f.write(c9)

    # 10. pendamping_sos_banner.dart
    p10 = 'lib/features/dashboard/widgets/pendamping_sos_banner.dart'
    with open(p10, 'r', encoding='utf-8') as f:
        c10 = f.read()
    if "import '../../../core/locales/app_localizations.dart';" not in c10:
        c10 = "import '../../../core/locales/app_localizations.dart';\n" + c10
    c10 = c10.replace("label: 'Hotline Krisis Kemenag RI',", "label: context.tr('dashboard.hotlineKemenag'),")
    c10 = c10.replace("label: 'Ambulans Arab Saudi (Red Crescent)',", "label: context.tr('dashboard.redCrescent'),")
    c10 = c10.replace("label: 'Polisi Darurat Arab Saudi',", "label: context.tr('dashboard.saudiPolice'),")
    with open(p10, 'w', encoding='utf-8') as f:
        f.write(c10)

    print("Migrated all dashboard files successfully!")

if __name__ == '__main__':
    migrate_dashboard()
