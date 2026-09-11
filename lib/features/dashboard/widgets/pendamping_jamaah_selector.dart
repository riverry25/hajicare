import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Jamaah Dipantau (${state.jamaahList.length})',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.espressoDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Sinkron Gelang Pintar',
              style: AppTypography.caption.copyWith(
                color: AppColors.secondary,
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
              for (int i = 0; i < state.jamaahList.length; i++) ...[
                _buildJamaahPill(
                  name: state.jamaahList[i].shortLabel,
                  distance: '${state.jamaahList[i].distance.toInt()}m',
                  isActive: selectedIndex == i,
                  tier: state.jamaahList[i].tier,
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
                    color: AppColors.tanMedium.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.person_add, color: AppColors.tanMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJamaahPill({
    required String name,
    required String distance,
    required bool isActive,
    required DistanceTier tier,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.only(
          left: 4,
          top: 4,
          bottom: 4,
          right: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.surfaceWhite
              : AppColors.surfaceWhite.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isActive ? AppColors.espressoDark : AppColors.goldLight,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldLight),
                color: AppColors.canvasCream,
              ),
              child: const Icon(Icons.person, color: AppColors.textBody),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.labelLarge.copyWith(
                    color: isActive
                        ? AppColors.espressoDark
                        : AppColors.textHeading,
                  ),
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
                      '${tier.label} • $distance',
                      style: AppTypography.captionSmall.copyWith(
                        color: isActive ? tier.color : AppColors.textBody,
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
