import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/join_room_controller.dart';

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdgeGutter,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Icon & Header
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
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
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.meeting_room_rounded,
                          size: 42,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Gabung ke Room',
                    textAlign: TextAlign.center,
                    style: AppTypography.displaySmall.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    'Masukkan nama kelompok dan 6 digit kode room yang diberikan oleh ketua rombongan atau petugas maktab.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: bodyColor,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 2. Input Form Card
                  AppCard(
                    backgroundColor: cardBg,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Field: Nama Room
                          Row(
                            children: [
                              Icon(Icons.apartment_rounded, size: 18, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Nama Room / Kelompok',
                                style: AppTypography.labelMedium.copyWith(
                                  color: headingColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: controller.roomNameController,
                            style: AppTypography.bodyMedium.copyWith(color: headingColor),
                            decoration: InputDecoration(
                              hintText: 'Contoh: Maktab 48 Kloter 12',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondaryColor(context),
                              ),
                              prefixIcon: Icon(
                                Icons.group_work_outlined,
                                color: AppColors.textSecondaryColor(context),
                                size: 20,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkPrimaryContainer.withValues(alpha: 0.25)
                                  : AppColors.canvasCream.withValues(alpha: 0.5),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(color: AppColors.cardBorderColor(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(color: AppColors.cardBorderColor(context)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Field: Kode Room PIN (Besar, Tebal, Mudah Diketik)
                          Row(
                            children: [
                              Icon(Icons.pin_rounded, size: 18, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Kode Room (6 Karakter PIN)',
                                style: AppTypography.labelMedium.copyWith(
                                  color: headingColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: controller.roomCodeController,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                              LengthLimitingTextInputFormatter(8),
                            ],
                            style: TextStyle(
                              letterSpacing: 6.0,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: headingColor,
                              fontFamily: 'monospace',
                            ),
                            decoration: InputDecoration(
                              hintText: 'M48X7K',
                              hintStyle: TextStyle(
                                letterSpacing: 6.0,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: AppColors.textSecondaryColor(context).withValues(alpha: 0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.key_rounded,
                                color: AppColors.textSecondaryColor(context),
                                size: 20,
                              ),
                              helperText: 'Kombinasi huruf kapital & angka tanpa spasi',
                              helperStyle: AppTypography.captionSmall.copyWith(
                                color: AppColors.textSecondaryColor(context),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkPrimaryContainer.withValues(alpha: 0.35)
                                  : AppColors.goldPrimary.withValues(alpha: 0.05),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(
                                  color: primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.goldPrimary.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Error Message Display
                          Obx(() {
                            final err = controller.errorMessage.value;
                            if (err == null) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      err,
                                      style: AppTypography.captionSmall.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          // Submit Button: Standard 54px height
                          Obx(() {
                            final loading = controller.isLoading.value;
                            return SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: loading ? null : controller.joinRoom,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: primaryColor.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.login_rounded, size: 20, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Gabung Room',
                                            style: AppTypography.button.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Switch Account / Sign Out option
                  Center(
                    child: TextButton.icon(
                      onPressed: controller.switchAccount,
                      icon: Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: AppColors.textSecondaryColor(context),
                      ),
                      label: Text(
                        'Keluar / Ganti Akun',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
}
