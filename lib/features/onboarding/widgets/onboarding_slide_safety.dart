import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideSafety extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideSafety({
    super.key,
    this.activeIndex = 1,
  });

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
            const SizedBox(height: AppSpacing.lg),

            // Stepper
            _buildStepper(activeIndex: activeIndex, label: '2 DARI 3 TAHAP AWAL'),
            const Divider(color: AppColors.surfaceContainer, height: 1),
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
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espressoDark.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield,
                      color: AppColors.espressoDark, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Fitur Keselamatan Jamaah',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                Text(
                  'Bisa diatur kapan saja',
                  style: AppTypography.caption.copyWith(color: AppColors.tanMedium),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56.0, top: 4),
              child: Text(
                'Teknologi pendampingan cerdas agar jamaah lansia dan keluarga tetap aman serta terhubung selama di Tanah Suci.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textBody),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Feature cards
            _buildFeatureCard(
              icon: Icons.near_me,
              title: 'Pendamping Aman (GPS & Radar)',
              description:
                  'Pantau rombongan secara real-time dan terima peringatan getar otomatis saat terpisah melebihi batas aman.',
              badgeText: 'Radar Aktif',
              badgeColor: AppColors.espressoDark,
              badgeBgColor: AppColors.canvasCream.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildFeatureCard(
              icon: Icons.map,
              title: 'Peta Terpadu & Tombol SOS',
              description:
                  'Akses mudah menuju pos kesehatan, hotel, dan panggil bantuan petugas maktab seketika hanya dengan satu sentuhan.',
              badgeText: 'SOS 24 Jam',
              badgeColor: AppColors.sosEmergency,
              badgeBgColor: AppColors.sosEmergency.withValues(alpha: 0.1),
              isSosBadge: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildFeatureCard(
              icon: Icons.accessibility_new,
              title: 'Dirancang Khusus Jamaah Lansia',
              description:
                  'Tampilan ramah satu jempol, tombol berjarak aman, dan kontras tajam nyaman di bawah terik matahari Mekkah.',
              badgeText: 'Ramah Lansia',
              badgeColor: AppColors.espressoDark,
              badgeBgColor: AppColors.canvasCream.withValues(alpha: 0.6),
            ),

            const SizedBox(height: AppSpacing.lg),
            // Accessibility hint footer
            Container(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.canvasCream)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.statusPositive, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Notifikasi getar & suara otomatis aktif',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textBody),
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
            style: AppTypography.captionSmall.copyWith(color: AppColors.tanMedium),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.goldLight.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              color: AppColors.canvasCream,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.espressoDark, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.espressoDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isSosBadge
                              ? AppColors.sosEmergency.withValues(alpha: 0.2)
                              : AppColors.goldLight.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSosBadge) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.sosEmergency,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            badgeText.toUpperCase(),
                            style: AppTypography.captionSmall.copyWith(
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
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
