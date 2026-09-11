import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../routes/app_routes.dart';
import '../state/hajicare_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class HajiCareBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const HajiCareBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (onTap != null) {
      onTap!(index);
    }

    String route;
    switch (index) {
      case 0:
        final state = Provider.of<HajiCareState>(context, listen: false);
        route = state.role == UserRole.jamaah
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

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm2,
            vertical: AppSpacing.sm2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_rounded, 'Beranda'),
              _buildNavItem(context, 1, Icons.near_me_rounded, 'Peta & Arah'),
              _buildNavItem(context, 2, Icons.schedule_rounded, 'Jadwal'),
              _buildNavItem(context, 3, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => _handleNavigation(context, index),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.canvasCream : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.espressoDark : AppColors.textBody,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: isSelected ? AppColors.espressoDark : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
