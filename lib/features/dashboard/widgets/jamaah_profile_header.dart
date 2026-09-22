import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../presentation/dashboard_typography.dart';
import '../../../../core/widgets/animated_ping_dot.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';

class JamaahProfileHeader extends StatelessWidget {
  final HajiCareState state;

  const JamaahProfileHeader({super.key, required this.state});

  void _showTextSizeSheet(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkOutline
                        : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('selectTextSizeTitle'),
                style: DashboardTypography.titleLarge.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...AppTextScale.values.map((scale) {
                return Obx(() {
                  final isSelected = settings.rxTextScale.value == scale;
                  return InkWell(
                    onTap: () {
                      settings.setTextScale(scale);
                      Get.back();
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? AppColors.darkOutlineVariant.withValues(
                                    alpha: 0.3,
                                  )
                                : AppColors.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? (isDark
                                          ? AppColors.accentGoldStar
                                          : AppColors.espressoDark)
                                    : AppColors.outline,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                scale.label,
                                style: DashboardTypography.bodyMedium.copyWith(
                                  color: headingColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(scale.factor * 100).toStringAsFixed(0)}%',
                            style: DashboardTypography.captionSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextBody
                                  : AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final jamaah = state.self;
      final userName = jamaah.name;
      final effectiveKloter =
          (jamaah.kloter != null && jamaah.kloter!.isNotEmpty)
          ? jamaah.kloter
          : state.activeRoom.value?.kloter;
      final effectiveMaktab =
          (jamaah.maktab != null && jamaah.maktab!.isNotEmpty)
          ? jamaah.maktab
          : state.activeRoom.value?.maktab;
      final kloterLabel = context.tr('kloterLabelShort');
      final maktabLabel = context.tr('maktabLabelShort');
      final kloterText =
          (effectiveKloter != null && effectiveKloter.trim().isNotEmpty)
          ? (effectiveKloter.trim().toLowerCase().startsWith('kloter')
                ? effectiveKloter.trim()
                : '$kloterLabel ${effectiveKloter.trim()}')
          : '';
      final maktabText =
          (effectiveMaktab != null && effectiveMaktab.trim().isNotEmpty)
          ? (effectiveMaktab.trim().toLowerCase().startsWith('maktab')
                ? effectiveMaktab.trim()
                : '$maktabLabel ${effectiveMaktab.trim()}')
          : '';

      return AppCard(
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
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.tanMedium.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.account_circle,
                    color: isDark ? AppColors.goldLight : AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: DashboardTypography.titleLarge.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: AppColors.statusPositive,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (kloterText.isNotEmpty && maktabText.isNotEmpty)
                        Text(
                          '$kloterText • $maktabText',
                          style: DashboardTypography.caption.copyWith(
                            color: bodyColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (kloterText.isNotEmpty || maktabText.isNotEmpty)
                        Text(
                          kloterText.isNotEmpty ? kloterText : maktabText,
                          style: DashboardTypography.caption.copyWith(
                            color: bodyColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (state.activeRoom.value != null &&
                          state.activeRoom.value!.name.isNotEmpty)
                        Text(
                          state.activeRoom.value!.name,
                          style: DashboardTypography.caption.copyWith(
                            color: bodyColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.format_size, color: headingColor),
                  onPressed: () => _showTextSizeSheet(context),
                  tooltip: context.tr('changeTextSize'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.statusPositive.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const AnimatedPingDot(
                    color: AppColors.statusPositive,
                    size: 10,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: context.tr('connectedWith'),
                        style: DashboardTypography.caption.copyWith(
                          color: headingColor,
                        ),
                        children: [
                          TextSpan(
                            text: state.pendampingName.value,
                            style: DashboardTypography.captionSmall.copyWith(
                              color: isDark
                                  ? AppColors.accentGoldStar
                                  : AppColors.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppStatusBadge(
                    label: context.tr('activeStatus'),
                    statusType: AppStatusType.safe,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
