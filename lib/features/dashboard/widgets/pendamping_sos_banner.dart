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
  final Future<void> Function(String jamaahId)? onDismissSos;

  const PendampingSosBanner({
    super.key,
    required this.state,
    this.onDismissSos,
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
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.sosEmergency,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.sosEmergency.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('sosEmergencyActive'),
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sosJamaah.name} ${context.tr('sosNeedsImmediateHelp')}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.sosEmergency,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      context.tr('contactOfficer'),
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.sosEmergency,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onDismissSos != null
                        ? () => onDismissSos!(sosJamaah.id)
                        : () => state.dismissSos(sosJamaah.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: Text(
                      context.tr('endSos'),
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
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
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      borderColor: isDark
          ? AppColors.darkCardBorder
          : AppColors.lightCardBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.canvasCream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety_rounded,
              color: isDark ? AppColors.goldLight : AppColors.secondary,
              size: 24,
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
                        style: AppTypography.titleMedium.copyWith(
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
                            : AppColors.secondaryContainer.withValues(alpha: 0.6),
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
                const SizedBox(height: 3),
                Text(
                  context.tr('sosStandbyDesc'),
                  style: AppTypography.bodySmall.copyWith(
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
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
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: outline ? Border.all(color: borderColor ?? fg, width: 1.2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
