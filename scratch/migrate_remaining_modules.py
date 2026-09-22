import os
import re

def safe_replace(file_path, replacements, import_statement=None):
    if not os.path.exists(file_path):
        print(f"Skipping {file_path} (does not exist)")
        return
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
        print(f"Migrated {file_path}")
    else:
        print(f"No match in {file_path}")

def migrate_all():
    # --- ROOM CONTROLLERS ---
    safe_replace(
        'lib/features/room/controllers/admin_room_controller.dart',
        [
            ("title: 'Perhatian',", "title: context.tr('room.attention'),"),
            ("message: 'Isi nama rombongan terlebih dahulu.',", "message: context.tr('room.emptyRoomName'),"),
            ("title: 'Nama Terlalu Panjang',", "title: context.tr('room.nameTooLong'),"),
            ("message: 'Nama rombongan maksimal 100 karakter.',", "message: context.tr('room.nameMax100'),"),
            ("title: 'Rombongan Berhasil Dibuat',", "title: context.tr('room.roomCreated'),"),
            ("'Rombongan \"${newRoom.name}\" dibuat dengan kode ${newRoom.code}.'", "context.tr('room.roomCreatedDesc', {'name': newRoom.name, 'code': newRoom.code})"),
            ("title: 'Belum Berhasil',", "title: context.tr('room.roomCreateFailed'),"),
            ("fallback: 'Rombongan belum dapat dibuat. Silakan coba lagi.',", "fallback: context.tr('room.createFailedFallback'),"),
            ("title: 'Nama Berhasil Diubah',", "title: context.tr('room.roomNameChanged'),"),
            ("'Nama rombongan sekarang \"$trimmed\".'", "context.tr('room.roomNameChangedDesc', {'name': trimmed})"),
            ("title: 'Nama Belum Diubah',", "title: context.tr('room.roomNameChangeFailed'),"),
            ("fallback: 'Nama rombongan belum dapat diubah. Silakan coba lagi.',", "fallback: context.tr('room.roomNameChangeFailedFallback'),"),
            ("title: 'Nonaktifkan Rombongan?',", "title: context.tr('room.deactivateRoomTitle'),"),
            ("'Rombongan \"${room.name}\" akan dinonaktifkan sementara. Anggota tidak dapat bergabung selama dinonaktifkan.'", "context.tr('room.deactivateRoomDesc', {'name': room.name})"),
            ("confirmText: 'Nonaktifkan',", "confirmText: context.tr('room.deactivate'),"),
            ("cancelText: 'Batal',", "cancelText: context.tr('common.cancel'),"),
            ("title: 'Status Diperbarui',", "title: context.tr('room.statusUpdated'),"),
            ("'Rombongan berhasil $label.'", "context.tr('room.statusUpdatedDesc', {'status': label})"),
            ("title: 'Status Belum Diubah',", "title: context.tr('room.statusUpdateFailed'),"),
            ("fallback: 'Status rombongan belum dapat diubah. Silakan coba lagi.',", "fallback: context.tr('room.statusChangeFailedFallback'),"),
            ("title: 'Hapus Rombongan?',", "title: context.tr('room.deleteRoomTitle'),"),
            ("'Semua anggota akan keluar dari rombongan \"${room.name}\". Rombongan yang dihapus tidak dapat dikembalikan.'", "context.tr('room.deleteRoomDesc', {'name': room.name})"),
            ("confirmText: 'Hapus',", "confirmText: context.tr('room.delete'),"),
            ("title: 'Rombongan Dihapus',", "title: context.tr('room.roomDeleted'),"),
            ("'Rombongan \"${room.name}\" telah dihapus.'", "context.tr('room.roomDeletedDesc', {'name': room.name})"),
            ("title: 'Belum Dapat Dihapus',", "title: context.tr('room.deleteFailed'),"),
            ("fallback: 'Rombongan belum dapat dihapus. Silakan coba lagi.',", "fallback: context.tr('room.deleteFailedFallback'),"),
            ("title: 'Keluar dari Admin?',", "title: context.tr('room.exitAdminTitle'),"),
            ("message: 'Anda akan keluar dari sesi administrator Command Center.',", "message: context.tr('room.exitAdminDesc'),"),
            ("confirmText: 'Keluar',", "confirmText: context.tr('common.logout'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/room/controllers/join_room_controller.dart',
        [
            ("title: 'Berhasil Bergabung',", "title: AppTranslations.tr('room.joinedSuccess'),"),
            ("'Anda sudah bergabung dengan rombongan \"${joinedRoom.name}\".'", "AppTranslations.tr('room.joinedSuccessDesc', {'name': joinedRoom.name})"),
            ("fallback:\n            'Belum dapat bergabung. Periksa kode rombongan, lalu coba lagi.',", "fallback: AppTranslations.tr('room.joinFailedFallback'),"),
            ("title: 'Belum Berhasil',", "title: AppTranslations.tr('room.roomCreateFailed'),"),
            ("okText: 'Coba Lagi',", "okText: AppTranslations.tr('common.tryAgain'),"),
        ],
        import_statement="import '../../../core/locales/app_translations.dart';"
    )

    # --- ROOM WIDGETS & SCREENS ---
    safe_replace(
        'lib/features/room/widgets/create_room_dialog.dart',
        [
            ("title: 'Buat Room Pantau Baru',", "title: context.tr('room.createNewMonitorRoom'),"),
            ("hintText: 'Misal: Maktab 48 Kloter 12',", "hintText: context.tr('room.sampleGroupHint'),"),
            ("badgeText: 'ROOM PEMANTAUAN',", "badgeText: context.tr('room.roomMonitoringBadge'),"),
            ("label: 'BUAT ROOM',", "label: context.tr('room.createRoomBtn'),"),
            ("label: 'Batal',", "label: context.tr('common.cancel'),"),
            ("AppAlertService.showWarning('Nama rombongan tidak boleh kosong');", "AppAlertService.showWarning(context.tr('room.emptyRoomName'));"),
            ("AppAlertService.showWarning('Nama rombongan maksimal 100 karakter');", "AppAlertService.showWarning(context.tr('room.nameMax100'));"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/room/widgets/edit_room_dialog.dart',
        [
            ("'Perubahan Disimpan'", "context.tr('room.changesSaved')"),
            ("title: 'Ubah Pengaturan Room',", "title: context.tr('room.editRoomSettings'),"),
            ("value: 'Kode: ", "value: '${context.tr('room.codePrefix')}"),
            ("label: 'Nama Room / Rombongan *',", "label: context.tr('room.roomNameField'),"),
            ("hint: 'Contoh: Rombongan Maktab 10',", "hint: context.tr('room.sampleMaktab10'),"),
            ("label: 'Batas Radius Aman (Meter) *',", "label: context.tr('room.safeRadiusLimit'),"),
            ("badgeText: 'PENGATURAN ROMBONGAN',", "badgeText: context.tr('room.groupSettingsBadge'),"),
            ("label: 'SIMPAN',", "label: context.tr('common.save'),"),
            ("label: 'Batal',", "label: context.tr('common.cancel'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/room/widgets/room_qr_dialog.dart',
        [
            ("'Kode Disalin'", "context.tr('room.codeCopied')"),
            ("'Teks Undangan Disalin'", "context.tr('room.invitationCopied')"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/room/widgets/active_room_card.dart',
        [
            ("label: 'Kode Room',", "label: context.tr('room.roomCode'),"),
            ("'Kode Disalin'", "context.tr('room.codeCopied')"),
            ("label: 'Radius Radar',", "label: context.tr('room.radarRadius'),"),
            ("label: 'Undang Jamaah Sekarang',", "label: context.tr('room.invitePilgrimNow'),"),
            ("title: 'Rombongan Dihapus',", "title: context.tr('room.roomDeleted'),"),
            ("title: 'Belum Dapat Dihapus',", "title: context.tr('room.deleteFailed'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/room/widgets/add_jamaah_dialog.dart',
        [
            ("title: 'Undangan Terkirim',", "title: context.tr('room.invitationSent'),"),
            ("title: 'Undangan Belum Terkirim',", "title: context.tr('room.invitationFailed'),"),
            ("hintText: 'contoh: jamaah@gmail.com',", "hintText: context.tr('room.sampleEmailHint'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/room/screens/room_detail_screen.dart',
        [
            ("title: 'Hapus Rombongan?',", "title: context.tr('room.deleteRoomTitle'),"),
            ("confirmText: 'Hapus Rombongan',", "confirmText: context.tr('room.delete'),"),
            ("cancelText: 'Batal',", "cancelText: context.tr('common.cancel'),"),
            ("title: 'Rombongan Dihapus',", "title: context.tr('room.roomDeleted'),"),
            ("title: 'Belum Dapat Dihapus',", "title: context.tr('room.deleteFailed'),"),
            ("label: 'Kembali ke Beranda',", "label: context.tr('room.returnToHome'),"),
            ("'Kode Disalin'", "context.tr('room.codeCopied')"),
            ("label: 'Total Anggota',", "label: context.tr('room.totalMembers'),"),
            ("hintText: 'Cari nama atau peran anggota...',", "hintText: context.tr('room.searchMember'),"),
            ("label: 'Reset Filter & Pencarian',", "label: context.tr('room.resetFilter'),"),
            ("label: 'Status Kehadiran',", "label: context.tr('room.attendanceStatus'),"),
            ("label: 'Tanggal Bergabung',", "label: context.tr('room.joinDate'),"),
            ("label: 'Koordinat Lokasi',", "label: context.tr('room.locationCoordinates'),"),
            ("label: 'Lihat di Peta',", "label: context.tr('room.viewOnMap'),"),
            ("label: 'Keluarkan',", "label: context.tr('room.removeAction'),"),
            ("title: 'Keluarkan Jamaah?',", "title: context.tr('room.removeMemberTitle'),"),
            ("title: 'Jamaah Dikeluarkan',", "title: context.tr('room.memberRemoved'),"),
            ("title: 'Belum Dapat Dikeluarkan',", "title: context.tr('room.memberRemoveFailed'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/room/screens/admin_room_management_screen.dart',
        [
            ("title: 'Kelola Room Pantau',", "title: context.tr('room.manageTrackingRoom'),"),
            ("subtitle: 'Delegasi & Monitoring Maktab Jamaah',", "subtitle: context.tr('room.manageTrackingRoomSub'),"),
            ("label: 'Menyinkronkan',", "label: context.tr('room.syncing'),"),
            ("label: 'Total Room',", "label: context.tr('room.totalRooms'),"),
            ("label: 'Jamaah Pantau',", "label: context.tr('room.pilgrimsMonitored'),"),
            ("hintText: 'Cari nama room atau 6-digit kode...',", "hintText: context.tr('room.searchRoomOrCode'),"),
            ("title: 'Buka Ruang Pantau & Anggota',", "title: context.tr('room.openMonitorRoom'),"),
            ("subtitle: 'Pantau posisi live jamaah dan pendamping',", "subtitle: context.tr('room.openMonitorRoomSub'),"),
            ("title: 'Lihat QR Code Room',", "title: context.tr('room.viewQrCode'),"),
            ("subtitle: 'Bagikan kode ke jamaah agar dapat bergabung',", "subtitle: context.tr('room.shareCodeSub'),"),
            ("'Kode Disalin'", "context.tr('room.codeCopied')"),
            ("title: 'Ubah Nama Ruang',", "title: context.tr('room.renameRoom'),"),
            ("subtitle: 'Perbarui label maktab atau kelompok',", "subtitle: context.tr('room.renameRoomSub'),"),
            ("title: 'Hapus Ruang Pantau',", "title: context.tr('room.deleteMonitorRoom'),"),
            ("subtitle: 'Hapus permanen room dan daftar delegasi anggota',", "subtitle: context.tr('room.deleteMonitorRoomSub'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/room/screens/edit_room_screen.dart',
        [
            ("'Perubahan Disimpan'", "context.tr('room.changesSaved')"),
            ("label: 'Nama Room / Rombongan *',", "label: context.tr('room.roomNameField'),"),
            ("label: 'Batas Radius Aman *',", "label: context.tr('room.safeRadiusLimit'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/room/screens/join_room_screen.dart',
        [
            ("label: 'Buat Room',", "label: context.tr('room.createRoomBtn'),"),
            ("label: 'Gabung Room',", "label: context.tr('room.joinRoomTitle'),"),
            ("hint: 'Contoh: Rombongan Maktab 48',", "hint: context.tr('room.sampleRoomName'),"),
            ("hint: 'Contoh: Maktab 48',", "hint: context.tr('room.sampleMaktabNumber'),"),
            ("hint: 'Contoh: SOC-12',", "hint: context.tr('room.sampleKloter'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    # --- SOS SCREENS ---
    safe_replace(
        'lib/features/sos/screens/distance_alert_screen.dart',
        [
            ("'45m melebihi batas aman'", "context.tr('sos.distanceExceeded', {'distance': 45})"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/sos/screens/modal_sos_screen.dart',
        [
            ("'SOS Belum Terkirim'", "context.tr('sos.failedToSend')"),
            ("title: 'Selesaikan Darurat SOS?',", "title: context.tr('sos.completeDialogTitle'),"),
            ("confirmText: 'Ya, Selesaikan',", "confirmText: context.tr('sos.yesComplete'),"),
            ("cancelText: 'Batal',", "cancelText: context.tr('common.cancel'),"),
            ("title: 'SOS Selesai',", "title: context.tr('sos.completed'),"),
            ("title: 'Status Belum Diubah',", "title: context.tr('sos.statusNotChanged'),"),
            ("title: 'Sinyal SOS Dinonaktifkan',", "title: context.tr('sos.signalDisabled'),"),
            ("title: 'SOS Belum Dinonaktifkan',", "title: context.tr('sos.signalDisableFailed'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/sos/screens/sos_alert_detail_screen.dart',
        [
            ("'Lokasi Belum Tersedia'", "context.tr('maps.locationUnavailable')"),
            ("title: 'Selesaikan SOS?',", "title: context.tr('sos.completeDialogTitle'),"),
            ("confirmText: 'Ya, Selesaikan',", "confirmText: context.tr('sos.yesComplete'),"),
            ("cancelText: 'Batal',", "cancelText: context.tr('common.cancel'),"),
            ("title: 'SOS Diselesaikan',", "title: context.tr('sos.completed'),"),
            ("title: 'Gagal Menyelesaikan',", "title: context.tr('sos.statusNotChanged'),"),
            ("label: 'ID Jamaah',", "label: context.tr('sos.pilgrimId'),"),
            ("label: 'Kloter',", "label: context.tr('sos.kloterLabel'),"),
            ("label: 'Maktab',", "label: context.tr('sos.maktabLabel'),"),
            ("label: 'Waktu SOS',", "label: context.tr('sos.sosTime'),"),
            ("'Koordinat Disalin'", "context.tr('sos.coordinatesCopied')"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/sos/screens/sos_companion_scanning_screen.dart',
        [
            ("title: 'Kontak Tidak Tersedia',", "title: context.tr('sos.contactUnavailable'),"),
            ("title: 'Gagal Melakukan Panggilan',", "title: context.tr('sos.callFailed'),"),
            ("label: 'Pindai Ulang',", "label: context.tr('sos.rescan'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    # --- NOTIFICATION ---
    safe_replace(
        'lib/features/notification/controllers/notification_controller.dart',
        [
            ("title: 'Undangan Diterima!',", "title: AppTranslations.tr('notification.invitationAccepted'),"),
            ("title: 'Undangan Tidak Berlaku',", "title: AppTranslations.tr('notification.invitationInvalid'),"),
            ("title: 'Belum Dapat Bergabung',", "title: AppTranslations.tr('notification.joinFailed'),"),
            ("title: 'Undangan Ditolak',", "title: AppTranslations.tr('notification.invitationRejected'),"),
            ("title: 'Pilihan Belum Disimpan',", "title: AppTranslations.tr('notification.choiceNotSaved'),"),
        ],
        import_statement="import '../../../core/locales/app_translations.dart';"
    )

    safe_replace(
        'lib/features/notification/screens/notification_screen.dart',
        [
            ("title: 'FAQ & Bantuan',", "title: context.tr('notification.faqAndHelp'),"),
            ("cancelText: 'Batal',", "cancelText: context.tr('common.cancel'),"),
            ("title: 'Himbauan Gelombang Panas Makkah',", "title: context.tr('notification.heatwaveAdvisory'),"),
            ("title: 'Jadwal Bus Shalawat Rute Syisyah',", "title: context.tr('notification.busScheduleInfo'),"),
            ("title: 'Materi Manasik Tambahan Siap Dibaca',", "title: context.tr('notification.additionalManasikInfo'),"),
            ("'Peta Belum Dapat Dibuka'", "context.tr('notification.mapOpenFailed')"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    safe_replace(
        'lib/features/notification/widgets/notification_composer_dialog.dart',
        [
            ("title: 'Penerima Belum Dipilih',", "title: context.tr('notification.recipientNotSelected'),"),
            ("title: 'Silakan Masuk Kembali',", "title: context.tr('notification.pleaseRelogin'),"),
            ("title: 'Pesan Terkirim',", "title: context.tr('notification.messageSent'),"),
            ("title: 'Pesan Belum Terkirim',", "title: context.tr('notification.messageSendFailed'),"),
            ("label: 'Pilih Penerima',", "label: context.tr('notification.selectRecipient'),"),
            ("label: 'Kategori Pesan',", "label: context.tr('notification.messageCategory'),"),
            ("label: 'Tulis Pesan',", "label: context.tr('notification.writeMessage'),"),
            ("hintText: 'Misalnya: Waktu Berkumpul',", "hintText: context.tr('notification.sampleTitle'),"),
            ("label: 'Pilih maktab tujuan *',", "label: context.tr('notification.selectTargetMaktab'),"),
            ("label: 'Pilih kloter tujuan *',", "label: context.tr('notification.selectTargetKloter'),"),
            ("label: 'Ganti',", "label: context.tr('notification.change'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    # --- PRAYER ---
    safe_replace(
        'lib/features/prayer/controllers/prayer_times_controller.dart',
        [
            ("'Lokasi Ponsel Belum Aktif'", "AppTranslations.tr('prayer.phoneGpsInactive')"),
            ("'Izin Lokasi Diperlukan'", "AppTranslations.tr('prayer.locationPermissionRequired')"),
            ("'Lokasi Belum Ditemukan'", "AppTranslations.tr('prayer.locationNotFound')"),
        ],
        import_statement="import '../../../core/locales/app_translations.dart';"
    )

    # --- MONEY ---
    safe_replace(
        'lib/features/money/screens/money_recognition_screen.dart',
        [
            ("label: 'Ambil Foto Uang Riyal',", "label: context.tr('money.captureRiyal'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    # --- SIGN LANGUAGE ---
    safe_replace(
        'lib/features/sign_language/screens/bisindo_screen.dart',
        [
            ("label: 'Dengarkan',", "label: context.tr('sign.listen'),"),
            ("label: 'HAPUS',", "label: context.tr('sign.delete'),"),
            ("label: 'RESET',", "label: context.tr('sign.reset'),"),
            ("label: 'SPASI',", "label: context.tr('sign.space'),"),
            ("label: 'Izinkan kamera',", "label: context.tr('sign.allowCamera'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    # --- SMARTBAND ---
    safe_replace(
        'lib/features/smartband/controllers/smartband_ldr_controller.dart',
        [
            ("'Peringatan Api'", "AppTranslations.tr('smartband.fireAlert')"),
            ("'Bluetooth Tidak Aktif'", "AppTranslations.tr('smartband.bluetoothInactive')"),
            ("'Gelang Belum Terhubung'", "AppTranslations.tr('smartband.bandNotConnected')"),
        ],
        import_statement="import '../../../core/locales/app_translations.dart';"
    )

    safe_replace(
        'lib/features/smartband/screens/smartband_ldr_page.dart',
        [
            ("title: 'Gelang Pintar Haji',", "title: context.tr('smartband.hajjSmartband'),"),
            ("subtitle: 'Prototype BLE – Sensor LDR & Flame',", "subtitle: context.tr('smartband.blePrototype'),"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    # --- TRANSLATOR ---
    safe_replace(
        'lib/features/translator/widgets/translator_sheet.dart',
        [
            ("title: 'Tersesat',", "title: context.tr('translator.lostPhrase'),"),
            ("title: 'Pintu Keluar',", "title: context.tr('translator.exitPhrase'),"),
            ("title: 'Medis / Dokter',", "title: context.tr('translator.medicalPhrase'),"),
            ("title: 'Toilet / Wudhu',", "title: context.tr('translator.toiletPhrase'),"),
            ("title: 'Air Zamzam',", "title: context.tr('translator.zamzamPhrase'),"),
            ("title: 'Tanya Harga',", "title: context.tr('translator.pricePhrase'),"),
            ("title: 'Taksi ke Hotel',", "title: context.tr('translator.taxiPhrase'),"),
            ("'Teks terjemahan sudah disalin dan siap ditempel.'", "context.tr('translator.copiedReady')"),
            ("'Ketik teks atau gunakan tombol mikrofon…'", "context.tr('translator.typeOrMicPrompt')"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

    # --- HELP CENTER ---
    safe_replace(
        'lib/features/profile/screens/help_center_screen.dart',
        [
            ("label: 'Tampilkan semua bantuan',", "label: context.tr('help.showAllHelp'),"),
            ("label: 'Semua',", "label: context.tr('help.all'),"),
            ("'Alamat Email Disalin'", "context.tr('help.emailCopied')"),
            ("'Kontak Belum Tersedia'", "context.tr('help.contactUnavailable')"),
            ("'Nomor WhatsApp Disalin'", "context.tr('help.waCopied')"),
        ],
        import_statement="import '../../../core/locales/app_localizations.dart';"
    )

if __name__ == '__main__':
    migrate_all()
