import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:vibration/vibration.dart';

class JamaahSosBanner extends StatelessWidget {
  final HajiCareState state;

  const JamaahSosBanner({
    super.key,
    required this.state,
  });

  Future<void> _handleSosTrigger(BuildContext context) async {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        title: Text(
          context.tr('sosConfirmTitle'),
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: headingColor,
          ),
        ),
        content: Text(
          context.tr('sosConfirmMessage'),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textBodyColor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              context.tr('cancel'),
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? AppColors.darkTextBody : AppColors.textBody,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosEmergency,
              foregroundColor: AppColors.surfaceWhite,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(
              context.tr('sosSendButton'),
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.surfaceWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final notifTitle = context.mounted ? context.tr('notificationTooltip') : 'SOS';
      final sentTo = context.mounted ? context.tr('sosSentTo') : 'Sent to';
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }
      state.triggerSos();
      Get.snackbar(
        notifTitle,
        '$sentTo ${state.pendampingName.value}',
        backgroundColor: AppColors.sosEmergency,
        colorText: AppColors.surfaceWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return GestureDetector(
      onTap: () => _handleSosTrigger(context),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.sosEmergency.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.sosEmergency.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sosEmergency.withValues(alpha: isDark ? 0.05 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sosEmergency,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sosEmergency.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emergency_share_rounded,
                          color: AppColors.surfaceWhite,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('sosButtonTitle'),
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.surfaceWhite,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              context.tr('sosButtonSubtitle'),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.surfaceWhite.withValues(alpha: 0.95),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTypography.bodySmall.copyWith(
                      color: bodyColor,
                    ),
                    children: [
                      TextSpan(
                        text: context.tr('sosForwardedTo'),
                      ),
                      TextSpan(
                        text: context.tr('sosSectorOfficers'),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: headingColor,
                        ),
                      ),
                      TextSpan(text: context.tr('sosAnd')),
                      TextSpan(
                        text: context.tr('sosFamilyCompanion'),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: headingColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Divider(
                  color: isDark ? AppColors.darkOutlineVariant : AppColors.canvasCreamSubtle,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.sosEmergency,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        context.tr('sos24HoursResponse'),
                        style: AppTypography.caption.copyWith(
                          color: bodyColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

