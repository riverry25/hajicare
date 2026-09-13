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
              Flexible(
                child: Text(
                  '${context.tr('kloterLabelShort')} 14 JKS • ${context.tr('maktabLabelShort')} 48',
                  style: AppTypography.caption.copyWith(color: bodyColor),
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

