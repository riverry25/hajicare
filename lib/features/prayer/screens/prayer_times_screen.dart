import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../controllers/prayer_times_controller.dart';

class PrayerTimesScreen extends StatelessWidget {
  final bool showBottomNav;
  const PrayerTimesScreen({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PrayerTimesController>();
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(
          context.tr('jadwal').isEmpty
              ? 'Jadwal Sholat & Kiblat'
              : context.tr('jadwal'),
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textHeadingColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Perbarui Lokasi GPS',
            icon: Obx(
              () => controller.isLoadingLocation.value
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.espressoDark,
                      ),
                    )
                  : Icon(
                      Icons.my_location,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.espressoDark,
                      size: 20,
                    ),
            ),
            onPressed: () => controller.refreshLocation(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdgeGutter,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            // ── Dynamic Location & Hijri Date Bar ───────────────────────────
            Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: controller.isUsingFallbackLocation
                        ? AppColors.error.withValues(alpha: isDark ? 0.5 : 0.3)
                        : (isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.canvasCreamSubtle),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : AppColors.espressoDark.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            controller.isUsingFallbackLocation
                                ? Icons.location_off_outlined
                                : Icons.location_on,
                            color: controller.isUsingFallbackLocation
                                ? AppColors.tanMedium
                                : AppColors.accentGoldStar,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              controller.locationName.value,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.textHeadingColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (controller.isUsingFallbackLocation) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Text(
                                'Fallback',
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.error,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.canvasCreamSubtle,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        controller.hijriDateText.value,
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.espressoDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Realtime Next Prayer Hero ──────────────────────────────────
            Obx(
              () => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF281E17),
                            Color(0xFF38291F),
                            Color(0xFF20160F),
                          ]
                        : const [
                            AppColors.espressoDark,
                            AppColors.primaryContainer,
                            AppColors.primary,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.goldLight.withValues(
                      alpha: isDark ? 0.25 : 0.15,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : AppColors.espressoDark.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accentGoldStar,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'WAKTU SHOLAT BERIKUTNYA',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.goldLight,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      controller.nextPrayerName.value,
                      style: AppTypography.heroNumberLarge.copyWith(
                        color: AppColors.surfaceWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      controller.nextPrayerArabic.value,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.nextPrayerTime.value,
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.goldLight.withValues(alpha: 0.12)
                            : AppColors.surfaceWhite.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.goldLight.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: AppColors.goldLight,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Waktu tersisa: ${controller.countdownText.value}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.surfaceWhite,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Dynamic Qibla Compass ──────────────────────────────────────
            Obx(() {
              final isAligned = controller.isQiblaAligned.value;
              final qiblaDeg = controller.qiblaBearing.value.toStringAsFixed(0);
              final angleRadians =
                  (controller.qiblaOffset.value * math.pi / 180.0);

              return AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.explore,
                              color: isAligned
                                  ? AppColors.statusPositive
                                  : AppColors.textHeadingColor(context),
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Arah Kiblat',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textHeadingColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isAligned
                                ? AppColors.statusPositive.withValues(
                                    alpha: 0.15,
                                  )
                                : (isDark
                                    ? AppColors.darkSurfaceContainerHigh
                                    : AppColors.canvasCreamSubtle),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '$qiblaDeg° Ka\'bah',
                            style: AppTypography.captionSmall.copyWith(
                              color: isAligned
                                  ? AppColors.statusPositive
                                  : AppColors.textHeadingColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (!controller.hasCompassSensor.value)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        margin: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceContainerHigh
                              : AppColors.canvasCreamSubtle,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          'Kompas hanya berfungsi di perangkat mobile dengan sensor.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textBodyColor(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      // Rotating Compass Dial
                      Center(
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isAligned
                                  ? AppColors.statusPositive
                                  : (isDark
                                      ? AppColors.darkOutline
                                      : AppColors.goldLight),
                              width: isAligned ? 5 : 3,
                            ),
                            color: isDark
                                ? AppColors.darkSurfaceContainer
                                : AppColors.canvasCream,
                            boxShadow: [
                              BoxShadow(
                                color: isAligned
                                    ? AppColors.statusPositive.withValues(
                                        alpha: 0.35,
                                      )
                                    : (isDark
                                        ? Colors.black.withValues(alpha: 0.3)
                                        : AppColors.espressoDark.withValues(
                                            alpha: 0.08,
                                          )),
                                blurRadius: isAligned ? 20 : 10,
                                spreadRadius: isAligned ? 4 : 1,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Dial markings (U, S, B, T)
                              const Positioned(
                                top: 8,
                                child: Text(
                                  'U',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                child: Text(
                                  'S',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBodyColor(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                child: Text(
                                  'B',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBodyColor(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                child: Text(
                                  'T',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBodyColor(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                              // Background concentric circle
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.tanMedium.withValues(
                                      alpha: isDark ? 0.3 : 0.2,
                                    ),
                                  ),
                                ),
                              ),

                              // Dynamic Rotating Qibla Needle
                              Transform.rotate(
                                angle: angleRadians,
                                child: SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // North/Kaaba pointer
                                      Positioned(
                                        top: 4,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.mosque,
                                              size: 24,
                                              color: isAligned
                                                  ? AppColors.statusPositive
                                                  : AppColors.accentGoldStar,
                                            ),
                                            Container(
                                              width: 4,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: isAligned
                                                    ? AppColors.statusPositive
                                                    : AppColors.accentGoldStar,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Tail pointer
                                      Positioned(
                                        bottom: 12,
                                        child: Container(
                                          width: 3,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: AppColors.tanMedium
                                                .withValues(alpha: isDark ? 0.5 : 0.4),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Center pivot
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: isAligned
                                              ? AppColors.statusPositive
                                              : (isDark
                                                  ? AppColors.goldLight
                                                  : AppColors.espressoDark),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.darkSurface
                                                : Colors.white,
                                            width: 2,
                                          ),
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
                      const SizedBox(height: AppSpacing.md),

                      // Direction Feedback Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isAligned
                              ? AppColors.statusPositive.withValues(alpha: 0.15)
                              : (isDark
                                  ? AppColors.darkSurfaceContainerHigh
                                  : AppColors.canvasCreamSubtle),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isAligned
                                ? AppColors.statusPositive.withValues(
                                    alpha: 0.4,
                                  )
                                : (isDark
                                    ? AppColors.darkOutlineVariant
                                    : Colors.transparent),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAligned ? Icons.check_circle : Icons.navigation,
                              size: 16,
                              color: isAligned
                                  ? AppColors.statusPositive
                                  : AppColors.tanMedium,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isAligned
                                    ? 'Ponsel Anda Tepat Mengarah ke Kiblat ✓'
                                    : 'Selisih: ${controller.qiblaOffset.value.toStringAsFixed(0)}° (Putar ke arah Ka\'bah)',
                                style: AppTypography.captionSmall.copyWith(
                                  color: isAligned
                                      ? AppColors.statusPositive
                                      : AppColors.textHeadingColor(context),
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),

            // ── Full Day Dynamic Schedule ──────────────────────────────────
            Obx(
              () => AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: AppColors.textHeadingColor(context),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Jadwal Sholat Hari Ini',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.textHeadingColor(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainerHigh
                                  : AppColors.canvasCream,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              controller.calculationMethodName.value,
                              style: AppTypography.captionSmall.copyWith(
                                color: isDark
                                    ? AppColors.goldLight
                                    : AppColors.tanMedium,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.canvasCreamSubtle,
                    ),
                    Column(
                      children: controller.prayers.map((p) {
                        return _buildPrayerRow(
                          context: context,
                          name: p.name,
                          arabicName: p.arabicName,
                          time: p.formattedTime,
                          isNext: p.isNext,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.space3xl),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? const HajiCareBottomNavBar(currentIndex: 2)
          : null,
    );
  }

  Widget _buildPrayerRow({
    required BuildContext context,
    required String name,
    required String arabicName,
    required String time,
    required bool isNext,
  }) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isNext
            ? (isDark
                ? AppColors.darkPrimaryContainer.withValues(alpha: 0.45)
                : AppColors.secondaryContainer.withValues(alpha: 0.5))
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkOutlineVariant.withValues(alpha: 0.4)
                : AppColors.canvasCreamSubtle.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isNext
                      ? AppColors.accentGoldStar.withValues(
                          alpha: isDark ? 0.25 : 0.2,
                        )
                      : (isDark
                          ? AppColors.darkSurfaceContainerHigh
                          : AppColors.canvasCreamSubtle),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNext ? Icons.volume_up : Icons.access_time,
                  size: 16,
                  color: isNext
                      ? (isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark)
                      : (isDark
                          ? AppColors.darkTextBody
                          : AppColors.tanMedium),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isNext
                          ? (isDark
                              ? AppColors.goldLight
                              : AppColors.espressoDark)
                          : AppColors.textHeadingColor(context),
                      fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Text(
                    arabicName,
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextBody
                          : AppColors.tanMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (isNext) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.accentGoldStar
                        : AppColors.espressoDark,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Berikutnya',
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark
                          ? AppColors.darkScaffold
                          : AppColors.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                time,
                style: AppTypography.titleMedium.copyWith(
                  color: isNext
                      ? (isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark)
                      : AppColors.textHeadingColor(context),
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
