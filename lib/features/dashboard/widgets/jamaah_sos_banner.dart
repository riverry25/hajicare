import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_alert_service.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../presentation/dashboard_typography.dart';
import 'package:vibration/vibration.dart';

class JamaahSosBanner extends StatelessWidget {
  final HajiCareState state;

  const JamaahSosBanner({super.key, required this.state});

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
        final success = await state.triggerSos();
        if (context.mounted) {
          if (success) {
            final companion = state.pendampingName.value.isNotEmpty
                ? state.pendampingName.value
                : context.tr('dashboard.officerFallback');
            AppAlert.success(
              context,
              title: context.tr('dashboard.sosSignalSent'),
              message: context.tr('dashboard.sosNotifyCompanion', {
                'name': companion,
              }),
            );
          } else {
            AppAlert.error(
              context,
              title: context.tr('dashboard.sosSendFailed'),
              message: context.tr('dashboard.sosRetryDesc'),
              okText: context.tr('common.tryAgain'),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bodyColor = AppColors.textBodyColor(context);
    final headingColor = AppColors.textHeadingColor(context);

    final hasActiveRoom =
        state.activeRoomId.value != null &&
        state.activeRoomId.value!.isNotEmpty;

    if (!hasActiveRoom) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.goldLight.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.canvasCream,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: isDark ? AppColors.goldLight : AppColors.goldDark,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('dashboard.sosButton'),
                        style: DashboardTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr('dashboard.sosNeedsRoom'),
                        style: DashboardTypography.bodySmall.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.joinRoom),
                icon: const Icon(Icons.meeting_room_outlined, size: 20),
                label: Text(
                  context.tr('dashboard.joinGroup'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.sosEmergency.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sosEmergency.withValues(
              alpha: isDark ? 0.08 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        children: [
          // Big tactile SOS Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleSosTrigger(context),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sosEmergency.withValues(alpha: 0.35),
                      blurRadius: 12,
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
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sos_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('sosButtonTitle'),
                            style: DashboardTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            context.tr('sosButtonSubtitle'),
                            style: DashboardTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Clarifying text beneath
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security_rounded,
                size: 16,
                color: isDark ? AppColors.goldLight : AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.tr('dashboard.locationSentToCompanion'),
                  style: DashboardTypography.caption.copyWith(
                    color: bodyColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
