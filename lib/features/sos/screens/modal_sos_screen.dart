import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/pill_button.dart';

class ModalSosScreen extends StatelessWidget {
  const ModalSosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.espressoDark.withOpacity(0.9), // Dark overlay
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(AppConstants.spaceLg),
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            boxShadow: [
              BoxShadow(
                color: AppColors.sosEmergency.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing SOS Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.sosEmergency.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.sosEmergency,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sosEmergency.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emergency_share, color: Colors.white, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spaceMd),
              
              Text(
                'Konfirmasi Darurat SOS',
                style: AppTypography.headlineLg.copyWith(color: AppColors.espressoDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spaceXs),
              Text(
                'Apakah Anda benar-benar membutuhkan bantuan medis atau tersesat? Sinyal akan dikirim ke Petugas Maktab dan Pendamping.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textBody),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spaceLg),
              
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Batal',
                      onPressed: () => Navigator.of(context).pop(),
                      isOutline: true,
                      color: AppColors.outline,
                      textColor: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceSm),
                  Expanded(
                    child: PillButton(
                      label: 'Kirim SOS',
                      onPressed: () {
                        // Demo sent logic
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sinyal SOS telah dikirim. Bantuan sedang dalam perjalanan.'),
                            backgroundColor: AppColors.statusPositive,
                          ),
                        );
                      },
                      color: AppColors.sosEmergency,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
