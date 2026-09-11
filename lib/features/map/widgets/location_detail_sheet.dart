import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/pill_button.dart';

class LocationDetailSheet extends StatelessWidget {
  const LocationDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceLg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusSheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppConstants.spaceLg),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
              ),
            ),
          ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.canvasCream,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(color: AppColors.goldLight),
                ),
                child: const Icon(Icons.mosque, color: AppColors.primaryContainer, size: 32),
              ),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Masjidil Haram', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
                    const SizedBox(height: 4),
                    Text('Jarak: 450m • Akses Kursi Roda Tersedia', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusPositive.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                      ),
                      child: Text('Sangat Ramai', style: AppTypography.captionBold.copyWith(color: AppColors.statusPositive, fontSize: 10)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceLg),
          
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'Rute',
                  icon: Icons.directions,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppConstants.spaceSm),
              Expanded(
                child: PillButton(
                  label: 'Simpan',
                  icon: Icons.bookmark_border,
                  onPressed: () {},
                  isOutline: true,
                  color: AppColors.goldLight,
                  textColor: AppColors.espressoDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationDetailSheet(),
    );
  }
}
