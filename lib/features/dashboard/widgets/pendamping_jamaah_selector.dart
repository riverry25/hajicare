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
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      context.tr('monitoredPilgrims'),
                      style: AppTypography.titleMedium.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${jamaahList.length} Jamaah',
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.espressoDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.statusSafe,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Radar Terhubung',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.statusSafe,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
                  jamaah: jamaahList[i],
                  isActive: selectedIndex == i,
                  isDark: isDark,
                  onTap: () => onSelected?.call(i),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJamaahPill({
    required BuildContext context,
    required JamaahData jamaah,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final initial = jamaah.name.trim().isNotEmpty
        ? jamaah.name.trim()[0].toUpperCase()
        : 'J';
    final distance = '${jamaah.distance.toInt()}${context.tr('meterUnit')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.only(
          left: 5,
          top: 5,
          bottom: 5,
          right: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? (isActive
                    ? AppColors.darkPrimaryContainer
                    : AppColors.darkSurface)
              : (isActive
                    ? AppColors.surfaceWhite
                    : AppColors.surfaceWhite.withValues(alpha: 0.9)),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isActive
                ? (isDark ? AppColors.goldPrimary : AppColors.primaryContainer)
                : (isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder),
            width: isActive ? 1.8 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppColors.espressoDark)
                        .withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              AppColors.darkPrimaryContainer,
                              AppColors.darkSurfaceContainerHighest,
                            ]
                          : [
                              AppColors.espressoDark,
                              AppColors.primaryContainer,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.surfaceWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: jamaah.isGpsActive
                          ? AppColors.statusSafe
                          : AppColors.outline,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.surfaceWhite,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      jamaah.shortLabel,
                      style: AppTypography.labelLarge.copyWith(
                        color: headingColor,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (jamaah.sosActive) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sosEmergency,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: jamaah.tier.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_localizedTierLabel(context, jamaah.tier)} • $distance',
                      style: AppTypography.captionSmall.copyWith(
                        color: isActive ? jamaah.tier.color : bodyColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
