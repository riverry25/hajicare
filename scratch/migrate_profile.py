import re

def migrate_profile_screen():
    p = 'lib/features/profile/screens/profile_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    # Settings groups
    c = c.replace(
        """                child: _SettingsGroup(
                  title: context.tr('accountData').isEmpty
                      ? 'Data Jamaah & Rombongan'
                      : context.tr('accountData'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.medical_information_rounded,
                      label: context.tr('medicalData').isEmpty
                          ? 'Data Medis & Riwayat'
                          : context.tr('medicalData'),
                      trailingLabel: 'Lihat',
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showMedicalDataSheet(context, state),
                    ),
                    _DividerThin(),
                    _SettingsTile(
                      icon: Icons.groups_rounded,
                      label: context.tr('manageCompanion').isEmpty
                          ? 'Kontak Pendamping & Room'
                          : context.tr('manageCompanion'),
                      trailingLabel: state?.activeRoom.value?.name ?? 'Aktif',
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showCompanionInfoSheet(context, state),
                    ),
                  ],
                ),""",
        """                child: _SettingsGroup(
                  title: context.tr('profile.groupAccountData'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.medical_information_rounded,
                      label: context.tr('profile.medicalData'),
                      trailingLabel: context.tr('profile.view'),
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showMedicalDataSheet(context, state),
                    ),
                    _DividerThin(),
                    _SettingsTile(
                      icon: Icons.groups_rounded,
                      label: context.tr('profile.manageCompanion'),
                      trailingLabel: state?.activeRoom.value?.name ?? context.tr('profile.active'),
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showCompanionInfoSheet(context, state),
                    ),
                  ],
                ),"""
    )

    c = c.replace(
        """                child: _SettingsGroup(
                  title: context.tr('accessibilitySettings').isEmpty
                      ? 'Aksesibilitas'
                      : context.tr('accessibilitySettings'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.text_fields_rounded,
                      label: context.tr('textSize').isEmpty
                          ? 'Ukuran Teks'
                          : context.tr('textSize'),
                      trailingLabel: settings.currentTextScale.label,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showTextSizePicker(context, settings),
                    ),
                  ],
                ),""",
        """                child: _SettingsGroup(
                  title: context.tr('profile.accessibility'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.text_fields_rounded,
                      label: context.tr('profile.textSize'),
                      trailingLabel: settings.currentTextScale.label,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showTextSizePicker(context, settings),
                    ),
                  ],
                ),"""
    )

    c = c.replace(
        """                child: _SettingsGroup(
                  title: context.tr('preferenceSettings').isEmpty
                      ? 'Preferensi & Tampilan'
                      : context.tr('preferenceSettings'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      label: context.tr('language').isEmpty
                          ? 'Bahasa Aplikasi'
                          : context.tr('language'),
                      trailingLabel: settings.localeName,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showLanguagePicker(context, settings),
                    ),
                    _DividerThin(),
                    _SettingsTile(
                      icon: Icons.brightness_6_rounded,
                      label: context.tr('theme').isEmpty
                          ? 'Tema Tampilan'
                          : context.tr('theme'),
                      trailingLabel: settings.themeModeName,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showThemePicker(context, settings),
                    ),
                  ],
                ),""",
        """                child: _SettingsGroup(
                  title: context.tr('profile.preferencesAndDisplay'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      label: context.tr('profile.language'),
                      trailingLabel: settings.localeName,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showLanguagePicker(context, settings),
                    ),
                    _DividerThin(),
                    _SettingsTile(
                      icon: Icons.brightness_6_rounded,
                      label: context.tr('profile.theme'),
                      trailingLabel: settings.themeModeName,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showThemePicker(context, settings),
                    ),
                  ],
                ),"""
    )

    c = c.replace(
        """                child: _SettingsGroup(
                  title: context.tr('otherSettings').isEmpty
                      ? 'Bantuan & Informasi'
                      : context.tr('otherSettings'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      label: context.tr('helpCenter').isEmpty
                          ? 'Pusat Bantuan & FAQ'
                          : context.tr('helpCenter'),
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => Get.toNamed(AppRoutes.helpCenter),
                    ),
                    _DividerThin(),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: context.tr('aboutApp').isEmpty
                          ? 'Tentang HajiCare'
                          : context.tr('aboutApp'),
                      trailingLabel: AppConstants.appVersion,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => Get.toNamed(AppRoutes.about),
                    ),
                  ],
                ),""",
        """                child: _SettingsGroup(
                  title: context.tr('profile.helpAndInfo'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      label: context.tr('profile.helpCenter'),
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => Get.toNamed(AppRoutes.helpCenter),
                    ),
                    _DividerThin(),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: context.tr('profile.aboutApp'),
                      trailingLabel: AppConstants.appVersion,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => Get.toNamed(AppRoutes.about),
                    ),
                  ],
                ),"""
    )

    c = c.replace(
        """                child: _LogoutButton(
                  label: context.tr('logout').isEmpty
                      ? 'Keluar dari Akun'
                      : context.tr('logout'),
                ),""",
        """                child: _LogoutButton(
                  label: context.tr('profile.logout'),
                ),"""
    )

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Migrated profile_screen.dart")

