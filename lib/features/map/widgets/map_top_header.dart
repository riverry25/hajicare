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
  final bool isLiveTracking;
  final double gpsAccuracy;
  final String? roomName;
  final String? memberSummary;
  final String? nearestInfo;

  const MapTopHeader({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onSosPressed,
    this.onSearchChanged,
    this.isLiveTracking = false,
    this.gpsAccuracy = 0.0,
    this.roomName,
    this.memberSummary,
    this.nearestInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          left: AppSpacing.screenEdgeGutter,
          right: AppSpacing.screenEdgeGutter,
          bottom: AppSpacing.sm2,
        ),
        decoration: BoxDecoration(
          color: AppColors.canvasCream.withValues(alpha: 0.96),
          border: Border(
            bottom: BorderSide(
              color: AppColors.cardBorderColor(context),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.espressoDark.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // TOP STATUS ROW: Live Tracking Badge & Emergency SOS
            // ============================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.cardBorderColor(context),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espressoDark.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AnimatedPingDot(
                        color: AppColors.statusPositive,
                        size: 8,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Pelacakan Aktif',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.espressoDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' • GPS ${gpsAccuracy > 0 ? '${gpsAccuracy.round()}m' : 'OK'}',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textBody,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Emergency SOS Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSosPressed,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sosEmergency,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.sosEmergency.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'SOS',
                            style: AppTypography.captionSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ============================================================
            // ACTIVE ROOM STATUS (If Bound)
            // ============================================================
            if (roomName != null && roomName!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.03),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.meeting_room_rounded,
                          size: 16,
                          color: AppColors.goldPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Room: $roomName',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.espressoDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (memberSummary != null && memberSummary!.isNotEmpty)
                      Text(
                        memberSummary!,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // ============================================================
            // LEGEND & NEAREST STATUS ROW
            // ============================================================
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Row(
                children: [
                  _buildLegendDot(AppColors.espressoDark, 'Anda'),
                  const SizedBox(width: 12),
                  _buildLegendDot(AppColors.goldPrimary, 'Pendamping'),
                  const SizedBox(width: 12),
                  _buildLegendDot(AppColors.statusPositive, 'Jamaah'),
                  if (nearestInfo != null && nearestInfo!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nearestInfo!,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textBody,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ============================================================
            // SEARCH BAR
            // ============================================================
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.cardBorderColor(context),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.tanMedium,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cari posko medis, toilet, tenda maktab...',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
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
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.mic_rounded,
                          color: AppColors.goldPrimary,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ============================================================
            // POI & ROLE FILTER CHIPS
            // ============================================================
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = index == selectedFilter;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onFilterSelected(index),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.espressoDark
                              : AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.goldPrimary
                                : AppColors.cardBorderColor(context),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.espressoDark.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: AppColors.espressoDark.withValues(
                                      alpha: 0.03,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (filter.icon != null) ...[
                              Icon(
                                filter.icon,
                                size: 15,
                                color: isSelected
                                    ? AppColors.goldPrimary
                                    : AppColors.tanMedium,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              filter.label,
                              style: AppTypography.captionSmall.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textHeadingColor(context),
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.espressoDark,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
