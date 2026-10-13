import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
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
    final colors = context.hc;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
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
                              child: _buildLogo(colors),
                            ),

                            const SizedBox(height: 24),

                            // Arabic Calligraphy Text
                            Text(
                              'رِعَايَةُ الحَجِيجِ وَالمُعْتَمِرِينَ',
                              textAlign: TextAlign.center,
                              style: AppTypography.arabicText(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: colors.islamic,
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
                                    style: context.text.displayLarge.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 34,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Care',
                                    style: context.text.displayLarge.copyWith(
                                      color: colors.accent,
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
                              style: context.text.titleSmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Subtle Feature Subtitle
                            Text(
                              'Pendampingan Pintar • Radar Jarak Jauh • Bantuan Lansia',
                              textAlign: TextAlign.center,
                              style: context.text.labelSmall.copyWith(
                                color: colors.textSecondary,
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
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Memuat data...',
                                    style: context.text.labelSmall.copyWith(
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      final pct =
                                          25 +
                                          ((_controller.value * 75).round());
                                      return Text(
                                        '$pct%',
                                        style: context.text.labelSmall
                                            .copyWith(
                                              color: colors.islamic,
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
                                  color: colors.surfaceSand,
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
                                          decoration: BoxDecoration(
                                            color: colors.accent,
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
                            Icon(
                              Icons.verified_user_rounded,
                              size: 14,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(HajiColors colors) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Image.asset(
        'assets/icon.jpeg',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.mosque_rounded,
            size: 54,
            color: colors.accent,
          );
        },
      ),
    );
  }
}
