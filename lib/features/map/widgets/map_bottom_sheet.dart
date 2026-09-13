import 'package:flutter/material.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_status_badge.dart';

class MapBottomSheet extends StatelessWidget {
  final HajiCareState state;
  final VoidCallback? onNavigate;
  final VoidCallback? onShareLocation;
  final VoidCallback? onCall;

  final double bottomOffset;

  const MapBottomSheet({
    super.key,
    required this.state,
    this.onNavigate,
    this.onShareLocation,
    this.onCall,
    this.bottomOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final jamaah = state.self;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomOffset,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
          border: Border(
            top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.espressoDark.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Pilgrim Identity Row with Overflow Safety
                  Row(
                    children: [
                      // Avatar
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.canvasCream,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.goldLight),
                            ),
                            child: const Icon(
                              Icons.elderly,
                              color: AppColors.tanMedium,
                              size: 30,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: jamaah.tier.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surfaceWhite,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Name & Status with Flexible
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    jamaah.name,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.espressoDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AppStatusBadge(
                                  label: jamaah.shortLabel,
                                  statusType: AppStatusType.neutral,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  jamaah.tier.icon,
                                  size: 14,
                                  color: jamaah.tier.color,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${jamaah.tier.label} (${jamaah.distance.toInt()}m)',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textBody,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  ' • Baru saja',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Call button
                      InkWell(
                        onTap: onCall,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.canvasCream,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.espressoDark.withValues(alpha: 0.05),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call,
                            color: AppColors.tanMedium,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Status Metrics Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvasCream.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.goldLight.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            icon: Icons.watch,
                            label: 'Baterai Gelang',
                            value: '92% • Aktif',
                            iconColor: AppColors.statusPositive,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.goldLight.withValues(alpha: 0.4),
                        ),
                        Expanded(
                          child: _buildMetric(
                            icon: Icons.favorite,
                            label: 'Detak Jantung',
                            value: '78 bpm • Normal',
                            iconColor: AppColors.sosEmergency,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.goldLight.withValues(alpha: 0.4),
                        ),
                        Expanded(
                          child: _buildMetric(
                            icon: Icons.holiday_village,
                            label: 'Maktab',
                            value: 'Maktab 48 Mina',
                            iconColor: AppColors.tanMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.buttonHeightSecondary,
                          child: ElevatedButton.icon(
                            onPressed: onNavigate,
                            icon: const Icon(Icons.directions, size: 18),
                            label: Text(
                              'Navigasi ke Jamaah',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.surfaceWhite,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.espressoDark,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      InkWell(
                        onTap: onShareLocation,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.canvasCream,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.goldLight),
                          ),
                          child: const Icon(
                            Icons.share_location,
                            color: AppColors.espressoDark,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: AppTypography.captionSmall.copyWith(
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
    );
  }
}
