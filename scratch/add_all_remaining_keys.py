import re

REMAINING_KEYS = {
    'auth.welcomeAlertTitle': {
        'id': 'Selamat Datang!',
        'en': 'Welcome!',
        'jv': 'Sugeng Rawuh!',
        'su': 'Wilujeng Sumping!',
    },
    'auth.cannotLoginAlertTitle': {
        'id': 'Belum Bisa Masuk',
        'en': 'Cannot Sign In',
        'jv': 'Dèrèng Saged Mlebet',
        'su': 'Teu Acan Tiasa Lebet',
    },
    'comm.emergencyAndHealth': {
        'id': 'Darurat & Kesehatan',
        'en': 'Emergency & Health',
        'jv': 'Darurat & Kasarasan',
        'su': 'Darurat & Kaséhatan',
    },
    'comm.directionAndLocation': {
        'id': 'Arah & Lokasi',
        'en': 'Direction & Location',
        'jv': 'Pener & Papan Dunung',
        'su': 'Madhab & Lokasi',
    },
    'comm.generalConversation': {
        'id': 'Percakapan Umum',
        'en': 'General Conversation',
        'jv': 'Pacelathon Umum',
        'su': 'Obrolan Umum',
    },
    'dashboard.companionUnavailable': {
        'id': 'Pendamping Tidak Tersedia',
        'en': 'Companion Unavailable',
        'jv': 'Pendamping Mboten Sumadya',
        'su': 'Pendamping Teu Sayaga',
    },
    'dashboard.selectTargetCompanion': {
        'id': 'Pilih pendamping tujuan',
        'en': 'Select target companion',
        'jv': 'Pilih pendamping jujugan',
        'su': 'Pilih pendamping tujuan',
    },
    'dashboard.yesEndSos': {
        'id': 'Ya, Akhiri SOS',
        'en': 'Yes, End SOS',
        'jv': 'Inggih, Pungkasi SOS',
        'su': 'Muhun, Pungkas SOS',
    },
    'dashboard.sampleRadius': {
        'id': 'Contoh: 250',
        'en': 'Example: 250',
        'jv': 'Tuladha: 250',
        'su': 'Conto: 250',
    },
    'room.memberRemovedDesc': {
        'id': '{name} sudah dikeluarkan dari rombongan "{room}".',
        'en': '{name} has been removed from group "{room}".',
        'jv': '{name} sampun dipunkeluarken saking rombongan "{room}".',
        'su': '{name} parantos dikaluarkeun tina rombongan "{room}".',
    },
    'profile.nameChangedSuccessDesc': {
        'id': 'Nama Anda sekarang "{name}".',
        'en': 'Your name is now "{name}".',
        'jv': 'Asma panjenengan sakmenika "{name}".',
        'su': 'Nami anjeun ayeuna "{name}".',
    },
    # Room
    'room.emptyRoomName': {
        'id': 'Isi nama rombongan terlebih dahulu.',
        'en': 'Please enter a group name first.',
        'jv': 'Kersaa ngisi nama rombongan rumiyin.',
        'su': 'Eusian nami rombongan heula.',
    },
    'room.nameMax100': {
        'id': 'Nama rombongan maksimal 100 karakter.',
        'en': 'Group name must be at most 100 characters.',
        'jv': 'Nama rombongan paling kathah 100 karakter.',
        'su': 'Nami rombongan maksimal 100 karakter.',
    },
    'room.roomCreatedDesc': {
        'id': 'Rombongan "{name}" dibuat dengan kode {code}.',
        'en': 'Group "{name}" was created with code {code}.',
        'jv': 'Rombongan "{name}" dipundamel kanthi kode {code}.',
        'su': 'Rombongan "{name}" didamel kalayan kode {code}.',
    },
    'room.createFailedFallback': {
        'id': 'Rombongan belum dapat dibuat. Silakan coba lagi.',
        'en': 'Failed to create group. Please try again.',
        'jv': 'Rombongan dèrèng saged dipundamel. Cobi malih.',
        'su': 'Rombongan teu acan tiasa didamel. Mangga cobian deui.',
    },
    'room.roomNameChangedDesc': {
        'id': 'Nama rombongan sekarang "{name}".',
        'en': 'Group name is now "{name}".',
        'jv': 'Nama rombongan sakmenika "{name}".',
        'su': 'Nami rombongan ayeuna "{name}".',
    },
    'room.roomNameChangeFailedFallback': {
        'id': 'Nama rombongan belum dapat diubah. Silakan coba lagi.',
        'en': 'Failed to update group name. Please try again.',
        'jv': 'Nama rombongan dèrèng saged dipunéwahi. Cobi malih.',
        'su': 'Nami rombongan teu acan tiasa dirobih. Mangga cobian deui.',
    },
    'room.deactivateRoomDesc': {
        'id': 'Rombongan "{name}" akan dinonaktifkan sementara. Anggota tidak dapat bergabung selama dinonaktifkan.',
        'en': 'Group "{name}" will be temporarily deactivated. Members cannot join while deactivated.',
        'jv': 'Rombongan "{name}" badhé dipun-nonaktifaken sauntara. Anggota mboten saged gathuk nalika dipun-nonaktifaken.',
        'su': 'Rombongan "{name}" bakal dinonaktifkeun samentawis. Anggota teu tiasa gabung salila dinonaktifkeun.',
    },
    'room.deactivate': {
        'id': 'Nonaktifkan',
        'en': 'Deactivate',
        'jv': 'Nonaktifaken',
        'su': 'Nonaktifkeun',
    },
    'room.statusUpdatedDesc': {
        'id': 'Rombongan berhasil {status}.',
        'en': 'Group successfully {status}.',
        'jv': 'Rombongan kasil {status}.',
        'su': 'Rombongan parantos {status}.',
    },
    'room.activatedStatus': {
        'id': 'diaktifkan',
        'en': 'activated',
        'jv': 'dipun-aktifaken',
        'su': 'diaktifkeun',
    },
    'room.deactivatedStatus': {
        'id': 'dinonaktifkan',
        'en': 'deactivated',
        'jv': 'dipun-nonaktifaken',
        'su': 'dinonaktifkeun',
    },
    'room.statusChangeFailedFallback': {
        'id': 'Status rombongan belum dapat diubah. Silakan coba lagi.',
        'en': 'Failed to change group status. Please try again.',
        'jv': 'Status rombongan dèrèng saged dipunéwahi. Cobi malih.',
        'su': 'Status rombongan teu acan tiasa dirobih. Mangga cobian deui.',
    },
    'room.deleteRoomDesc': {
        'id': 'Semua anggota akan keluar dari rombongan "{name}". Rombongan yang dihapus tidak dapat dikembalikan.',
        'en': 'All members will leave group "{name}". Deleted groups cannot be recovered.',
        'jv': 'Sedanten anggota badhé miyos saking rombongan "{name}". Rombongan ingkang kabusek mboten saged dipunwangsulaken.',
        'su': 'Sadaya anggota bakal kaluar tina rombongan "{name}". Rombongan anu dihapus teu tiasa dibalikeun.',
    },
    'room.delete': {
        'id': 'Hapus',
        'en': 'Delete',
        'jv': 'Busek',
        'su': 'Hapus',
    },
    'room.roomDeletedDesc': {
        'id': 'Rombongan "{name}" telah dihapus.',
        'en': 'Group "{name}" has been deleted.',
        'jv': 'Rombongan "{name}" sampun kabusek.',
        'su': 'Rombongan "{name}" parantos dihapus.',
    },
    'room.deleteFailedFallback': {
        'id': 'Rombongan belum dapat dihapus. Silakan coba lagi.',
        'en': 'Failed to delete group. Please try again.',
        'jv': 'Rombongan dèrèng saged kabusek. Cobi malih.',
        'su': 'Rombongan teu acan tiasa dihapus. Mangga cobian deui.',
    },
    'room.exitAdminDesc': {
        'id': 'Anda akan keluar dari sesi administrator Command Center.',
        'en': 'You will exit the Command Center administrator session.',
        'jv': 'Panjenengan badhé miyos saking sesi administrator Command Center.',
        'su': 'Anjeun bakal kaluar tina sési administrator Command Center.',
    },
    'room.joinedSuccessDesc': {
        'id': 'Anda sudah bergabung dengan rombongan "{name}".',
        'en': 'You have joined group "{name}".',
        'jv': 'Panjenengan sampun gathuk kaliyan rombongan "{name}".',
        'su': 'Anjeun parantos gabung sareng rombongan "{name}".',
    },
    'room.joinFailedFallback': {
        'id': 'Belum dapat bergabung. Periksa kode rombongan, lalu coba lagi.',
        'en': 'Failed to join. Check group code and try again.',
        'jv': 'Dèrèng saged gathuk. Priksani kode rombongan, lajeng cobi malih.',
        'su': 'Teu acan tiasa gabung. Parios kode rombongan, teras cobian deui.',
    },
    'room.createNewMonitorRoom': {
        'id': 'Buat Room Pantau Baru',
        'en': 'Create New Monitoring Room',
        'jv': 'Damel Room Pantau Enggal',
        'su': 'Damel Room Pantau Anyar',
    },
    'room.sampleGroupHint': {
        'id': 'Misal: Maktab 48 Kloter 12',
        'en': 'E.g.: Maktab 48 Flight 12',
        'jv': 'Tuladha: Maktab 48 Kloter 12',
        'su': 'Conto: Maktab 48 Kloter 12',
    },
    'room.roomMonitoringBadge': {
        'id': 'ROOM PEMANTAUAN',
        'en': 'MONITORING ROOM',
        'jv': 'ROOM PAMANTAUAN',
        'su': 'ROOM PAMANTAUAN',
    },
    'room.createRoomBtn': {
        'id': 'BUAT ROOM',
        'en': 'CREATE ROOM',
        'jv': 'DAMEL ROOM',
        'su': 'DAMEL ROOM',
    },
    'room.editRoomSettings': {
        'id': 'Ubah Pengaturan Room',
        'en': 'Edit Room Settings',
        'jv': 'Éwah Pangaturan Room',
        'su': 'Robi Setélan Room',
    },
    'room.codePrefix': {
        'id': 'Kode: ',
        'en': 'Code: ',
        'jv': 'Kode: ',
        'su': 'Kode: ',
    },
    'room.sampleMaktab10': {
        'id': 'Contoh: Rombongan Maktab 10',
        'en': 'Example: Maktab 10 Group',
        'jv': 'Tuladha: Rombongan Maktab 10',
        'su': 'Conto: Rombongan Maktab 10',
    },
    'room.groupSettingsBadge': {
        'id': 'PENGATURAN ROMBONGAN',
        'en': 'GROUP SETTINGS',
        'jv': 'PANGATURAN ROMBONGAN',
        'su': 'SETÉLAN ROMBONGAN',
    },
    'room.totalMembers': {
        'id': 'Total Anggota',
        'en': 'Total Members',
        'jv': 'Gunggung Anggota',
        'su': 'Jumlah Anggota',
    },
    'room.returnToHome': {
        'id': 'Kembali ke Beranda',
        'en': 'Back to Home',
        'jv': 'Wangsul dhateng Beranda',
        'su': 'Mulang ka Beranda',
    },
    'room.sampleEmailHint': {
        'id': 'contoh: jamaah@gmail.com',
        'en': 'example: pilgrim@gmail.com',
        'jv': 'tuladha: jamaah@gmail.com',
        'su': 'conto: jamaah@gmail.com',
    },
    'room.newGroupOrKloter': {
        'id': 'Grup/Kloter baru',
        'en': 'New Group/Flight',
        'jv': 'Grup/Kloter enggal',
        'su': 'Grup/Kloter anyar',
    },
    'room.managePilgrims': {
        'id': 'Kelola Jamaah',
        'en': 'Manage Pilgrims',
        'jv': 'Atur Jamaah',
        'su': 'Atur Jamaah',
    },
    'room.allRoomsList': {
        'id': 'Daftar semua room',
        'en': 'List of all rooms',
        'jv': 'Dhaptar sedanten room',
        'su': 'Daptar sadaya room',
    },
    'room.monitorMap': {
        'id': 'Pantau Map',
        'en': 'Monitor Map',
        'jv': 'Pantau Map',
        'su': 'Pantau Map',
    },
    'room.locationAndPerimeter': {
        'id': 'Lokasi & perimeter',
        'en': 'Location & perimeter',
        'jv': 'Papan dunung & wates',
        'su': 'Lokasi & wates',
    },
    'room.searchActivityOrPilgrim': {
        'id': 'Cari aktivitas, kamar, atau jamaah...',
        'en': 'Search activity, room, or pilgrim...',
        'jv': 'Padosi aktivitas, kamar, utawi jamaah...',
        'su': 'Milarian kagiatan, kamar, atanapi jamaah...',
    },

    # SOS
    'sos.distanceExceeded': {
        'id': '{distance}m melebihi batas aman',
        'en': '{distance}m exceeds safe boundary',
        'jv': '{distance}m nglangkahi wates aman',
        'su': '{distance}m ngaleuwihan wates aman',
    },
    'sos.failedToSend': {
        'id': 'SOS Belum Terkirim',
        'en': 'Failed to Send SOS',
        'jv': 'SOS Dèrèng Kakintun',
        'su': 'SOS Teu Acan Kakintun',
    },
    'sos.completeDialogTitle': {
        'id': 'Selesaikan Darurat SOS?',
        'en': 'Resolve Emergency SOS?',
        'jv': 'Rampungaken Darurat SOS?',
        'su': 'Réngsékeun Darurat SOS?',
    },
    'sos.yesComplete': {
        'id': 'Ya, Selesaikan',
        'en': 'Yes, Resolve',
        'jv': 'Inggih, Rampungaken',
        'su': 'Muhun, Réngsékeun',
    },
    'sos.completed': {
        'id': 'SOS Selesai',
        'en': 'SOS Resolved',
        'jv': 'SOS Sampun Rampung',
        'su': 'SOS Parantos Réngsé',
    },
    'sos.statusNotChanged': {
        'id': 'Status Belum Diubah',
        'en': 'Status Not Changed',
        'jv': 'Status Dèrèng Dipunéwahi',
        'su': 'Status Teu Acan Dirobih',
    },
    'sos.signalDisabled': {
        'id': 'Sinyal SOS Dinonaktifkan',
        'en': 'SOS Signal Disabled',
        'jv': 'Sinyal SOS Dipun-nonaktifaken',
        'su': 'Sinyal SOS Dinonaktifkeun',
    },
    'sos.signalDisableFailed': {
        'id': 'SOS Belum Dinonaktifkan',
        'en': 'Failed to Disable SOS',
        'jv': 'SOS Dèrèng Dipun-nonaktifaken',
        'su': 'SOS Teu Acan Dinonaktifkeun',
    },
    'sos.pilgrimId': {
        'id': 'ID Jamaah',
        'en': 'Pilgrim ID',
        'jv': 'ID Jamaah',
        'su': 'ID Jamaah',
    },
    'sos.kloterLabel': {
        'id': 'Kloter',
        'en': 'Flight',
        'jv': 'Kloter',
        'su': 'Kloter',
    },
    'sos.maktabLabel': {
        'id': 'Maktab',
        'en': 'Maktab',
        'jv': 'Maktab',
        'su': 'Maktab',
    },
    'sos.sosTime': {
        'id': 'Waktu SOS',
        'en': 'SOS Time',
        'jv': 'Wekdal SOS',
        'su': 'Waktos SOS',
    },
    'sos.coordinatesCopied': {
        'id': 'Koordinat Disalin',
        'en': 'Coordinates Copied',
        'jv': 'Kordinat Katurun',
        'su': 'Koordinat Kasalin',
    },
    'sos.contactUnavailable': {
        'id': 'Kontak Tidak Tersedia',
        'en': 'Contact Unavailable',
        'jv': 'Kontak Mboten Sumadya',
        'su': 'Kontak Teu Sayaga',
    },
    'sos.callFailed': {
        'id': 'Gagal Melakukan Panggilan',
        'en': 'Call Failed',
        'jv': 'Gagal Nimbali',
        'su': 'Gagal Nélépon',
    },
    'sos.rescan': {
        'id': 'Pindai Ulang',
        'en': 'Rescan',
        'jv': 'Pindai Malih',
        'su': 'Parios Deui',
    },

    # Notification
    'notification.invitationAccepted': {
        'id': 'Undangan Diterima!',
        'en': 'Invitation Accepted!',
        'jv': 'Uleman Dipuntampi!',
        'su': 'Uleman Ditampi!',
    },
    'notification.invitationInvalid': {
        'id': 'Undangan Tidak Berlaku',
        'en': 'Invitation Expired or Invalid',
        'jv': 'Uleman Mboten Lumaku',
        'su': 'Uleman Teu Sah',
    },
    'notification.joinFailed': {
        'id': 'Belum Dapat Bergabung',
        'en': 'Failed to Join',
        'jv': 'Dèrèng Saged Gathuk',
        'su': 'Teu Acan Tiasa Gabung',
    },
    'notification.invitationRejected': {
        'id': 'Undangan Ditolak',
        'en': 'Invitation Declined',
        'jv': 'Uleman Dipuntolak',
        'su': 'Uleman Ditampik',
    },
    'notification.choiceNotSaved': {
        'id': 'Pilihan Belum Disimpan',
        'en': 'Choice Not Saved',
        'jv': 'Pilihan Dèrèng Kasimpen',
        'su': 'Pilihan Teu Acan Kasimpen',
    },
    'notification.faqAndHelp': {
        'id': 'FAQ & Bantuan',
        'en': 'FAQ & Help',
        'jv': 'FAQ & Pitulungan',
        'su': 'FAQ & Bantosan',
    },
    'notification.heatwaveAdvisory': {
        'id': 'Himbauan Gelombang Panas Makkah',
        'en': 'Makkah Heatwave Advisory',
        'jv': 'Pèngetan Panas Makkah',
        'su': 'Pépéling Panas Makkah',
    },
    'notification.busScheduleInfo': {
        'id': 'Jadwal Bus Shalawat Rute Syisyah',
        'en': 'Shalawat Bus Schedule - Syisyah Route',
        'jv': 'Jadwal Bis Shalawat Rute Syisyah',
        'su': 'Jadwal Beus Shalawat Rute Syisyah',
    },
    'notification.additionalManasikInfo': {
        'id': 'Materi Manasik Tambahan Siap Dibaca',
        'en': 'Additional Manasik Materials Ready to Read',
        'jv': 'Materi Manasik Tambahan Sumadya Kawaos',
        'su': 'Matéri Manasik Tambahan Sayaga Diaos',
    },
    'notification.mapOpenFailed': {
        'id': 'Peta Belum Dapat Dibuka',
        'en': 'Failed to Open Map',
        'jv': 'Peta Dèrèng Saged Dipunbikak',
        'su': 'Peta Teu Acan Tiasa Dibuka',
    },
    'notification.recipientNotSelected': {
        'id': 'Penerima Belum Dipilih',
        'en': 'Recipient Not Selected',
        'jv': 'Panampi Dèrèng Dipunpilih',
        'su': 'Panampi Teu Acan Dipilih',
    },
    'notification.pleaseRelogin': {
        'id': 'Silakan Masuk Kembali',
        'en': 'Please Sign In Again',
        'jv': 'Kersaa Mlebet Malih',
        'su': 'Mangga Lebet Deui',
    },
    'notification.messageSent': {
        'id': 'Pesan Terkirim',
        'en': 'Message Sent',
        'jv': 'Pesen Kakintun',
        'su': 'Pesen Kakintun',
    },
    'notification.messageSendFailed': {
        'id': 'Pesan Belum Terkirim',
        'en': 'Failed to Send Message',
        'jv': 'Pesen Dèrèng Kakintun',
        'su': 'Pesen Teu Acan Kakintun',
    },
    'notification.selectRecipient': {
        'id': 'Pilih Penerima',
        'en': 'Select Recipient',
        'jv': 'Pilih Panampi',
        'su': 'Pilih Panampi',
    },
    'notification.messageCategory': {
        'id': 'Kategori Pesan',
        'en': 'Message Category',
        'jv': 'Kategori Pesen',
        'su': 'Kategori Pesen',
    },
    'notification.writeMessage': {
        'id': 'Tulis Pesan',
        'en': 'Write Message',
        'jv': 'Serat Pesen',
        'su': 'Serat Pesen',
    },
    'notification.sampleTitle': {
        'id': 'Misalnya: Waktu Berkumpul',
        'en': 'E.g.: Gathering Time',
        'jv': 'Tuladha: Wekdal Makempal',
        'su': 'Conto: Waktos Ngariung',
    },
    'notification.selectTargetMaktab': {
        'id': 'Pilih maktab tujuan *',
        'en': 'Select target maktab *',
        'jv': 'Pilih maktab jujugan *',
        'su': 'Pilih maktab tujuan *',
    },
    'notification.selectTargetKloter': {
        'id': 'Pilih kloter tujuan *',
        'en': 'Select target flight *',
        'jv': 'Pilih kloter jujugan *',
        'su': 'Pilih kloter jujugan *',
    },
    'notification.change': {
        'id': 'Ganti',
        'en': 'Change',
        'jv': 'Gantos',
        'su': 'Ganti',
    },

    # Prayer
    'prayer.phoneGpsInactive': {
        'id': 'Lokasi Ponsel Belum Aktif',
        'en': 'Phone Location Not Active',
        'jv': 'Papan Dunung Ponsel Dèrèng Aktif',
        'su': 'Lokasi HP Teu Acan Aktif',
    },
    'prayer.locationPermissionRequired': {
        'id': 'Izin Lokasi Diperlukan',
        'en': 'Location Permission Required',
        'jv': 'Idin Papan Dunung Dibetahaken',
        'su': 'Idin Lokasi Peryogi',
    },
    'prayer.locationNotFound': {
        'id': 'Lokasi Belum Ditemukan',
        'en': 'Location Not Found',
        'jv': 'Papan Dunung Dèrèng Pinanggih',
        'su': 'Lokasi Teu Acan Kapendak',
    },

    # Money
    'money.captureRiyal': {
        'id': 'Ambil Foto Uang Riyal',
        'en': 'Capture Saudi Riyal Photo',
        'jv': 'Pundhut Foto Arta Riyal',
        'su': 'Candak Poto Artos Riyal',
    },

    # Sign Language
    'sign.listen': {
        'id': 'Dengarkan',
        'en': 'Listen',
        'jv': 'Mirengaken',
        'su': 'Ngupingkeun',
    },
    'sign.delete': {
        'id': 'HAPUS',
        'en': 'DELETE',
        'jv': 'BUSEK',
        'su': 'HAPUS',
    },
    'sign.reset': {
        'id': 'RESET',
        'en': 'RESET',
        'jv': 'WANGSULAKEN',
        'su': 'BALIKEUN',
    },
    'sign.space': {
        'id': 'SPASI',
        'en': 'SPACE',
        'jv': 'SPASI',
        'su': 'SPASI',
    },
    'sign.allowCamera': {
        'id': 'Izinkan kamera',
        'en': 'Allow camera',
        'jv': 'Keparengaken kodhak',
        'su': 'Widian kaméra',
    },

    # Smartband
    'smartband.fireAlert': {
        'id': 'Peringatan Api',
        'en': 'Fire Alert',
        'jv': 'Pèngetan Geni',
        'su': 'Pépéling Seuneu',
    },
    'smartband.bluetoothInactive': {
        'id': 'Bluetooth Tidak Aktif',
        'en': 'Bluetooth Inactive',
        'jv': 'Bluetooth Mboten Aktif',
        'su': 'Bluetooth Teu Aktif',
    },
    'smartband.bandNotConnected': {
        'id': 'Gelang Belum Terhubung',
        'en': 'Smartband Not Connected',
        'jv': 'Gelang Dèrèng Sambung',
        'su': 'Gelang Teu Acan Nyambung',
    },
    'smartband.hajjSmartband': {
        'id': 'Gelang Pintar Haji',
        'en': 'Hajj Smartband',
        'jv': 'Gelang Pinter Kaji',
        'su': 'Gelang Pinter Haji',
    },
    'smartband.blePrototype': {
        'id': 'Prototype BLE – Sensor LDR & Flame',
        'en': 'BLE Prototype – LDR & Flame Sensor',
        'jv': 'Prototipe BLE – Sensor LDR & Flame',
        'su': 'Prototipe BLE – Sénsor LDR & Flame',
    },

    # Translator
    'translator.lostPhrase': {
        'id': 'Tersesat',
        'en': 'Lost',
        'jv': 'Kesesat',
        'su': 'Kasasab',
    },
    'translator.exitPhrase': {
        'id': 'Pintu Keluar',
        'en': 'Exit Gate',
        'jv': 'Kori Miyos',
        'su': 'Panto Kaluar',
    },
    'translator.medicalPhrase': {
        'id': 'Medis / Dokter',
        'en': 'Medical / Doctor',
        'jv': 'Medis / Dhokter',
        'su': 'Médis / Dokter',
    },
    'translator.toiletPhrase': {
        'id': 'Toilet / Wudhu',
        'en': 'Restroom / Wudhu',
        'jv': 'Toilet / Papan Wudhu',
        'su': 'Toilet / Tempat Wudhu',
    },
    'translator.zamzamPhrase': {
        'id': 'Air Zamzam',
        'en': 'Zamzam Water',
        'jv': 'Toya Zamzam',
        'su': 'Cai Zamzam',
    },
    'translator.pricePhrase': {
        'id': 'Tanya Harga',
        'en': 'Ask Price',
        'jv': 'Nyuwun Pirsa Regi',
        'su': 'Naroskeun Pangaos',
    },
    'translator.taxiPhrase': {
        'id': 'Taksi ke Hotel',
        'en': 'Taxi to Hotel',
        'jv': 'Taksi dhateng Hotèl',
        'su': 'Taksi ka Hotél',
    },
    'translator.copiedReady': {
        'id': 'Teks terjemahan sudah disalin dan siap ditempel.',
        'en': 'Translated text copied and ready to paste.',
        'jv': 'Seratan jarwan sampun katurun lan sumadya dipuntèmpèl.',
        'su': 'Téks tarjamahan parantos kasalin sareng sayaga ditèmpèl.',
    },
    'translator.typeOrMicPrompt': {
        'id': 'Ketik teks atau gunakan tombol mikrofon',
        'en': 'Type text or use microphone button',
        'jv': 'Ketik seratan utawi ginakaken tombol mikrofon',
        'su': 'Ketik téks atanapi anggo tombol mikrofon',
    },

    # Help Center
    'help.showAllHelp': {
        'id': 'Tampilkan semua bantuan',
        'en': 'Show all help',
        'jv': 'Tingalaken sedanten pitulungan',
        'su': 'Tingalkeun sadaya bantosan',
    },
    'help.all': {
        'id': 'Semua',
        'en': 'All',
        'jv': 'Sedanten',
        'su': 'Sadaya',
    },
    'help.emailCopied': {
        'id': 'Alamat Email Disalin',
        'en': 'Email Address Copied',
        'jv': 'Alamat Email Katurun',
        'su': 'Alamat Surélék Kasalin',
    },
    'help.contactUnavailable': {
        'id': 'Kontak Belum Tersedia',
        'en': 'Contact Not Available',
        'jv': 'Kontak Dèrèng Sumadya',
        'su': 'Kontak Teu Acan Sayaga',
    },
    'help.waCopied': {
        'id': 'Nomor WhatsApp Disalin',
        'en': 'WhatsApp Number Copied',
        'jv': 'Nomer WhatsApp Katurun',
        'su': 'Nomer WhatsApp Kasalin',
    },
}

