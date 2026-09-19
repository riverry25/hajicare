import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../features/translator/widgets/translator_sheet.dart';
import '../locales/app_localizations.dart';
import '../routes/app_routes.dart';
import '../state/hajicare_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class HajiCareBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const HajiCareBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (onTap != null) {
      onTap!(index);
      return;
    }

    // Fallback when used outside an IndexedStack shell.
    final hajicare = Get.find<HajiCareController>();

    final String route;

    switch (index) {
      case 0:
        route = hajicare.role == UserRole.admin
            ? AppRoutes.adminDashboard
            : hajicare.role == UserRole.jamaah
            ? AppRoutes.dashboardJamaah
            : AppRoutes.dashboardPendamping;
        break;

      case 1:
        route = AppRoutes.interactiveMap;
        break;

      case 2:
        route = AppRoutes.prayerTimes;
        break;

      case 3:
        route = AppRoutes.profile;
        break;

      default:
        return;
    }

    Get.offNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Main Navigation Dock Card with Scooped Notched Cradle
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: CustomPaint(
                  painter: _ScoopedNavBarPainter(
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.surfaceWhite,
                    borderColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.espressoDark.withValues(alpha: 0.06),
                    shadowColor: Colors.black.withValues(
                      alpha: isDark ? 0.35 : 0.08,
                    ),
                    cornerRadius: 30.0,
                    buttonRadius: 30.0,
                    buttonCenterY: 10.0,
                    notchMargin: 10.0,
                    shoulderWidth: 20.0,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 64),
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Tab 0: Beranda (Home)
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 0,
                            icon: Icons.home_rounded,
                            label: context.tr('navHome'),
                          ),
                        ),

                        // Tab 1: Peta (Map)
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 1,
                            icon: Icons.near_me_rounded,
                            label: context.tr('navMap'),
                          ),
                        ),

                        // Center Slot: Reserved generous gap for wide scooped cradle and mic button
                        const SizedBox(width: 96),

                        // Tab 2: Jadwal Salat (Prayer)
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 2,
                            icon: Icons.schedule_rounded,
                            label: context.tr('navPrayer'),
                          ),
                        ),

                        // Tab 3: Profil (Profile)
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 3,
                            icon: Icons.person_rounded,
                            label: context.tr('navProfile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Elevated Center Mic / Voice Translator Button nestled in the Scoop
              Positioned(
                top: -6,
                child: _buildCenterMicButton(context, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterMicButton(BuildContext context, bool isDark) {
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerHighest
        : AppColors.surfaceWhite;
    final iconColor = isDark ? AppColors.goldLight : AppColors.espressoDark;

    return Semantics(
      button: true,
      label: 'Penerjemah HajiCare',
      child: Tooltip(
        message: 'Penerjemah Suara (Voice Translator)',
        child: Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: surfaceColor,
            border: Border.all(
              color: isDark
                  ? AppColors.goldLight.withValues(alpha: 0.35)
                  : AppColors.goldLight.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.espressoDark)
                    .withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                HajiCareTranslatorSheet.show(context);
              },
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(Icons.mic_rounded, size: 28, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final isDark = AppColors.isDark(context);

    final selectedColor = isDark
        ? Theme.of(context).colorScheme.primary
        : AppColors.espressoDark;

    final unselectedColor = isDark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)
        : AppColors.textBody.withValues(alpha: 0.65);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleNavigation(context, index),
            borderRadius: BorderRadius.circular(AppRadius.md),
            splashColor: selectedColor.withValues(alpha: 0.1),
            highlightColor: selectedColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated pill indicator around icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 44 : 32,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                ? selectedColor.withValues(alpha: 0.16)
                                : AppColors.canvasCream)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: AnimatedScale(
                      scale: isSelected ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        icon,
                        size: 21,
                        color: isSelected ? selectedColor : unselectedColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Tab Label
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 10.5,
                        color: isSelected ? selectedColor : unselectedColor,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: isSelected ? -0.1 : 0,
                        height: 1.15,
                      ),
                    ),
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

/// Custom painter that draws a modern floating navbar with a mathematically
/// concentric circular scooped notch cradling the elevated center action button
/// with uniform margin all around.
class _ScoopedNavBarPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final double cornerRadius;
  final double buttonRadius;
  final double buttonCenterY;
  final double notchMargin;
  final double shoulderWidth;

  _ScoopedNavBarPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    this.cornerRadius = 24.0,
    this.buttonRadius = 24.0,
    this.buttonCenterY = 8.0,
    this.notchMargin = 8.0,
    this.shoulderWidth = 14.0,
  });

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final centerX = w / 2;

    final cradleRadius = buttonRadius + notchMargin;
    final cradleBottom = buttonCenterY + cradleRadius;
    final k = cradleRadius * 0.5522847;
    final shoulderX = cradleRadius + shoulderWidth;

    final path = Path();
    // Top-left start (after corner curve)
    path.moveTo(r, 0);

    // Flat line towards center notch left shoulder
    path.lineTo(centerX - shoulderX, 0);

    // Left shoulder: smooth transition from horizontal line to vertical cradle tangent
    path.cubicTo(
      centerX - (cradleRadius + shoulderWidth * 0.60),
      0,
      centerX - cradleRadius,
      buttonCenterY * 0.45,
      centerX - cradleRadius,
      buttonCenterY,
    );

    // Left cradle quadrant: true circular arc (radius = cradleRadius)
    path.cubicTo(
      centerX - cradleRadius,
      buttonCenterY + k,
      centerX - k,
      cradleBottom,
      centerX,
      cradleBottom,
    );

    // Right cradle quadrant: true circular arc (radius = cradleRadius)
    path.cubicTo(
      centerX + k,
      cradleBottom,
      centerX + cradleRadius,
      buttonCenterY + k,
      centerX + cradleRadius,
      buttonCenterY,
    );

    // Right shoulder: smooth transition from vertical cradle tangent to horizontal line
    path.cubicTo(
      centerX + cradleRadius,
      buttonCenterY * 0.45,
      centerX + (cradleRadius + shoulderWidth * 0.60),
      0,
      centerX + shoulderX,
      0,
    );

    // Flat line towards top-right corner
    path.lineTo(w - r, 0);

    // Top-right corner
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));

    // Right edge
    path.lineTo(w, h - r);

    // Bottom-right corner
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));

    // Bottom edge
    path.lineTo(r, h);

    // Bottom-left corner
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));

    // Left edge
    path.lineTo(0, r);

    // Top-left corner
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    // Ambient soft drop shadow
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path.shift(const Offset(0, 5)), shadowPaint);

    // Solid surface fill
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Delicate outline border
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ScoopedNavBarPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.buttonRadius != buttonRadius ||
        oldDelegate.buttonCenterY != buttonCenterY ||
        oldDelegate.notchMargin != notchMargin ||
        oldDelegate.shoulderWidth != shoulderWidth;
  }
}
