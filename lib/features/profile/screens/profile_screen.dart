import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/state/app_settings_controller.dart';
import '../../../core/state/app_startup_controller.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/services/app_alert_service.dart';

class ProfileScreen extends StatelessWidget {
  final bool showBottomNav;
  const ProfileScreen({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final profileCtrl = Get.put(ProfileController());
    final state = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;

    return Obx(() {
      settings.currentTextScale;
      settings.currentLocale;
      {
        final isDark = AppColors.isDark(context);
        final scaffoldBg = AppColors.scaffoldColor(context);
        final cardBg = AppColors.cardBgColor(context);
        final headingColor = AppColors.textHeadingColor(context);
        final bodyColor = AppColors.textBodyColor(context);

        return Scaffold(
          backgroundColor: scaffoldBg,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: scaffoldBg,
            elevation: 0,
            title: Text(
              context.tr('profileTitle').isEmpty
                  ? 'Profil & Pengaturan'
                  : context.tr('profileTitle'),
              style: AppTypography.titleLarge.copyWith(
                color: headingColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenEdgeGutter,
              AppSpacing.md,
              AppSpacing.screenEdgeGutter,
              100,
            ),
            children: [
              // 1. Profile Identity Header Card
              _ProfileHeader(
                controller: profileCtrl,
                state: state,
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Data Jamaah & Rombongan
              _SettingsGroup(
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
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Aksesibilitas
              _SettingsGroup(
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
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. Preferensi & Tampilan
              _SettingsGroup(
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
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Informasi & Bantuan
              _SettingsGroup(
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
              ),
              const SizedBox(height: AppSpacing.xl),

              // 6. Logout Button
              _LogoutButton(
                label: context.tr('logout').isEmpty
                    ? 'Keluar dari Akun'
                    : context.tr('logout'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
          bottomNavigationBar: showBottomNav
              ? const HajiCareBottomNavBar(currentIndex: 3)
              : null,
        );
      }
    });
  }

  // ── Dialogs & Bottom Sheets ───────────────────────────────────────────────

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
                      border: Border.all(color: AppColors.cardBorderColor(context)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.health_and_safety_outlined, size: 44, color: bodyColor.withValues(alpha: 0.4)),
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
                          style: AppTypography.captionSmall.copyWith(color: bodyColor, height: 1.4),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditMedicalDialog(context, profileCtrl);
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text('Isi Data Medis Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      border: Border.all(color: AppColors.cardBorderColor(context)),
                    ),
                    child: Column(
                      children: [
                        _buildMedRow(
                          context,
                          'Golongan Darah',
                          profileCtrl.bloodType.value.isNotEmpty ? profileCtrl.bloodType.value : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          'Riwayat Alergi',
                          profileCtrl.allergies.value.isNotEmpty ? profileCtrl.allergies.value : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          'Kondisi Khusus',
                          profileCtrl.conditions.value.isNotEmpty ? profileCtrl.conditions.value : '-',
                        ),
                        const Divider(height: 16),
                        _buildMedRow(
                          context,
                          'Kontak Darurat',
                          profileCtrl.emergencyContact.value.isNotEmpty ? profileCtrl.emergencyContact.value : '-',
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showEditMedicalDialog(context, profileCtrl);
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Ubah Data', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkPrimaryContainer : AppColors.espressoDark,
                            foregroundColor: isDark ? AppColors.goldLight : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
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

  void _showEditMedicalDialog(BuildContext context, ProfileController profileCtrl) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.cardBgColor(context);
    final headingColor = AppColors.textHeadingColor(context);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    final bloodTypeCtrl = TextEditingController(text: profileCtrl.bloodType.value);
    final allergiesCtrl = TextEditingController(text: profileCtrl.allergies.value);
    final conditionsCtrl = TextEditingController(text: profileCtrl.conditions.value);
    final emergencyContactCtrl = TextEditingController(text: profileCtrl.emergencyContact.value);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.sosEmergency.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.medical_services_rounded, color: AppColors.sosEmergency, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kelola Data Medis',
                              style: AppTypography.titleMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Informasi kesehatan pribadi Jamaah',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.textBodyColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Golongan Darah
                  Text('Golongan Darah', style: AppTypography.labelMedium.copyWith(color: headingColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bloodTypeCtrl,
                    style: TextStyle(color: headingColor),
                    decoration: InputDecoration(
                      hintText: 'Contoh: O Rhesus (+), A (+), B (+)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      prefixIcon: const Icon(Icons.bloodtype_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Riwayat Alergi
                  Text('Riwayat Alergi Obat / Makanan', style: AppTypography.labelMedium.copyWith(color: headingColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: allergiesCtrl,
                    style: TextStyle(color: headingColor),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Alergi penisilin, atau tidak ada',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      prefixIcon: const Icon(Icons.warning_amber_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Kondisi Khusus
                  Text('Kondisi Khusus / Riwayat Penyakit', style: AppTypography.labelMedium.copyWith(color: headingColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: conditionsCtrl,
                    style: TextStyle(color: headingColor),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Hipertensi, Diabetes, Asma, dsb.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      prefixIcon: const Icon(Icons.healing_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Kontak Darurat
                  Text('Nomor Kontak Darurat (Keluarga)', style: AppTypography.labelMedium.copyWith(color: headingColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emergencyContactCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: headingColor),
                    decoration: InputDecoration(
                      hintText: 'Contoh: 0812-3456-7890 (Anak / Pasangan)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      prefixIcon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Obx(() {
                    final saving = profileCtrl.isSavingMedical.value;
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : () => Navigator.of(dialogCtx).pop(),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            onPressed: saving
                                ? null
                                : () async {
                                    await profileCtrl.updateMedicalData(
                                      bloodTypeVal: bloodTypeCtrl.text,
                                      allergiesVal: allergiesCtrl.text,
                                      conditionsVal: conditionsCtrl.text,
                                      emergencyContactVal: emergencyContactCtrl.text,
                                    );
                                    if (dialogCtx.mounted) {
                                      Navigator.of(dialogCtx).pop();
                                    }
                                    if (context.mounted) {
                                      AppAlert.success(context, message: 'Data medis berhasil diperbarui.');
                                    }
                                  },
                            icon: saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_rounded, size: 18),
                            label: Text(saving ? 'Menyimpan...' : 'Simpan Data Medis'),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
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

    final hasRoom = state?.activeRoomId.value != null && state!.activeRoomId.value!.trim().isNotEmpty;
    final roomName = hasRoom ? (state.activeRoom.value?.name ?? 'Room Pemantauan') : '-';
    final roomCode = hasRoom ? (state.activeRoom.value?.code ?? '-') : '-';
    final pendamping = hasRoom ? (state.pendampingName.value.isNotEmpty ? state.pendampingName.value : 'Pendamping Room') : '-';

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
                    border: Border.all(color: AppColors.cardBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.meeting_room_outlined, size: 48, color: bodyColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'Belum Ada Room Terhubung',
                        style: AppTypography.titleSmall.copyWith(color: headingColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Anda belum memiliki room aktif. Gabung ke room untuk mengaktifkan koordinasi dengan ketua rombongan & monitoring jarak realtime.',
                        textAlign: TextAlign.center,
                        style: AppTypography.captionSmall.copyWith(color: bodyColor, height: 1.4),
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
                      foregroundColor: isDark ? AppColors.espressoDark : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.toNamed(AppRoutes.joinRoom);
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Gabung Room Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    border: Border.all(color: AppColors.cardBorderColor(context)),
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
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final ProfileController controller;
  final HajiCareController? state;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _ProfileHeader({
    required this.controller,
    required this.state,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final self = state?.self;
    final porsiText = self?.porsi != null && self!.porsi!.isNotEmpty
        ? 'Porsi: ${self.porsi}'
        : 'Paspor: Indonesia';
    final maktabText = self?.maktab != null && self!.maktab!.isNotEmpty
        ? 'Maktab ${self.maktab}'
        : (self?.kloter != null ? '• Kloter ${self!.kloter}' : '');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.cardBorderColor(context),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () =>
                _InitialsAvatar(initials: controller.initials, isDark: isDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Text(
              controller.displayName.value,
              style: AppTypography.headlineMd.copyWith(
                color: headingColor,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
          const SizedBox(height: 4),
          if (controller.safeEmail.isNotEmpty)
            Text(
              controller.safeEmail,
              style: AppTypography.bodySmall.copyWith(color: bodyColor),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          const SizedBox(height: 10),

          // Role & Identity Meta Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimaryContainer.withValues(alpha: 0.6)
                      : AppColors.espressoDark,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.goldPrimary, width: 1),
                ),
                child: Text(
                  state?.role == UserRole.pendamping
                      ? 'Pendamping'
                      : 'Jamaah Haji',
                  style: AppTypography.captionSmall.copyWith(
                    color: isDark ? AppColors.goldPrimary : Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : AppColors.canvasCream,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.cardBorderColor(context)),
                ),
                child: Text(
                  '$porsiText  $maktabText',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textHeadingColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EditNameButton(controller: controller, isDark: isDark),
        ],
      ),
    );
  }
}

// ── Initials Avatar ───────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final bool isDark;

  const _InitialsAvatar({required this.initials, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkPrimaryContainer,
                  AppColors.darkSurfaceContainerHigh,
                ]
              : [AppColors.espressoDark, Color(0xFF22160E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.goldPrimary, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.displayMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Edit Name Button ──────────────────────────────────────────────────────────

class _EditNameButton extends StatelessWidget {
  final ProfileController controller;
  final bool isDark;

  const _EditNameButton({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;

    return Semantics(
      button: true,
      label: context.tr('editName'),
      child: InkWell(
        onTap: () => _showEditNameDialog(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, size: 14, color: accentColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.tr('editName').isEmpty
                    ? 'Ubah Nama'
                    : context.tr('editName'),
                style: AppTypography.bodySmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final isDarkDialog = AppColors.isDark(context);
    final dialogBg = isDarkDialog
        ? AppColors.darkSurface
        : AppColors.surfaceWhite;
    final headingClr = isDarkDialog
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyClr = isDarkDialog ? AppColors.darkTextBody : AppColors.textBody;
    final borderClr = isDarkDialog
        ? AppColors.darkOutlineVariant
        : AppColors.cardBorderColor(context);
    final nameCtrl = TextEditingController(text: controller.displayName.value);
    final inputError = RxnString();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.goldPrimary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdgeGutter,
          vertical: 24,
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Center Icon Badge
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.goldPrimary.withValues(alpha: 0.22),
                            AppColors.goldPrimary.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.goldPrimary,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Title
                  Text(
                    dialogCtx.tr('editNameTitle').isEmpty
                        ? 'Ubah Nama Lengkap'
                        : dialogCtx.tr('editNameTitle'),
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge.copyWith(
                      color: headingClr,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nama ini akan ditampilkan pada profil, dashboard, dan pantauan rombongan.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: bodyClr,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Text Field with validation
                  Obx(
                    () => TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 50,
                      style: AppTypography.bodyLarge.copyWith(
                        color: headingClr,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: dialogCtx.tr('name').isEmpty
                            ? 'Nama Lengkap'
                            : dialogCtx.tr('name'),
                        labelStyle: TextStyle(color: bodyClr),
                        errorText: inputError.value,
                        filled: true,
                        fillColor: isDarkDialog
                            ? AppColors.darkSurfaceContainer
                            : AppColors.canvasCream,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide(color: borderClr),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide(color: borderClr),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: const BorderSide(
                            color: AppColors.goldPrimary,
                            width: 1.8,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.person_rounded,
                          color: AppColors.goldPrimary,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => nameCtrl.clear(),
                        ),
                      ),
                      onChanged: (_) {
                        if (inputError.value != null) inputError.value = null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons: Batal & Simpan
                  Obx(() {
                    final saving = controller.isSavingName.value;
                    return Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(dialogCtx).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderClr),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                              child: Text(
                                dialogCtx.tr('cancel').isEmpty
                                    ? 'Batal'
                                    : dialogCtx.tr('cancel'),
                                style: TextStyle(
                                  color: isDarkDialog
                                      ? AppColors.darkTextBody
                                      : AppColors.espressoDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final input = nameCtrl.text.trim();
                                      if (input.isEmpty) {
                                        inputError.value =
                                            'Nama tidak boleh kosong';
                                        return;
                                      }
                                      inputError.value = null;

                                      try {
                                        await controller.updateDisplayName(
                                          input,
                                        );
                                        if (dialogCtx.mounted &&
                                            Navigator.of(dialogCtx).canPop()) {
                                          Navigator.of(dialogCtx).pop();
                                        }
                                        if (!context.mounted) return;
                                        AppAlert.success(
                                          context,
                                          title: 'Berhasil',
                                          message:
                                              'Nama berhasil diperbarui menjadi "$input"',
                                        );
                                      } catch (_) {
                                        if (!context.mounted) return;
                                        AppAlert.error(
                                          context,
                                          title: 'Gagal',
                                          message:
                                              'Gagal memperbarui nama. Silakan coba lagi.',
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkDialog
                                    ? AppColors.darkPrimaryContainer
                                    : AppColors.espressoDark,
                                foregroundColor: isDarkDialog
                                    ? AppColors.goldLight
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                              child: saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Settings Group ────────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Color cardBg;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.titleColor,
    required this.cardBg,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6, top: 4),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.captionSmall.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.cardBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: AppColors.espressoDark.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailingLabel,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Semantics(
      button: true,
      label: '$label${trailingLabel != null ? ': $trailingLabel' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : AppColors.canvasCream,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.cardBorderColor(context),
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailingLabel != null) ...[
                Text(
                  trailingLabel!,
                  style: AppTypography.captionSmall.copyWith(
                    color: isDark ? AppColors.goldLight : AppColors.tanMedium,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.tanMedium,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Thin Divider ──────────────────────────────────────────────────────────────

class _DividerThin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 58,
      color: AppColors.cardBorderColor(context),
    );
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final String label;
  const _LogoutButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () {
            AppDialog.confirm(
              context: context,
              title: label,
              message:
                  'Apakah Anda yakin ingin keluar? Anda perlu login kembali untuk mengakses data room rombongan.',
              confirmText: 'Ya, Keluar',
              cancelText: 'Batal',
              confirmColor: AppColors.sosEmergency,
              isDestructive: true,
              onConfirm: () async {
                await Get.find<AppStartupController>().signOut();
              },
            );
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: AppColors.sosEmergency.withValues(alpha: 0.4),
              width: 1.2,
            ),
            backgroundColor: AppColors.sosEmergency.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          icon: const Icon(
            Icons.logout_rounded,
            size: 18,
            color: AppColors.sosEmergency,
          ),
          label: Text(
            label,
            style: const TextStyle(
              color: AppColors.sosEmergency,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Picker Option ─────────────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? trailingHint;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickerOption({
    this.icon,
    required this.label,
    this.trailingHint,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final activeColor = isDark ? AppColors.goldPrimary : AppColors.espressoDark;
    final textColor = AppColors.textHeadingColor(context);
    final selectedBg = isDark
        ? AppColors.darkPrimaryContainer.withValues(alpha: 0.40)
        : AppColors.espressoDark.withValues(alpha: 0.07);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSizes.touchTargetMin + 4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppSizes.iconMd,
                  color: isSelected ? activeColor : textColor,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isSelected ? activeColor : textColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              if (trailingHint != null) ...[
                Text(
                  trailingHint!,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textBodyColor(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: activeColor, size: 22)
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardBorderColor(context),
                      width: 1.8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