def extract_map(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    pattern = re.compile(r"'([a-zA-Z0-9_.]+)':\s*'((?:\\'|[^'])*)'")
    result = {}
    for match in pattern.finditer(content):
        k, v = match.group(1), match.group(2)
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

    for k, trans in REMAINING_KEYS.items():
        id_map[k] = trans['id']
        en_map[k] = trans['en']
        jv_map[k] = trans['jv']
        su_map[k] = trans['su']

    all_keys = set(id_map.keys()) | set(en_map.keys()) | set(jv_map.keys()) | set(su_map.keys())
    for k in all_keys:
        if k not in id_map: id_map[k] = en_map.get(k, k)
        if k not in en_map: en_map[k] = id_map.get(k, k)
        if k not in jv_map: jv_map[k] = id_map.get(k, k)
        if k not in su_map: su_map[k] = id_map.get(k, k)

    write_locale_file('lib/core/locales/id.dart', 'idTranslations', id_map)
    write_locale_file('lib/core/locales/en.dart', 'enTranslations', en_map)
    write_locale_file('lib/core/locales/jv.dart', 'jvTranslations', jv_map)
    write_locale_file('lib/core/locales/su.dart', 'suTranslations', su_map)
    print("Catalog updated successfully!")

if __name__ == '__main__':
    main()
