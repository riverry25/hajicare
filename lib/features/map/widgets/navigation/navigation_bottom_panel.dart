import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_dialog.dart';
import '../../../../core/utils/distance_formatter.dart';
import '../../controllers/map_controller.dart';

/// Accessible Bottom Navigation Info Panel.
/// Displays live ETA, remaining distance, estimated arrival clock time,
/// destination label, and the Exit Navigation button.
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

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: bottomPadding + 36,
      child: Obx(() {
        final remDistance = mapCtrl.remainingNavDistance.value;
        final remDuration = mapCtrl.remainingNavDuration.value;
        final destTitle = mapCtrl.destinationTitle.value.isNotEmpty
            ? mapCtrl.destinationTitle.value
            : 'Tujuan Anda';

        final durationText = _formatDurationMinutes(remDuration);
        final distanceText = remDistance != null
            ? DistanceFormatter.format(remDistance)
            : '-- m';
        final arrivalClock = _formatEtaClock(remDuration);

        return RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppColors.goldLight.withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Primary Metrics Row: ETA, Distance, Arrival Clock
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // ETA (Minutes)
                    Text(
                      durationText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF16A34A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.espressoDark.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Remaining Distance
                    Text(
                      distanceText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.espressoDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.espressoDark.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Arrival Time
                    Text(
                      'Tiba $arrivalClock',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.65)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. Destination Info Row
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      size: 16,
                      color: Color(0xFFE11D48),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        destTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.espressoDark.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Action Buttons Row: Exit Button & Overview Button
                Row(
                  children: [
                    // Exit Button (Prominent pill)
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmExit(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 19,
                            color: Color(0xFFEF4444),
                          ),
                          label: const Text(
                            'Keluar Navigasi',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            backgroundColor: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Recenter / Focus Button Shortcut
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: Material(
                        color: isDark
                            ? AppColors.darkSurfaceContainer
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

  void _confirmExit(BuildContext context) {
    AppDialog.confirm(
      context: context,
      title: 'Keluar dari Navigasi?',
      message:
          'Apakah Anda ingin menghentikan mode panduan navigasi dan kembali ke tampilan peta biasa?',
      confirmText: 'Keluar',
      cancelText: 'Lanjutkan',
      confirmColor: AppColors.sosEmergency,
      isDestructive: true,
      icon: Icons.close_rounded,
      onConfirm: () {
        mapCtrl.exitNavigation();
      },
    );
  }
}
