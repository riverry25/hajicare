import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/state/app_settings_controller.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../controllers/prayer_times_controller.dart';
import '../widgets/next_prayer_luxury_hero.dart';
import '../widgets/qibla_astrolabe_compass.dart';

class PrayerTimesScreen extends StatelessWidget {
  final bool showBottomNav;
  const PrayerTimesScreen({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PrayerTimesController>();
    final colors = context.hc;
    final isDark = context.isDark;
    final headingColor = colors.textPrimary;
    final AppSettingsController? settings =
        Get.isRegistered<AppSettingsController>()
        ? Get.find<AppSettingsController>()
        : null;

    return Obx(() {
      settings?.rxLocale.value;

      return Scaffold(
        backgroundColor: colors.canvas,
        extendBody: true,
        body: RefreshIndicator(
          onRefresh: () => controller.refreshLocation(),
          color: colors.accent,
          backgroundColor: colors.surface,
          child: ResponsiveCenter(
            maxWidth: AppBreakpoints.maxTabletContentWidth,
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
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF2E1C12), Color(0xFF1B1009)]
                              : [colors.primary, colors.primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: colors.accent, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.25),
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
                              color: colors.accent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.accent.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Icon(
                              Icons.volume_up_rounded,
                              color: colors.accent,
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
                                      decoration: BoxDecoration(
                                        color: colors.success,
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
                                        style: context.text.titleSmall.copyWith(
                                          color: colors.accent,
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
                                  style: context.text.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextBody
                                        : colors.surfaceSand,
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
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.danger,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.danger.withValues(
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
                                    Icon(
                                      Icons.volume_off_rounded,
                                      size: 16,
                                      color: colors.onPrimary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      context.tr('prayerStopAdhan'),
                                      style: context.text.labelSmall.copyWith(
                                        color: colors.onPrimary,
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

                  // ── Realtime Next Prayer Hero (Modern Islamic Luxury) ───────────
                  NextPrayerLuxuryHero(controller: controller),
                  const SizedBox(height: AppSpacing.md),

                  // ── Dynamic Qibla Compass (Modern Astrolabe Instrument) ─────────
                  QiblaAstrolabeCompass(controller: controller),
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
                                        color: colors.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.calendar_month_rounded,
                                        color: isDark
                                            ? colors.accent
                                            : colors.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        context
                                                .tr(
                                                  'prayerScheduleSectionTitle',
                                                )
                                                .isEmpty
                                            ? 'Jadwal 5 Waktu Sholat'
                                            : context.tr(
                                                'prayerScheduleSectionTitle',
                                              ),
                                        style: context.text.titleMedium
                                            .copyWith(
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
                                            ? colors.surfaceSubtle
                                            : colors.primary,
                                        colorText: nowOn
                                            ? (isDark
                                                  ? colors.accent
                                                  : colors.onPrimary)
                                            : colors.onPrimary,
                                        icon: Icon(
                                          nowOn
                                              ? Icons.volume_up_rounded
                                              : Icons.volume_off_rounded,
                                          color: nowOn
                                              ? colors.accent
                                              : (isDark
                                                    ? colors.textSecondary
                                                    : colors.surfaceSand),
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
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAnyOn
                                            ? (isDark
                                                  ? colors.accent.withValues(
                                                      alpha: 0.15,
                                                    )
                                                  : colors.surfaceSand
                                                        .withValues(alpha: 0.5))
                                            : colors.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                        border: Border.all(
                                          color: isAnyOn
                                              ? colors.accent.withValues(
                                                  alpha: 0.6,
                                                )
                                              : colors.border,
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
                                                ? colors.accent
                                                : colors.textSecondary,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isAnyOn
                                                ? context.tr(
                                                    'prayerAdhanActive',
                                                  )
                                                : context.tr(
                                                    'prayerAdhanSilent',
                                                  ),
                                            style: context.text.labelSmall
                                                .copyWith(
                                                  color: isAnyOn
                                                      ? (isDark
                                                            ? colors.accent
                                                            : colors.primary)
                                                      : colors.textSecondary,
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
                        Divider(height: 1, color: colors.border),
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
    final colors = context.hc;
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
                style: context.text.titleLarge.copyWith(
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
                style: context.text.bodySmall.copyWith(
                  color: colors.textSecondary,
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
    final colors = context.hc;

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
                    Color(0xFF26180E),
                    Color(0xFF1A1009),
                    Color(0xFF120B06),
                  ]
                : [
                    colors.primary,
                    const Color(0xFF2E1C12),
                    const Color(0xFF23160D),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isFallback
                ? colors.danger.withValues(alpha: isDark ? 0.5 : 0.35)
                : (isDark
                      ? AppColors.darkSecondary.withValues(alpha: 0.45)
                      : colors.accent.withValues(alpha: 0.25)),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : colors.primary).withValues(
                alpha: isDark ? 0.4 : 0.22,
              ),
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
                                        Color(0xFF382415),
                                        Color(0xFF20130A),
                                      ]
                                    : [colors.primary, const Color(0xFF22160E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: isFallback
                                    ? colors.danger
                                    : (isDark
                                          ? AppColors.darkSecondary
                                          : colors.accent),
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isFallback
                                              ? colors.danger
                                              : (isDark
                                                    ? AppColors.darkSecondary
                                                    : colors.accent))
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
                                  ? colors.danger
                                  : (isDark
                                        ? AppColors.darkSecondary
                                        : colors.accent),
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
                                    ? colors.danger
                                    : (isDark
                                          ? AppColors.darkSecondary
                                          : colors.accent),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.espressoDark,
                                  width: 1.8,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: isLoading
                                  ? SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        color: colors.primary,
                                      ),
                                    )
                                  : Icon(
                                      isFallback
                                          ? Icons.priority_high_rounded
                                          : Icons.sync_rounded,
                                      size: 11,
                                      color: isFallback
                                          ? Colors.white
                                          : colors.primary,
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
                                      ? colors.danger
                                      : (isDark
                                            ? AppColors.darkSecondary
                                            : colors.accent),
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
                                    style: context.text.labelSmall.copyWith(
                                      color: isFallback
                                          ? colors.danger
                                          : (isDark
                                                ? AppColors.darkSecondary
                                                : colors.accent),
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
                              style: context.text.titleMedium.copyWith(
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
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.08 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkSecondary.withValues(
                                      alpha: 0.45,
                                    )
                                  : Colors.white.withValues(alpha: 0.22),
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
                                      ? colors.danger
                                      : colors.success,
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
                                  style: context.text.labelSmall.copyWith(
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
    final colors = context.hc;
    final isDark = context.isDark;
    final isTerbit =
        name.toLowerCase() == 'terbit' || name.toLowerCase() == 'sunrise';

    return Obx(() {
      final isSoundOn = controller.isPrayerSoundOn(name);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isNext
              ? (isDark
                    ? colors.primaryContainer.withValues(alpha: 0.5)
                    : colors.surfaceSand.withValues(alpha: 0.5))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: colors.border.withValues(alpha: 0.7)),
            left: isNext
                ? BorderSide(color: colors.accent, width: 4)
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
                              ? colors.surfaceSubtle
                              : colors.primary,
                          colorText: willBeOn
                              ? (isDark ? colors.accent : colors.onPrimary)
                              : colors.onPrimary,
                          icon: Icon(
                            willBeOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: willBeOn
                                ? colors.accent
                                : (isDark
                                      ? colors.textSecondary
                                      : colors.surfaceSand),
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
                        ? colors.surfaceSubtle
                        : (isSoundOn
                              ? (isNext
                                    ? (isDark
                                          ? colors.primaryContainer
                                          : colors.primary)
                                    : colors.accent.withValues(
                                        alpha: isDark ? 0.18 : 0.25,
                                      ))
                              : colors.surfaceSubtle),
                    shape: BoxShape.circle,
                    border: !isTerbit && isSoundOn
                        ? Border.all(
                            color: colors.accent.withValues(
                              alpha: isNext ? 1.0 : 0.6,
                            ),
                            width: 1.5,
                          )
                        : Border.all(color: colors.border, width: 1),
                  ),
                  child: Icon(
                    isTerbit
                        ? Icons.wb_sunny_rounded
                        : (isSoundOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded),
                    size: 18,
                    color: isTerbit
                        ? colors.textSecondary
                        : (isSoundOn ? colors.accent : colors.textTertiary),
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
                    style: context.text.bodyLarge.copyWith(
                      color: isNext
                          ? (isDark ? colors.accent : colors.primary)
                          : colors.textPrimary,
                      fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    arabicName,
                    style: AppTypography.arabicSmall.copyWith(
                      color: colors.textSecondary,
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
                      color: isDark ? colors.primaryContainer : colors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: colors.accent, width: 1),
                    ),
                    child: Text(
                      context.tr('prayerNextBadge').isEmpty
                          ? 'Berikutnya'
                          : context.tr('prayerNextBadge'),
                      style: context.text.labelSmall.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  time,
                  style: context.text.titleMedium.copyWith(
                    color: isNext
                        ? (isDark ? colors.accent : colors.primary)
                        : colors.textPrimary,
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
    final colors = context.hc;
    final isDark = context.isDark;
    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeScale = textScaler.scale(1) > 1.25;
    final isExtraLarge = textScaler.scale(1) > 1.4;

    final double bannerHeight = isExtraLarge
        ? 104.0
        : (isLargeScale ? 96.0 : 86.0);
    const double bannerProtrude = 30.0;

    final headingColor = colors.textPrimary;
    final bodyColor = colors.textSecondary;
    final cardBg = colors.surface;
    final borderColor = colors.border;
    final innerCardBg = colors.surfaceSubtle;

    return Padding(
      padding: const EdgeInsets.only(top: bannerProtrude),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── 1. Main Card Container ──────────────────────────────────
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
                  color: (isDark ? Colors.black : colors.primary).withValues(
                    alpha: isDark ? 0.35 : 0.07,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtitle
                Text(
                  context.tr('prayerBgSubtitle'),
                  style: context.text.bodySmall.copyWith(
                    color: bodyColor,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Tag Chips Row
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

                // Container Petunjuk Ramah Lansia
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
                              color: colors.accent.withValues(
                                alpha: isDark ? 0.25 : 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lightbulb_rounded,
                              size: 16,
                              color: colors.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr('prayerBgGuideTitle'),
                              style: context.text.bodyMedium.copyWith(
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

          // ── 2. Elevated Floating Top Banner ────────────────────────
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
                      ? const [
                          Color(0xFF26180E),
                          Color(0xFF1C1109),
                          Color(0xFF120A05),
                        ]
                      : [
                          colors.primary,
                          const Color(0xFF2E1C12),
                          const Color(0xFF23160D),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : colors.primary).withValues(
                      alpha: 0.35,
                    ),
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

                  // Content inside Banner
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
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [
                                      AppColors.darkSecondary,
                                      AppColors.secondary,
                                    ]
                                  : [colors.accent, colors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.accent.withValues(alpha: 0.4),
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
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 13,
                                    color: isDark
                                        ? AppColors.darkSecondary
                                        : colors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'PENGINGAT OTOMATIS',
                                      style: context.text.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkSecondary
                                            : colors.accent,
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
                                style: context.text.titleMedium.copyWith(
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

                        // Top-Right Glassmorphic Badge
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
                                decoration: BoxDecoration(
                                  color: colors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Aktif',
                                style: context.text.labelSmall.copyWith(
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
    final colors = context.hc;
    final bg = isPrimary
        ? (isDark
              ? colors.primaryContainer.withValues(alpha: 0.6)
              : colors.primary)
        : colors.surfaceSubtle;
    final borderColor = isPrimary ? colors.accent : colors.border;
    final textColor = isPrimary
        ? (isDark ? colors.accent : colors.onPrimary)
        : colors.textPrimary;

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
            style: context.text.labelSmall.copyWith(
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
    final colors = context.hc;
    final headingColor = colors.textPrimary;
    final bodyColor = colors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: isDark ? 0.2 : 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.accent.withValues(alpha: isDark ? 0.35 : 0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 15, color: colors.accent),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: headingColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: context.text.bodySmall.copyWith(
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
