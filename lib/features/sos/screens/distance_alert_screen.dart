import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/pill_button.dart';

class DistanceAlertScreen extends StatelessWidget {
  const DistanceAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.distanceWarning, // Bright orange background for alert
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(AppConstants.spaceLg),
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppConstants.radiusCard),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDark.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.distanceWarning.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: AppColors.distanceWarning,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceMd),
                
                Text(
                  'PERINGATAN JARAK',
                  style: AppTypography.labelPill.copyWith(color: AppColors.distanceWarning, letterSpacing: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spaceXs),
                Text(
                  'Anda Terlalu Jauh',
                  style: AppTypography.displayHero.copyWith(color: AppColors.espressoDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spaceSm),
                Text(
                  'Jarak Anda dari Pendamping (Siti Aminah) telah melebihi batas aman 200 meter. Harap segera kembali ke rombongan.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textBody),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spaceLg),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('245', style: AppTypography.displayHero.copyWith(color: AppColors.distanceWarning, fontSize: 48)),
                    const SizedBox(width: 8),
                    Text('meter', style: AppTypography.titleSm.copyWith(color: AppColors.textBody)),
                  ],
                ),
                const SizedBox(height: AppConstants.spaceLg),
                
                PillButton(
                  label: 'Lihat Arah Kembali',
                  icon: Icons.directions,
                  onPressed: () => Navigator.of(context).pop(), // Just pop the demo
                  color: AppColors.espressoDark,
                  textColor: Colors.white,
                ),
                const SizedBox(height: AppConstants.spaceSm),
                PillButton(
                  label: 'Telepon Pendamping',
                  icon: Icons.call,
                  onPressed: () {},
                  isOutline: true,
                  color: AppColors.goldLight,
                  textColor: AppColors.espressoDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
