import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/state/app_settings_controller.dart';
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
    final headingColor = AppColors.textHeadingColor(context);
    final AppSettingsController? settings =
        Get.isRegistered<AppSettingsController>()
        ? Get.find<AppSettingsController>()
        : null;

    return Obx(() {
      settings?.rxLocale.value;

      return Scaffold(
        backgroundColor: AppColors.scaffoldColor(context),
        extendBody: true,
        body: RefreshIndicator(
          onRefresh: () => controller.refreshLocation(),
          color: AppColors.goldPrimary,
          backgroundColor: isDark
              ? AppColors.darkSurfaceContainerHigh
              : AppColors.surfaceWhite,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenEdgeGutter,
              MediaQuery.paddingOf(context).top,
              AppSpacing.screenEdgeGutter,
              100,
            ),
            child: Column(
              children: [
                // ── Custom Page Header (replaces AppBar) ──────────────────────
                _buildPageHeader(context, headingColor, isDark),

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
                      border: Border.all(
                        color: AppColors.goldPrimary,
                        width: 1.5,
                      ),
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
                            color: AppColors.goldPrimary.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.goldPrimary.withValues(
                                alpha: 0.6,
                              ),
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
                                      context.tr('prayerAdhanResonating', {
                                        'name': context.localizedPrayerName(
                                          playingName,
                                        ),
                                      }),
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withValues(
                                      alpha: 0.35,
                                    ),
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
                                    context.tr('prayerStopAdhan'),
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

                // ── Dynamic Location & Hijri Date Card (Pilgrim Card Design) ───
                _buildLocationPilgrimCard(
                  context: context,
                  controller: controller,
                  isDark: isDark,
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
                            color: AppColors.surfaceWhite.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.goldPrimary.withValues(
                                alpha: 0.35,
                              ),
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
                          context.localizedPrayerName(
                            controller.nextPrayerName.value,
                          ),
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
                          style: AppTypography.arabicMedium.copyWith(
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
                            color: AppColors.surfaceWhite.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.goldPrimary.withValues(
                                alpha: 0.4,
                              ),
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
                                  '${context.tr('prayerTimeRemaining')}: ${controller.formatCountdown(context)}',
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
                                              ? AppColors
                                                    .darkSurfaceContainerHigh
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: isAligned
                                      ? AppColors.statusPositive
                                      : AppColors.cardBorderColor(context),
                                ),
                              ),
                              child: Text(
                                '$qiblaDeg° ${context.tr('qiblaKabah')}',
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
                                              ? Colors.black.withValues(
                                                  alpha: 0.3,
                                                )
                                              : AppColors.espressoDark
                                                    .withValues(alpha: 0.08)),
                                    blurRadius: isAligned ? 22 : 12,
                                    spreadRadius: isAligned ? 4 : 1,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Dial markings (U, S, B, T)
                                  Positioned(
                                    top: 8,
                                    child: Text(
                                      context.tr('compassNorth'),
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    child: Text(
                                      context.tr('compassSouth'),
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textBodyColor(context),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 10,
                                    child: Text(
                                      context.tr('compassWest'),
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textBodyColor(context),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 10,
                                    child: Text(
                                      context.tr('compassEast'),
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textBodyColor(context),
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
                                                        ? AppColors
                                                              .statusPositive
                                                        : AppColors.goldPrimary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          2,
                                                        ),
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
                                                      alpha: isDark
                                                          ? 0.5
                                                          : 0.45,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(2),
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
                                                        : AppColors
                                                              .espressoDark),
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
                                  ? AppColors.statusPositive.withValues(
                                      alpha: 0.15,
                                    )
                                  : (isDark
                                        ? AppColors.darkSurfaceContainerHigh
                                        : AppColors.canvasCream),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
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
                                        color: AppColors.textHeadingColor(
                                          context,
                                        ),
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
                                          ? context.tr('prayerSoundAllActive')
                                          : context.tr('prayerSoundAllMuted'),
                                      nowOn
                                          ? context.tr(
                                              'prayerSoundAllActiveDesc',
                                            )
                                          : context.tr(
                                              'prayerSoundAllMutedDesc',
                                            ),
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
                                      margin: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
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
                                                ? AppColors.goldPrimary
                                                      .withValues(alpha: 0.15)
                                                : AppColors.goldLight
                                                      .withValues(alpha: 0.35))
                                          : (isDark
                                                ? AppColors
                                                      .darkSurfaceContainerHigh
                                                : AppColors.canvasCream),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      border: Border.all(
                                        color: isAnyOn
                                            ? AppColors.goldPrimary.withValues(
                                                alpha: 0.6,
                                              )
                                            : AppColors.cardBorderColor(
                                                context,
                                              ),
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
                                          isAnyOn
                                              ? context.tr('prayerAdhanActive')
                                              : context.tr('prayerAdhanSilent'),
                                          style: AppTypography.captionSmall
                                              .copyWith(
                                                color: isAnyOn
                                                    ? (isDark
                                                          ? AppColors.goldLight
                                                          : AppColors
                                                                .espressoDark)
                                                    : (isDark
                                                          ? AppColors
                                                                .darkTextBody
                                                          : AppColors
                                                                .tanMedium),
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
                      Divider(
                        height: 1,
                        color: AppColors.cardBorderColor(context),
                      ),
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
                const SizedBox(height: AppSpacing.lg),
                _buildAdhanBackgroundCard(
                  context: context,
                  controller: controller,
                ),
                const SizedBox(height: AppConstants.space3xl),
              ],
            ),
          ),
        ),
        bottomNavigationBar: showBottomNav
            ? const HajiCareBottomNavBar(currentIndex: 2)
            : null,
      );
    });
  }

  // ── Custom Page Header: title+subtitle centered like Profile Page ─────────
  Widget _buildPageHeader(
    BuildContext context,
    Color headingColor,
    bool isDark,
  ) {
    final bodyColor = AppColors.textBodyColor(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (canPop)
            Positioned(
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: headingColor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                context.tr('prayerTitle').isEmpty
                    ? 'Jadwal Sholat & Kiblat'
                    : context.tr('prayerTitle'),
                style: AppTypography.headlineMd.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('prayerSubtitle').isEmpty
                    ? 'Waktu sholat akurat & kompas arah Ka\'bah'
                    : context.tr('prayerSubtitle'),
                style: AppTypography.bodySmall.copyWith(
                  color: bodyColor,
                  fontSize: 12.5,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dynamic Location & Hijri Date Card (Pilgrim Card Design) ───────────────
  Widget _buildLocationPilgrimCard({
    required BuildContext context,
    required PrayerTimesController controller,
    required bool isDark,
  }) {
    return Obx(() {
      final isFallback = controller.isUsingFallbackLocation;
      final locationName = controller.locationName.value.trim().isNotEmpty
          ? controller.locationName.value.trim()
          : (isFallback ? 'Makkah, Arab Saudi' : context.tr('prayerLocation'));
      final hijriDate = controller.hijriDateText.value.trim().isNotEmpty
          ? controller.hijriDateText.value.trim()
          : '1445 H';
      final isLoading = controller.isLoadingLocation.value;

      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    AppColors.darkPrimaryContainer,
                    AppColors.espressoDark,
                    Color(0xFF160E09),
                  ]
                : const [
                    AppColors.primary,
                    AppColors.espressoDark,
                    Color(0xFF23160D),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isFallback
                ? AppColors.error.withValues(alpha: isDark ? 0.5 : 0.35)
                : AppColors.goldPrimary.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.espressoDark)
                  .withValues(alpha: isDark ? 0.4 : 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : () => controller.refreshLocation(),
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // 3D Concentric Ripples in top-right (Pilgrim Card signature aesthetic)
                Positioned(
                  top: -45,
                  right: -45,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ripple ring
                        Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Mid ripple ring 2
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Mid ripple ring 1
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Inner ripple
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Glossy Glass Arc Highlight across top
                Positioned(
                  top: -50,
                  left: -30,
                  right: -30,
                  height: 110,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.elliptical(260, 90),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content inside Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar / Circular Icon with Gold Border & Status Badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDark
                                    ? const [
                                        AppColors.darkPrimaryContainer,
                                        AppColors.darkSurfaceContainerHigh,
                                      ]
                                    : const [
                                        AppColors.espressoDark,
                                        Color(0xFF22160E),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: isFallback
                                    ? AppColors.error
                                    : AppColors.goldPrimary,
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isFallback
                                              ? AppColors.error
                                              : AppColors.goldPrimary)
                                          .withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              isFallback
                                  ? Icons.location_off_outlined
                                  : Icons.location_on_rounded,
                              size: 24,
                              color: isFallback
                                  ? AppColors.tanMedium
                                  : AppColors.goldLight,
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isFallback
                                    ? AppColors.error
                                    : AppColors.goldPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.espressoDark
                                      : const Color(0xFF23160D),
                                  width: 1.8,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        color: AppColors.espressoDark,
                                      ),
                                    )
                                  : Icon(
                                      isFallback
                                          ? Icons.priority_high_rounded
                                          : Icons.sync_rounded,
                                      size: 11,
                                      color: isFallback
                                          ? Colors.white
                                          : AppColors.espressoDark,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Location Title & Subtitle beside Avatar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFallback
                                      ? Icons.info_outline_rounded
                                      : Icons.verified_rounded,
                                  size: 14,
                                  color: isFallback
                                      ? AppColors.tanMedium
                                      : AppColors.accentGoldStar,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    isLoading
                                        ? context.tr('prayerLoading')
                                        : (isFallback
                                              ? context.tr(
                                                  'prayerFallbackBadge',
                                                )
                                              : context.tr('prayerLocation')),
                                    style: AppTypography.heading(
                                      color: AppColors.goldLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              locationName,
                              style: AppTypography.heading(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Top-Right Glassmorphic Badge (Hijri Date & Status)
                      Flexible(
                        flex: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isFallback
                                      ? AppColors.error
                                      : AppColors.statusSafe,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 120,
                                ),
                                child: Text(
                                  hijriDate,
                                  style: AppTypography.heading(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
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
                              ? context.tr('prayerAdhanActive')
                              : context.tr('prayerAdhanSilent'),
                          willBeOn
                              ? context.tr('prayerSoundOneActiveDesc', {
                                  'name': context.localizedPrayerName(name),
                                })
                              : context.tr('prayerSoundOneMutedDesc', {
                                  'name': context.localizedPrayerName(name),
                                }),
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
                    context.localizedPrayerName(name),
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
                    style: AppTypography.arabicSmall.copyWith(
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

  Widget _buildAdhanBackgroundCard({
    required BuildContext context,
    required PrayerTimesController controller,
  }) {
    final isDark = AppColors.isDark(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeScale = textScaler.scale(1) > 1.25;
    final isExtraLarge = textScaler.scale(1) > 1.4;

    final double bannerHeight = isExtraLarge
        ? 104.0
        : (isLargeScale ? 96.0 : 86.0);
    const double bannerProtrude = 30.0;

    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceWhite;
    final borderColor = isDark
        ? AppColors.darkOutlineVariant
        : AppColors.cardBorderColor(context);
    final innerCardBg = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.canvasCreamSubtle.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.only(top: bannerProtrude),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── 1. Main Card Container (Tailwind Card Body) ──────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              isLargeScale ? AppSpacing.lg : 20,
              (bannerHeight - bannerProtrude) + 18,
              isLargeScale ? AppSpacing.lg : 20,
              20,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : AppColors.espressoDark.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtitle / Deskripsi
                Text(
                  context.tr('prayerBgSubtitle'),
                  style: AppTypography.bodySmall.copyWith(
                    color: bodyColor,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Tag Chips Row (seperti Kartu Jamaah di profil)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPrayerTagChip(
                      context: context,
                      icon: Icons.alarm_on_rounded,
                      label: 'Alarm Otomatis',
                      isDark: isDark,
                      isPrimary: true,
                    ),
                    _buildPrayerTagChip(
                      context: context,
                      icon: Icons.screen_lock_portrait_rounded,
                      label: 'Layar Terkunci',
                      isDark: isDark,
                      isPrimary: false,
                    ),
                    _buildPrayerTagChip(
                      context: context,
                      icon: Icons.volume_up_rounded,
                      label: 'Audio Tepat Waktu',
                      isDark: isDark,
                      isPrimary: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Container Petunjuk Ramah Lansia (Terstruktur & Rapi)
                Container(
                  padding: EdgeInsets.all(isLargeScale ? AppSpacing.md : 14),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: borderColor.withValues(alpha: isDark ? 0.6 : 0.8),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.goldPrimary.withValues(
                                alpha: isDark ? 0.25 : 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lightbulb_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.goldLight
                                  : AppColors.goldPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr('prayerBgGuideTitle'),
                              style: AppTypography.bodyMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAdhanGuideStep(
                        context: context,
                        icon: Icons.alarm_on_rounded,
                        title: context.tr('prayerStepReminderTitle'),
                        description: context.tr('prayerStepReminderDesc'),
                        isDark: isDark,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: borderColor.withValues(alpha: 0.45),
                          height: 1,
                        ),
                      ),
                      _buildAdhanGuideStep(
                        context: context,
                        icon: Icons.volume_up_rounded,
                        title: context.tr('prayerStepAlarmPermTitle'),
                        description: context.tr('prayerStepAlarmPermDesc'),
                        isDark: isDark,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: borderColor.withValues(alpha: 0.45),
                          height: 1,
                        ),
                      ),
                      _buildAdhanGuideStep(
                        context: context,
                        icon: Icons.battery_charging_full_rounded,
                        title: context.tr('prayerStepBatteryTitle'),
                        description: context.tr('prayerStepBatteryDesc'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Elevated Floating Top Banner (Identik dengan Kartu Jamaah di Profile) ──
          Positioned(
            top: -bannerProtrude,
            left: 12,
            right: 12,
            height: bannerHeight,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.darkPrimaryContainer,
                          AppColors.espressoDark,
                          const Color(0xFF160E09),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.espressoDark,
                          const Color(0xFF23160D),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppColors.espressoDark)
                        .withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 3D Concentric Ripples in top-right
                  Positioned(
                    top: -45,
                    right: -45,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.03),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.07),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Glossy Glass Arc Highlight across top
                  Positioned(
                    top: -50,
                    left: -30,
                    right: -30,
                    height: 110,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.elliptical(260, 90),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content inside Banner: Icon Avatar + Title + Glassmorphic Status Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gold Bell Icon Badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.goldPrimary,
                                AppColors.goldDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldPrimary.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 13,
                                    color: AppColors.accentGoldStar,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'PENGINGAT OTOMATIS',
                                      style: AppTypography.heading(
                                        color: AppColors.goldLight,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                context.tr('prayerBgTitle'),
                                style: AppTypography.heading(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Top-Right Glassmorphic Badge (Like Profile Card)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.statusSafe,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Aktif',
                                style: AppTypography.heading(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTagChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required bool isPrimary,
  }) {
    final bg = isPrimary
        ? (isDark
              ? AppColors.darkPrimaryContainer.withValues(alpha: 0.6)
              : AppColors.espressoDark)
        : (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.canvasCream);
    final borderColor = isPrimary
        ? AppColors.goldPrimary
        : AppColors.cardBorderColor(context);
    final textColor = isPrimary
        ? (isDark ? AppColors.goldPrimary : Colors.white)
        : AppColors.textHeadingColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.heading(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdhanGuideStep({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.goldPrimary.withValues(alpha: isDark ? 0.2 : 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.goldPrimary.withValues(
                alpha: isDark ? 0.35 : 0.2,
              ),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isDark ? AppColors.goldLight : AppColors.goldPrimary,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: headingColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: bodyColor,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
