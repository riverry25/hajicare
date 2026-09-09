import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

class MoneyRecognitionScreen extends StatelessWidget {
  const MoneyRecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Camera Feed
          Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Icon(Icons.camera_alt, color: Colors.white24, size: 100),
            ),
          ),
          
          // Camera Guide Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceMd,
                    vertical: AppConstants.spaceSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Pindai Uang Riyal',
                        style: AppTypography.headlineMd.copyWith(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flash_off, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Scanning Frame
                Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.goldLight.withOpacity(0.8), width: 3),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Stack(
                    children: [
                      // Scanning line animation placeholder
                      Center(
                        child: Container(
                          width: double.infinity,
                          height: 2,
                          color: AppColors.statusPositive,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppConstants.spaceLg),
                Text(
                  'Arahkan kamera ke uang kertas',
                  style: AppTypography.bodyMd.copyWith(color: Colors.white),
                ),
                
                const Spacer(),
                
                // Result Panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.spaceLg),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusSheet)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppConstants.spaceLg),
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.statusPositive, size: 28),
                          const SizedBox(width: AppConstants.spaceSm),
                          Text('Terdeteksi', style: AppTypography.titleSm.copyWith(color: AppColors.statusPositive)),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spaceSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('50', style: AppTypography.displayHero.copyWith(color: AppColors.espressoDark, fontSize: 64)),
                          const SizedBox(width: 8),
                          Text('Riyal', style: AppTypography.headlineLg.copyWith(color: AppColors.tanMedium)),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spaceXs),
                      Text('Lima Puluh Riyal Saudi', style: AppTypography.bodyLg.copyWith(color: AppColors.textBody)),
                      const SizedBox(height: AppConstants.spaceLg),
                      
                      // Audio Feedback Button
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                        ),
                        child: const Icon(Icons.volume_up, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: AppConstants.spaceSm),
                      Text('Ulangi Suara', style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
