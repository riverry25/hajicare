import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/join_room_controller.dart';
import '../widgets/qr_scanner_dialog.dart';

class JoinRoomScreen extends StatelessWidget {
  const JoinRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JoinRoomController());
    final isDark = AppColors.isDark(context);
    final scaffoldBg = AppColors.scaffoldColor(context);
    final cardBg = AppColors.cardBgColor(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final primaryColor = isDark ? AppColors.goldLight : AppColors.goldPrimary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: headingColor,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Get.back();
            } else {
              controller.selectedMode.value == 0
                  ? Get.offAllNamed('/dashboard_pendamping')
                  : (controller.isPendamping
                        ? Get.offAllNamed('/dashboard_pendamping')
                        : Get.offAllNamed('/dashboard_jamaah'));
            }
          },
        ),
        title: Text(
          controller.isPendamping ? 'Room Pemantauan' : 'Gabung ke Room',
          style: AppTypography.titleMedium.copyWith(
            color: headingColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdgeGutter,
              vertical: AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Hero Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.18),
                            primaryColor.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.meeting_room_rounded,
                          size: 38,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Header Title & Subtitle
                  Obx(() {
                    final isCreating =
                        controller.isPendamping &&
                        controller.selectedMode.value == 0;
                    return Column(
                      children: [
                        Text(
                          isCreating ? 'Buat Room Baru' : 'Gabung ke Room',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isCreating
                              ? 'Buat room pemantauan untuk jamaah Anda. Kode unik dan QR Code akan dibuat otomatis oleh sistem.'
                              : 'Masukkan 6 digit kode room yang diberikan oleh ketua rombongan atau muthawif Anda.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: bodyColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: AppSpacing.lg),

                  // Mode Switcher for Pendamping
                  if (controller.isPendamping) ...[
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.canvasCream,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : AppColors.lightCardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ModeTabButton(
                                label: 'Buat Room',
                                icon: Icons.add_business_rounded,
                                isSelected: controller.selectedMode.value == 0,
                                primaryColor: primaryColor,
                                headingColor: headingColor,
                                isDark: isDark,
                                onTap: () => controller.selectedMode.value = 0,
                              ),
                            ),
                            Expanded(
                              child: _ModeTabButton(
                                label: 'Gabung Room',
                                icon: Icons.login_rounded,
                                isSelected: controller.selectedMode.value == 1,
                                primaryColor: primaryColor,
                                headingColor: headingColor,
                                isDark: isDark,
                                onTap: () => controller.selectedMode.value = 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Main Form Card
                  AppCard(
                    backgroundColor: cardBg,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Obx(() {
                        if (controller.isPendamping &&
                            controller.selectedMode.value == 0) {
                          return _buildCreateRoomForm(
                            context,
                            controller,
                            primaryColor,
                            headingColor,
                            isDark,
                          );
                        } else {
                          return _buildJoinRoomForm(
                            context,
                            controller,
                            primaryColor,
                            headingColor,
                            isDark,
                          );
                        }
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Bottom Info & Switch Account
                  Center(
                    child: TextButton.icon(
                      onPressed: () => controller.switchAccount(),
                      icon: Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: bodyColor,
                      ),
                      label: Text(
                        'Keluar / Ganti Akun',
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateRoomForm(
    BuildContext context,
    JoinRoomController controller,
    Color primaryColor,
    Color headingColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room Name Field
        Text(
          'Nama Room / Rombongan *',
          style: AppTypography.labelMedium.copyWith(
            color: headingColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller.createRoomNameController,
          style: AppTypography.bodyMedium.copyWith(color: headingColor),
          decoration: InputDecoration(
            hintText: 'Contoh: Rombongan Maktab 48',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
            prefixIcon: Icon(
              Icons.groups_rounded,
              color: primaryColor,
              size: 20,
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.darkPrimaryContainer.withValues(alpha: 0.25)
                : AppColors.canvasCream.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Maktab Field
        Text(
          'Nomor Maktab (Opsional)',
          style: AppTypography.labelMedium.copyWith(
            color: headingColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller.createMaktabController,
          style: AppTypography.bodyMedium.copyWith(color: headingColor),
          decoration: InputDecoration(
            hintText: 'Contoh: Maktab 48',
            prefixIcon: Icon(
              Icons.hotel_rounded,
              color: primaryColor,
              size: 20,
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.darkPrimaryContainer.withValues(alpha: 0.25)
                : AppColors.canvasCream.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Kloter Field
        Text(
          'Nomor Kloter (Opsional)',
          style: AppTypography.labelMedium.copyWith(
            color: headingColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller.createKloterController,
          style: AppTypography.bodyMedium.copyWith(color: headingColor),
          decoration: InputDecoration(
            hintText: 'Contoh: SOC-12',
            prefixIcon: Icon(
              Icons.flight_takeoff_rounded,
              color: primaryColor,
              size: 20,
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.darkPrimaryContainer.withValues(alpha: 0.25)
                : AppColors.canvasCream.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Submit Button
        Obx(
          () => SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.createRoom(),
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text(
                controller.isLoading.value
                    ? 'Membuat Room...'
                    : 'Buat Room Sekarang',
                style: AppTypography.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.espressoDark
                      : AppColors.surfaceWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinRoomForm(
    BuildContext context,
    JoinRoomController controller,
    Color primaryColor,
    Color headingColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // QR Code Scanner Action Button
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : () async {
                    final scannedCode = await QrScannerDialog.show(context);
                    if (scannedCode != null && scannedCode.isNotEmpty) {
                      controller.joinRoom(scannedCode);
                    }
                  },
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
            label: const Text(
              'Scan QR Code Pendamping',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Divider with "ATAU KODE MANUAL"
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark
                    ? AppColors.darkOutlineVariant
                    : AppColors.surfaceVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ATAU KODE MANUAL',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark
                    ? AppColors.darkOutlineVariant
                    : AppColors.surfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        Text(
          'Kode Room (6 Karakter)',
          style: AppTypography.labelMedium.copyWith(
            color: headingColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller.roomCodeController,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
          ],
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'KODE6',
            hintStyle: AppTypography.headlineMedium.copyWith(
              color: AppColors.textSecondaryColor(
                context,
              ).withValues(alpha: 0.4),
              letterSpacing: 8,
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.darkPrimaryContainer.withValues(alpha: 0.25)
                : AppColors.canvasCream.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Submit Button
        Obx(
          () => SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.joinRoom(),
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                controller.isLoading.value ? 'Memproses...' : 'Gabung ke Room',
                style: AppTypography.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.espressoDark
                      : AppColors.surfaceWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color primaryColor;
  final Color headingColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.primaryColor,
    required this.headingColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? primaryColor : AppColors.espressoDark)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDark ? AppColors.espressoDark : Colors.white)
                  : AppColors.textSecondaryColor(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDark ? AppColors.espressoDark : Colors.white)
                    : AppColors.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
