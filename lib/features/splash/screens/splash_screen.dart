import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

import '../../../core/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Simulate loading and navigate
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Get.offNamed(AppRoutes.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.espressoDark,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.espressoDark,
                  AppColors.primaryContainer,
                  AppColors.primary,
                ],
              ),
            ),
          ),

          // Top ambient glow
          Positioned(
            top: -96,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldLight.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Status
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdgeGutter,
                    vertical: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.statusPositive,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm2),
                          Text(
                            'KONEKSI AMAN',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.canvasCreamSubtle,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.espressoDark.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.goldLight.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mosque,
                              size: 14,
                              color: AppColors.goldLight,
                            ),
                            const SizedBox(width: AppSpacing.sm2),
                            Text(
                              'Makkah Al-Mukarramah',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.canvasCream,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Identity
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Monogram Emblem
                      Container(
                        width: 144,
                        height: 144,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.goldLight.withValues(alpha: 0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  AppColors.accentGoldStar.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_controller.value * 0.04),
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                    colors: [
                                      AppColors.espressoDark,
                                      AppColors.primaryContainer,
                                      AppColors.secondary,
                                    ],
                                  ),
                                  border: Border.all(
                                    color:
                                        AppColors.goldLight.withValues(alpha: 0.4),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.shield,
                                    size: 40,
                                    color: AppColors.goldLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Arabic Calligraphy Text
                      Text(
                        'رِعَايَةُ الحَجِيجِ وَالمُعْتَمِرِينَ',
                        style: GoogleFonts.amiri(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldLight,
                        ),
                      ),

                      // App Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Haji',
                            style: AppTypography.displayLarge.copyWith(
                              color: AppColors.surfaceWhite,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Care',
                            style: AppTypography.displayLarge.copyWith(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.goldLight.withValues(alpha: 0.6),
                                    AppColors.goldLight,
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                Icons.star,
                                size: 12,
                                color: AppColors.accentGoldStar,
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.goldLight,
                                    AppColors.goldLight.withValues(alpha: 0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tagline
                      Text(
                        'Sahabat Setia & Amanah di Tanah Suci',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.canvasCream,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Pendampingan ramah lansia, keselamatan, dan aksesibilitas ibadah',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Loader
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.xl3,
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 220,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Menyiapkan Layanan',
                                  style: AppTypography.captionSmall.copyWith(
                                    color:
                                        AppColors.goldLight.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  'Harmoni',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: AppColors.goldLight
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                child: const LinearProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.goldLight,
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user,
                            color: AppColors.goldLight,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.sm2),
                          Text(
                            'Didukung oleh Inisiatif Pelayanan Jamaah',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.canvasCreamSubtle
                                  .withValues(alpha: 0.8),
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
        ],
      ),
    );
  }
}
