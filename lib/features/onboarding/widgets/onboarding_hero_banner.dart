import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

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
    this.height = 180,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary,
                    colors.primaryContainer,
                    colors.primary,
                  ],
                ),
              ),
            ),

            // Decorative Circle 1
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .04),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Decorative Circle 2
            Positioned(
              bottom: -60,
              left: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .03),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Floating Icon Card
            Positioned(
              right: 20,
              top: 20,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .20),
                  ),
                ),
                child: Icon(
                  icon,
                  color: colors.accent,
                  size: 34,
                ),
              ),
            ),

            // Badge
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: .95),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.success,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      badgeText.toUpperCase(),
                      style: context.text.labelSmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: .20),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      stageText,
                      style: context.text.labelSmall.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    title,
                    style: context.text.titleLarge.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
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
