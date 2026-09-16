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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.canvasCream.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _buildStepper(
                activeIndex: activeIndex,
                label: '3 DARI 3 TAHAP AWAL',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section intro header
            _buildAccessibilityHeader(),
            const SizedBox(height: AppSpacing.sm),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusPositive.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.statusPositive.withValues(alpha: .15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.record_voice_over_rounded,
                    color: AppColors.statusPositive,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Text-to-Speech dan bantuan suara siap digunakan untuk membantu jamaah selama perjalanan ibadah.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textBody,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildAccessibilityHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.canvasCream.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.accessibility_new,
              size: 28,
              color: AppColors.primaryContainer,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitur Kemudahan',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.espressoDark.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Membantu jamaah lansia dan disabilitas beribadah lebih nyaman.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.espressoDark.withValues(alpha: 0.5),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: .25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.canvasCream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: AppColors.primaryContainer),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(badgeText, style: AppTypography.captionSmall),
                  ),

                if (badgeText != null) const SizedBox(height: 10),

                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.espressoDark.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.espressoDark.withValues(alpha: 0.5),
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
