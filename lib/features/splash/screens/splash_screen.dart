import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_startup_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final startup = Get.find<AppStartupController>();

    final results = await Future.wait([
      startup.determineInitialRoute(),
      Future.delayed(const Duration(milliseconds: 2400)),
    ]);

    final destination = results.first as String;

    if (mounted) {
      Get.offAllNamed(destination);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F3),
      body: Stack(
        children: [
          // Background Gradient (Warm Luminous Canvas)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFCFAF6),
                    Color(0xFFF7F2E8),
                    Color(0xFFEFE7DB),
                  ],
                ),
              ),
            ),
          ),

          // Ambient Top Emerald Glow
          Positioned(
            top: -size.width * 0.25,
            left: -size.width * 0.1,
            right: -size.width * 0.1,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 0.94 + (_controller.value * 0.08);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                height: size.width * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emeraldIslamic.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),

          // Ambient Center-Bottom Mecca Gold Glow
          Positioned(
            bottom: -size.width * 0.35,
            left: -size.width * 0.2,
            right: -size.width * 0.2,
            child: Container(
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldPrimary.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  // Top Brand Pill Badge
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.emeraldIslamic,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'HAJICARE INDONESIA',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center Logo & Identity
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                final scale = 1.0 + (_controller.value * 0.02);
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: _buildLogo(),
                            ),

                            const SizedBox(height: 24),

                            // Arabic Calligraphy Text
                            Text(
                              'رِعَايَةُ الحَجِيجِ وَالمُعْتَمِرِينَ',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emeraldIslamic,
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // App Brand Name
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Haji',
                                    style: AppTypography.displayLarge.copyWith(
                                      color: AppColors.textHeading,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 34,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Care',
                                    style: AppTypography.displayLarge.copyWith(
                                      color: AppColors.goldPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 34,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Tagline
                            Text(
                              'Sahabat Setia & Amanah Ibadah Anda',
                              textAlign: TextAlign.center,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textBody,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Subtle Feature Subtitle
                            Text(
                              'Pendampingan Pintar • Radar Jarak Jauh • Bantuan Lansia',
                              textAlign: TextAlign.center,
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Progress Bar
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    child: Column(
                      children: [
                        Container(
                          width: 210,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: AppColors.goldPrimary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Memuat data...',
                                    style: AppTypography.captionSmall.copyWith(
                                      color: AppColors.textBody,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      final pct = 25 + ((_controller.value * 75).round());
                                      return Text(
                                        '$pct%',
                                        style: AppTypography.captionSmall.copyWith(
                                          color: AppColors.emeraldIslamic,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.canvasCream,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: 0.25 + (_controller.value * 0.75),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.emeraldIslamic,
                                                AppColors.goldPrimary,
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 14,
                              color: AppColors.emeraldIslamic,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Melayani Jamaah dengan Amanah & Ikhlas',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E1C12).withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          'assets/icon.jpeg',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.canvasCream,
              child: const Icon(
                Icons.mosque_rounded,
                size: 54,
                color: AppColors.goldPrimary,
              ),
            );
          },
        ),
      ),
    );
  }
}
