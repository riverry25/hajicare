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
      backgroundColor: AppColors.distanceWarning,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
                padding: const EdgeInsets.all(AppConstants.spaceLg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSheet),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning Icon with double ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.distanceWarning.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.distanceWarning.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.distanceWarning,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.distanceWarning.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.radar, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spaceMd),

                    // Label pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.espressoDark,
                        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                      ),
                      child: Text(
                        'PERINGATAN JARAK LANSIA',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.surfaceWhite,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceSm),

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

                    // Distance metric
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spaceMd),
                      decoration: BoxDecoration(
                        color: AppColors.canvasCream.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                        border: Border.all(color: AppColors.distanceWarning.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '245',
                                style: AppTypography.displayHero.copyWith(
                                  color: AppColors.distanceWarning,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('meter', style: AppTypography.titleSm.copyWith(color: AppColors.textBody)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.sosEmergency.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                                ),
                                child: Text(
                                  '45m melebihi batas aman',
                                  style: AppTypography.captionBold.copyWith(color: AppColors.sosEmergency, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceLg),

                    // Buttons
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.espressoDark,
                        foregroundColor: AppColors.surfaceWhite,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions, size: 20),
                          const SizedBox(width: AppConstants.spaceXs),
                          Text('Lihat Arah Kembali', style: AppTypography.labelPill.copyWith(color: AppColors.surfaceWhite)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceSm),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.espressoDark,
                        side: const BorderSide(color: AppColors.goldLight, width: 2),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.call, size: 20, color: AppColors.tanMedium),
                          const SizedBox(width: AppConstants.spaceXs),
                          Text('Telepon Pendamping', style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
