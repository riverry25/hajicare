import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/theme_context.dart';

/// An elegant, atmospheric hero banner for HajiCare onboarding slides.
/// Inspired by the prestigious Kaaba Kiswah aesthetic: deep espresso velvet,
/// warm desert gold calligraphy accents, and high-contrast typography (WCAG AAA).
class OnboardingHeroBanner extends StatelessWidget {
  final String badgeText;
  final String stageText;
  final String title;
  final IconData icon;
  final double height;
  final double borderRadius;

  const OnboardingHeroBanner({
    super.key,
    required this.badgeText,
    required this.stageText,
    required this.title,
    required this.icon,
    this.height = 175,
    this.borderRadius = AppRadius.xl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final isDark = colors.isDark;

    // Deep, reverent espresso velvet gradient guaranteed to have >12:1 contrast
    // with warm white and gold typography in both light and dark modes.
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
            color: colors.shadow.withValues(alpha: isDark ? 0.45 : 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Deep Velvet Canvas
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

            // Islamic Geometric Arch Watermark
            Positioned.fill(
              child: CustomPaint(
                painter: _IslamicArchWatermarkPainter(
                  goldColor: const Color(0xFFD4B07B),
                ),
              ),
            ),

            // Subtle Ambient Gold Glow Top-Right
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE5C28A).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Floating Sacred Icon Card
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D120A).withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2C499).withValues(alpha: 0.50),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: const Color(0xFFF7DEB4), size: 28),
              ),
            ),

            // Top Pill Badge (Elderly/Safety Category)
            Positioned(
              top: 18,
              left: 18,
              right: 90,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF150D08).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: const Color(0xFFD4B07B).withValues(alpha: 0.40),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4EBA75), // Vibrant emerald dot
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          badgeText.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelSmall.copyWith(
                            color: const Color(0xFFFAF7F2),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Content Area (Stage badge + Bold Title)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2C499).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: const Color(0xFFE2C499).withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      stageText,
                      style: context.text.labelSmall.copyWith(
                        color: const Color(0xFFF7DEB4),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleLarge.copyWith(
                      color: const Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      letterSpacing: -0.3,
                      height: 1.18,
                      shadows: const [
                        Shadow(
                          color: Color(0x99000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Subtle Gold Border Outline
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: const Color(0xFFD4B07B).withValues(alpha: 0.30),
                      width: 1.2,
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

/// Custom painter for subtle, elegant Islamic geometric arches.
class _IslamicArchWatermarkPainter extends CustomPainter {
  final Color goldColor;

  const _IslamicArchWatermarkPainter({required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = goldColor.withValues(alpha: 0.065)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric Islamic arches anchored at bottom-center-right
    final center = Offset(size.width * 0.85, size.height * 0.7);
    final maxRadius = math.min(size.width, size.height) * 0.95;

    for (double r = 35; r <= maxRadius; r += 24) {
      canvas.drawCircle(center, r, paint);
    }

    // Additional subtle arc at top-left
    final leftCenter = Offset(size.width * 0.15, -10);
    for (double r = 40; r <= 140; r += 28) {
      canvas.drawCircle(leftCenter, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicArchWatermarkPainter oldDelegate) =>
      oldDelegate.goldColor != goldColor;
}
