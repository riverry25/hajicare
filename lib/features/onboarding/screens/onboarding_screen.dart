import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

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
            // Header (identical across all 3 slides per Stitch)
            Padding(
              padding: const EdgeInsets.only(
                left: AppConstants.spaceMd,
                right: AppConstants.spaceMd,
                top: AppConstants.spaceMd,
                bottom: AppConstants.spaceXs,
              ),
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
                  // Skip button: pill with border, matching Stitch
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/login'),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceWhite,
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spaceMd,
                        vertical: AppConstants.spaceXs,
                      ),
                      side: BorderSide(
                          color: AppColors.goldLight.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusPill),
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

            // Footer (matches Stitch bottom tray)
            Container(
              padding: const EdgeInsets.only(
                left: AppConstants.spaceMd,
                right: AppConstants.spaceMd,
                top: AppConstants.spaceXs,
                bottom: AppConstants.spaceLg,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.radiusSm)),
                border: Border(
                  top: BorderSide(
                      color: AppColors.goldLight.withValues(alpha: 0.2)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Primary CTA button (52px, pill, espressoDark bg)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.espressoDark,
                        foregroundColor: AppColors.surfaceWhite,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusPill),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 0
                                ? 'Lanjut ke Pengenalan Fitur'
                                : _currentPage == 1
                                    ? 'Lanjut ke Fitur Aksesibilitas'
                                    : 'Mulai Sekarang',
                            style: AppTypography.labelPill.copyWith(
                              color: AppColors.surfaceWhite,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spaceXs),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceXs),
                  // Bottom step indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user,
                          size: 14, color: AppColors.accentGoldStar),
                      const SizedBox(width: 6),
                      Text(
                        'Langkah ${_currentPage + 1} dari 3 Menuju Perjalanan Aman Anda',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textBody),
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

  // ── Slide 1: Pilih Bahasa ─────────────────────────────────────────
  Widget _buildSlide1() {
    return _buildSlideContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner with gradient overlay (matches Stitch)
            _buildHeroBanner(
              badgeText: 'Akses Ramah Lansia',
              stageText: 'TAHAP 1 DARI 3',
              title: 'Pilih Bahasa Kenyamanan',
            ),
            const SizedBox(height: AppConstants.spaceMd),

            // Stepper indicator
            _buildStepper(activeIndex: 0, label: '1 DARI 3 TAHAP AWAL'),
            const Divider(color: AppColors.surfaceContainer, height: 1),
            const SizedBox(height: AppConstants.spaceMd),

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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bahasa Pengantar Aplikasi',
                    style: AppTypography.titleSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                Text(
                  'Bisa diubah kapan saja',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.tanMedium),
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

            // 2x2 Language Grid (min-h 96px per card, rounded-DEFAULT = 16px)
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.spaceSm,
              mainAxisSpacing: AppConstants.spaceSm,
              childAspectRatio: 1.6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildLanguageCard(
                    'Bahasa Indonesia', 'Baku & Lengkap', 'Bahasa Utama', true),
                _buildLanguageCard(
                    'Basa Jawi', 'Unggah-ungguh', 'Daerah', false),
                _buildLanguageCard(
                    'Basa Sunda', 'Lemes & Santun', 'Daerah', false),
                _buildLanguageCard(
                    'العربية / English', 'Dual Global', 'Global', false),
              ],
            ),

            const SizedBox(height: AppConstants.spaceMd),
            // Accessibility hint footer
            Container(
              padding: const EdgeInsets.only(top: AppConstants.spaceXs),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.canvasCream)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.statusPositive, size: 18),
                  const SizedBox(width: AppConstants.spaceXs),
                  Expanded(
                    child: Text(
                      'Ukuran teks & audio akan otomatis disesuaikan',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textBody, fontSize: 12),
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

  // ── Slide 2: Fitur Keselamatan ────────────────────────────────────
  Widget _buildSlide2() {
    return _buildSlideContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner with gradient (matches Stitch Slide 2)
            _buildHeroBanner(
              badgeText: 'Sistem Keselamatan Jamaah',
              stageText: 'TAHAP 2 DARI 3',
              title: 'Jaga Jarak Aman & Terpantau',
            ),
            const SizedBox(height: AppConstants.spaceMd),

            // Stepper
            _buildStepper(activeIndex: 1, label: '2 DARI 3 TAHAP AWAL'),
            const Divider(color: AppColors.surfaceContainer, height: 1),
            const SizedBox(height: AppConstants.spaceMd),

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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fitur Keselamatan Jamaah',
                    style: AppTypography.titleSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                Text(
                  'Bisa diatur kapan saja',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.tanMedium),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56.0, top: 4),
              child: Text(
                'Teknologi pendampingan cerdas agar jamaah lansia dan keluarga tetap aman serta terhubung selama di Tanah Suci.',
                style: AppTypography.bodySm.copyWith(color: AppColors.textBody),
              ),
            ),
            const SizedBox(height: AppConstants.spaceMd),

            // Feature cards (vertical list, matching Stitch)
            _buildFeatureCard(
              icon: Icons.near_me,
              title: 'Pendamping Aman (GPS & Radar)',
              description:
                  'Pantau rombongan secara real-time dan terima peringatan getar otomatis saat terpisah melebihi batas aman.',
              badgeText: 'Radar Aktif',
              badgeColor: AppColors.espressoDark,
              badgeBgColor: AppColors.canvasCream.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppConstants.spaceSm),
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
            const SizedBox(height: AppConstants.spaceSm),
            _buildFeatureCard(
              icon: Icons.accessibility_new,
              title: 'Dirancang Khusus Jamaah Lansia',
              description:
                  'Tampilan ramah satu jempol, tombol berjarak aman, dan kontras tajam nyaman di bawah terik matahari Mekkah.',
              badgeText: 'Ramah Lansia',
              badgeColor: AppColors.espressoDark,
              badgeBgColor: AppColors.canvasCream.withValues(alpha: 0.6),
            ),

            const SizedBox(height: AppConstants.spaceMd),
            // Accessibility hint footer
            Container(
              padding: const EdgeInsets.only(top: AppConstants.spaceXs),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.canvasCream)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.statusPositive, size: 18),
                  const SizedBox(width: AppConstants.spaceXs),
                  Expanded(
                    child: Text(
                      'Notifikasi getar & suara otomatis aktif',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textBody, fontSize: 12),
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

  // ── Slide 3: Fitur Aksesibilitas ──────────────────────────────────
  Widget _buildSlide3() {
    return _buildSlideContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner (Slide 3 uses rounded-2xl = 32px, h-48 = 192px)
            _buildHeroBanner(
              badgeText: 'Aksesibilitas Ramah Lansia & Disabilitas',
              stageText: 'TAHAP 3 DARI 3',
              title: 'Mudah Diakses Siapa Saja',
              height: 192,
              borderRadius: AppConstants.radiusCard,
            ),
            const SizedBox(height: AppConstants.spaceMd),

            // Stepper (Slide 3 has a bordered badge variant)
            _buildStepper(activeIndex: 2, label: '3 DARI 3 TAHAP AWAL'),
            const SizedBox(height: AppConstants.spaceMd),

            // Section intro header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.canvasCream,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceContainerHigh,
                    ),
                  ),
                  child: const Icon(Icons.person,
                      color: AppColors.primaryContainer, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fitur Kemudahan Ibadah',
                    style: AppTypography.headlineMd.copyWith(
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
            const SizedBox(height: AppConstants.spaceXs),
            Text(
              'Bantuan cerdas deteksi uang riyal dan komunikasi suara & isyarat untuk kelancaran ibadah jamaah lansia dan berkebutuhan khusus.',
              style: AppTypography.bodySm.copyWith(color: AppColors.textBody),
            ),
            const SizedBox(height: AppConstants.spaceMd),

            // Feature Card 1: Scan Uang Riyal
            _buildSlide3FeatureCard(
              icon: Icons.payments_outlined,
              title: 'Scan Uang Riyal',
              description:
                  'Arahkan kamera ke lembaran riyal, nominal langsung terdeteksi dan dibacakan otomatis via suara (Text-to-Speech).',
            ),
            const SizedBox(height: AppConstants.spaceMd),

            // Feature Card 2: Komunikasi & Isyarat
            _buildSlide3FeatureCard(
              icon: Icons.mic_outlined,
              title: 'Komunikasi & Isyarat',
              description:
                  'Konversi bicara ke teks besar serta ungkapan darurat cepat (Tolong, Sakit, Air) yang mudah dimengerti warga lokal.',
              badgeText: 'SUARA & TEKS',
            ),

            const SizedBox(height: AppConstants.spaceMd),

            // Checklist indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: const Icon(Icons.check,
                      size: 14, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pembaca suara (Text-to-Speech) siap digunakan',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textHeading,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Components ─────────────────────────────────────────────

  /// Hero banner with gradient overlay, floating badge, stage text, and title
  Widget _buildHeroBanner({
    required String badgeText,
    required String stageText,
    required String title,
    double height = 160,
    double borderRadius = 16.0,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.canvasCreamSubtle,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Placeholder background (would be image from Stitch)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.espressoDark,
              ),
              child: Center(
                child: Icon(
                  _currentPage == 0
                      ? Icons.mosque
                      : _currentPage == 1
                          ? Icons.shield
                          : Icons.accessibility_new,
                  color: AppColors.surfaceWhite.withValues(alpha: 0.15),
                  size: 80,
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.espressoDark.withValues(alpha: 0.30),
                    AppColors.espressoDark.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Floating badge top-left
            Positioned(
              top: AppConstants.spaceSm,
              left: AppConstants.spaceSm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  border: Border.all(
                      color: AppColors.goldLight.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                      badgeText.toUpperCase(),
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.espressoDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom text overlay
            Positioned(
              bottom: AppConstants.spaceSm,
              left: AppConstants.spaceSm,
              right: AppConstants.spaceSm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stageText,
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.accentGoldStar,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.surfaceWhite,
                      fontWeight: FontWeight.w700,
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

  /// Stepper row with 3 dots and label
  Widget _buildStepper({required int activeIndex, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(3, (index) {
              bool isActive = _currentPage == index;
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
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusPill),
                  ),
                ),
              );
            }),
          ),
          Text(
            label,
            style:
                AppTypography.captionBold.copyWith(color: AppColors.tanMedium),
          ),
        ],
      ),
    );
  }

  /// Slide container (hero card) matching Stitch section wrapper
  Widget _buildSlideContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceMd,
        vertical: AppConstants.spaceXs,
      ),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16), // rounded-lg = 2rem in Stitch but 16px maps well
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
      child: child,
    );
  }

  /// Language card for Slide 1 grid (matches Stitch language option)
  Widget _buildLanguageCard(
      String title, String subtitle, String type, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.espressoDark : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16), // rounded-DEFAULT = 1rem
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.canvasCream,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusPill),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: AppTypography.captionBold.copyWith(
                    color: isSelected
                        ? AppColors.accentGoldStar
                        : AppColors.tanMedium,
                    fontSize: 11,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: AppColors.accentGoldStar, size: 22)
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.goldLight, width: 2),
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
                  color: isSelected
                      ? AppColors.surfaceWhite
                      : AppColors.textHeading,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? AppColors.canvasCream.withValues(alpha: 0.8)
                      : AppColors.textBody,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Feature card for Slide 2 (horizontal layout with icon circle, title, badge, description)
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
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.goldLight.withValues(alpha: 0.4), width: 2),
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
          const SizedBox(width: AppConstants.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.headlineMd.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.espressoDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusPill),
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
                            style: AppTypography.captionBold.copyWith(
                              color: badgeColor,
                              fontSize: 10,
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
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textBody,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Feature card for Slide 3 (rounded-2xl, card-shadow style)
  Widget _buildSlide3FeatureCard({
    required IconData icon,
    required String title,
    required String description,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
            color: AppColors.espressoDark.withValues(alpha: 0.1)),
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
          const SizedBox(width: AppConstants.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleSm.copyWith(
                          color: AppColors.textHeading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.canvasCream,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusPill),
                          border: Border.all(
                              color: AppColors.surfaceContainerHigh),
                        ),
                        child: Text(
                          badgeText,
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.tanMedium,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySm.copyWith(
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
