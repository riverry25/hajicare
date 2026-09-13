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

    // Concurrently determine route & let minimum splash progress complete
    // to ensure beautiful branding presentation without flicker or premature redirects.
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
          // ============================================================
          // BACKGROUND
          // ============================================================
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

          // ============================================================
          // AMBIENT GLOW
          // ============================================================
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
                  color: AppColors.goldLight.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),

          // ============================================================
          // SECOND SUBTLE GLOW
          // ============================================================
          Positioned(
            bottom: -size.width * 0.45,
            left: -size.width * 0.25,
            right: -size.width * 0.25,
            child: Container(
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.espressoDark.withValues(alpha: 0.22),
              ),
            ),
          ),

          // ============================================================
          // MAIN CONTENT
          // ============================================================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  // ======================================================
                  // TOP BRAND MARK
                  // ======================================================
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.goldLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'HARMONI',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.canvasCreamSubtle,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.goldLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ======================================================
                  // CENTER
                  // ======================================================
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ==================================================
                            // LOGO
                            // ==================================================
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

                            const SizedBox(height: 30),

                            // ==================================================
                            // ARABIC TEXT
                            // ==================================================
                            Text(
                              'رِعَايَةُ الحَجِيجِ وَالمُعْتَمِرِينَ',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldLight,
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ==================================================
                            // APP NAME
                            // ==================================================
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Haji',
                                    style: AppTypography.displayLarge.copyWith(
                                      color: AppColors.surfaceWhite,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Care',
                                    style: AppTypography.displayLarge.copyWith(
                                      color: AppColors.goldLight,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ==================================================
                            // DECORATIVE DIVIDER
                            // ==================================================
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildDivider(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 11,
                                    color: AppColors.accentGoldStar,
                                  ),
                                ),
                                _buildDivider(reverse: true),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ==================================================
                            // TAGLINE
                            // ==================================================
                            Text(
                              'Sahabat Setia & Amanah',
                              textAlign: TextAlign.center,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.canvasCream,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // ==================================================
                            // DESCRIPTION
                            // ==================================================
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 330),
                              child: Text(
                                'Pendamping perjalanan ibadah yang ramah, '
                                'aman, dan mudah diakses.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.canvasCreamSubtle,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ========================================================
                  // BOTTOM LOADING
                  // ========================================================
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
                    child: Column(
                      children: [
                        // Loading indicator
                        SizedBox(
                          width: 180,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Menyiapkan pengalaman',
                                    style: AppTypography.captionSmall.copyWith(
                                      color: AppColors.canvasCreamSubtle,
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      return Text(
                                        '${((_controller.value * 100).round())}%',
                                        style: AppTypography.captionSmall
                                            .copyWith(
                                              color: AppColors.goldLight,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Progress track
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.espressoDark.withValues(
                                    alpha: 0.45,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor:
                                            0.25 + (_controller.value * 0.75),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.goldLight,
                                                AppColors.accentGoldStar,
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

                        const SizedBox(height: 18),

                        // ====================================================
                        // FOOTER
                        // ====================================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.goldLight.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Melayani dengan amanah',
                              style: AppTypography.captionSmall.copyWith(
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

  // ==============================================================
  // LOGO BUILDER
  // ==============================================================

  Widget _buildLogo() {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.goldLight.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
          ),

          // Middle ring
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.goldLight.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
          ),

          // Main emblem
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
                color: AppColors.goldLight.withValues(alpha: 0.65),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldLight.withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle inner circle
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldLight.withValues(alpha: 0.12),
                    ),
                  ),
                ),

                // Icon
                const Icon(
                  Icons.shield_rounded,
                  size: 42,
                  color: AppColors.goldLight,
                ),

                // Small star
                Positioned(
                  top: 17,
                  right: 22,
                  child: Icon(
                    Icons.star_rounded,
                    size: 9,
                    color: AppColors.accentGoldStar.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // DIVIDER BUILDER
  // ==============================================================

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
            AppColors.goldLight.withValues(alpha: 0.25),
            AppColors.goldLight.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }
}
