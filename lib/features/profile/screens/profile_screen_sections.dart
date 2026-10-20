part of 'profile_screen.dart';

extension _ProfileScreenSections on ProfileScreen {
  void _showMedicalDataSheet(BuildContext context, HajiCareController? state) {
    final colors = context.hc;
    final isDark = context.isDark;
    final cardBg = colors.surface;
    final headingColor = colors.textPrimary;
    final bodyColor = colors.textSecondary;
    final primaryColor = colors.primary;
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
                      color: colors.border,
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
                        color: colors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medical_information_rounded,
                        color: colors.danger,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('medical.sheetTitle'),
                            style: context.text.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('medical.sheetSubtitle'),
                            style: context.text.labelSmall.copyWith(
                              color: colors.textSecondary,
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
                          ? colors.surfaceSubtle
                          : colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: colors.border),
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
                          context.tr('medical.emptyTitle'),
                          style: context.text.titleSmall.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('medical.emptyDesc'),
                          textAlign: TextAlign.center,
                          style: context.text.labelSmall.copyWith(
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
                        foregroundColor: colors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        _showEditMedicalDialog(context, profileCtrl);
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: Text(
                        context.tr('medicalFillDataNow'),
                        style: context.text.labelLarge.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.surfaceSubtle
                          : colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        _buildMedRow(
                          context,
                          context.tr('profile.nik'),
                          profileCtrl.nik.value.isNotEmpty
                              ? profileCtrl.nik.value
                              : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          context.tr('profile.portionNumber'),
                          profileCtrl.nomorPorsi.value.isNotEmpty
                              ? profileCtrl.nomorPorsi.value
                              : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          context.tr('profile.bloodType'),
                          profileCtrl.bloodType.value.isNotEmpty
                              ? profileCtrl.bloodType.value
                              : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          context.tr('medical.allergiesLabel'),
                          profileCtrl.allergies.value.isNotEmpty
                              ? profileCtrl.allergies.value
                              : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          context.tr('profile.specialConditions'),
                          profileCtrl.conditions.value.isNotEmpty
                              ? profileCtrl.conditions.value
                              : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          context.tr('profile.emergencyContact'),
                          profileCtrl.emergencyContact.value.isNotEmpty
                              ? profileCtrl.emergencyContact.value
                              : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          context.tr('profile.passportNumber'),
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
                            _showEditMedicalDialog(context, profileCtrl);
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(
                            context.tr('profile.editData'),
                            style: context.text.labelLarge.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? colors.surfaceSand
                                : colors.primary,
                            foregroundColor: isDark
                                ? colors.accent
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            context.tr('close'),
                            style: context.text.labelLarge.copyWith(
                              color: isDark ? colors.accent : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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
      builder: (dialogCtx) =>
          _EditMedicalDialog(profileCtrl: profileCtrl, isDark: context.isDark),
    );
  }

  Widget _buildMedRow(BuildContext context, String label, String value) {
    final colors = context.hc;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: context.text.bodySmall.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: context.text.bodySmall.copyWith(
              color: colors.textPrimary,
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
    final colors = context.hc;
    final isDark = context.isDark;
    final cardBg = colors.surface;
    final headingColor = colors.textPrimary;
    final bodyColor = colors.textSecondary;
    final primaryColor = colors.primary;

    final hasRoom =
        state?.activeRoomId.value != null &&
        state!.activeRoomId.value!.trim().isNotEmpty;
    final roomName = hasRoom
        ? (state.activeRoom.value?.name ?? context.tr('profileRoomMonitoring'))
        : '-';
    final roomCode = hasRoom ? (state.activeRoom.value?.code ?? '-') : '-';
    final pendamping = hasRoom
        ? (state.pendampingName.value.isNotEmpty
              ? state.pendampingName.value
              : context.tr('profileRoomCompanion'))
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
                    color: colors.border,
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
                      color: colors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: colors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('profileCompanionSheetTitle'),
                          style: context.text.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasRoom
                              ? context.tr('profileConnectedToGroup')
                              : context.tr('profileNotConnectedToGroup'),
                          style: context.text.labelSmall.copyWith(
                            color: colors.textSecondary,
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
                    color: isDark ? colors.surfaceSubtle : colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: colors.border),
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
                        context.tr('profileNoRoomConnectedTitle'),
                        style: context.text.titleSmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('profileNoRoomConnectedDesc'),
                        textAlign: TextAlign.center,
                        style: context.text.labelSmall.copyWith(
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
                      foregroundColor: isDark ? colors.onPrimary : Colors.white,
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
                    label: Text(
                      context.tr('profileJoinRoomNow'),
                      style: context.text.labelLarge.copyWith(
                        color: isDark ? colors.onPrimary : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? colors.surfaceSubtle : colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      _buildMedRow(
                        context,
                        context.tr('profileRoomMonitoring'),
                        roomName,
                      ),
                      const Divider(height: 16),
                      _buildMedRow(
                        context,
                        context.tr('profileRoomCode'),
                        roomCode,
                      ),
                      const Divider(height: 16),
                      _buildMedRow(
                        context,
                        context.tr('profileGroupLeader'),
                        pendamping,
                      ),
                      const Divider(height: 16),
                      _buildMedRow(
                        context,
                        context.tr('profileConnectionStatus'),
                        context.tr('profileRealtimeConnected'),
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
                          ? colors.surfaceSand
                          : colors.primary,
                      foregroundColor: isDark ? colors.accent : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      context.tr('done'),
                      style: context.text.labelLarge.copyWith(
                        color: isDark ? colors.accent : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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
          label: scale.localizedLabel(context),
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
    final colors = context.hc;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: colors.surface,
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
                    color: colors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: context.text.titleLarge.copyWith(
                  color: colors.textPrimary,
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

  // Custom Page Header: title+subtitle left, Hajicare logo right
  Widget _buildPageHeader(
    BuildContext context,
    Color headingColor,
    bool isDark,
  ) {
    final bodyColor = context.hc.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.tr('profileTitle').isEmpty
                ? 'Profil & Pengaturan'
                : context.tr('profileTitle'),
            style: context.text.headlineSmall.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('profileSubtitle'),
            style: context.text.bodySmall.copyWith(
              color: bodyColor,
              fontSize: 12.5,
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
  late final TextEditingController _nikCtrl;
  late final TextEditingController _nomorPorsiCtrl;
  late final TextEditingController _bloodTypeCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _conditionsCtrl;
  late final TextEditingController _emergencyContactCtrl;
  late final TextEditingController _passportNumberCtrl;

  @override
  void initState() {
    super.initState();
    _nikCtrl = TextEditingController(text: widget.profileCtrl.nik.value);
    _nomorPorsiCtrl = TextEditingController(
      text: widget.profileCtrl.nomorPorsi.value,
    );
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
    _nikCtrl.dispose();
    _nomorPorsiCtrl.dispose();
    _bloodTypeCtrl.dispose();
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _emergencyContactCtrl.dispose();
    _passportNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.profileCtrl.isSavingMedical.value) return;

    final nikText = _nikCtrl.text.trim();
    if (nikText.isNotEmpty) {
      if (!RegExp(r'^\d{16}$').hasMatch(nikText)) {
        AppAlert.warning(
          context,
          title: context.tr('medical.nikInvalidTitle'),
          message: context.tr('medical.nikInvalidMsg'),
        );
        return;
      }
    }

    final porsiText = _nomorPorsiCtrl.text.trim();
    if (porsiText.isNotEmpty) {
      if (!RegExp(r'^\d{10}$').hasMatch(porsiText)) {
        AppAlert.warning(
          context,
          title: context.tr('medical.porsiInvalidTitle'),
          message: context.tr('medical.porsiInvalidMsg'),
        );
        return;
      }
    }

    try {
      await widget.profileCtrl.updateMedicalData(
        bloodTypeVal: _bloodTypeCtrl.text.trim(),
        allergiesVal: _allergiesCtrl.text.trim(),
        conditionsVal: _conditionsCtrl.text.trim(),
        emergencyContactVal: _emergencyContactCtrl.text.trim(),
        passportNumberVal: _passportNumberCtrl.text.trim(),
        nikVal: nikText,
        nomorPorsiVal: porsiText,
      );
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      final rootCtx = Get.context;
      if (rootCtx != null && rootCtx.mounted) {
        AppAlert.success(
          rootCtx,
          title: rootCtx.tr('medical.saveSuccessTitle'),
          message: rootCtx.tr('medical.saveSuccessMsg'),
        );
      }
    } catch (_) {
      if (mounted) {
        AppAlert.error(
          context,
          title: context.tr('medical.saveErrorTitle'),
          message: context.tr('medical.saveErrorMsg'),
          okText: context.tr('common.tryAgain'),
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
    final colors = context.hc;
    final isDark = widget.isDark;
    final headingColor = colors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.labelMedium.copyWith(
            color: headingColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: context.text.bodyMedium.copyWith(
            color: headingColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.text.bodySmall.copyWith(
              color: isDark ? Colors.white38 : colors.textTertiary,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    size: 17,
                    color: isDark
                        ? colors.accent.withValues(alpha: 0.7)
                        : colors.primary.withValues(alpha: 0.6),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 26,
              minHeight: 26,
            ),
            filled: false,
            contentPadding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.border, width: 1.2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.border, width: 1.2),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? colors.accent : colors.primary,
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
    final colors = context.hc;
    final isDark = widget.isDark;
    final cardBg = colors.surface;
    final headingColor = colors.textPrimary;

    return HajiTransparentDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: (MediaQuery.sizeOf(context).height * 0.85).clamp(500, 680),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // 1. Main Card Body
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
                      : colors.border,
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
                    Text(
                      context.tr('medicalManageTitle'),
                      style: context.text.titleMedium.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 17.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      context.tr('medicalManageSubtitle'),
                      style: context.text.bodySmall.copyWith(
                        color: colors.textSecondary.withValues(alpha: 0.85),
                        height: 1.35,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Field: NIK
                    _buildUnderlineField(
                      context: context,
                      label: context.tr('medical.nikLabel'),
                      hint: context.tr('medical.nikHint'),
                      ctrl: _nikCtrl,
                      keyboardType: TextInputType.number,
                      icon: Icons.credit_card_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Field: Nomor Porsi
                    _buildUnderlineField(
                      context: context,
                      label: context.tr('medical.porsiLabel'),
                      hint: context.tr('medical.porsiHint'),
                      ctrl: _nomorPorsiCtrl,
                      keyboardType: TextInputType.number,
                      icon: Icons.confirmation_number_outlined,
                    ),
                    const SizedBox(height: 14),

                    // Field 1: Golongan Darah
                    _buildUnderlineField(
                      context: context,
                      label: context.tr('profile.bloodType'),
                      hint: context.tr('medicalBloodTypeHint'),
                      ctrl: _bloodTypeCtrl,
                      icon: Icons.bloodtype_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Field 2: Riwayat Alergi
                    _buildUnderlineField(
                      context: context,
                      label: context.tr('medical.allergiesLabel'),
                      hint: context.tr('medical.allergiesHint'),
                      ctrl: _allergiesCtrl,
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Field 3: Kondisi Khusus
                    _buildUnderlineField(
                      context: context,
                      label: context.tr('medical.conditionsLabel'),
                      hint: context.tr('medical.conditionsHint'),
                      ctrl: _conditionsCtrl,
                      icon: Icons.healing_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Field 4: Kontak Darurat
                    _buildUnderlineField(
                      context: context,
                      label: context.tr('medical.emergencyContactLabel'),
                      hint: context.tr('medical.emergencyContactHint'),
                      ctrl: _emergencyContactCtrl,
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone_in_talk_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Field 5: Nomor Paspor (Opsional
                    _buildUnderlineField(
                      context: context,
                      label: context.tr('medical.passportLabel'),
                      hint: context.tr('medical.passportHint'),
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
                                : colors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            context.tr('cancel').isEmpty
                                ? 'Batal'
                                : context.tr('cancel'),
                            style: context.text.labelLarge.copyWith(
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 135),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Floating Hero Card
            Positioned(
              top: 0,
              left: 22,
              right: 22,
              child: HajiDialogHeroHeader(
                icon: Icons.medical_services_rounded,
                title: context.tr('medicalBadgeHeader'),
              ),
            ),

            // 3. Protruding Ribbon Submit Button
            Positioned(
              bottom: 0,
              right: 0,
              child: Obx(() {
                final saving = widget.profileCtrl.isSavingMedical.value;
                return HajiDialogRibbonButton(
                  label: context.tr('save').toUpperCase(),
                  isLoading: saving,
                  onPressed: _submit,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
