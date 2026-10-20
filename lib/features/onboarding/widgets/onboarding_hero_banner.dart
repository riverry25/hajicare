import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/theme_context.dart';

/// An elegant, atmospheric visual frame for HajiCare onboarding slides.
/// Inspired by the warm desert aesthetic
/// providing a soft ambient glow, subtle border, and high-contrast tokens.
class OnboardingHeroBanner extends StatelessWidget {
  final String badgeText;
  final String stageText;
  final String title;
  final IconData icon;
  final double? height;
  final double borderRadius;
  final Widget? child;

  const OnboardingHeroBanner({
    super.key,
    required this.badgeText,
    required this.stageText,
    required this.title,
    required this.icon,
    this.height = 175,
    this.borderRadius = AppRadius.xxl,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final isDark = colors.isDark;

    if (child != null) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Soft warm ambient gold aura in the center
            Positioned(
              top: -30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark
                                ? const Color(0xFFB08A57)
                                : const Color(0xFFD4B896))
                            .withValues(alpha: isDark ? 0.22 : 0.32),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Decorative celestial sparkles (Family Appaesthetic
            Positioned(
              top: 14,
              right: 18,
              child: Text(
                '✦',
                style: TextStyle(
                  color: colors.accent.withValues(alpha: isDark ? 0.50 : 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              child: Text(
                '✧',
                style: TextStyle(
                  color: colors.accent.withValues(alpha: isDark ? 0.40 : 0.55),
                  fontSize: 11,
                ),
              ),
            ),
            Positioned(
              top: 36,
              left: 14,
              child: Text(
                '✦',
                style: TextStyle(
                  color: colors.accent.withValues(alpha: isDark ? 0.30 : 0.45),
                  fontSize: 8.5,
                ),
              ),
            ),

            // Embedded custom visual scene
            child!,
          ],
        ),
      );
    }

    // Default Fallback Banner (for backward compatibility
    final gradientColors = isDark
        ? const [Color(0xFF2C1B11), Color(0xFF1E120A), Color(0xFF140C07)]
        : const [Color(0xFF382315), Color(0xFF26160C), Color(0xFF1A0E08)];

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.50)
                : colors.shadow.withValues(alpha: 0.14),
            blurRadius: isDark ? 24 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D120A).withValues(alpha: 0.70),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2C499).withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: const Color(0xFFF7DEB4), size: 24),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stageText.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFE2C499),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
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
}
