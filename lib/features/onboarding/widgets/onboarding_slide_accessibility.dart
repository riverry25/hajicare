import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideAccessibility extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideAccessibility({super.key, this.activeIndex = 2});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OnboardingHeroBanner(
              badgeText: 'Aksesibilitas Ramah Lansia & Disabilitas',
              stageText: 'TAHAP 3 DARI 3',
              title: 'Mudah Diakses Siapa Saja',
              icon: Icons.accessibility_new,
              height: 180,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Stepper
            _buildStepper(
              activeIndex: activeIndex,
              label: '3 DARI 3 TAHAP AWAL',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section intro header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.canvasCream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Fitur Kemudahan Ibadah',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Bisa disesuaikan',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.tanMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm2),
            Text(
              'Bantuan cerdas deteksi uang riyal dan komunikasi suara & isyarat untuk kelancaran ibadah jamaah lansia dan berkebutuhan khusus.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Feature Card 1: Scan Uang Riyal
            _buildSlide3FeatureCard(
              icon: Icons.payments_outlined,
              title: 'Scan Uang Riyal',
              description:
                  'Arahkan kamera ke lembaran riyal, nominal langsung terdeteksi dan dibacakan otomatis via suara (Text-to-Speech).',
            ),
            const SizedBox(height: AppSpacing.md),

            // Feature Card 2: Komunikasi & Isyarat
            _buildSlide3FeatureCard(
              icon: Icons.mic_outlined,
              title: 'Komunikasi & Isyarat',
              description:
                  'Konversi bicara ke teks besar serta ungkapan darurat cepat (Tolong, Sakit, Air) yang mudah dimengerti warga lokal.',
              badgeText: 'SUARA & TEKS',
            ),

            const SizedBox(height: AppSpacing.lg),

            // Checklist indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.statusPositive.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.statusPositive.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.statusPositive,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Text-to-Speech siap digunakan',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textHeading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper({required int activeIndex, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = activeIndex == index;
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 32 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.espressoDark
                        : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              );
            }),
          ),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.tanMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide3FeatureCard({
    required IconData icon,
    required String title,
    required String description,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.espressoDark.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.canvasCream,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Icon(icon, color: AppColors.primaryContainer, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textHeading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.canvasCream,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.surfaceContainerHigh,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.tanMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textBody,
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
