import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/pill_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppConstants.spaceMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.espressoDark,
                        ),
                        child: const Icon(
                          Icons.mosque,
                          color: AppColors.canvasCream,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spaceXs),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HajiCare',
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Pendamping Keselamatan & Aksesibilitas',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.tanMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceWhite,
                      side: BorderSide(color: AppColors.goldLight.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                      ),
                    ),
                    child: Text(
                      'Lewati',
                      style: AppTypography.labelPill.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildSlide1(),
                  _buildSlide2(),
                  _buildSlide3(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceMd,
                vertical: AppConstants.spaceLg,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusSm)),
                border: Border.all(color: AppColors.goldLight.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  PillButton(
                    label: _currentPage == 2 ? 'Mulai Sekarang' : 'Lanjut ke Pengenalan Fitur',
                    icon: _currentPage == 2 ? Icons.check : Icons.arrow_forward,
                    onPressed: _nextPage,
                  ),
                  const SizedBox(height: AppConstants.spaceXs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user, size: 14, color: AppColors.accentGoldStar),
                      const SizedBox(width: 6),
                      Text(
                        'Langkah ${_currentPage + 1} dari 3 Menuju Perjalanan Aman Anda',
                        style: AppTypography.caption.copyWith(color: AppColors.textBody),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide1() {
    return _buildSlideContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.canvasCreamSubtle,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: AppConstants.spaceSm,
                  left: AppConstants.spaceSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                      border: Border.all(color: AppColors.goldLight.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.statusPositive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AKSES RAMAH LANSIA',
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.espressoDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: AppConstants.spaceSm,
                  left: AppConstants.spaceSm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAHAP 1 DARI 3',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.accentGoldStar, // Assuming dark background for banner
                        ),
                      ),
                      Text(
                        'Pilih Bahasa Kenyamanan',
                        style: AppTypography.headlineMd.copyWith(
                          color: AppColors.surfaceWhite, // Assuming dark background for banner
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          
          // Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildDot(0),
                  const SizedBox(width: 8),
                  _buildDot(1),
                  const SizedBox(width: 8),
                  _buildDot(2),
                ],
              ),
              Text(
                '1 DARI 3 TAHAP AWAL',
                style: AppTypography.captionBold.copyWith(color: AppColors.tanMedium),
              ),
            ],
          ),
          const Divider(color: AppColors.surfaceContainer),
          const SizedBox(height: AppConstants.spaceSm),
          
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.canvasCream,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.translate, color: AppColors.espressoDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bahasa Pengantar Aplikasi',
                  style: AppTypography.titleSm,
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
              style: AppTypography.bodySm.copyWith(color: AppColors.textBody),
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.spaceSm,
              mainAxisSpacing: AppConstants.spaceSm,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildLanguageCard('Bahasa Indonesia', 'Baku & Lengkap', 'Bahasa Utama', true),
                _buildLanguageCard('Basa Jawi', 'Unggah-ungguh', 'Daerah', false),
                _buildLanguageCard('Basa Sunda', 'Lemes & Santun', 'Daerah', false),
                _buildLanguageCard('العربية / English', 'Dual Global', 'Global', false),
              ],
            ),
          ),

          const Divider(color: AppColors.canvasCream),
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.statusPositive, size: 18),
              const SizedBox(width: AppConstants.spaceXs),
              Text(
                'Ukuran teks & audio akan otomatis disesuaikan',
                style: AppTypography.caption.copyWith(color: AppColors.textBody),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlide2() {
    return _buildSlideContainer(
      child: Center(
        child: Text(
          'Slide 2: Keamanan (Placeholder)',
          style: AppTypography.headlineMd,
        ),
      ),
    );
  }

  Widget _buildSlide3() {
    return _buildSlideContainer(
      child: Center(
        child: Text(
          'Slide 3: Navigasi (Placeholder)',
          style: AppTypography.headlineMd,
        ),
      ),
    );
  }

  Widget _buildSlideContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.spaceMd),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: AppColors.goldLight.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDot(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 32 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? AppColors.espressoDark : AppColors.outlineVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
      ),
    );
  }

  Widget _buildLanguageCard(String title, String subtitle, String type, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.espressoDark : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(
          color: isSelected ? AppColors.espressoDark : AppColors.goldLight.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.espressoDark.withOpacity(0.2),
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
                  color: isSelected ? AppColors.primaryContainer : AppColors.canvasCream,
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: AppTypography.captionBold.copyWith(
                    color: isSelected ? AppColors.accentGoldStar : AppColors.tanMedium,
                    fontSize: 9,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.accentGoldStar, size: 22)
              else
                Container(
                  width: 20,
                  height: 20,
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
                style: AppTypography.headlineMd.copyWith(
                  color: isSelected ? AppColors.surfaceWhite : AppColors.textHeading,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: isSelected ? AppColors.canvasCream.withOpacity(0.8) : AppColors.textBody,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
