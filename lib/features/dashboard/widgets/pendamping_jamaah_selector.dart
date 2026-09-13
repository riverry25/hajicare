import 'package:flutter/material.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class PendampingJamaahSelector extends StatelessWidget {
  final HajiCareState state;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const PendampingJamaahSelector({
    super.key,
    required this.state,
    this.selectedIndex = 0,
    this.onSelected,
  });

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

    final jamaahList = state.jamaahList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${context.tr('monitoredPilgrims')} (${jamaahList.length})',
                style: AppTypography.titleMedium.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.tr('syncSmartBand'),
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.accentGoldStar : AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < jamaahList.length; i++) ...[
                _buildJamaahPill(
                  context: context,
                  name: jamaahList[i].shortLabel,
                  distance: '${jamaahList[i].distance.toInt()}${context.tr('meterUnit')}',
                  isActive: selectedIndex == i,
                  tier: jamaahList[i].tier,
                  isDark: isDark,
                  onTap: () => onSelected?.call(i),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.tanMedium.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  color: isDark ? AppColors.goldLight : AppColors.tanMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJamaahPill({
    required BuildContext context,
    required String name,
    required String distance,
    required bool isActive,
    required DistanceTier tier,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.only(
          left: 4,
          top: 4,
          bottom: 4,
          right: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? (isActive ? AppColors.darkPrimaryContainer : AppColors.darkSurface)
              : (isActive ? AppColors.surfaceWhite : AppColors.surfaceWhite.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isActive
                ? (isDark ? AppColors.accentGoldStar : AppColors.primaryContainer)
                : (isDark ? AppColors.darkOutlineVariant : AppColors.goldLight),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkOutlineVariant : AppColors.goldLight,
                ),
                color: isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream,
              ),
              child: Icon(
                Icons.person,
                color: isDark ? AppColors.goldLight : AppColors.textBody,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTypography.labelLarge.copyWith(
                    color: headingColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tier.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_localizedTierLabel(context, tier)} • $distance',
                      style: AppTypography.captionSmall.copyWith(
                        color: isActive ? tier.color : bodyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

