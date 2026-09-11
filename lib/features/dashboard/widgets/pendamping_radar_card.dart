import 'package:flutter/material.dart';
import '../../../../core/models/jamaah_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_ping_dot.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';

class PendampingRadarCard extends StatelessWidget {
  final JamaahData jamaah;
  final VoidCallback? onTrackMap;

  const PendampingRadarCard({
    super.key,
    required this.jamaah,
    this.onTrackMap,
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

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.canvasCream,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.radar,
                        color: AppColors.espressoDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'RADAR JARAK JAMAAH',
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.textBody,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedPingDot(
                                color: jamaah.tier.color,
                                size: 8,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            jamaah.name,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(
                label: jamaah.tier.label,
                statusType: _mapStatusType(jamaah.tier),
                icon: jamaah.tier.icon,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.canvasCream.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.goldLight.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${jamaah.distance.toInt()}',
                          style: AppTypography.heroNumberLarge.copyWith(
                            color: jamaah.tier.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'meter',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textBody,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Batas Maksimal',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textBody,
                          ),
                        ),
                        Text(
                          '200 meter',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.espressoDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.goldLight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: (jamaah.distance / 200).clamp(0.0, 1.0),
                      backgroundColor: Colors.transparent,
                      color: jamaah.tier.color,
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0m (Dekat)',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                    Text(
                      '${((jamaah.distance / 200) * 100).toInt()}% dari radius batas',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.espressoDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '200m (Peringatan)',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.canvasCreamSubtle),
          const SizedBox(height: AppSpacing.sm2),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.watch,
                      color: AppColors.tanMedium,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gelang Pintar',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textBody,
                            ),
                          ),
                          Text(
                            'Baterai 92% • GPS Aktif',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.espressoDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: AppColors.tanMedium,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terakhir Sinkron',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textBody,
                            ),
                          ),
                          Text(
                            '15 detik yang lalu',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.espressoDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightPrimary,
            child: ElevatedButton(
              onPressed: onTrackMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espressoDark,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.near_me, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Lacak di Peta Interaktif',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.surfaceWhite,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightSecondary,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.espressoDark,
                side: const BorderSide(color: AppColors.goldLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tune, size: 16, color: AppColors.tanMedium),
                  const SizedBox(width: AppSpacing.sm2),
                  Text(
                    'Atur Batas Radius Aman (200m)',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.espressoDark,
                    ),
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
