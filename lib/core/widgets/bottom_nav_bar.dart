import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter/services.dart';

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
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // Surface navbar card.
                    // Everything outside this card is 100% transparent,
                    // so the underlying page background flows uninterrupted.
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.surfaceWhite,
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 0,
                            icon: Icons.home_rounded,
                            label: context.tr('navHome'),
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 1,
                            icon: Icons.near_me_rounded,
                            label: context.tr('navMap'),
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 2,
                            icon: Icons.schedule_rounded,
                            label: context.tr('navPrayer'),
                          ),
                        ),
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
              Positioned(
                top: 0,
                child: _buildCenterMicButton(context, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterMicButton(BuildContext context, bool isDark) {
    final primaryColor = isDark
        ? Theme.of(context).colorScheme.primary
        : AppColors.espressoDark;
    final iconColor = isDark
        ? AppColors.darkOnPrimary
        : Colors.white;

    return Semantics(
      button: true,
      label: 'Penerjemah HajiCare',
      child: Tooltip(
        message: 'Penerjemah HajiCare',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              HajiCareTranslatorSheet.show(context);
            },
            customBorder: const CircleBorder(),
            child: Ink(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppColors.goldLight.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.mic_rounded,
                  size: 24,
                  color: iconColor,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedColor = isDark
        ? Theme.of(context).colorScheme.primary
        : AppColors.espressoDark;

    final unselectedColor = isDark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62)
        : AppColors.textBody.withValues(alpha: 0.72);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => _handleNavigation(context, index),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                        ? selectedColor.withValues(alpha: 0.14)
                        : AppColors.canvasCream)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 42 : 32,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedColor.withValues(alpha: isDark ? 0.14 : 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    icon,
                    size: isSelected ? 23 : 22,
                    color: isSelected ? selectedColor : unselectedColor,
                  ),
                ),
                const SizedBox(height: 2),

                // Flexible prevents long translated labels from
                // causing overflow when text scaling is increased.
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.captionSmall.copyWith(
                      color: isSelected ? selectedColor : unselectedColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
