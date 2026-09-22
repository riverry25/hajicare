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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(_iconForStage(category.stage), color: accentColor),
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr('hajjDuaAvailableCount', {'count': duaCount}),
                    style: HajjDuaTypography.metadataLabel.copyWith(
                      color: duaCount > 0
                          ? AppColors.statusPositive
                          : AppColors.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondaryColor(context),
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
      HajjDuaStage.sai => Icons.directions_walk_rounded,
      HajjDuaStage.arafah => Icons.landscape_rounded,
      HajjDuaStage.muzdalifah => Icons.nights_stay_rounded,
      HajjDuaStage.mina => Icons.location_city_rounded,
      HajjDuaStage.tahallul => Icons.content_cut_rounded,
      HajjDuaStage.general => Icons.volunteer_activism_rounded,
    };
  }
}
