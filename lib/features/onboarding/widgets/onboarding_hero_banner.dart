import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: .12),
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
                    AppColors.espressoDark,
                    AppColors.primaryContainer,
                    AppColors.espressoDark,
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
                  color: Colors.white.withValues(alpha: .05),
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
                  color: Colors.white.withValues(alpha: .04),
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
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .15),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white.withValues(alpha: .95),
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
                  color: Colors.white.withValues(alpha: .95),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.statusPositive,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      badgeText.toUpperCase(),
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.espressoDark,
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
                      color: AppColors.accentGoldStar.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      stageText,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.accentGoldStar,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.surfaceWhite,
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
