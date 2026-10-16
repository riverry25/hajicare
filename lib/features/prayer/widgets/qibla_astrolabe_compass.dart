import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/prayer_times_controller.dart';

/// Modern Astrolabe Qibla Compass Widget.
///
/// Features:
/// 1. Precision Astrolabe Dial with fine 360-degree ticks and 8-point Islamic Star (Khatam) rosette.
/// 2. Smoothly rotating Kaaba needle with detailed pointer and counterweight.
/// 3. Dynamic Turn Guidance (e.g. "Putar 28° ke kanan ➔" vs "⬅ Putar 15° ke kiri").
/// 4. Emerald glow halo and haptic feedback trigger when perfectly aligned.
/// 5. Sensor missing / calibration state fallback.
class QiblaAstrolabeCompass extends StatelessWidget {
  final PrayerTimesController controller;

  const QiblaAstrolabeCompass({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final isDark = context.isDark;

    return Obx(() {
      final isAligned = controller.isQiblaAligned.value;
      final qiblaBearingVal = controller.qiblaBearing.value;
      final safeQiblaBearing =
          qiblaBearingVal.isFinite && !qiblaBearingVal.isNaN
          ? qiblaBearingVal
          : 0.0;
      final qiblaDeg = safeQiblaBearing.toStringAsFixed(0);

      final offsetVal = controller.qiblaOffset.value;
      final safeOffset = offsetVal.isFinite && !offsetVal.isNaN
          ? offsetVal
          : 0.0;
      final rawAngle = (safeOffset * math.pi / 180.0);
      final safeAngle = rawAngle.isFinite && !rawAngle.isNaN ? rawAngle : 0.0;

      final hasSensor = controller.hasCompassSensor.value;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          children: [
            // ── Header: Title & Bearing Badge ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isAligned
                              ? colors.islamic.withValues(alpha: 0.18)
                              : colors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isAligned
                                ? colors.islamic
                                : colors.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Icon(
                          Icons.explore_rounded,
                          color: isAligned ? colors.islamic : colors.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          context.tr('qiblaDirection').isEmpty
                              ? 'Arah Kiblat'
                              : context.tr('qiblaDirection'),
                          style: context.text.titleMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Kaaba Bearing Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAligned
                        ? colors.islamic.withValues(alpha: 0.15)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : colors.surfaceSubtle),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isAligned ? colors.islamic : colors.border,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 14,
                        color: isAligned ? colors.islamic : colors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$qiblaDeg° ${context.tr('qiblaKabah')}',
                        style: context.text.labelSmall.copyWith(
                          color: isAligned
                              ? colors.islamic
                              : colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            if (!hasSensor)
              _buildNoSensorView(context, colors)
            else ...[
              // ── Astrolabe Compass Dial ─────────────────────────────────────
              Center(
                child: SizedBox(
                  width: 230,
                  height: 230,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dial plate with Astrolabe ticks & Khatam Rosette
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _QiblaCompassDialPainter(
                            isAligned: isAligned,
                            isDark: isDark,
                            accentColor: colors.accent,
                            successColor: colors.islamic,
                            borderColor: colors.border,
                          ),
                        ),
                      ),

                      // Cardinal Labels (U, S, B, T)
                      Positioned(
                        top: 14,
                        child: Text(
                          context.tr('compassNorth'),
                          style: TextStyle(
                            color: colors.danger,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        child: Text(
                          context.tr('compassSouth'),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        child: Text(
                          context.tr('compassWest'),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        child: Text(
                          context.tr('compassEast'),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Rotating Kaaba Pointer Needle
                      Transform.rotate(
                        angle: safeAngle,
                        child: SizedBox(
                          width: 170,
                          height: 170,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // North/Kaaba Tip
                              Positioned(
                                top: 6,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isAligned
                                            ? colors.islamic
                                            : colors.accent,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (isAligned
                                                        ? colors.islamic
                                                        : colors.accent)
                                                    .withValues(alpha: 0.5),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.mosque_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 4,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            isAligned
                                                ? colors.islamic
                                                : colors.accent,
                                            isAligned
                                                ? colors.islamic.withValues(
                                                    alpha: 0.65,
                                                  )
                                                : (isDark
                                                      ? AppColors.darkSecondary
                                                      : AppColors.goldLight),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Counterweight Tail
                              Positioned(
                                bottom: 18,
                                child: Container(
                                  width: 3,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: colors.borderStrong,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),

                              // Center Hub
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: isAligned
                                      ? colors.islamic
                                      : colors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 4,
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
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Dynamic Turn Guidance Status Banner ─────────────────────────
              _buildTurnGuidanceBanner(
                context,
                isAligned: isAligned,
                safeOffset: safeOffset,
                colors: colors,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTurnGuidanceBanner(
    BuildContext context, {
    required bool isAligned,
    required double safeOffset,
    required dynamic colors,
  }) {
    if (isAligned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.islamic.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: colors.islamic.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: colors.islamic),
            const SizedBox(width: 8),
            Text(
              context.tr('qiblaAligned').isNotEmpty
                  ? context.tr('qiblaAligned')
                  : 'Tepat Menghadap Ka\'bah',
              style: context.text.labelMedium.copyWith(
                color: colors.islamic,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    // Determine shortest rotation direction
    final bool turnRight = safeOffset <= 180.0;
    final double degreesToTurn = turnRight ? safeOffset : (360.0 - safeOffset);
    final String turnText = turnRight
        ? 'Putar ponsel ${degreesToTurn.toStringAsFixed(0)}° ke kanan ➔'
        : '⬅ Putar ponsel ${degreesToTurn.toStringAsFixed(0)}° ke kiri';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            turnRight ? Icons.rotate_right_rounded : Icons.rotate_left_rounded,
            size: 18,
            color: colors.accent,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              turnText,
              style: context.text.labelMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSensorView(BuildContext context, dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sensors_off_rounded,
            color: colors.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('kompasNoSensor').isNotEmpty
                ? context.tr('kompasNoSensor')
                : 'Sensor kompas tidak terdeteksi pada perangkat ini.',
            style: context.text.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for rendering the Astrolabe 360° ticks and 8-point Islamic star rosette
class _QiblaCompassDialPainter extends CustomPainter {
  final bool isAligned;
  final bool isDark;
  final Color accentColor;
  final Color successColor;
  final Color borderColor;

  _QiblaCompassDialPainter({
    required this.isAligned,
    required this.isDark,
    required this.accentColor,
    required this.successColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Outer Plate Background
    final platePaint = Paint()
      ..color = isDark
          ? AppColors.darkSurfaceContainer
          : AppColors.canvasCreamSubtle
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, platePaint);

    // 2. Glowing Halo when aligned
    if (isAligned) {
      final glowPaint = Paint()
        ..color = successColor.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 16);
      canvas.drawCircle(center, radius - 2, glowPaint);
    }

    // 3. Outer Rim Border
    final rimPaint = Paint()
      ..color = isAligned
          ? successColor
          : (isDark ? accentColor.withValues(alpha: 0.6) : accentColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAligned ? 4.0 : 2.5;
    canvas.drawCircle(center, radius - 4, rimPaint);

    // 4. Astrolabe 360-degree Calibration Ticks
    final tickPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.25)
          : Colors.black.withValues(alpha: 0.20)
      ..strokeWidth = 1.0;

    final majorTickPaint = Paint()
      ..color = isDark
          ? accentColor.withValues(alpha: 0.7)
          : accentColor.withValues(alpha: 0.9)
      ..strokeWidth = 2.0;

    for (int deg = 0; deg < 360; deg += 6) {
      final isMajor = (deg % 30 == 0);
      final angle = deg * math.pi / 180.0;
      final tickLength = isMajor ? 10.0 : 5.0;

      final startR = radius - 8;
      final endR = startR - tickLength;

      final p1 = Offset(
        center.dx + startR * math.cos(angle),
        center.dy + startR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + endR * math.cos(angle),
        center.dy + endR * math.sin(angle),
      );

      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }

    // 5. Khatam Sulayman (8-point Islamic Star Rosette)
    final starPaint = Paint()
      ..color = isDark
          ? accentColor.withValues(alpha: 0.08)
          : accentColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final starRadius = radius * 0.45;
    final starRect1 = Rect.fromCircle(center: center, radius: starRadius);
    canvas.drawRect(starRect1, starPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    final starRect2 = Rect.fromCenter(
      center: Offset.zero,
      width: starRadius * 2,
      height: starRadius * 2,
    );
    canvas.drawRect(starRect2, starPaint);
    canvas.restore();

    // Concentric Inner Rosette Ring
    final innerRingPaint = Paint()
      ..color = isDark
          ? accentColor.withValues(alpha: 0.15)
          : accentColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.58, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _QiblaCompassDialPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned ||
        oldDelegate.isDark != isDark ||
        oldDelegate.accentColor != accentColor;
  }
}
