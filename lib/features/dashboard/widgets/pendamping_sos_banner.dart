import 'package:flutter/material.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import 'package:vibration/vibration.dart';

class PendampingSosBanner extends StatelessWidget {
  final HajiCareState state;

  const PendampingSosBanner({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (state.anySosActive) {
      return _buildActiveSos(context);
    }
    return _buildStandbySos(context);
  }

  Widget _buildActiveSos(BuildContext context) {
    Vibration.vibrate();
    final sosJamaah = state.jamaahList.firstWhere(
      (j) => j.sosActive,
      orElse: () => state.jamaahList.first,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.sosEmergency,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.sosEmergency.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.surfaceWhite,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('sosEmergencyActive'),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.surfaceWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${sosJamaah.name} ${context.tr('sosNeedsImmediateHelp')}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceWhite,
                    foregroundColor: AppColors.sosEmergency,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    context.tr('contactOfficer'),
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.sosEmergency,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state.dismissSos(sosJamaah.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.surfaceWhite,
                    side: const BorderSide(color: AppColors.surfaceWhite),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    context.tr('endSos'),
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.surfaceWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandbySos(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return AppCard(
      borderColor: isDark
          ? AppColors.darkOutlineVariant
          : AppColors.distanceWarning.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.distanceWarning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: AppColors.distanceWarning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        context.tr('sosStatusStandby'),
                        style: AppTypography.labelLarge.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        context.tr('sosStandbyBadge'),
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('sosStandbyDesc'),
                  style: AppTypography.bodySmall.copyWith(
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm2,
                  children: [
                    _buildSmallBtn(
                      icon: Icons.volume_up_rounded,
                      label: context.tr('testAlarmSignal'),
                      bg: isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream,
                      fg: isDark ? AppColors.goldLight : AppColors.espressoDark,
                      outline: false,
                    ),
                    _buildSmallBtn(
                      icon: Icons.call_rounded,
                      label: context.tr('responseCenter'),
                      bg: Colors.transparent,
                      fg: AppColors.sosEmergency,
                      outline: true,
                      borderColor: AppColors.sosEmergency.withValues(alpha: 0.4),
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

  Widget _buildSmallBtn({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required bool outline,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: outline ? Border.all(color: borderColor ?? fg) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

