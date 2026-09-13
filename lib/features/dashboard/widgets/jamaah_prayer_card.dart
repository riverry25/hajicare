import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:hajicare/features/prayer/models/prayer_schedule_item.dart';

class JamaahPrayerCard extends StatelessWidget {
  const JamaahPrayerCard({super.key});

  String _localizedPrayerName(BuildContext context, String rawName) {
    final name = rawName.trim().toLowerCase();
    if (name == 'subuh' || name == 'fajr') return context.tr('subuh');
    if (name == 'terbit' || name == 'sunrise') return context.tr('terbit');
    if (name == 'dzuhur' || name == 'dhuhr') return context.tr('dzuhur');
    if (name == 'ashar' || name == 'asr') return context.tr('ashar');
    if (name == 'maghrib') return context.tr('maghrib');
    if (name == 'isya' || name == 'isha') return context.tr('isya');
    return rawName;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    // Resolve PrayerTimesController registered in DashboardBinding
    final prayerCtrl = Get.isRegistered<PrayerTimesController>()
        ? Get.find<PrayerTimesController>()
        : Get.put(PrayerTimesController());

    return Obx(() {
      final locName = prayerCtrl.locationName.value;
      final displayCity = locName.isNotEmpty ? locName.split(',').first.trim() : '';
      final qiblaDeg = prayerCtrl.qiblaBearing.value;
      final nextName = prayerCtrl.nextPrayerName.value.isNotEmpty
          ? prayerCtrl.nextPrayerName.value
          : 'Subuh';
      final nextTime = prayerCtrl.nextPrayerTime.value;
      final countdown = prayerCtrl.countdownText.value;

      // Filter to the 5 canonical fardhu prayers (exclude Sunrise/Terbit for mini time bar)
      final allPrayers = prayerCtrl.prayers;
      final fardhuPrayers = allPrayers.isNotEmpty
          ? allPrayers.where((p) {
              final n = p.name.toLowerCase();
              return n != 'terbit' && n != 'sunrise';
            }).toList()
          : <PrayerScheduleItem>[];

      return AppCard(
        backgroundColor: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLow,
        borderColor: isDark
            ? AppColors.darkOutlineVariant
            : AppColors.goldLight.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Schedule Title + Location + Qibla Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: AppColors.accentGoldStar,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          displayCity.isNotEmpty
                              ? '${context.tr('prayerScheduleTitle')} • ${displayCity.toUpperCase()}'
                              : context.tr('prayerScheduleTitle'),
                          style: AppTypography.captionSmall.copyWith(
                            color: isDark ? AppColors.darkPrimary : AppColors.espressoDark,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.surfaceWhite.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.goldLight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.explore_rounded,
                        color: AppColors.accentGoldStar,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        qiblaDeg > 0
                            ? '${context.tr('qiblaDegree')} ${qiblaDeg.toStringAsFixed(0)}°'
                            : '${context.tr('qiblaDegree')} --°',
                        style: AppTypography.captionSmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Next Prayer Spotlight Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.goldLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('nextPrayerLabel'),
                          style: AppTypography.caption.copyWith(
                            color: bodyColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: 2,
                          children: [
                            Text(
                              _localizedPrayerName(context, nextName),
                              style: AppTypography.displayMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              nextTime,
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark
                                    ? AppColors.accentGoldStar
                                    : AppColors.tanMedium,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (countdown.isNotEmpty && countdown != '--:--:--')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${context.tr('inCountdownPrefix')} $countdown',
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.surfaceWhite,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 5 Daily Prayers Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: fardhuPrayers.isNotEmpty
                  ? fardhuPrayers.map((item) {
                      final localizedName = _localizedPrayerName(context, item.name);
                      // Extract only HH:mm (omit timezone code AST/WIB to avoid overflow in mini boxes)
                      final timeParts = item.formattedTime.trim().split(' ');
                      final shortTime = timeParts.isNotEmpty ? timeParts.first : '--:--';
                      return _buildMiniTime(
                        context: context,
                        name: localizedName,
                        time: shortTime,
                        isActive: item.isNext,
                        isDark: isDark,
                      );
                    }).toList()
                  : [
                      _buildMiniTime(
                        context: context,
                        name: context.tr('subuh'),
                        time: '--:--',
                        isActive: false,
                        isDark: isDark,
                      ),
                      _buildMiniTime(
                        context: context,
                        name: context.tr('dzuhur'),
                        time: '--:--',
                        isActive: false,
                        isDark: isDark,
                      ),
                      _buildMiniTime(
                        context: context,
                        name: context.tr('ashar'),
                        time: '--:--',
                        isActive: false,
                        isDark: isDark,
                      ),
                      _buildMiniTime(
                        context: context,
                        name: context.tr('maghrib'),
                        time: '--:--',
                        isActive: false,
                        isDark: isDark,
                      ),
                      _buildMiniTime(
                        context: context,
                        name: context.tr('isya'),
                        time: '--:--',
                        isActive: false,
                        isDark: isDark,
                      ),
                    ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMiniTime({
    required BuildContext context,
    required String name,
    required String time,
    required bool isActive,
    required bool isDark,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer)
            : (isDark
                ? AppColors.darkSurface
                : AppColors.surfaceWhite.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isActive
            ? Border.all(color: AppColors.accentGoldStar, width: 1.5)
            : Border.all(
                color: isDark
                    ? AppColors.darkOutlineVariant.withValues(alpha: 0.4)
                    : AppColors.goldLight.withValues(alpha: 0.3),
              ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: AppTypography.captionSmall.copyWith(
              color: isActive ? AppColors.accentGoldStar : bodyColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: AppTypography.captionSmall.copyWith(
              color: isActive
                  ? AppColors.surfaceWhite
                  : headingColor,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return Expanded(
      child: isActive ? Transform.scale(scale: 1.04, child: content) : content,
    );
  }
}
