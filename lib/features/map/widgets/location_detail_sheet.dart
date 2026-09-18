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

class _LocationDetailSheetState extends State<LocationDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  Animation<double>? _slideAnim;
  bool _isDismissing = false;
  double _dragOffset = 0.0;

  MapPoi get poi => widget.poi;
  double? get distanceMeters => widget.distanceMeters;
  VoidCallback? get onRoute => widget.onRoute;
  VoidCallback? get onShare => widget.onShare;
  VoidCallback? get onClose => widget.onClose;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    // Smooth entrance slide up
    _dragOffset = 60.0;
    _slideAnim = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    )..addListener(_onAnimTick);
    _animCtrl.forward();
  }

  void _onAnimTick() {
    if (mounted && _slideAnim != null) {
      setState(() {
        _dragOffset = _slideAnim!.value;
      });
    }
  }

  @override
  void dispose() {
    _slideAnim?.removeListener(_onAnimTick);
    _animCtrl.dispose();
    super.dispose();
  }

  void _dismissWithAnimation({double velocity = 0.0}) {
    if (_isDismissing) return;
    _isDismissing = true;

    final startOffset = _dragOffset;
    final targetOffset = math.max(450.0, startOffset + 320.0);

    // Dynamic duration based on downward velocity
    int durationMs = 220;
    if (velocity > 800) {
      durationMs = 150;
    } else if (velocity > 400) {
      durationMs = 180;
    }

    _slideAnim?.removeListener(_onAnimTick);
    _animCtrl.duration = Duration(milliseconds: durationMs);
    _slideAnim = Tween<double>(begin: startOffset, end: targetOffset).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInCubic),
    )..addListener(_onAnimTick);

    _animCtrl.reset();
    _animCtrl.forward().then((_) {
      if (mounted) {
        widget.onClose?.call();
      }
    });
  }

  void _springBackAnimation() {
    if (_isDismissing) return;
    if (_dragOffset == 0.0) return;

    final startOffset = _dragOffset;
    _slideAnim?.removeListener(_onAnimTick);
    _animCtrl.duration = const Duration(milliseconds: 220);
    _slideAnim = Tween<double>(begin: startOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    )..addListener(_onAnimTick);

    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    if (_animCtrl.isAnimating) {
      _animCtrl.stop();
    }
    if (details.primaryDelta != null) {
      setState(() {
        if (details.primaryDelta! > 0) {
          _dragOffset += details.primaryDelta!;
        } else {
          if (_dragOffset > 0) {
            _dragOffset = math.max(0.0, _dragOffset + details.primaryDelta!);
          } else {
            _dragOffset = math.max(
              -20.0,
              _dragOffset + details.primaryDelta! * 0.25,
            );
          }
        }
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    final velocity = details.primaryVelocity ?? 0.0;
    final isFlingDown = velocity > 300.0;
    final isDraggedDown = _dragOffset > 60.0 && velocity > -100.0;
    final isDeepDrag = _dragOffset > 110.0;

    if (isFlingDown || isDraggedDown || isDeepDrag) {
      _dismissWithAnimation(velocity: velocity);
    } else {
      _springBackAnimation();
    }
  }

  void _onVerticalDragCancel() {
    if (!_isDismissing) {
      _springBackAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDistance = distanceMeters != null
        ? (distanceMeters! >= 1000
              ? '${(distanceMeters! / 1000).toStringAsFixed(1)} km'
              : '${distanceMeters!.round()} m')
        : 'Dekat';

    final isDark = AppColors.isDark(context);
    final opacity = (1.0 - (_dragOffset / 280.0)).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
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
                    onTap: () => _dismissWithAnimation(),
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

                // ── CATEGORY BADGE & STATUS ROW ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: poi.color.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: poi.color.withValues(alpha: isDark ? 0.5 : 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(poi.icon, size: 13, color: poi.color),
                          const SizedBox(width: 5),
                          Text(
                            poi.category.label,
                            style: AppTypography.captionSmall.copyWith(
                              color: poi.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.canvasCream,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.espressoDark.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.statusSafe,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            poi.statusLabel,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : AppColors.espressoDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Icon Box
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(poi.color, Colors.white, 0.15)!,
                            poi.color,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: poi.color.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(poi.icon, color: Colors.white, size: 26),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Title, distance, subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            poi.name,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textHeadingColor(context),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Walk time estimation & distance
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_walk_rounded,
                                size: 14,
                                color: AppColors.goldPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distanceMeters != null
                                    ? '~${math.max(1, (distanceMeters! / 70).ceil())} mnt jalan kaki · $formattedDistance'
                                    : formattedDistance,
                                style: AppTypography.captionSmall.copyWith(
                                  color: isDark ? AppColors.goldPrimary : AppColors.espressoDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          if (poi.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              poi.subtitle!,
                              style: AppTypography.captionSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextBody
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Close button
                    if (onClose != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: isDark
                            ? AppColors.darkTextBody
                            : AppColors.tanMedium,
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _dismissWithAnimation(),
                      ),
                  ],
                ),

                // Tags chips (e.g. Ramah Lansia, Air Dingin, Bebas Biaya)
                if (poi.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: poi.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceContainer
                              : AppColors.canvasCream,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.espressoDark.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.textBody,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

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
                            color: isDark
                                ? AppColors.espressoDark
                                : AppColors.goldPrimary,
                          ),
                          label: Text(
                            'Rute Jalan Kaki',
                            style: AppTypography.labelLarge.copyWith(
                              color: isDark
                                  ? AppColors.espressoDark
                                  : Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.goldPrimary
                                : AppColors.espressoDark,
                            foregroundColor: isDark
                                ? AppColors.espressoDark
                                : Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.espressoDark.withValues(
                              alpha: 0.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.goldPrimary
                                    : AppColors.goldPrimary.withValues(
                                        alpha: 0.5,
                                      ),
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
                            color: isDark
                                ? AppColors.darkTextHeading
                                : AppColors.espressoDark,
                          ),
                          label: Text(
                            'Bagikan',
                            style: AppTypography.labelLarge.copyWith(
                              color: isDark
                                  ? AppColors.darkTextHeading
                                  : AppColors.espressoDark,
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
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
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
    ),
  );
}
}
