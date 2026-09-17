import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/map_poi.dart';

/// Bottom sheet displaying dynamic information and action controls for a selected Point of Interest.
class LocationDetailSheet extends StatefulWidget {
  final MapPoi poi;
  final double? distanceMeters;
  final VoidCallback? onRoute;
  final VoidCallback? onShare;
  final VoidCallback? onClose;

  const LocationDetailSheet({
    super.key,
    required this.poi,
    this.distanceMeters,
    this.onRoute,
    this.onShare,
    this.onClose,
  });

  @override
  State<LocationDetailSheet> createState() => _LocationDetailSheetState();

  static void show(
    BuildContext context, {
    required MapPoi poi,
    double? distanceMeters,
    VoidCallback? onRoute,
    VoidCallback? onShare,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationDetailSheet(
        poi: poi,
        distanceMeters: distanceMeters,
        onRoute: onRoute,
        onShare: onShare,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

class _LocationDetailSheetState extends State<LocationDetailSheet> {
  double _dragOffset = 0.0;

  MapPoi get poi => widget.poi;
  double? get distanceMeters => widget.distanceMeters;
  VoidCallback? get onRoute => widget.onRoute;
  VoidCallback? get onShare => widget.onShare;
  VoidCallback? get onClose => widget.onClose;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta != null) {
      setState(() {
        _dragOffset = math.max(0.0, _dragOffset + details.primaryDelta!);
      });
      if (_dragOffset > 80) {
        onClose?.call();
        _dragOffset = 0.0;
      }
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset > 35 || velocity > 80) {
      onClose?.call();
    }
    setState(() {
      _dragOffset = 0.0;
    });
  }

  void _onVerticalDragCancel() {
    setState(() {
      _dragOffset = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDistance = distanceMeters != null
        ? (distanceMeters! >= 1000
            ? '${(distanceMeters! / 1000).toStringAsFixed(1)} km'
            : '${distanceMeters!.round()} m')
        : 'Dekat';

    final isDark = AppColors.isDark(context);

    return Transform.translate(
      offset: Offset(0, _dragOffset),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onVerticalDragCancel: _onVerticalDragCancel,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              12,
              AppSpacing.cardPadding,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.espressoDark.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    onVerticalDragUpdate: _onVerticalDragUpdate,
                    onVerticalDragEnd: _onVerticalDragEnd,
                    onVerticalDragCancel: _onVerticalDragCancel,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : AppColors.cardBorderColor(context),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Box
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: poi.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: poi.color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(poi.icon, color: poi.color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 13,
                          color: AppColors.tanMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$formattedDistance dari posisi Anda',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.textBodyColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          poi.isAccessible
                              ? Icons.accessible_rounded
                              : Icons.stairs_rounded,
                          size: 13,
                          color: poi.isAccessible
                              ? AppColors.statusPositive
                              : AppColors.tanMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          poi.isAccessible
                              ? 'Akses Kursi Roda Tersedia'
                              : 'Jalur Bertangga',
                          style: AppTypography.captionSmall.copyWith(
                            color: poi.isAccessible
                                ? AppColors.statusPositive
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (poi.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        poi.subtitle!,
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark ? AppColors.darkTextBody : AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: poi.color.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: poi.color.withValues(alpha: isDark ? 0.45 : 0.3),
                        ),
                      ),
                      child: Text(
                        poi.statusLabel,
                        style: AppTypography.captionSmall.copyWith(
                          color: poi.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Close button
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: isDark ? AppColors.darkTextBody : AppColors.tanMedium,
                  splashRadius: 20,
                  onPressed: onClose,
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Actions Row: Rute Berjalan (Primary 52px) & Bagikan (Secondary)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onRoute ?? () {},
                    icon: Icon(
                      Icons.directions_walk_rounded,
                      size: 20,
                      color: isDark ? AppColors.espressoDark : AppColors.goldPrimary,
                    ),
                    label: Text(
                      'Rute Jalan Kaki',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? AppColors.espressoDark : Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.goldPrimary : AppColors.espressoDark,
                      foregroundColor: isDark ? AppColors.espressoDark : Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.espressoDark.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.goldPrimary.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: onShare ?? () {},
                    icon: Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: isDark ? AppColors.darkTextHeading : AppColors.espressoDark,
                    ),
                    label: Text(
                      'Bagikan',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? AppColors.darkTextHeading : AppColors.espressoDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream.withValues(alpha: 0.35),
                      side: BorderSide(
                        color: AppColors.cardBorderColor(context),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
);
}
}

