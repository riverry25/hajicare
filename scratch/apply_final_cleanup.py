import re

def safe_replace(file_path, replacements, import_statement=None):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if import_statement and import_statement not in content:
        content = import_statement + "\n" + content

    changed = False
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new)
            changed = True

    if changed:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Cleaned up {file_path}")
    else:
        print(f"No match in {file_path}")

def cleanup():
    # 1. profile_screen_sections.dart
    safe_replace(
        'lib/features/profile/screens/profile_screen_sections.dart',
        [
            ("title: 'Format NIK Tidak Sesuai',", "title: context.tr('medical.nikInvalidTitle'),"),
            ("message: 'NIK harus berupa 16 digit angka.',", "message: context.tr('medical.nikInvalidMsg'),"),
            ("title: 'Format Nomor Porsi Tidak Sesuai',", "title: context.tr('medical.porsiInvalidTitle'),"),
            ("message: 'Nomor Porsi harus berupa 10 digit angka.',", "message: context.tr('medical.porsiInvalidMsg'),"),
            ("title: 'Data Jamaah Disimpan',", "title: context.tr('medical.saveSuccessTitle'),"),
            ("message: 'Data jamaah & medis Anda sudah diperbarui.',", "message: context.tr('medical.saveSuccessMsg'),"),
            ("title: 'Data Belum Disimpan',", "title: context.tr('medical.saveErrorTitle'),"),
            ("message: 'Periksa internet, lalu coba simpan sekali lagi.',", "message: context.tr('medical.saveErrorMsg'),"),
            ("okText: 'Coba Lagi',", "okText: context.tr('common.tryAgain'),"),
            ("label: 'Nomor Induk Kependudukan / NIK (Opsional)',", "label: context.tr('medical.nikLabel'),"),
            ("hint: 'Contoh: 3201234567890001 (16 digit)',", "hint: context.tr('medical.nikHint'),"),
            ("label: 'Nomor Porsi Haji (Opsional)',", "label: context.tr('medical.porsiLabel'),"),
            ("hint: 'Contoh: 1001234567 (10 digit)',", "hint: context.tr('medical.porsiHint'),"),
            ("label: 'Riwayat Alergi Obat / Makanan',", "label: context.tr('medical.allergiesLabel'),"),
            ("hint: 'Contoh: Alergi penisilin, udang, dsb.',", "hint: context.tr('medical.allergiesHint'),"),
            ("label: 'Kondisi Khusus / Riwayat Penyakit',", "label: context.tr('medical.conditionsLabel'),"),
            ("hint: 'Contoh: Hipertensi, Diabetes, Asma',", "hint: context.tr('medical.conditionsHint'),"),
            ("label: 'Nomor Kontak Darurat (Keluarga)',", "label: context.tr('medical.emergencyContactLabel'),"),
            ("hint: 'Contoh: 0812-3456-7890 (Anak / Pasangan)',", "hint: context.tr('medical.emergencyContactHint'),"),
            ("label: 'Nomor Paspor (Opsional)',", "label: context.tr('medical.passportLabel'),"),
            ("hint: 'Contoh: A 1234567 / B 9876543',", "hint: context.tr('medical.passportHint'),"),
        ]
    )

    # 2. profile_screen_components.dart
    safe_replace(
        'lib/features/profile/screens/profile_screen_components.dart',
        [
            ("title: 'Nama Berhasil Diubah',", "title: context.tr('profile.nameChangedSuccess'),"),
            ("'Nama Anda sekarang \"$input\".'", "context.tr('profile.nameChangedSuccessDesc', {'name': input})"),
            ("title: 'Nama Belum Diubah',", "title: context.tr('profile.nameChangedError'),"),
            ("message: 'Periksa internet, lalu coba simpan sekali lagi.',", "message: context.tr('medical.saveErrorMsg'),"),
            ("okText: 'Coba Lagi',", "okText: context.tr('common.tryAgain'),"),
            ("hintText: 'Nama lengkap Anda',", "hintText: context.tr('profile.yourFullName'),"),
            ("message:\n                  'Apakah Anda yakin ingin keluar? Anda perlu login kembali untuk mengakses data room rombongan.',", "message: context.tr('profile.logoutConfirm'),"),
            ("confirmText: 'Ya, Keluar',", "confirmText: context.tr('profile.logoutConfirmAction'),"),
            ("cancelText: 'Batal',", "cancelText: context.tr('common.cancel'),"),
        ]
    )

    # 3. jamaah_detail_sheet.dart
    safe_replace(
        'lib/features/room/widgets/jamaah_detail_sheet.dart',
        [
            ("title: 'Keluarkan Jamaah?',", "title: context.tr('room.removeMemberTitle'),"),
            ("message:\n          'Jamaah ini akan dikeluarkan dari rombongan dan tidak lagi dapat dipantau oleh pendamping.',", "message: context.tr('room.removeConfirmMsg', {'name': widget.jamaah.name}),"),
            ("confirmText: 'Keluarkan',", "confirmText: context.tr('room.removeAction'),"),
            ("cancelText: 'Batal',", "cancelText: context.tr('common.cancel'),"),
            ("title: 'Jamaah Dikeluarkan',", "title: context.tr('room.memberRemoved'),"),
            ("'${widget.jamaah.name} sudah dikeluarkan dari rombongan \"${widget.roomName}\".'", "context.tr('room.memberRemovedDesc', {'name': widget.jamaah.name, 'room': widget.roomName})"),
            ("title: 'Belum Dapat Dikeluarkan',", "title: context.tr('room.memberRemoveFailed'),"),
            ("label: 'NIK',", "label: context.tr('profile.nik'),"),
            ("label: 'Nomor Porsi',", "label: context.tr('profile.portionNumber'),"),
            ("label: 'Nomor Paspor',", "label: context.tr('profile.passportNumber'),"),
            ("label: 'Golongan Darah',", "label: context.tr('profile.bloodType'),"),
            ("label: 'Riwayat Alergi',", "label: context.tr('profile.allergyHistory'),"),
            ("label: 'Kondisi Khusus',", "label: context.tr('profile.specialConditions'),"),
            ("label: 'Kontak Darurat',", "label: context.tr('profile.emergencyContact'),"),
        ]
    )

    # 4. login_controller.dart
    safe_replace(
        'lib/features/auth/controllers/login_controller.dart',
        [
            ("title: 'Selamat Datang!',", "title: AppTranslations.tr('auth.welcomeAlertTitle'),"),
            ("title: 'Belum Bisa Masuk',", "title: AppTranslations.tr('auth.cannotLoginAlertTitle'),"),
        ]
    )

    # 5. communication_screen.dart
    safe_replace(
        'lib/features/communication/screens/communication_screen.dart',
        [
            ("label: 'Darurat & Kesehatan',", "label: context.tr('comm.emergencyAndHealth'),"),
            ("label: 'Arah & Lokasi',", "label: context.tr('comm.directionAndLocation'),"),
            ("label: 'Percakapan Umum',", "label: context.tr('comm.generalConversation'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    # 6. dashboard_jamaah_sections.dart
    safe_replace(
        'lib/features/dashboard/screens/dashboard_jamaah_sections.dart',
        [
            ("'Pendamping Tidak Tersedia'", "context.tr('dashboard.companionUnavailable')"),
            ("title: 'Pilih pendamping tujuan',", "title: context.tr('dashboard.selectTargetCompanion'),"),
        ]
    )

    # 7. dashboard_pendamping_screen.dart
    safe_replace(
        'lib/features/dashboard/screens/dashboard_pendamping_screen.dart',
        [
            ("title: 'Akhiri Darurat SOS?',", "title: context.tr('dashboard.endSos'),"),
            ("confirmText: 'Ya, Akhiri SOS',", "confirmText: context.tr('dashboard.yesEndSos'),"),
            ("cancelText: 'Batal',", "cancelText: context.tr('common.cancel'),"),
            ("hintText: 'Cari jamaah...',", "hintText: context.tr('dashboard.searchPilgrim'),"),
        ]
    )

    # 8. pendamping_radar_card.dart
    safe_replace(
        'lib/features/dashboard/widgets/pendamping_radar_card.dart',
        [
            ("hintText: 'Contoh: 250',", "hintText: context.tr('dashboard.sampleRadius'),"),
        ]
    )

    # 9. notification_screen.dart
    safe_replace(
        'lib/features/notification/screens/notification_screen.dart',
        [
            ("title: 'Notifikasi',", "title: context.tr('notificationTooltip'),"),
        ]
    )

    # 10. notification_composer_dialog.dart
    safe_replace(
        'lib/features/notification/widgets/notification_composer_dialog.dart',
        [
            ("title: 'Pilih Penerima',", "title: context.tr('notification.selectRecipient'),"),
            ("title: 'Kategori Pesan',", "title: context.tr('notification.messageCategory'),"),
            ("title: 'Tulis Pesan',", "title: context.tr('notification.writeMessage'),"),
            ("Text('Ganti')", "Text(context.tr('notification.change'))"),
        ]
    )

    # 11. room_detail_screen.dart
    safe_replace(
        'lib/features/room/screens/room_detail_screen.dart',
        [
            ("label: 'Lihat di Peta',", "label: context.tr('room.viewOnMap'),"),
            ("label: 'Keluarkan',", "label: context.tr('room.removeAction'),"),
            ("confirmText: 'Keluarkan',", "confirmText: context.tr('room.removeAction'),"),
        ]
    )

    # 12. bisindo_screen.dart
    safe_replace(
        'lib/features/sign_language/screens/bisindo_screen.dart',
        [
            ("label: 'SPASI',", "label: context.tr('sign.space'),"),
            ("label: 'Dengarkan',", "label: context.tr('sign.listen'),"),
            ("label: 'Izinkan kamera',", "label: context.tr('sign.allowCamera'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    # 13. smartband_ldr_page.dart
    safe_replace(
        'lib/features/smartband/screens/smartband_ldr_page.dart',
        [
            ("subtitle: 'Prototype BLE – Sensor LDR & Flame',", "subtitle: context.tr('smartband.blePrototype'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    # 14. sos_companion_scanning_screen.dart
    safe_replace(
        'lib/features/sos/screens/sos_companion_scanning_screen.dart',
        [
            ("label: 'Pindai Ulang',", "label: context.tr('sos.rescan'),"),
        ]
    )

    # 15. translator_sheet.dart
    safe_replace(
        'lib/features/translator/widgets/translator_sheet.dart',
        [
            ("label: 'Tersesat',", "label: context.tr('translator.lostPhrase'),"),
            ("label: 'Pintu Keluar',", "label: context.tr('translator.exitPhrase'),"),
            ("label: 'Medis / Dokter',", "label: context.tr('translator.medicalPhrase'),"),
            ("label: 'Toilet / Wudhu',", "label: context.tr('translator.toiletPhrase'),"),
            ("label: 'Air Zamzam',", "label: context.tr('translator.zamzamPhrase'),"),
            ("label: 'Tanya Harga',", "label: context.tr('translator.pricePhrase'),"),
            ("label: 'Taksi ke Hotel',", "label: context.tr('translator.taxiPhrase'),"),
        ]
    )

    # 16. bottom_nav_bar.dart
    safe_replace(
        'lib/core/widgets/bottom_nav_bar.dart',
        [
            ("tooltip: 'Penerjemah HajiCare',", "tooltip: context.tr('translator.title'),"),
        ],
        import_statement="import '../locales/app_localizations.dart';"
    )

    print("Cleanup completed successfully!")

if __name__ == '__main__':
    cleanup()
