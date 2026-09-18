import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class PendampingGreetingHeader extends StatelessWidget {
  final HajiCareState state;

  const PendampingGreetingHeader({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final pName = state.pendampingName.value.trim();
      final shortName = pName.isNotEmpty ? pName.split(' ')[0] : 'Pendamping';

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
        groupInfo = room.name;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.onSecondaryContainer,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('modePendampingSubtitle'),
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  groupInfo.isNotEmpty ? groupInfo : 'Rombongan Belum Diatur',
                  style: AppTypography.caption.copyWith(
                    color: groupInfo.isNotEmpty
                        ? (isDark ? AppColors.goldLight : AppColors.espressoDark)
                        : bodyColor.withValues(alpha: 0.6),
                    fontWeight: groupInfo.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${context.tr('pendampingGreeting')}, $shortName',
            style: AppTypography.displayMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            context.tr('pendampingSubtitleDesc'),
            style: AppTypography.bodySmall.copyWith(color: bodyColor),
          ),
        ],
      );
    });
  }
}

