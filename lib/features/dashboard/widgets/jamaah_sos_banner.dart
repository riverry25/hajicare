import 'package:flutter/material.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/services/app_alert_service.dart';
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

  void _handleSosTrigger(BuildContext context) {
    AppAlert.confirm(
      context,
      title: context.tr('sosConfirmTitle'),
      message: context.tr('sosConfirmMessage'),
      confirmText: context.tr('sosSendButton'),
      cancelText: context.tr('cancel'),
      isDestructive: true,
      onConfirm: () async {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(pattern: [0, 200, 100, 200]);
        }
        await state.triggerSos();
        if (context.mounted) {
          final sentTo = context.tr('sosSentTo');
          final companion = state.pendampingName.value.isNotEmpty
              ? state.pendampingName.value
              : 'Pendamping & Petugas';
          AppAlert.success(
            context,
            title: 'Sinyal Darurat Terkirim',
            message: '$sentTo $companion. Mohon tetap tenang di lokasi Anda.',
          );
        }
      },
    );
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