def migrate_profile_components():
    p = 'lib/features/profile/screens/profile_screen_components.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    c = c.replace(
        """    final roleLabel = state?.role == UserRole.pendamping
        ? 'Pendamping'
        : 'Jamaah Haji';""",
        """    final roleLabel = state?.role == UserRole.pendamping
        ? context.tr('auth.rolePendamping')
        : context.tr('auth.roleJamaah');"""
    )

    c = c.replace(
        """: 'Pengguna HajiCare',""",
        """: context.tr('profile.defaultUser'),"""
    )

    c = c.replace(
        """                _HeroBadge(
                  icon: Icons.flag_rounded,
                  label: 'Kloter $kloterStr',
                ),""",
        """                _HeroBadge(
                  icon: Icons.flag_rounded,
                  label: context.tr('profile.kloterNumber', {'kloter': kloterStr}),
                ),"""
    )

    c = c.replace(
        """                _HeroBadge(
                  icon: Icons.hotel_rounded,
                  label: 'Maktab $maktabStr',
                ),""",
        """                _HeroBadge(
                  icon: Icons.hotel_rounded,
                  label: context.tr('profile.maktabNumber', {'maktab': maktabStr}),
                ),"""
    )

    c = c.replace(
        "label: 'Ubah Profil',",
        "label: context.tr('profile.editProfile'),"
    )

    c = c.replace(
        """                Text(
                  'Kartu Jamaah',""",
        """                Text(
                  context.tr('profile.pilgrimCard'),"""
    )

    c = c.replace(
        """                  Text(
                    'Pengguna',""",
        """                  Text(
                    context.tr('profile.user'),"""
    )

    c = c.replace(
        "AppAlertService.showWarning('Nama tidak boleh kosong');",
        "AppAlertService.showWarning(context.tr('profile.nameCannotBeEmpty'));"
    )

    c = c.replace(
        "AppAlertService.showSuccess('Nama Berhasil Diubah');",
        "AppAlertService.showSuccess(context.tr('profile.nameChangedSuccess'));"
    )

    c = c.replace(
        """        AppAlertService.showError(
          'Nama Belum Diubah',
          actionLabel: 'Coba Lagi',
          onAction: _saveName,
        );""",
        """        AppAlertService.showError(
          context.tr('profile.nameChangedError'),
          actionLabel: context.tr('common.tryAgain'),
          onAction: _saveName,
        );"""
    )

    c = c.replace(
        "title: 'Ubah Nama Pengguna',",
        "title: context.tr('profile.editFullName'),"
    )

    c = c.replace(
        "label: 'Nama lengkap Anda',",
        "label: context.tr('profile.yourFullName'),"
    )

    c = c.replace(
        """              _ActionButton(
                label: 'Batal',""",
        """              _ActionButton(
                label: context.tr('common.cancel'),"""
    )

    c = c.replace(
        "badgeText: 'IDENTITAS PENGGUNA',",
        "badgeText: context.tr('profile.userIdentityBadge'),"
    )

    c = c.replace(
        """              _ActionButton(
                label: 'SIMPAN',""",
        """              _ActionButton(
                label: context.tr('common.save'),"""
    )

    c = c.replace(
        """              _ActionButton(
                label: 'Ya, Keluar',""",
        """              _ActionButton(
                label: context.tr('profile.logoutConfirmAction'),"""
    )

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Migrated profile_screen_components.dart")

