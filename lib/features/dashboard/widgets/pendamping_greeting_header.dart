import 'package:flutter/material.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class PendampingGreetingHeader extends StatelessWidget {
  final HajiCareState state;

  const PendampingGreetingHeader({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: AppColors.onSecondaryContainer,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mode Pendamping Aktif',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Kloter 14 JKS • Maktab 48',
              style: AppTypography.caption.copyWith(color: AppColors.textBody),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Assalamu’alaikum, ${state.pendampingName.split(' ')[0]}',
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.espressoDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Pantau keselamatan dan pergerakan jamaah binaan Anda secara real-time.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textBody),
        ),
      ],
    );
  }
}
