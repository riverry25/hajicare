import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../presentation/dashboard_typography.dart';

class PendampingGreetingHeader extends StatelessWidget {
  final HajiCareState state;

  const PendampingGreetingHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final headingColor = context.hc.textPrimary;
    final bodyColor = context.hc.textSecondary;

    return Obx(() {
      final pName = state.pendampingName.value.trim();
      final shortName = pName.isNotEmpty
          ? pName.split(' ')[0]
          : context.tr('dashboard.officerFallback');

      final rawKloter = state.effectiveKloter?.trim();
      final rawMaktab = state.effectiveMaktab?.trim();
      final room = state.activeRoom.value;

      final kloterLabel = context.tr('kloterLabelShort');
      final maktabLabel = context.tr('maktabLabelShort');

      final kloter = (rawKloter != null && rawKloter.isNotEmpty)
          ? (rawKloter.toLowerCase().startsWith('kloter')
                ? rawKloter
                : '$kloterLabel $rawKloter')
          : null;

      final maktab = (rawMaktab != null && rawMaktab.isNotEmpty)
          ? (rawMaktab.toLowerCase().startsWith('maktab')
                ? rawMaktab
                : '$maktabLabel $rawMaktab')
          : null;

      String groupInfo = '';
      if (kloter != null && maktab != null) {
        groupInfo = '$kloter • $maktab';
      } else if (kloter != null) {
        groupInfo = kloter;
      } else if (maktab != null) {
        groupInfo = maktab;
      } else if (room != null && room.name.isNotEmpty) {
        groupInfo = room.capitalizedName;
      }

      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badges Row: Role Badge + Kloter/Maktab Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mode Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: context.hc.surfaceSand,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: context.hc.border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: context.hc.primary,
                        size: 13,
                      ),
                      const SizedBox(width: 4.5),
                      Text(
                        context.tr('modePendampingSubtitle'),
                        style: TextStyle(
                          color: context.hc.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Group / Maktab Badge
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: context.hc.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: context.hc.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: context.hc.accent,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            groupInfo.isNotEmpty
                                ? groupInfo
                                : context.tr('dashboard.noGroupYet'),
                            style: TextStyle(
                              color: context.hc.textPrimary,
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
            const SizedBox(height: 12),
            // Greeting Title
            Text(
              '${context.tr('pendampingGreeting')}, $shortName',
              style: DashboardTypography.headlineLarge.copyWith(
                color: headingColor,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.3,
                height: 1.25,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            // Subtitle Description
            Text(
              context.tr('pendampingSubtitleDesc'),
              style: DashboardTypography.bodySmall.copyWith(
                color: bodyColor.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    });
  }
}
