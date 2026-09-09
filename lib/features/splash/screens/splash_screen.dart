import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    // Simulate loading
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Navigate to onboarding next
        Navigator.of(context).pushReplacementNamed('/onboarding');
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
          // Background Gradient & Pattern
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
          
          // Ornaments
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
                  color: AppColors.goldLight.withOpacity(0.1),
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
                    horizontal: AppConstants.spaceLg,
                    vertical: AppConstants.spaceXl,
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
                          const SizedBox(width: AppConstants.spaceXs),
                          Text(
                            'KONEKSI AMAN',
                            style: AppTypography.captionBold.copyWith(
                              color: AppColors.canvasCreamSubtle,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spaceSm,
                          vertical: AppConstants.space2xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.espressoDark.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                          border: Border.all(color: AppColors.goldLight.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mosque, size: 14, color: AppColors.goldLight),
                            const SizedBox(width: AppConstants.spaceXs),
                            Text(
                              'Makkah Al-Mukarramah',
                              style: AppTypography.caption.copyWith(color: AppColors.canvasCream),
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
                          border: Border.all(color: AppColors.goldLight.withOpacity(0.3)),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentGoldStar.withOpacity(0.4),
                              style: BorderStyle.solid, // Should be dashed but solid for simplicity
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
                                  border: Border.all(color: AppColors.goldLight.withOpacity(0.4)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
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
                      const SizedBox(height: AppConstants.spaceXl),
                      
                      // Arabic Text
                      const Text(
                        'رِعَايَةُ الحَجِيجِ وَالمُعْتَمِرِينَ',
                        style: TextStyle(
                          fontFamily: 'Amiri', // Assumes added, fallback to sans if not
                          fontSize: 24,
                          color: AppColors.goldLight,
                        ),
                      ),
                      
                      // App Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Haji',
                            style: AppTypography.displayHero.copyWith(
                              color: AppColors.surfaceWhite,
                            ),
                          ),
                          Text(
                            'Care',
                            style: AppTypography.displayHero.copyWith(
                              color: AppColors.goldLight,
                            ),
                          ),
                        ],
                      ),
                      
                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceSm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, AppColors.goldLight.withOpacity(0.6), AppColors.goldLight],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.star, size: 12, color: AppColors.accentGoldStar),
                            ),
                            Container(
                              width: 60,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.goldLight, AppColors.goldLight.withOpacity(0.6), Colors.transparent],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tagline
                      Text(
                        'Sahabat Setia & Amanah di Tanah Suci',
                        style: AppTypography.headlineMd.copyWith(
                          color: AppColors.canvasCream,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppConstants.space2xs),
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
                    bottom: AppConstants.space2xl,
                    left: AppConstants.spaceXl,
                    right: AppConstants.spaceXl,
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
                                  style: AppTypography.captionBold.copyWith(
                                    color: AppColors.goldLight.withOpacity(0.8),
                                  ),
                                ),
                                Text(
                                  'Harmoni',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.space2xs),
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                                border: Border.all(color: AppColors.goldLight.withOpacity(0.25)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                                child: LinearProgressIndicator(
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldLight),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_user, color: AppColors.goldLight, size: 16),
                          const SizedBox(width: AppConstants.spaceXs),
                          Text(
                            'Didukung oleh Inisiatif Pelayanan Jamaah',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.canvasCreamSubtle.withOpacity(0.8),
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
