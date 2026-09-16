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
      duration: const Duration(milliseconds: 2400),
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
      backgroundColor: AppColors.espressoDark,
      body: Stack(
        children: [
          // Background Gradient (Deep Espresso to Warm Kaaba Tone)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
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
          ),

          // Ambient Golden Glow at the top
          Positioned(
            top: -size.width * 0.35,
            left: -size.width * 0.15,
            right: -size.width * 0.15,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 0.92 + (_controller.value * 0.08);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          // Secondary subtle ambient glow at bottom
          Positioned(
            bottom: -size.width * 0.45,
            left: -size.width * 0.25,
            right: -size.width * 0.25,
            child: Container(
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.25),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  // Top Brand Subtle Header
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.goldPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'HAJICARE INDONESIA',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.canvasCreamSubtle,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.goldPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
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
                                final scale = 1.0 + (_controller.value * 0.025);
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: _buildLogo(),
                            ),

                            const SizedBox(height: 28),

                            // Arabic Calligraphy Text
                            Text(
                              'رِعَايَةُ الحَجِيجِ وَالمُعْتَمِرِينَ',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldPrimary,
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // App Brand Name
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Haji',
                                    style: AppTypography.displayLarge.copyWith(
                                      color: AppColors.surfaceWhite,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Care',
                                    style: AppTypography.displayLarge.copyWith(
                                      color: AppColors.goldPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Ornamental Divider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildDivider(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: AppColors.accentGoldStar,
                                  ),
                                ),
                                _buildDivider(reverse: true),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Tagline
                            Text(
                              'Sahabat Setia & Amanah Ibadah Anda',
                              textAlign: TextAlign.center,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.canvasCream,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Description
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                'Sistem pendampingan pintar, pemantauan jarak real-time, dan bantuan darurat ramah lansia.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.canvasCreamSubtle.withValues(alpha: 0.85),
                                  height: 1.45,
                                ),
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
                        SizedBox(
                          width: 200,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Memuat data...',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.canvasCreamSubtle,
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      final pct = 25 + ((_controller.value * 75).round());
                                      return Text(
                                        '$pct%',
                                        style: AppTypography.captionSmall.copyWith(
                                          color: AppColors.goldPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.6),
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
                                                AppColors.goldLight,
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: AppColors.goldPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Melayani Jamaah dengan Amanah',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.canvasCreamSubtle,
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
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer delicate golden ring
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.goldPrimary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),

          // Middle golden ring
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.goldPrimary.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),

          // Main Emblem
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryContainer, AppColors.espressoDark],
              ),
              border: Border.all(
                color: AppColors.goldPrimary.withValues(alpha: 0.8),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                const Icon(
                  Icons.shield_rounded,
                  size: 44,
                  color: AppColors.goldPrimary,
                ),
                const Positioned(
                  top: 18,
                  right: 22,
                  child: Icon(
                    Icons.star_rounded,
                    size: 10,
                    color: AppColors.accentGoldStar,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider({bool reverse = false}) {
    return Container(
      width: 52,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: reverse ? Alignment.centerRight : Alignment.centerLeft,
          end: reverse ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            Colors.transparent,
            AppColors.goldPrimary.withValues(alpha: 0.3),
            AppColors.goldPrimary.withValues(alpha: 0.9),
          ],
        ),
      ),
    );
  }
}
