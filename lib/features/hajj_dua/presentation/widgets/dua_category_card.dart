import 'package:flutter/material.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../models/hajj_dua_category.dart';
import '../hajj_dua_typography.dart';

class DuaCategoryCard extends StatelessWidget {
  final HajjDuaCategory category;
  final int duaCount;
  final VoidCallback onTap;

  const DuaCategoryCard({
    super.key,
    required this.category,
    required this.duaCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accentColor = isDark ? AppColors.goldLight : AppColors.espressoDark;
    final categoryTitle = context.tr(category.titleKey);

    return Semantics(
      button: true,
      label: context.tr('hajjDuaCategorySemantics', {
        'category': categoryTitle,
        'count': duaCount,
      }),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(_iconForStage(category.stage), color: accentColor, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryTitle,
                        style: HajjDuaTypography.cardTitle.copyWith(
                          color: AppColors.textHeadingColor(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.tr(category.descriptionKey),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: HajjDuaTypography.caption.copyWith(
                          color: AppColors.textBodyColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondaryColor(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    duaCount > 0
                        ? context.tr('hajjDuaAvailableCount', {'count': duaCount})
                        : 'Bacaan tersedia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HajjDuaTypography.metadataLabel.copyWith(
                      color: duaCount > 0
                          ? AppColors.statusPositive
                          : AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Wrap(
                  spacing: 4,
                  children: [
                    _FeaturePill(label: 'عربي', isDark: isDark),
                    _FeaturePill(label: 'Latin', isDark: isDark),
                    _FeaturePill(label: 'Arti', isDark: isDark),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForStage(HajjDuaStage stage) {
    return switch (stage) {
      HajjDuaStage.ihram => Icons.checkroom_rounded,
      HajjDuaStage.masjidAlHaram => Icons.mosque_rounded,
      HajjDuaStage.tawaf => Icons.sync_rounded,
      HajjDuaStage.zamzam => Icons.water_drop_rounded,
      HajjDuaStage.sai => Icons.directions_walk_rounded,
      HajjDuaStage.arafah => Icons.landscape_rounded,
      HajjDuaStage.muzdalifah => Icons.nights_stay_rounded,
      HajjDuaStage.mina => Icons.location_city_rounded,
      HajjDuaStage.tahallul => Icons.content_cut_rounded,
      HajjDuaStage.tawafIfadah => Icons.sync_alt_rounded,
      HajjDuaStage.tawafWada => Icons.waving_hand_rounded,
      HajjDuaStage.madinah => Icons.star_border_purple500_rounded,
      HajjDuaStage.general => Icons.volunteer_activism_rounded,
    };
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  final bool isDark;

  const _FeaturePill({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
          color: AppColors.outlineColor(context).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryColor(context),
        ),
      ),
    );
  }
}
