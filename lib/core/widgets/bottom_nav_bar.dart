import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';

class HajiCareBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const HajiCareBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusMd)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceXs, vertical: AppConstants.spaceXs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Beranda'),
              _buildNavItem(1, Icons.near_me_rounded, 'Peta & Arah'),
              _buildNavItem(2, Icons.schedule_rounded, 'Jadwal'),
              _buildNavItem(3, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: AppConstants.spaceXs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.canvasCream : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusPill),
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
              style: AppTypography.captionBold.copyWith(
                color: isSelected ? AppColors.espressoDark : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
