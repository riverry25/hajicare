import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_dialog.dart';
import '../../../../core/utils/distance_formatter.dart';
import '../../controllers/map_controller.dart';

/// Modern Navigation Bottom Panel refactored to match high-end delivery/tracking
/// card interface (Photo 2 reference) with live milestone stepper, adaptive typography,
/// dark mode support, and resilient text scaling.
class NavigationBottomPanel extends StatelessWidget {
  final MapController mapCtrl;

  const NavigationBottomPanel({super.key, required this.mapCtrl});

  String _formatEtaClock(int? durationSeconds) {
    if (durationSeconds == null || durationSeconds <= 0) {
      final now = DateTime.now();
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }
    final arrival = DateTime.now().add(Duration(seconds: durationSeconds));
    final h = arrival.hour.toString().padLeft(2, '0');
    final m = arrival.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDurationMinutes(int? durationSeconds) {
    if (durationSeconds == null || durationSeconds <= 0) return '1 mnt';
    final minutes = (durationSeconds / 60).ceil();
    if (minutes < 60) return '$minutes mnt';
    final hours = minutes ~/ 60;
    final remMin = minutes % 60;
    return '${hours}j ${remMin}m';
  }

  int _getCurrentStep(double? remDist) {
    if (mapCtrl.mapMode.value == MapMode.arrived) return 3;
    if (remDist != null && remDist <= 150.0) return 2;
    return 1;
  }

  String _getStatusPillLabel(int activeStep, BuildContext context) {
    switch (activeStep) {
      case 3:
        return context.tr('maps.arrivedAtDestination');
      case 2:
        return context.tr('maps.approachingDestination');
      default:
        return context.tr('maps.headingToDestination');
    }
  }

  IconData _getDestinationIcon() {
    final poi = mapCtrl.selectedPoi.value;
    if (poi != null) {
      return poi.category.defaultIcon;
    }
    if (mapCtrl.selectedMember.value != null ||
        mapCtrl.selectedJamaah.value != null) {
      return Icons.person_rounded;
    }
    return Icons.place_rounded;
  }

  Color _getDestinationColor() {
    final poi = mapCtrl.selectedPoi.value;
    if (poi != null) {
      return poi.category.defaultColor;
    }
    if (mapCtrl.selectedMember.value != null ||
        mapCtrl.selectedJamaah.value != null) {
      return AppColors.espressoDark;
    }
    return const Color(0xFFE11D48);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: bottomPadding + 16,
      child: Obx(() {
        final remDistance = mapCtrl.remainingNavDistance.value;
        final remDuration = mapCtrl.remainingNavDuration.value;
        final destTitle = mapCtrl.destinationTitle.value.isNotEmpty
            ? mapCtrl.destinationTitle.value
            : context.tr('maps.yourDestination');

        final durationText = _formatDurationMinutes(remDuration);
        final distanceText = remDistance != null
            ? DistanceFormatter.format(remDistance)
            : '-- m';
        final arrivalClock = _formatEtaClock(remDuration);
        final activeStep = _getCurrentStep(remDistance);
        final statusLabel = _getStatusPillLabel(activeStep, context);
        final destIcon = _getDestinationIcon();
        final destColor = _getDestinationColor();

        return RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.98)
                  : Colors.white.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppColors.goldLight.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. TOP ROW: Status Badge Pill & Arrival Clock ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status Pill (Photo 2 style: Circular icon inside pill)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A2B)
                              : const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: isDark ? 0.3 : 0.25),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF22C55E),
                              ),
                              child: const Icon(
                                Icons.directions_walk_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.captionSmall.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Arrival Time: ~20:48 (Photo 2 style: High emphasis bold clock)
                    Text(
                      '~$arrivalClock',
                      style: AppTypography.heading(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark
                            ? AppColors.darkTextHeading
                            : AppColors.espressoDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── 2. LIVE MILESTONE STEPPER (Photo 2 reference) ──
                _buildMilestoneStepper(context, activeStep),
                const SizedBox(height: 18),

                // ── 3. DESTINATION METADATA & ITEM CARD (Photo 2 reference) ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Leading Category Squircle
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              destColor,
                              destColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: destColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(destIcon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),

                      // Destination Name & Category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              destTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHeadingColor(context),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              context.tr('maps.remainingTimeWalking', {
                                'time': durationText,
                              }),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.textSecondaryColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Right Distance Badge (Photo 2 item metric style)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF22C55E,
                          ).withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          distanceText,
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 4. ACTION BUTTONS ROW (Photo 2 Contact Support style) ──
                Row(
                  children: [
                    // Primary Action: Keluar Navigasi (Prominent Pill)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: Material(
                          color: isDark
                              ? const Color(0xFFEF4444).withValues(alpha: 0.14)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: InkWell(
                            onTap: () => _confirmExit(context),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: isDark
                                      ? const Color(0xFFFCA5A5)
                                      : const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('maps.exitNavigation'),
                                  style: AppTypography.button.copyWith(
                                    color: isDark
                                        ? const Color(0xFFFCA5A5)
                                        : const Color(0xFFDC2626),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Recenter / Target Focus Shortcut
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: Material(
                        color: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: InkWell(
                          onTap: mapCtrl.recenterNavigation,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Icon(
                            Icons.my_location_rounded,
                            size: 22,
                            color: isDark
                                ? AppColors.goldPrimary
                                : AppColors.espressoDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 4-Stage Horizontal Milestone Stepper matching Photo 2 reference
  Widget _buildMilestoneStepper(BuildContext context, int activeStep) {
    final isDark = AppColors.isDark(context);
    final steps = [
      {'title': context.tr('maps.stepStart'), 'icon': Icons.flag_rounded},
      {
        'title': context.tr('maps.stepOnTheWay'),
        'icon': Icons.directions_walk_rounded,
      },
      {
        'title': context.tr('maps.stepApproaching'),
        'icon': Icons.near_me_rounded,
      },
      {'title': context.tr('maps.stepArrived'), 'icon': Icons.place_rounded},
    ];

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          // Step Icon & Label
          _buildStepItem(
            context: context,
            icon: steps[i]['icon'] as IconData,
            label: steps[i]['title'] as String,
            isActive: i <= activeStep,
            isCurrent: i == activeStep,
          ),
          // Connector Bar between steps
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 3.5,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: i < activeStep
                      ? const Color(0xFF22C55E)
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStepItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isCurrent,
  }) {
    final isDark = AppColors.isDark(context);
    const activeColor = Color(0xFF22C55E);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? (isCurrent
                      ? activeColor
                      : activeColor.withValues(alpha: isDark ? 0.25 : 0.15))
                : (isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : const Color(0xFFF1F5F9)),
            border: Border.all(
              color: isActive
                  ? activeColor
                  : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
              width: isCurrent ? 2.0 : 1.2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? (isCurrent ? Colors.white : activeColor)
                : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            color: isCurrent
                ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                : (isActive
                      ? (isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading)
                      : (isDark
                            ? AppColors.darkTextBody.withValues(alpha: 0.5)
                            : AppColors.textMuted)),
          ),
        ),
      ],
    );
  }

  void _confirmExit(BuildContext context) {
    AppDialog.confirm(
      context: context,
      title: context.tr('maps.exitNavTitle'),
      message: context.tr('maps.exitNavConfirm'),
      confirmText: context.tr('maps.exitAction'),
      cancelText: context.tr('maps.continueAction'),
      confirmColor: AppColors.sosEmergency,
      isDestructive: true,
      icon: Icons.close_rounded,
      onConfirm: () {
        mapCtrl.exitNavigation();
      },
    );
  }
}
