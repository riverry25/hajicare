import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../presentation/dashboard_typography.dart';
import '../../../../core/widgets/app_card.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:hajicare/features/prayer/models/prayer_schedule_item.dart';

class JamaahPrayerCard extends StatelessWidget {
  const JamaahPrayerCard({super.key});

  String _localizedPrayerName(BuildContext context, String rawName) {
    return context.localizedPrayerName(rawName);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.hc.isDark;
    final headingColor = context.hc.textPrimary;
    final bodyColor = context.hc.textSecondary;

    final prayerCtrl = Get.find<PrayerTimesController>();

    return Obx(() {
      final locName = prayerCtrl.locationName.value;
      final displayCity = locName.isNotEmpty
          ? locName.split(',').first.trim()
          : '';
      final qiblaDeg = prayerCtrl.qiblaBearing.value;
      final nextName = prayerCtrl.nextPrayerName.value.isNotEmpty
          ? context.localizedPrayerName(prayerCtrl.nextPrayerName.value)
          : context.tr('subuh');
      final nextTime = prayerCtrl.nextPrayerTime.value;
      final countdown = prayerCtrl.formatCountdown(context);

      // Filter to the 5 canonical fardhu prayers (exclude Sunrise/Terbit for mini time bar)
      final allPrayers = prayerCtrl.prayers;
      final fardhuPrayers = allPrayers.isNotEmpty
          ? allPrayers.where((p) {
              final n = p.name.toLowerCase();
              return n != 'terbit' && n != 'sunrise';
            }).toList()
          : <PrayerScheduleItem>[];

      return AppCard(
        backgroundColor: context.hc.surface,
        borderColor: context.hc.border,
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
                      Icon(
                        Icons.schedule_rounded,
                        color: context.hc.accent,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          displayCity.isNotEmpty
                              ? '${context.tr('prayerScheduleTitle')} • ${displayCity.toUpperCase()}'
                              : context.tr('prayerScheduleTitle'),
                          style: DashboardTypography.captionSmall.copyWith(
                            color: headingColor,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.hc.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: context.hc.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.explore_rounded,
                        color: context.hc.accent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        qiblaDeg > 0
                            ? '${context.tr('qiblaDegree')} ${qiblaDeg.toStringAsFixed(0)}°'
                            : '${context.tr('qiblaDegree')} --°',
                        style: DashboardTypography.captionSmall.copyWith(
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
                color: context.hc.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: context.hc.border,
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
                          style: DashboardTypography.caption.copyWith(
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
                              style: DashboardTypography.displayMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              nextTime,
                              style: DashboardTypography.titleMedium.copyWith(
                                color: context.hc.accent,
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
                        color: context.hc.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${context.tr('inCountdownPrefix')} $countdown',
                        style: DashboardTypography.captionSmall.copyWith(
                          color: context.hc.primary,
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
                      final localizedName = _localizedPrayerName(
                        context,
                        item.name,
                      );
                      // Extract only HH:mm (omit timezone code AST/WIB to avoid overflow in mini boxes)
                      final timeParts = item.formattedTime.trim().split(' ');
                      final shortTime = timeParts.isNotEmpty
                          ? timeParts.first
                          : '--:--';
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
    final headingColor = context.hc.textPrimary;
    final bodyColor = context.hc.textSecondary;

    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: isActive
            ? context.hc.primaryContainer
            : context.hc.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isActive
            ? Border.all(color: context.hc.accent, width: 1.5)
            : Border.all(
                color: context.hc.border,
              ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: context.hc.primary.withValues(alpha: 0.12),
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
            style: DashboardTypography.captionSmall.copyWith(
              color: isActive ? context.hc.primary : bodyColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: DashboardTypography.captionSmall.copyWith(
              color: isActive ? context.hc.primary : headingColor,
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
