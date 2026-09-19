import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideLanguage extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideLanguage({super.key, this.activeIndex = 0});

  // locale code, display title, subtitle, type badge
  static const List<(String, String, String, String)> _languages = [
    ('id', 'Indonesia', 'Baku & Lengkap', 'Bahasa Utama'),
    ('jv', 'Basa Jawi', 'Unggah-ungguh', 'Daerah'),
    ('su', 'Basa Sunda', 'Lemes & Santun', 'Daerah'),
    ('en', 'English', 'Global Standard', 'Global'),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
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
              badgeText: 'Akses Ramah Lansia',
              stageText: 'TAHAP 1 DARI 3',
              title: 'Pilih Bahasa Kenyamanan',
              icon: Icons.mosque,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Stepper indicator
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.canvasCream.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _buildStepper(
                activeIndex: activeIndex,
                label: '1 DARI 3 TAHAP AWAL',
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Section intro header
            _buildLanguageHeader(),

            const SizedBox(height: AppSpacing.lg),

            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Text(
                'Pilih bahasa yang paling mudah dipahami untuk kenyamanan ibadah dan komunikasi darurat Anda.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textBody,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 2x2 Language Grid
            Obx(() {
              final currentCode = settings.currentLocale.languageCode;

              return GridView.builder(
                itemCount: _languages.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = currentCode == lang.$1;

                  return _buildLanguageCard(
                    title: lang.$2,
                    subtitle: lang.$3,
                    type: lang.$4,
                    isSelected: isSelected,
                    onTap: () {
                      settings.setLocale(Locale(lang.$1));
                    },
                  );
                },
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // Accessibility hint footer
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
                    Icons.volume_up_rounded,
                    color: AppColors.statusPositive,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Ukuran teks dan panduan audio akan otomatis disesuaikan dengan bahasa yang dipilih.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.espressoDark.withValues(alpha: 0.5),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.tanMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icons.translate,
              size: 26,
              color: AppColors.espressoDark,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bahasa Pengantar',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.espressoDark,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Pilih bahasa yang paling mudah dipahami selama ibadah.',
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

  Widget _buildLanguageCard({
    required String title,
    required String subtitle,
    required String type,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.lightCardBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.goldPrimary.withValues(alpha: 0.15)
                        : AppColors.canvasCream,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    type,
                    style: AppTypography.captionSmall.copyWith(
                      color: isSelected
                          ? AppColors.espressoDark
                          : AppColors.textBody,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey(true),
                          color: AppColors.statusSafe,
                          size: 22,
                        )
                      : const Icon(
                          Icons.radio_button_unchecked_rounded,
                          key: ValueKey(false),
                          color: AppColors.tanMedium,
                          size: 22,
                        ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.espressoDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: AppColors.textBody),
            ),
          ],
        ),
      ),
    );
  }
}
