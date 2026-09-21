part of 'profile_screen.dart';

extension _ProfileScreenSections on ProfileScreen {
  void _showMedicalDataSheet(BuildContext context, HajiCareController? state) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.cardBgColor(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;
    final profileCtrl = Get.find<ProfileController>();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Obx(() {
        final hasData = profileCtrl.hasMedicalData;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorderColor(context),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.sosEmergency.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medical_information_rounded,
                        color: AppColors.sosEmergency,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Medis & Riwayat Jamaah',
                            style: AppTypography.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Digunakan saat penanganan darurat di Posko PPIH',
                            style: AppTypography.captionSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextBody
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (!hasData) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.cardBorderColor(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          size: 44,
                          color: bodyColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Data Medis Masih Kosong',
                          style: AppTypography.titleSmall.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Anda belum mengisi data medis pribadi. Lengkapi golongan darah, riwayat alergi, kondisi khusus, dan kontak darurat untuk kesiapsiagaan.',
                          textAlign: TextAlign.center,
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditMedicalDialog(context, profileCtrl);
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text(
                        'Isi Data Medis Sekarang',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.cardBorderColor(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildMedRow(
                          context,
                          'Golongan Darah',
                          profileCtrl.bloodType.value.isNotEmpty
                              ? profileCtrl.bloodType.value
                              : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          'Riwayat Alergi',
                          profileCtrl.allergies.value.isNotEmpty
                              ? profileCtrl.allergies.value
                              : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          'Kondisi Khusus',
                          profileCtrl.conditions.value.isNotEmpty
                              ? profileCtrl.conditions.value
                              : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          'Kontak Darurat',
                          profileCtrl.emergencyContact.value.isNotEmpty
                              ? profileCtrl.emergencyContact.value
                              : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          'Nomor Paspor',
                          profileCtrl.passportNumber.value.isNotEmpty
                              ? profileCtrl.passportNumber.value
                              : '-',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showEditMedicalDialog(context, profileCtrl);
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text(
                            'Ubah Data',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkPrimaryContainer
                                : AppColors.espressoDark,
                            foregroundColor: isDark
                                ? AppColors.goldLight
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showEditMedicalDialog(
    BuildContext context,
    ProfileController profileCtrl,
  ) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogCtx) => _EditMedicalDialog(
        profileCtrl: profileCtrl,
        isDark: AppColors.isDark(context),
      ),
    );
  }

  Widget _buildMedRow(BuildContext context, String label, String value) {
    final isDark = AppColors.isDark(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextBody : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextHeading
                  : AppColors.espressoDark,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _showCompanionInfoSheet(
    BuildContext context,
    HajiCareController? state,
  ) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.cardBgColor(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    final hasRoom =
        state?.activeRoomId.value != null &&
        state!.activeRoomId.value!.trim().isNotEmpty;
    final roomName = hasRoom
        ? (state.activeRoom.value?.name ?? 'Room Pemantauan')
        : '-';
    final roomCode = hasRoom ? (state.activeRoom.value?.code ?? '-') : '-';
    final pendamping = hasRoom
        ? (state.pendampingName.value.isNotEmpty
              ? state.pendampingName.value
              : 'Pendamping Room')
        : '-';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorderColor(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.goldPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pendamping & Room Aktif',
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasRoom
                              ? 'Terhubung ke pengawasan rombongan Anda'
                              : 'Anda belum terhubung ke room rombongan manapun',
                          style: AppTypography.captionSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextBody
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (!hasRoom) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.cardBorderColor(context),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.meeting_room_outlined,
                        size: 48,
                        color: bodyColor.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum Ada Room Terhubung',
                        style: AppTypography.titleSmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Anda belum bergabung dengan rombongan. Masukkan kode dari pendamping agar lokasi Anda dapat dipantau.',
                        textAlign: TextAlign.center,
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isDark
                          ? AppColors.espressoDark
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.toNamed(AppRoutes.joinRoom);
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text(
                      'Gabung Room Sekarang',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.cardBorderColor(context),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildMedRow(context, 'Room Pemantauan', roomName),
                      const Divider(height: 16),
                      _buildMedRow(context, 'Kode Room', roomCode),
                      const Divider(height: 16),
                      _buildMedRow(context, 'Ketua Rombongan', pendamping),
                      const Divider(height: 16),
                      _buildMedRow(
                        context,
                        'Status Sambungan',
                        'Terkoneksi Realtime',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.espressoDark,
                      foregroundColor: isDark
                          ? AppColors.goldLight
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    AppSettingsController settings,
  ) {
    final options = [
      (const Locale('id'), 'Bahasa Indonesia', '🇮🇩'),
      (const Locale('jv'), 'Basa Jawi', '🏝️'),
      (const Locale('su'), 'Basa Sunda', '🌿'),
      (const Locale('en'), 'English', '🌐'),
    ];
    _showPickerSheet(
      context: context,
      title: context.tr('selectLanguageTitle').isEmpty
          ? 'Pilih Bahasa'
          : context.tr('selectLanguageTitle'),
      children: options.map((opt) {
        final isSelected =
            settings.currentLocale.languageCode == opt.$1.languageCode;
        return _PickerOption(
          label: '${opt.$3}  ${opt.$2}',
          isSelected: isSelected,
          onTap: () {
            settings.setLocale(opt.$1);
            Get.back();
          },
        );
      }).toList(),
    );
  }

  void _showThemePicker(BuildContext context, AppSettingsController settings) {
    final options = [
      (
        ThemeMode.system,
        context.tr('themeSystem').isEmpty
            ? 'Ikuti Sistem'
            : context.tr('themeSystem'),
        Icons.brightness_auto_rounded,
      ),
      (
        ThemeMode.light,
        context.tr('themeLight').isEmpty
            ? 'Mode Terang'
            : context.tr('themeLight'),
        Icons.light_mode_rounded,
      ),
      (
        ThemeMode.dark,
        context.tr('themeDark').isEmpty
            ? 'Mode Gelap'
            : context.tr('themeDark'),
        Icons.dark_mode_rounded,
      ),
    ];
    _showPickerSheet(
      context: context,
      title: context.tr('selectThemeTitle').isEmpty
          ? 'Pilih Tema'
          : context.tr('selectThemeTitle'),
      children: options.map((opt) {
        final isSelected = settings.currentThemeMode == opt.$1;
        return _PickerOption(
          icon: opt.$3,
          label: opt.$2,
          isSelected: isSelected,
          onTap: () {
            settings.setThemeMode(opt.$1);
            Get.back();
          },
        );
      }).toList(),
    );
  }

  void _showTextSizePicker(
    BuildContext context,
    AppSettingsController settings,
  ) {
    _showPickerSheet(
      context: context,
      title: context.tr('selectTextSizeTitle').isEmpty
          ? 'Pilih Ukuran Teks'
          : context.tr('selectTextSizeTitle'),
      children: AppTextScale.values.map((scale) {
        final isSelected = settings.currentTextScale == scale;
        return _PickerOption(
          label: scale.label,
          trailingHint: '${(scale.factor * 100).toStringAsFixed(0)}%',
          isSelected: isSelected,
          onTap: () {
            settings.setTextScale(scale);
            Get.back();
          },
        );
      }).toList(),
    );
  }

  void _showPickerSheet({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.cardBgColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorderColor(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textHeadingColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // ── Custom Page Header: title+subtitle left, Hajicare logo right ───────────
  Widget _buildPageHeader(
    BuildContext context,
    Color headingColor,
    bool isDark,
  ) {
    final bodyColor = AppColors.textBodyColor(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.tr('profileTitle').isEmpty
                ? 'Profil & Pengaturan'
                : context.tr('profileTitle'),
            style: AppTypography.headlineMd.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola akun dan preferensi Hajicare Anda',
            style: TextStyle(
              color: bodyColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EditMedicalDialog extends StatefulWidget {
  final ProfileController profileCtrl;
  final bool isDark;

  const _EditMedicalDialog({required this.profileCtrl, required this.isDark});

  @override
  State<_EditMedicalDialog> createState() => _EditMedicalDialogState();
}

class _EditMedicalDialogState extends State<_EditMedicalDialog> {
  late final TextEditingController _bloodTypeCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _conditionsCtrl;
  late final TextEditingController _emergencyContactCtrl;
  late final TextEditingController _passportNumberCtrl;

  @override
  void initState() {
    super.initState();
    _bloodTypeCtrl = TextEditingController(
      text: widget.profileCtrl.bloodType.value,
    );
    _allergiesCtrl = TextEditingController(
      text: widget.profileCtrl.allergies.value,
    );
    _conditionsCtrl = TextEditingController(
      text: widget.profileCtrl.conditions.value,
    );
    _emergencyContactCtrl = TextEditingController(
      text: widget.profileCtrl.emergencyContact.value,
    );
    _passportNumberCtrl = TextEditingController(
      text: widget.profileCtrl.passportNumber.value,
    );
  }

  @override
  void dispose() {
    _bloodTypeCtrl.dispose();
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _emergencyContactCtrl.dispose();
    _passportNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.profileCtrl.isSavingMedical.value) return;
    try {
      await widget.profileCtrl.updateMedicalData(
        bloodTypeVal: _bloodTypeCtrl.text.trim(),
        allergiesVal: _allergiesCtrl.text.trim(),
        conditionsVal: _conditionsCtrl.text.trim(),
        emergencyContactVal: _emergencyContactCtrl.text.trim(),
        passportNumberVal: _passportNumberCtrl.text.trim(),
      );
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      final rootCtx = Get.context;
      if (rootCtx != null && rootCtx.mounted) {
        AppAlert.success(
          rootCtx,
          title: 'Data Medis Disimpan',
          message: 'Data medis Anda sudah diperbarui.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppAlert.error(
          context,
          title: 'Data Belum Disimpan',
          message: 'Periksa internet, lalu coba simpan sekali lagi.',
          okText: 'Coba Lagi',
        );
      }
    }
  }

  Widget _buildUnderlineField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController ctrl,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    final isDark = widget.isDark;
    final headingColor = AppColors.textHeadingColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: headingColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: TextStyle(
            color: headingColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : const Color(0xFF9E8E81),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    size: 17,
                    color: isDark
                        ? AppColors.goldLight.withValues(alpha: 0.7)
                        : AppColors.espressoDark.withValues(alpha: 0.6),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 26,
              minHeight: 26,
            ),
            filled: false,
            contentPadding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkOutlineVariant
                    : const Color(0xFFD4C7BC),
                width: 1.2,
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkOutlineVariant
                    : const Color(0xFFD4C7BC),
                width: 1.2,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = AppColors.cardBgColor(context);
    final headingColor = AppColors.textHeadingColor(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 620),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ── 1. Main Card Body ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(
                top: 28,
                bottom: 12,
                right: 10,
                left: 10,
              ),
              padding: const EdgeInsets.fromLTRB(20, 68, 20, 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.goldLight.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.09),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Kelola Data Medis',
                      style: AppTypography.titleMedium.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 17.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      'Informasi kesehatan pribadi Jamaah untuk pertolongan pertama darurat.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textBodyColor(
                          context,
                        ).withValues(alpha: 0.85),
                        height: 1.35,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Field 1: Golongan Darah
                    _buildUnderlineField(
                      context: context,
                      label: 'Golongan Darah',
                      hint: 'Contoh: O Rhesus (+), A (+), B (+)',
                      ctrl: _bloodTypeCtrl,
                      icon: Icons.bloodtype_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Field 2: Riwayat Alergi
                    _buildUnderlineField(
                      context: context,
                      label: 'Riwayat Alergi Obat / Makanan',
                      hint: 'Contoh: Alergi penisilin, udang, dsb.',
                      ctrl: _allergiesCtrl,
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Field 3: Kondisi Khusus
                    _buildUnderlineField(
                      context: context,
                      label: 'Kondisi Khusus / Riwayat Penyakit',
                      hint: 'Contoh: Hipertensi, Diabetes, Asma',
                      ctrl: _conditionsCtrl,
                      icon: Icons.healing_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Field 4: Kontak Darurat
                    _buildUnderlineField(
                      context: context,
                      label: 'Nomor Kontak Darurat (Keluarga)',
                      hint: 'Contoh: 0812-3456-7890 (Anak / Pasangan)',
                      ctrl: _emergencyContactCtrl,
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone_in_talk_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Field 5: Nomor Paspor (Opsional)
                    _buildUnderlineField(
                      context: context,
                      label: 'Nomor Paspor (Opsional)',
                      hint: 'Contoh: A 1234567 / B 9876543',
                      ctrl: _passportNumberCtrl,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Bottom Row: Cancel button on left, space reserved for protruding button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.white60
                                : const Color(0xFF8C7A6B),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            context.tr('cancel').isEmpty
                                ? 'Batal'
                                : context.tr('cancel'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 135,
                        ), // Spacer for protruding button
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Floating Hero Card (Compact header) ───────────────────
            Positioned(
              top: 0,
              left: 22,
              right: 22,
              height: 86,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF38251A), const Color(0xFF1F140D)]
                        : [AppColors.espressoDark, const Color(0xFF563B2A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Ambient Background Circular Glows
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -15,
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),

                    // Center Hero Graphic
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.goldPrimary.withValues(alpha: 0.25),
                                  AppColors.goldPrimary.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: AppColors.goldPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.medical_services_rounded,
                                color: AppColors.accentGoldStar,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'DATA KESEHATAN JAMAAH',
                            style: TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Protruding Ribbon Submit Button (No shadow) ───────────
            Positioned(
              bottom: 0,
              right: 0,
              child: Obx(() {
                final saving = widget.profileCtrl.isSavingMedical.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ribbon fold triangle at the top-right corner
                    Positioned(
                      top: -10,
                      right: 0,
                      child: CustomPaint(
                        size: const Size(10, 10),
                        painter: _RibbonFoldPainter(
                          color: isDark
                              ? const Color(0xFF140D08)
                              : const Color(0xFF160D07),
                        ),
                      ),
                    ),

                    // Main Pill Submit Button without box shadow
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: saving ? null : _submit,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(5),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkPrimaryContainer
                                : AppColors.espressoDark,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 13.5,
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'SIMPAN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
