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
import '../../../core/widgets/hajicare_header.dart';
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
      extendBody: true,
      appBar: HajiCareHeader(
        title: context.tr('prayerTitle').isEmpty
            ? 'Jadwal Sholat & Kiblat'
            : context.tr('prayerTitle'),
        subtitle: context.tr('prayerSubtitle').isEmpty
            ? 'Waktu sholat akurat & kompas arah Ka\'bah'
            : context.tr('prayerSubtitle'),
        icon: Icons.mosque_rounded,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenEdgeGutter),
            child: Center(
              child: Obx(
                () => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: controller.isLoadingLocation.value
                        ? null
                        : () => controller.refreshLocation(),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.cardBorderColor(context),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.12 : 0.04,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.isLoadingLocation.value)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? AppColors.goldPrimary
                                    : AppColors.espressoDark,
                              ),
                            )
                          else
                            Icon(
                              Icons.my_location_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.espressoDark,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            controller.isLoadingLocation.value
                                ? context.tr('prayerLoading')
                                : context.tr('prayerLocation'),
                            style: AppTypography.captionSmall.copyWith(
                              color: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.espressoDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdgeGutter,
          AppSpacing.md,
          AppSpacing.screenEdgeGutter,
          100,
        ),
        child: Column(
          children: [
            // ── Active Adhan Playing Banner ──────────────────────────────────
            Obx(() {
              if (!controller.isAdhanPlaying.value) {
                return const SizedBox.shrink();
              }
              final playingName = controller.playingPrayerName.value;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.espressoDark, Color(0xFF2C241E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.goldPrimary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldPrimary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.goldPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                              Flexible(
                                child: Text(
                                  'Adzan $playingName Berkumandang',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Syaikh Mishary Rashid Al-Afasy',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.tanLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller.stopAdhan(),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.volume_off_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Matikan',
                                style: AppTypography.captionSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── Dynamic Location & Hijri Date Bar ───────────────────────────
            Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: controller.isUsingFallbackLocation
                        ? AppColors.error.withValues(alpha: isDark ? 0.5 : 0.3)
                        : (isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.cardBorderColor(context)),
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
                                : Icons.location_on_rounded,
                            color: controller.isUsingFallbackLocation
                                ? AppColors.tanMedium
                                : AppColors.goldPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              controller.locationName.value,
                              style: AppTypography.bodyMedium.copyWith(
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
                                vertical: 1.5,
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
                                  fontWeight: FontWeight.w700,
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
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.canvasCream,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        controller.hijriDateText.value,
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.espressoDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Realtime Next Prayer Hero (Islamic Luxury) ──────────────────
            Obx(
              () => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
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
                            Color(0xFF2E1C12),
                            Color(0xFF1E140E),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(
                      alpha: isDark ? 0.35 : 0.4,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.45)
                          : AppColors.espressoDark.withValues(alpha: 0.25),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Badge Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.goldPrimary,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('prayerNextLabel').isEmpty
                                ? 'WAKTU SHOLAT BERIKUTNYA'
                                : context.tr('prayerNextLabel'),
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.goldPrimary,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Prayer Name
                    Text(
                      controller.nextPrayerName.value,
                      style: AppTypography.heroNumberLarge.copyWith(
                        color: AppColors.surfaceWhite,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Arabic Calligraphy
                    Text(
                      controller.nextPrayerArabic.value,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.goldPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Next Prayer Time
                    Text(
                      controller.nextPrayerTime.value,
                      style: AppTypography.headlineMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Countdown Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: AppColors.goldPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${context.tr('prayerTimeRemaining')}: ${controller.countdownText.value}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.surfaceWhite,
                                fontWeight: FontWeight.w700,
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
            const SizedBox(height: AppSpacing.md),

            // ── Dynamic Qibla Compass ──────────────────────────────────────
            Obx(() {
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
              final safeAngle = rawAngle.isFinite && !rawAngle.isNaN
                  ? rawAngle
                  : 0.0;

              return AppCard(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isAligned
                                    ? AppColors.statusPositive.withValues(
                                        alpha: 0.15,
                                      )
                                    : (isDark
                                          ? AppColors.darkSurfaceContainerHigh
                                          : AppColors.canvasCream),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.explore_rounded,
                                color: isAligned
                                    ? AppColors.statusPositive
                                    : (isDark
                                          ? AppColors.goldLight
                                          : AppColors.espressoDark),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('qiblaDirection').isEmpty
                                  ? 'Arah Kiblat'
                                  : context.tr('qiblaDirection'),
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textHeadingColor(context),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isAligned
                                ? AppColors.statusPositive.withValues(
                                    alpha: 0.15,
                                  )
                                : (isDark
                                      ? AppColors.darkSurfaceContainerHigh
                                      : AppColors.canvasCream),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isAligned
                                  ? AppColors.statusPositive
                                  : AppColors.cardBorderColor(context),
                            ),
                          ),
                          child: Text(
                            '$qiblaDeg° Ka\'bah',
                            style: AppTypography.captionSmall.copyWith(
                              color: isAligned
                                  ? AppColors.statusPositive
                                  : AppColors.textHeadingColor(context),
                              fontWeight: FontWeight.w800,
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
                              : AppColors.canvasCream,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          context.tr('kompasNoSensor'),
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
                          width: 200,
                          height: 200,
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
                                blurRadius: isAligned ? 22 : 12,
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
                                    fontWeight: FontWeight.w800,
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
                                    fontWeight: FontWeight.w800,
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
                                    fontWeight: FontWeight.w800,
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
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textBodyColor(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                              // Concentric inner circle
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.tanMedium.withValues(
                                      alpha: isDark ? 0.3 : 0.25,
                                    ),
                                  ),
                                ),
                              ),

                              // Dynamic Rotating Qibla Needle
                              Transform.rotate(
                                angle: safeAngle,
                                child: SizedBox(
                                  width: 150,
                                  height: 150,
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
                                              Icons.mosque_rounded,
                                              size: 26,
                                              color: isAligned
                                                  ? AppColors.statusPositive
                                                  : AppColors.goldPrimary,
                                            ),
                                            Container(
                                              width: 4,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isAligned
                                                    ? AppColors.statusPositive
                                                    : AppColors.goldPrimary,
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
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.tanMedium
                                                .withValues(
                                                  alpha: isDark ? 0.5 : 0.45,
                                                ),
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
                                                    ? AppColors.goldPrimary
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
                                    : AppColors.canvasCream),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isAligned
                                ? AppColors.statusPositive.withValues(
                                    alpha: 0.4,
                                  )
                                : AppColors.cardBorderColor(context),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAligned
                                  ? Icons.check_circle_rounded
                                  : Icons.navigation_rounded,
                              size: 16,
                              color: isAligned
                                  ? AppColors.statusPositive
                                  : AppColors.tanMedium,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isAligned
                                    ? context.tr('qiblaAligned')
                                    : '${context.tr('qiblaRotate')}: ${safeOffset.toStringAsFixed(0)}° ${context.tr('qiblaRotateToKabah')}',
                                style: AppTypography.captionSmall.copyWith(
                                  color: isAligned
                                      ? AppColors.statusPositive
                                      : AppColors.textHeadingColor(context),
                                  fontWeight: FontWeight.w800,
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
            const SizedBox(height: AppSpacing.md),

            // ── Full Day Dynamic Schedule ──────────────────────────────────
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceContainerHigh
                                      : AppColors.canvasCream,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: isDark
                                      ? AppColors.goldLight
                                      : AppColors.espressoDark,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context
                                          .tr('prayerScheduleSectionTitle')
                                          .isEmpty
                                      ? 'Jadwal 5 Waktu Sholat'
                                      : context.tr(
                                          'prayerScheduleSectionTitle',
                                        ),
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textHeadingColor(context),
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
                        Obx(() {
                          final isAnyOn = controller.isAnySoundOn;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                controller.toggleAllPrayerSounds();
                                final nowOn = !isAnyOn;
                                Get.closeAllSnackbars();
                                Get.snackbar(
                                  nowOn
                                      ? 'Suara Adzan Diaktifkan'
                                      : 'Suara Adzan Dimatikan',
                                  nowOn
                                      ? 'Semua jadwal sholat akan mengumandangkan adzan.'
                                      : 'Semua suara adzan dimatikan (mode hening).',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: isDark
                                      ? AppColors.darkSurfaceContainerHigh
                                      : AppColors.espressoDark,
                                  colorText: nowOn
                                      ? AppColors.goldLight
                                      : AppColors.surfaceWhite,
                                  icon: Icon(
                                    nowOn
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_off_rounded,
                                    color: nowOn
                                        ? AppColors.goldPrimary
                                        : AppColors.tanMedium,
                                  ),
                                  margin: const EdgeInsets.all(AppSpacing.md),
                                  borderRadius: AppRadius.md,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isAnyOn
                                      ? (isDark
                                            ? AppColors.goldPrimary.withValues(
                                                alpha: 0.15,
                                              )
                                            : AppColors.goldLight.withValues(
                                                alpha: 0.35,
                                              ))
                                      : (isDark
                                            ? AppColors.darkSurfaceContainerHigh
                                            : AppColors.canvasCream),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: isAnyOn
                                        ? AppColors.goldPrimary.withValues(
                                            alpha: 0.6,
                                          )
                                        : AppColors.cardBorderColor(context),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAnyOn
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_off_rounded,
                                      size: 15,
                                      color: isAnyOn
                                          ? AppColors.goldPrimary
                                          : (isDark
                                                ? AppColors.darkTextBody
                                                : AppColors.tanMedium),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isAnyOn ? 'Adzan Aktif' : 'Adzan Hening',
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                            color: isAnyOn
                                                ? (isDark
                                                      ? AppColors.goldLight
                                                      : AppColors.espressoDark)
                                                : (isDark
                                                      ? AppColors.darkTextBody
                                                      : AppColors.tanMedium),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.cardBorderColor(context)),
                  Obx(
                    () => Column(
                      children: controller.prayers.map((p) {
                        return _buildPrayerRow(
                          context: context,
                          controller: controller,
                          name: p.name,
                          arabicName: p.arabicName,
                          time: p.formattedTime,
                          isNext: p.isNext,
                        );
                      }).toList(),
                    ),
                  ),
                ],
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
    required PrayerTimesController controller,
    required String name,
    required String arabicName,
    required String time,
    required bool isNext,
  }) {
    final isDark = AppColors.isDark(context);
    final isTerbit =
        name.toLowerCase() == 'terbit' || name.toLowerCase() == 'sunrise';

    return Obx(() {
      final isSoundOn = controller.isPrayerSoundOn(name);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isNext
              ? (isDark
                    ? AppColors.darkPrimaryContainer.withValues(alpha: 0.5)
                    : AppColors.canvasCream.withValues(alpha: 0.7))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.cardBorderColor(context).withValues(alpha: 0.7),
            ),
            left: isNext
                ? const BorderSide(color: AppColors.goldPrimary, width: 4)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isTerbit
                    ? null
                    : () {
                        controller.togglePrayerSound(name);
                        final willBeOn = !isSoundOn;
                        Get.closeAllSnackbars();
                        Get.snackbar(
                          willBeOn
                              ? 'Suara Adzan Aktif'
                              : 'Suara Adzan Dimatikan',
                          willBeOn
                              ? 'Suara adzan $name akan berbunyi saat masuk waktu.'
                              : 'Suara adzan $name tidak akan berbunyi.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceContainerHigh
                              : AppColors.espressoDark,
                          colorText: willBeOn
                              ? AppColors.goldLight
                              : AppColors.surfaceWhite,
                          icon: Icon(
                            willBeOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: willBeOn
                                ? AppColors.goldPrimary
                                : AppColors.tanMedium,
                          ),
                          margin: const EdgeInsets.all(AppSpacing.md),
                          borderRadius: AppRadius.md,
                          duration: const Duration(seconds: 2),
                        );
                      },
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isTerbit
                        ? (isDark
                              ? AppColors.darkSurfaceContainerHigh
                              : AppColors.canvasCream)
                        : (isSoundOn
                              ? (isNext
                                    ? (isDark
                                          ? AppColors.darkPrimaryContainer
                                          : AppColors.espressoDark)
                                    : (isDark
                                          ? AppColors.goldPrimary.withValues(
                                              alpha: 0.18,
                                            )
                                          : AppColors.goldLight.withValues(
                                              alpha: 0.3,
                                            )))
                              : (isDark
                                    ? AppColors.darkSurfaceContainerHigh
                                    : AppColors.canvasCream)),
                    shape: BoxShape.circle,
                    border: !isTerbit && isSoundOn
                        ? Border.all(
                            color: AppColors.goldPrimary.withValues(
                              alpha: isNext ? 1.0 : 0.6,
                            ),
                            width: 1.5,
                          )
                        : Border.all(
                            color: AppColors.cardBorderColor(context),
                            width: 1,
                          ),
                  ),
                  child: Icon(
                    isTerbit
                        ? Icons.wb_sunny_rounded
                        : (isSoundOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded),
                    size: 18,
                    color: isTerbit
                        ? (isDark
                              ? AppColors.darkTextBody
                              : AppColors.tanMedium)
                        : (isSoundOn
                              ? AppColors.goldPrimary
                              : (isDark
                                    ? AppColors.darkTextBody.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.tanMedium.withValues(
                                        alpha: 0.6,
                                      ))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isNext
                          ? (isDark
                                ? AppColors.goldLight
                                : AppColors.espressoDark)
                          : AppColors.textHeadingColor(context),
                      fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    arabicName,
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextBody
                          : AppColors.tanMedium,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNext) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.espressoDark,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.goldPrimary,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      context.tr('prayerNextBadge').isEmpty
                          ? 'Berikutnya'
                          : context.tr('prayerNextBadge'),
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.goldPrimary,
                        fontWeight: FontWeight.w800,
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
                    fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
