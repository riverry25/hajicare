import 'package:flutter/material.dart';
import '../../../../core/models/filter_chip_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_ping_dot.dart';

class MapTopHeader extends StatelessWidget {
  final List<FilterChipItem> filters;
  final int selectedFilter;
  final ValueChanged<int> onFilterSelected;
  final VoidCallback onSosPressed;
  final ValueChanged<String>? onSearchChanged;

  const MapTopHeader({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onSosPressed,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          left: AppSpacing.screenEdgeGutter,
          right: AppSpacing.screenEdgeGutter,
          bottom: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.canvasCream.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: AppColors.espressoDark.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top row: Live Tracking Badge + SOS Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espressoDark.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const AnimatedPingDot(
                        color: AppColors.statusPositive,
                        size: 8,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pelacakan Aktif',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.espressoDark,
                        ),
                      ),
                      Text(
                        ' • GPS 3m',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
                // SOS Button
                GestureDetector(
                  onTap: onSosPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sosEmergency,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sosEmergency.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sos,
                          color: AppColors.surfaceWhite,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SOS',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.surfaceWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Search Bar
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.goldLight.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.md),
                    child: Icon(
                      Icons.search,
                      color: AppColors.tanMedium,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Cari toilet, tenda maktab, posko medis...',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textBody,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.mic,
                          color: AppColors.tanMedium,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm2),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Filter Chips
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm2),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = index == selectedFilter;
                  return GestureDetector(
                    onTap: () => onFilterSelected(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryContainer
                            : AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: AppColors.goldLight.withValues(alpha: 0.7),
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.espressoDark.withValues(alpha: 0.04),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (filter.icon != null) ...[
                            Icon(
                              filter.icon,
                              size: 14,
                              color: isSelected
                                  ? AppColors.surfaceWhite
                                  : AppColors.espressoDark,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            filter.label,
                            style: AppTypography.captionSmall.copyWith(
                              color: isSelected
                                  ? AppColors.surfaceWhite
                                  : AppColors.espressoDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