def migrate_profile_sections():
    p = 'lib/features/profile/screens/profile_screen_sections.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    c = c.replace(
        """                          Text(
                            'Data Medis & Riwayat Jamaah',""",
        """                          Text(
                            context.tr('medical.sheetTitle'),"""
    )

    c = c.replace(
        """                          Text(
                            'Digunakan saat penanganan darurat di Posko PPIH',""",
        """                          Text(
                            context.tr('medical.sheetSubtitle'),"""
    )

    c = c.replace(
        """                        Text(
                          'Data Medis Masih Kosong',""",
        """                        Text(
                          context.tr('medical.emptyTitle'),"""
    )

    c = c.replace(
        """                        Text(
                          'Anda belum mengisi data medis pribadi. Lengkapi golongan darah, riwayat alergi, kondisi khusus, dan kontak darurat untuk kesiapsiagaan.',""",
        """                        Text(
                          context.tr('medical.emptyDesc'),"""
    )

    c = c.replace(
        "label: 'Isi Data Medis Sekarang',",
        "label: context.tr('medical.fillNow'),"
    )

    c = c.replace(
        "label: 'NIK',",
        "label: context.tr('profile.nik'),"
    )

    c = c.replace(
        "label: 'Nomor Porsi',",
        "label: context.tr('profile.portionNumber'),"
    )

    c = c.replace(
        "label: 'Golongan Darah',",
        "label: context.tr('profile.bloodType'),"
    )

    c = c.replace(
        "label: 'Riwayat Alergi',",
        "label: context.tr('profile.allergyHistory'),"
    )

    c = c.replace(
        "label: 'Kondisi Khusus',",
        "label: context.tr('profile.specialConditions'),"
    )

    c = c.replace(
        "label: 'Kontak Darurat',",
        "label: context.tr('profile.emergencyContact'),"
    )

    c = c.replace(
        "label: 'Nomor Paspor',",
        "label: context.tr('profile.passportNumber'),"
    )

    c = c.replace(
        "label: 'Ubah Data',",
        "label: context.tr('common.editData'),"
    )

    c = c.replace(
        "label: 'Tutup',",
        "label: context.tr('common.close'),"
    )

    c = c.replace(
        """                          Text(
                            'Pendamping & Room Aktif',""",
        """                          Text(
                            context.tr('profile.companionAndActiveRoom'),"""
    )

    c = c.replace(
        """                          Text(
                            hasRoom
                                ? 'Terhubung ke pengawasan rombongan Anda'
                                : 'Anda belum terhubung ke room rombongan manapun',""",
        """                          Text(
                            hasRoom
                                ? context.tr('profile.connectedToMonitoring')
                                : context.tr('profile.notConnectedToRoom'),"""
    )

    c = c.replace(
        """                        Text(
                          'Belum Ada Room Terhubung',""",
        """                        Text(
                          context.tr('profile.noRoomConnected'),"""
    )

    c = c.replace(
        "label: 'Gabung Room Sekarang',",
        "label: context.tr('profile.joinRoomNow'),"
    )

    c = c.replace(
        """                  _DetailRow(
                    label: 'Room Pemantauan',""",
        """                  _DetailRow(
                    label: context.tr('profile.trackingRoom'),"""
    )

    c = c.replace(
        """                  _DetailRow(
                    label: 'Kode Room',""",
        """                  _DetailRow(
                    label: context.tr('room.roomCodeLabel'),"""
    )

    c = c.replace(
        """                  _DetailRow(
                    label: 'Ketua Rombongan',""",
        """                  _DetailRow(
                    label: context.tr('profile.leader'),"""
    )

    c = c.replace(
        """                  _DetailRow(
                    label: 'Status Sambungan',
                    value: 'Terkoneksi Realtime',""",
        """                  _DetailRow(
                    label: context.tr('profile.connectionStatus'),
                    value: context.tr('profile.realtimeConnected'),"""
    )

    c = c.replace(
        "label: 'Selesai',",
        "label: context.tr('profile.done'),"
    )

    # Pickers title
    c = c.replace(
        """    final title = context.tr('selectLanguageTitle').isEmpty
        ? 'Pilih Bahasa'
        : context.tr('selectLanguageTitle');""",
        """    final title = context.tr('selectLanguageTitle');"""
    )

    c = c.replace(
        """    final title = context.tr('selectThemeTitle').isEmpty
        ? 'Pilih Tema'
        : context.tr('selectThemeTitle');""",
        """    final title = context.tr('selectThemeTitle');"""
    )

    c = c.replace(
        """    final title = context.tr('selectTextSizeTitle').isEmpty
        ? 'Pilih Ukuran Teks'
        : context.tr('selectTextSizeTitle');""",
        """    final title = context.tr('selectTextSizeTitle');"""
    )

    # Header title
    c = c.replace(
        """            Text(
              context.tr('profileTitle').isEmpty
                  ? 'Profil & Pengaturan'
                  : context.tr('profileTitle'),
              style: AppTypography.headlineMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola akun dan preferensi Hajicare Anda',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextBody : AppColors.textMuted,
              ),
            ),""",
        """            Text(
              context.tr('profileTitle'),
              style: AppTypography.headlineMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('profile.desc'),
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextBody : AppColors.textMuted,
              ),
            ),"""
    )

    # Alert messages
    c = c.replace(
        """        AppAlertService.showWarning(
          'NIK harus berupa 16 digit angka.',
          title: 'Format NIK Tidak Sesuai',
        );""",
        """        AppAlertService.showWarning(
          context.tr('medical.nikInvalidMsg'),
          title: context.tr('medical.nikInvalidTitle'),
        );"""
    )

    c = c.replace(
        """        AppAlertService.showWarning(
          'Nomor Porsi harus berupa 10 digit angka.',
          title: 'Format Nomor Porsi Tidak Sesuai',
        );""",
        """        AppAlertService.showWarning(
          context.tr('medical.porsiInvalidMsg'),
          title: context.tr('medical.porsiInvalidTitle'),
        );"""
    )

    c = c.replace(
        """        AppAlertService.showSuccess(
          'Data jamaah & medis Anda sudah diperbarui.',
          title: 'Data Jamaah Disimpan',
        );""",
        """        AppAlertService.showSuccess(
          context.tr('medical.saveSuccessMsg'),
          title: context.tr('medical.saveSuccessTitle'),
        );"""
    )

    c = c.replace(
        """        AppAlertService.showError(
          'Periksa internet, lalu coba simpan sekali lagi.',
          title: 'Data Belum Disimpan',
          actionLabel: 'Coba Lagi',
          onAction: _saveMedicalData,
        );""",
        """        AppAlertService.showError(
          context.tr('medical.saveErrorMsg'),
          title: context.tr('medical.saveErrorTitle'),
          actionLabel: context.tr('common.tryAgain'),
          onAction: _saveMedicalData,
        );"""
    )

    # Edit medical dialog
    c = c.replace(
        """          title: 'Kelola Data Jamaah & Medis',
          subtitle:
              'Informasi identitas jamaah dan kesehatan pribadi untuk kesiapsiagaan.',""",
        """          title: context.tr('medical.editDialogTitle'),
          subtitle: context.tr('medical.editDialogSubtitle'),"""
    )

    c = c.replace(
        """            _buildField(
              controller: _nikCtrl,
              label: 'Nomor Induk Kependudukan / NIK (Opsional)',
              hint: 'Contoh: 3201234567890001 (16 digit)',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _porsiCtrl,
              label: 'Nomor Porsi Haji (Opsional)',
              hint: 'Contoh: 1001234567 (10 digit)',
              icon: Icons.confirmation_number_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _bloodTypeCtrl,
              label: 'Golongan Darah',
              hint: 'Contoh: O Rhesus (+), A (+), B (+)',
              icon: Icons.bloodtype_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _allergiesCtrl,
              label: 'Riwayat Alergi Obat / Makanan',
              hint: 'Contoh: Alergi penisilin, udang, dsb.',
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _conditionsCtrl,
              label: 'Kondisi Khusus / Riwayat Penyakit',
              hint: 'Contoh: Hipertensi, Diabetes, Asma',
              icon: Icons.medical_services_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _emergencyCtrl,
              label: 'Nomor Kontak Darurat (Keluarga)',
              hint: 'Contoh: 0812-3456-7890 (Anak / Pasangan)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _passportCtrl,
              label: 'Nomor Paspor (Opsional)',
              hint: 'Contoh: A 1234567 / B 9876543',
              icon: Icons.book_outlined,
            ),""",
        """            _buildField(
              controller: _nikCtrl,
              label: context.tr('medical.nikLabel'),
              hint: context.tr('medical.nikHint'),
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _porsiCtrl,
              label: context.tr('medical.porsiLabel'),
              hint: context.tr('medical.porsiHint'),
              icon: Icons.confirmation_number_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _bloodTypeCtrl,
              label: context.tr('medical.bloodTypeLabel'),
              hint: context.tr('medical.bloodTypeHint'),
              icon: Icons.bloodtype_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _allergiesCtrl,
              label: context.tr('medical.allergiesLabel'),
              hint: context.tr('medical.allergiesHint'),
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _conditionsCtrl,
              label: context.tr('medical.conditionsLabel'),
              hint: context.tr('medical.conditionsHint'),
              icon: Icons.medical_services_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _emergencyCtrl,
              label: context.tr('medical.emergencyContactLabel'),
              hint: context.tr('medical.emergencyContactHint'),
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _passportCtrl,
              label: context.tr('medical.passportLabel'),
              hint: context.tr('medical.passportHint'),
              icon: Icons.book_outlined,
            ),"""
    )

    c = c.replace(
        "badgeText: 'DATA KESEHATAN JAMAAH',",
        "badgeText: context.tr('profile.healthDataBadge'),"
    )

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Migrated profile_screen_sections.dart")

