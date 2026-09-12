import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideSafety extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideSafety({super.key, this.activeIndex = 1});

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
              badgeText: 'Sistem Keselamatan Jamaah',
              stageText: 'TAHAP 2 DARI 3',
              title: 'Jaga Jarak Aman & Terpantau',
              icon: Icons.shield,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Stepper Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.canvasCream.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: _buildStepper(
                activeIndex: activeIndex,
                label: '2 DARI 3 TAHAP AWAL',
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            _buildSectionHeader(),

            const SizedBox(height: AppSpacing.lg),

            _buildFeatureCard(
              icon: Icons.near_me,
              title: 'Pendamping Aman',
              description:
                  'Pantau rombongan secara real-time dan terima peringatan otomatis saat terpisah melebihi batas aman.',
              badgeText: 'Radar Aktif',
              badgeColor: AppColors.espressoDark,
              badgeBgColor: AppColors.canvasCream,
            ),

            const SizedBox(height: AppSpacing.md),

            _buildFeatureCard(
              icon: Icons.map,
              title: 'Peta Terpadu & SOS',
              description:
                  'Temukan pos kesehatan, hotel, dan hubungi bantuan darurat hanya dengan satu sentuhan.',
              badgeText: 'SOS 24 Jam',
              badgeColor: AppColors.sosEmergency,
              badgeBgColor: AppColors.sosEmergency.withValues(alpha: .08),
              isSosBadge: true,
            ),

            const SizedBox(height: AppSpacing.md),

            _buildFeatureCard(
              icon: Icons.accessibility_new,
              title: 'Ramah Jamaah Lansia',
              description:
                  'Ukuran tombol besar, kontras tinggi, dan mudah digunakan di bawah terik matahari.',
              badgeText: 'Ramah Lansia',
              badgeColor: AppColors.espressoDark,
              badgeBgColor: AppColors.canvasCream,
            ),

            const SizedBox(height: AppSpacing.xl),

            _buildSafetyFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvasCream.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: AppColors.espressoDark),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitur Keselamatan Jamaah',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Teknologi pendampingan cerdas agar jamaah tetap aman dan terhubung selama ibadah.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
    bool isSosBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: .25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 20,
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
            child: Icon(icon, size: 28, color: AppColors.espressoDark),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTypography.captionSmall.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusPositive.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.statusPositive.withValues(alpha: .15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user,
            color: AppColors.statusPositive,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Notifikasi getar dan suara otomatis aktif untuk membantu jamaah tetap aman selama perjalanan.',
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
