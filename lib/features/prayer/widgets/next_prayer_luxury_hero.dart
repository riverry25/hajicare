import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/prayer_times_controller.dart';

/// Modern Islamic Luxury Next Prayer Hero Card.
/// Features
/// 1. Asymmetric Islamic Arch (Mihrab) background silhouette.
/// 2. Deep Espresso & Desert Gold gradient palette from `AppColors`.
/// 3. Clear, senior-friendly typography hierarchy conforming to `ui-ux-pro-max`.
/// 4. Segmented luxury countdown capsule ([Jam] : [Menit] : [Detik]).
/// 5. Quick sound toggle shortcut right in the hero card header.
class NextPrayerLuxuryHero extends StatelessWidget {
  final PrayerTimesController controller;

  const NextPrayerLuxuryHero({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final accentColor = isDark ? AppColors.darkSecondary : AppColors.goldAccent;
    final accentTextColor = isDark
        ? AppColors.darkSecondary
        : AppColors.goldLight;

    return Obx(() {
      final rawPrayerName = controller.nextPrayerName.value;
      final localizedName = rawPrayerName.isNotEmpty
          ? context.localizedPrayerName(rawPrayerName)
          : 'Waktu Salat';
      final arabicName = controller.nextPrayerArabic.value;
      final timeStr = controller.nextPrayerTime.value;
      final isSoundOn = controller.isPrayerSoundOn(rawPrayerName);

      final hours = controller.countdownHours.value;
      final minutes = controller.countdownMinutes.value;
      final seconds = controller.countdownSeconds.value;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    AppColors.darkSurfaceContainer,
                    AppColors.darkSurface,
                    AppColors.darkScaffold,
                  ]
                : const [
                    AppColors.primary,
                    AppColors.espressoDark,
                    Color(0xFF1F150E),
                  ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.40 : 0.50),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.55)
                  : AppColors.espressoDark.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            children: [
              // Subtle Islamic Mihrab Arch Silhouette Pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: _MihrabSilhouettePainter(
                    accentColor: accentColor.withValues(
                      alpha: isDark ? 0.08 : 0.10,
                    ),
                  ),
                ),
              ),

              // Main Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Badge & Sound Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Next Prayer Pill Badge
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.55),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: accentTextColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      context.tr('prayerNextLabel').isEmpty
                                          ? 'WAKTU SHOLAT BERIKUTNYA'
                                          : context.tr('prayerNextLabel'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.labelSmall.copyWith(
                                        color: accentTextColor,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quick Sound Toggle (Touch target >= 48x48
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              controller.togglePrayerSound(rawPrayerName);
                            },
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSoundOn
                                    ? accentColor.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSoundOn
                                      ? accentColor.withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                isSoundOn
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_off_outlined,
                                color: isSoundOn
                                    ? accentTextColor
                                    : Colors.white.withValues(alpha: 0.6),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Hero Body: Prayer Name, Arabic Calligraphy, & Exact Time
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Left Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      localizedName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.displayLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        height: 1.05,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            timeStr,
                                            style: context.text.headlineSmall
                                                .copyWith(
                                                  color: accentTextColor,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Right Arabic Calligraphy
                            if (arabicName.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  arabicName,
                                  style: AppTypography.arabicMedium.copyWith(
                                    color: accentTextColor,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    // Segmented Countdown Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.38 : 0.28,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.hourglass_top_rounded,
                                color: accentTextColor,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  context
                                      .tr('prayerTimeRemaining')
                                      .toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.labelSmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.90),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTimeSegment(
                                context,
                                value: hours.toString().padLeft(2, '0'),
                                unit: 'JAM',
                                accentColor: accentColor,
                                accentTextColor: accentTextColor,
                              ),
                              _buildTimeDivider(accentColor),
                              _buildTimeSegment(
                                context,
                                value: minutes.toString().padLeft(2, '0'),
                                unit: 'MENIT',
                                accentColor: accentColor,
                                accentTextColor: accentTextColor,
                              ),
                              _buildTimeDivider(accentColor),
                              _buildTimeSegment(
                                context,
                                value: seconds.toString().padLeft(2, '0'),
                                unit: 'DETIK',
                                accentColor: accentColor,
                                accentTextColor: accentTextColor,
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
        ),
      );
    });
  }

  Widget _buildTimeSegment(
    BuildContext context, {
    required String value,
    required String unit,
    required Color accentColor,
    required Color accentTextColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withValues(alpha: 0.45)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: context.text.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              unit,
              style: TextStyle(
                color: accentTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDivider(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
      child: Text(
        ':',
        style: TextStyle(
          color: accentColor,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Custom painter rendering a subtle Islamic Mihrab Arch geometry silhouette
class _MihrabSilhouettePainter extends CustomPainter {
  final Color accentColor;

  _MihrabSilhouettePainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final width = size.width;
    final height = size.height;

    // Draw stylized arch on right side
    final path = Path();
    final centerX = width * 0.85;
    final radius = width * 0.35;

    path.moveTo(centerX - radius, height);
    path.lineTo(centerX - radius, height * 0.45);
    path.quadraticBezierTo(
      centerX - radius,
      height * 0.15,
      centerX,
      height * 0.05,
    );
    path.quadraticBezierTo(
      centerX + radius,
      height * 0.15,
      centerX + radius,
      height * 0.45,
    );
    path.lineTo(centerX + radius, height);

    canvas.drawPath(path, paint);

    // Inner concentric arch
    final innerPath = Path();
    final innerRadius = radius * 0.75;
    innerPath.moveTo(centerX - innerRadius, height);
    innerPath.lineTo(centerX - innerRadius, height * 0.50);
    innerPath.quadraticBezierTo(
      centerX - innerRadius,
      height * 0.25,
      centerX,
      height * 0.15,
    );
    innerPath.quadraticBezierTo(
      centerX + innerRadius,
      height * 0.25,
      centerX + innerRadius,
      height * 0.50,
    );
    innerPath.lineTo(centerX + innerRadius, height);

    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(covariant _MihrabSilhouettePainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}
