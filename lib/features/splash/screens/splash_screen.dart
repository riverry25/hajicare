import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/state/app_startup_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../widgets/corner_capsules_loader.dart';
import '../widgets/kabbah_hero_widget.dart';

/// Refactored, modern Splash Screen with dynamic animated corner loading stripes
/// and centered Ka'bah hero vector.
/// Adheres to UI/UX Pro Max, Flutter Architecture, and Flutter Responsive standards.
class SplashScreen extends StatefulWidget {
  final Duration bootstrapDelay;

  const SplashScreen({
    super.key,
    this.bootstrapDelay = const Duration(milliseconds: 2400),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _contentFade;

  /// Drives the soft loading sweep of the corner capsules.
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();

    // 1. Entrance: corners grow in first (staggered inside the painter
    // centre content fades in slightly later.
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _contentFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );

    // 2. Loop: one-directional sweep across the capsules.
    _sweepController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    // Start after the first Flutter frame so the entrance is not consumed
    // while the native launch screen is still covering the app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _entranceController.forward();
      _sweepController.repeat();
    });

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final startup = Get.find<AppStartupController>();

    final results = await Future.wait([
      startup.determineInitialRoute(),
      if (widget.bootstrapDelay > Duration.zero)
        Future.delayed(widget.bootstrapDelay),
    ]);

    final destination = results.first as String;

    if (mounted) {
      Get.offAllNamed(destination);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroWidth = math.min(240.0, screenWidth * 0.6);

    return Scaffold(
      backgroundColor: colors.canvas,
      body: ClipRect(
        child: Stack(
          children: [
            // 1. Top-Left Corner Animated Stripes Loader
            Positioned(
              top: 0,
              left: 0,
              child: CornerCapsulesLoader(
                position: CornerPosition.topLeft,
                entranceAnim: _entranceController,
                shimmerAnim: _sweepController,
              ),
            ),

            // 2. Bottom-Right Corner Animated Stripes Loader
            Positioned(
              bottom: 0,
              right: 0,
              child: CornerCapsulesLoader(
                position: CornerPosition.bottomRight,
                entranceAnim: _entranceController,
                shimmerAnim: _sweepController,
              ),
            ),

            // 3. Center Content (Ka'bah Hero + Brand Identity + Arabic Calligraphy
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ka'bah Lottie animation
                        KabbahHeroWidget(width: heroWidth),

                        const SizedBox(height: AppSpacing.lg),

                        // App Brand Name (HajiCare
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Haji',
                                style: context.text.displayLarge.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 36,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              TextSpan(
                                text: 'Care',
                                style: context.text.displayLarge.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 36,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Arabic Calligraphy Text
                        Text(
                          'رِعَايَةُ الحَجِيجِ وَالمُعْتَمِرِينَ',
                          textAlign: TextAlign.center,
                          style: AppTypography.arabicText(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: colors.islamic,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Tagline
                        Text(
                          'Sahabat Setia & Amanah Ibadah Anda',
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Bottom Verified Badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 15,
                              color: colors.islamic,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Melayani Jamaah dengan Amanah & Ikhlas',
                              style: context.text.labelSmall.copyWith(
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
