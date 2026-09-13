import 'package:flutter/material.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/models/jamaah_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';

class JamaahDistanceCard extends StatelessWidget {
  final JamaahData jamaah;
  final VoidCallback? onViewMap;

  const JamaahDistanceCard({
    super.key,
    required this.jamaah,
    this.onViewMap,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.radar,
                  color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('distanceToCompanion'),
                      style: AppTypography.caption.copyWith(
                        color: bodyColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          '${jamaah.distance.toInt()}',
                          style: AppTypography.displayMedium.copyWith(
                            color: jamaah.tier.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          context.tr('meterUnit'),
                          style: AppTypography.bodySmall.copyWith(
                            color: bodyColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppStatusBadge(
                label: _localizedTierLabel(context, jamaah.tier),
                statusType: _mapStatusType(jamaah.tier),
                icon: jamaah.tier.icon,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (jamaah.distance / 200).clamp(0.0, 1.0),
              backgroundColor: isDark
                  ? AppColors.darkSurfaceContainerHighest
                  : AppColors.surfaceVariant,
              color: jamaah.tier.color,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: onViewMap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pin_drop,
                          color: AppColors.tanMedium,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            context.tr('viewCompanionOnMap'),
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
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: headingColor,
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
