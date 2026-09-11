import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class JamaahPrayerCard extends StatelessWidget {
  const JamaahPrayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceContainerLow,
      borderColor: AppColors.goldLight.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.tanMedium, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'JADWAL SHOLAT MAKKAH',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.espressoDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.explore,
                      color: AppColors.accentGoldStar,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kiblat 294°',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textHeading,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu Sholat Berikutnya',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Ashar',
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.espressoDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '15:42 AST',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.tanMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Dalam 48 menit',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.surfaceWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniTime('Subuh', '04:52', false),
              _buildMiniTime('Dzuhur', '12:28', false),
              _buildMiniTime('Ashar', '15:42', true),
              _buildMiniTime('Maghrib', '18:35', false),
              _buildMiniTime('Isya', '20:05', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTime(String name, String time, bool isActive) {
    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryContainer
            : AppColors.surfaceWhite.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isActive
            ? Border.all(color: AppColors.goldLight)
            : Border.all(color: Colors.transparent),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            name,
            style: AppTypography.captionSmall.copyWith(
              color: isActive ? AppColors.accentGoldStar : AppColors.textBody,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: AppTypography.captionSmall.copyWith(
              color: isActive ? AppColors.surfaceWhite : AppColors.textHeading,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    return Expanded(
      child: isActive ? Transform.scale(scale: 1.05, child: content) : content,
    );
  }
}
