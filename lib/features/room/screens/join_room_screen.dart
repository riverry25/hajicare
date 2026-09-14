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
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Icon & Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.meeting_room_rounded,
                        size: 40,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Gabung ke Room',
                    textAlign: TextAlign.center,
                    style: AppTypography.displaySmall.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    'Masukkan Nama dan Kode Room pemantauan yang telah dibuat oleh Admin.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: bodyColor),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 2. Input Card
                  AppCard(
                    backgroundColor: cardBg,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Field: Nama Room
                          Text(
                            'Nama Room',
                            style: AppTypography.labelMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: controller.roomNameController,
                            decoration: InputDecoration(
                              hintText: 'Contoh: Maktab 48',
                              prefixIcon: Icon(Icons.apartment_rounded, color: bodyColor),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkPrimaryContainer.withValues(alpha: 0.3)
                                  : AppColors.canvasCream,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.borderGold,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.borderGold,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Field: Kode Room
                          Text(
                            'Kode Room (6 Karakter)',
                            style: AppTypography.labelMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: controller.roomCodeController,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                              LengthLimitingTextInputFormatter(8),
                            ],
                            style: const TextStyle(
                              letterSpacing: 4.0,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              hintText: 'M48X7K',
                              prefixIcon: Icon(Icons.key_rounded, color: bodyColor),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkPrimaryContainer.withValues(alpha: 0.3)
                                  : AppColors.canvasCream,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.borderGold,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.borderGold,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Error Message Display
                          Obx(() {
                            final err = controller.errorMessage.value;
                            if (err == null) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.error),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      err,
                                      style: AppTypography.captionSmall.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          // Submit Button
                          Obx(() {
                            final loading = controller.isLoading.value;
                            return ElevatedButton(
                              onPressed: loading ? null : controller.joinRoom,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: AppColors.surfaceWhite,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                elevation: 2,
                              ),
                              child: loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Gabung Room',
                                      style: AppTypography.button.copyWith(
                                        color: AppColors.surfaceWhite,
                                        fontWeight: FontWeight.bold,
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
                  TextButton.icon(
                    onPressed: controller.switchAccount,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Keluar / Ganti Akun'),
                    style: TextButton.styleFrom(
                      foregroundColor: bodyColor,
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
