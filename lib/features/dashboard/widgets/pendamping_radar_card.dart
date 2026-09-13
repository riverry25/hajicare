import 'package:flutter/material.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/models/jamaah_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_ping_dot.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';

class PendampingRadarCard extends StatelessWidget {
  final JamaahData jamaah;
  final VoidCallback? onTrackMap;

  const PendampingRadarCard({
    super.key,
    required this.jamaah,
    this.onTrackMap,
  });

  AppStatusType _mapStatusType(DistanceTier tier) {
    switch (tier) {
      case DistanceTier.aman:
        return AppStatusType.safe;
      case DistanceTier.waspada:
        return AppStatusType.warning;
      case DistanceTier.terlalujJauh:
        return AppStatusType.danger;
    }
  }

  String _localizedTierLabel(BuildContext context, DistanceTier tier) {
    switch (tier) {
      case DistanceTier.aman:
        return context.tr('statusSafe');
      case DistanceTier.waspada:
        return context.tr('statusWarning');
      case DistanceTier.terlalujJauh:
        return context.tr('statusDanger');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
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
                        Icons.radar,
                        color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                context.tr('radarJamaahDistance'),
                                style: AppTypography.captionSmall.copyWith(
                                  color: bodyColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedPingDot(
                                color: jamaah.tier.color,
                                size: 8,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            jamaah.name,
                            style: AppTypography.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
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
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(
                label: _localizedTierLabel(context, jamaah.tier),
                statusType: _mapStatusType(jamaah.tier),
                icon: jamaah.tier.icon,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface
                  : AppColors.canvasCream.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark
                    ? AppColors.darkOutlineVariant
                    : AppColors.goldLight.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          '${jamaah.distance.toInt()}',
                          style: AppTypography.heroNumberLarge.copyWith(
                            color: jamaah.tier.color,
                          ),
                        ),
                        Text(
                          context.tr('meterUnit'),
                          style: AppTypography.titleMedium.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.tr('maxLimit'),
                          style: AppTypography.caption.copyWith(
                            color: bodyColor,
                          ),
                        ),
                        Text(
                          '200 ${context.tr('meterUnit')}',
                          style: AppTypography.labelLarge.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.goldLight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: (jamaah.distance / 200).clamp(0.0, 1.0),
                      backgroundColor: Colors.transparent,
                      color: jamaah.tier.color,
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('nearDistanceLabel'),
                      style: AppTypography.captionSmall.copyWith(
                        color: bodyColor,
                      ),
                    ),
                    Text(
                      '${((jamaah.distance / 200) * 100).toInt()}% ${context.tr('fromRadiusLimit')}',
                      style: AppTypography.captionSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      context.tr('warningDistanceLabel'),
                      style: AppTypography.captionSmall.copyWith(
                        color: bodyColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.canvasCreamSubtle,
          ),
          const SizedBox(height: AppSpacing.sm2),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.watch_rounded,
                      color: AppColors.tanMedium,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('smartBand'),
                            style: AppTypography.caption.copyWith(
                              color: bodyColor,
                            ),
                          ),
                          Text(
                            context.tr('batteryGpsActive'),
                            style: AppTypography.captionSmall.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.w600,
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
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.tanMedium,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('lastSync'),
                            style: AppTypography.caption.copyWith(
                              color: bodyColor,
                            ),
                          ),
                          Text(
                            context.tr('secondsAgo'),
                            style: AppTypography.captionSmall.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.w600,
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
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightPrimary,
            child: ElevatedButton(
              onPressed: onTrackMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.primaryContainer,
                foregroundColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.surfaceWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.near_me_rounded, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      context.tr('trackOnInteractiveMap'),
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? AppColors.darkPrimary : AppColors.surfaceWhite,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightSecondary,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: headingColor,
                side: BorderSide(
                  color: isDark ? AppColors.darkOutlineVariant : AppColors.goldLight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tune_rounded, size: 16, color: AppColors.tanMedium),
                  const SizedBox(width: AppSpacing.sm2),
                  Flexible(
                    child: Text(
                      context.tr('setSafeRadius'),
                      style: AppTypography.labelLarge.copyWith(
                        color: headingColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

