import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/state/app_settings_controller.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideLanguage extends StatefulWidget {
  final int activeIndex;

  const OnboardingSlideLanguage({
    super.key,
    this.activeIndex = 0,
  });

  @override
  State<OnboardingSlideLanguage> createState() => _OnboardingSlideLanguageState();
}

class _OnboardingSlideLanguageState extends State<OnboardingSlideLanguage> {
  int _selectedLanguageIndex = 0;

  @override
  void initState() {
    super.initState();
    final current = Get.find<AppSettingsController>().currentLocale.languageCode;
    final idx = _languages.indexWhere((l) => l.$1 == current);
    if (idx != -1) {
      _selectedLanguageIndex = idx;
    }
  }

  // locale code, display title, subtitle, type badge
  static const List<(String, String, String, String)> _languages = [
    ('id', 'Bahasa Indonesia', 'Baku & Lengkap',    'Bahasa Utama'),
    ('jv', 'Basa Jawi',        'Unggah-ungguh',     'Daerah'),
    ('su', 'Basa Sunda',       'Lemes & Santun',    'Daerah'),
    ('en', 'English',          'Global Standard',   'Global'),
  ];

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
              badgeText: 'Akses Ramah Lansia',
              stageText: 'TAHAP 1 DARI 3',
              title: 'Pilih Bahasa Kenyamanan',
              icon: Icons.mosque,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Stepper indicator
            _buildStepper(activeIndex: widget.activeIndex, label: '1 DARI 3 TAHAP AWAL'),
            const Divider(color: AppColors.surfaceContainer, height: 1),
            const SizedBox(height: AppSpacing.lg),

            // Section intro header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.canvasCream,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.translate,
                      color: AppColors.espressoDark, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Bahasa Pengantar Aplikasi',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                Text(
                  'Bisa diubah kapan saja',
                  style: AppTypography.caption.copyWith(color: AppColors.tanMedium),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56.0, top: 4),
              child: Text(
                'Pilih bahasa yang paling mudah dipahami untuk kenyamanan ibadah dan komunikasi darurat Anda.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textBody),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2x2 Language Grid
            GridView.builder(
              itemCount: _languages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.55,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = _selectedLanguageIndex == index;
                return _buildLanguageCard(
                  title: lang.$2,
                  subtitle: lang.$3,
                  type: lang.$4,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedLanguageIndex = index);
                    // Immediately apply and persist the chosen language globally
                    Get.find<AppSettingsController>()
                        .setLocale(Locale(lang.$1));
                  },
                );
              },
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
                      'Ukuran teks & audio akan otomatis disesuaikan',
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

  Widget _buildLanguageCard({
    required String title,
    required String subtitle,
    required String type,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.espressoDark : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.espressoDark
                : AppColors.goldLight.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.canvasCream,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: AppTypography.captionSmall.copyWith(
                      color: isSelected
                          ? AppColors.accentGoldStar
                          : AppColors.tanMedium,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppColors.accentGoldStar, size: 20)
                else
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldLight, width: 2),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: isSelected
                        ? AppColors.surfaceWhite
                        : AppColors.textHeading,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? AppColors.canvasCream.withValues(alpha: 0.8)
                        : AppColors.textBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
