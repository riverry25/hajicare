import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_alert_service.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../presentation/dashboard_typography.dart';
import 'package:vibration/vibration.dart';

class JamaahSosBanner extends StatelessWidget {
  final HajiCareState state;

  const JamaahSosBanner({super.key, required this.state});

  void _handleSosTrigger(BuildContext context) {
    final hasRoom =
        (state.activeRoomId.value?.trim().isNotEmpty ?? false) ||
        state.activeRoom.value != null;
    if (!hasRoom) {
      AppAlert.warning(
        context,
        title: context.tr('dashboard.notRegisteredInRoom'),
        message: context.tr('dashboard.sosNeedsRoomDesc'),
        okText: context.tr('room.joinRoomTitle'),
        onOk: () => Get.toNamed(AppRoutes.joinRoom),
      );
      return;
    }

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
    final isDark = context.hc.isDark;
    final bodyColor = context.hc.textSecondary;
    final headingColor = context.hc.textPrimary;

    final hasActiveRoom =
        state.activeRoomId.value != null &&
        state.activeRoomId.value!.isNotEmpty;

    if (!hasActiveRoom) {
      return Container(
        decoration: BoxDecoration(
          color: context.hc.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: context.hc.border, width: 1.2),
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
                    color: context.hc.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: context.hc.primary,
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
                  backgroundColor: context.hc.primary,
                  foregroundColor: context.hc.onPrimary,
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
        color: context.hc.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: context.hc.danger.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: context.hc.danger.withValues(alpha: isDark ? 0.08 : 0.06),
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
                  gradient: LinearGradient(
                    colors: [
                      context.hc.danger,
                      context.hc.danger.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: context.hc.danger.withValues(alpha: 0.28),
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
              Icon(Icons.security_rounded, size: 16, color: context.hc.accent),
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