def migrate_jamaah_detail_sheet():
    p = 'lib/features/room/widgets/jamaah_detail_sheet.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    # import if needed
    if "import '../../../core/locales/app_localizations.dart';" not in c:
        c = "import '../../../core/locales/app_localizations.dart';\n" + c

    c = c.replace(
        """    final timeStr = diff.inMinutes < 1
        ? 'Baru saja'
        : '${diff.inMinutes} menit lalu';""",
        """    final timeStr = diff.inMinutes < 1
        ? context.tr('room.justNow')
        : context.tr('room.minutesAgo', {'minutes': diff.inMinutes});"""
    )

    c = c.replace(
        """        title: 'Keluarkan Jamaah?',
        content:
            'Apakah Anda yakin ingin mengeluarkan $displayName dari room ini?',
        confirmText: 'Keluarkan',
        cancelText: 'Batal',""",
        """        title: context.tr('room.removeConfirmTitle'),
        content: context.tr('room.removeConfirmMsg', {'name': displayName}),
        confirmText: context.tr('room.removeAction'),
        cancelText: context.tr('common.cancel'),"""
    )

    c = c.replace(
        "AppAlertService.showSuccess('Jamaah Dikeluarkan');",
        "AppAlertService.showSuccess(context.tr('room.memberRemoved'));"
    )

    c = c.replace(
        "AppAlertService.showError('Belum Dapat Dikeluarkan');",
        "AppAlertService.showError(context.tr('room.memberRemoveFailed'));"
    )

    c = c.replace(
        """                            Text(
                              role == 'admin'
                                  ? 'Admin'
                                  : role == 'pendamping'
                                  ? 'Pendamping'
                                  : 'Jamaah',""",
        """                            Text(
                              role == 'admin'
                                  ? context.tr('auth.roleAdmin')
                                  : role == 'pendamping'
                                  ? context.tr('auth.rolePendamping')
                                  : context.tr('auth.roleJamaah'),"""
    )

    c = c.replace(
        """                                  Text(
                                    'SOS DARURAT',""",
        """                                  Text(
                                    context.tr('sos.emergency'),"""
    )

    c = c.replace(
        """                                Text(
                                  'Jarak ke Pendamping',""",
        """                                Text(
                                  context.tr('room.distanceToCompanion'),"""
    )

    c = c.replace(
        """                                    Text(
                                      isSafe ? 'statusSafe' : 'GPS Mati',""",
        """                                    Text(
                                      isSafe ? context.tr('common.statusSafe') : context.tr('room.gpsInactive'),"""
    )

    c = c.replace(
        """                              statusText: sensorActive
                                  ? 'Sensor Aktif'
                                  : 'Sensor Mati',""",
        """                              statusText: sensorActive
                                  ? context.tr('room.gpsActive')
                                  : context.tr('room.gpsInactive'),"""
    )

    c = c.replace(
        "label: 'Kirim Notifikasi Langsung',",
        "label: context.tr('room.sendPrivateNotification'),"
    )

    c = c.replace(
        "label: 'Keluarkan dari Room',",
        "label: context.tr('room.removeFromRoom'),"
    )

    c = c.replace(
        """                        Text(
                          'Data Medis & Dokumen',""",
        """                        Text(
                          context.tr('room.medicalDataAndDocs'),"""
    )

    c = c.replace(
        """                        Text(
                          'Hanya Lihat',""",
        """                        Text(
                          context.tr('common.viewOnly'),"""
    )

    c = c.replace(
        """                  _MedicalItemTile(
                    label: 'NIK',
                    value: finalNik,
                  ),
                  _MedicalItemTile(
                    label: 'Nomor Porsi',
                    value: finalPorsi,
                  ),
                  _MedicalItemTile(
                    label: 'Nomor Paspor',
                    value: passport,
                  ),
                  _MedicalItemTile(
                    label: 'Golongan Darah',
                    value: bloodType,
                  ),
                  _MedicalItemTile(
                    label: 'Riwayat Alergi',
                    value: allergies,
                  ),
                  _MedicalItemTile(
                    label: 'Kondisi Khusus',
                    value: conditions,
                  ),
                  _MedicalItemTile(
                    label: 'Kontak Darurat',
                    value: emergencyContact,
                  ),""",
        """                  _MedicalItemTile(
                    label: context.tr('profile.nik'),
                    value: finalNik,
                  ),
                  _MedicalItemTile(
                    label: context.tr('profile.portionNumber'),
                    value: finalPorsi,
                  ),
                  _MedicalItemTile(
                    label: context.tr('profile.passportNumber'),
                    value: passport,
                  ),
                  _MedicalItemTile(
                    label: context.tr('profile.bloodType'),
                    value: bloodType,
                  ),
                  _MedicalItemTile(
                    label: context.tr('profile.allergyHistory'),
                    value: allergies,
                  ),
                  _MedicalItemTile(
                    label: context.tr('profile.specialConditions'),
                    value: conditions,
                  ),
                  _MedicalItemTile(
                    label: context.tr('profile.emergencyContact'),
                    value: emergencyContact,
                  ),"""
    )

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Migrated jamaah_detail_sheet.dart")

if __name__ == '__main__':
    migrate_profile_screen()
    migrate_profile_components()
    migrate_profile_sections()
    migrate_jamaah_detail_sheet()
