import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class JamaahServiceGrid extends StatelessWidget {
  const JamaahServiceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final textScale = Get.isRegistered<AppSettingsController>()
        ? Get.find<AppSettingsController>().textScaleFactor
        : 1.0;

    final List<Map<String, dynamic>> services = [
      {
        'title': context.tr('serviceMapTitle'),
        'subtitle': context.tr('serviceMapSubtitle'),
        'icon': Icons.near_me_rounded,
        'route': '/map',
      },
      {
        'title': context.tr('serviceMoneyTitle'),
        'subtitle': context.tr('serviceMoneySubtitle'),
        'icon': Icons.photo_camera_rounded,
        'route': '/money',
      },
      {
        'title': context.tr('serviceCommTitle'),
        'subtitle': context.tr('serviceCommSubtitle'),
        'icon': Icons.record_voice_over_rounded,
        'route': '/communication',
      },
      {
        'title': context.tr('serviceBandTitle'),
        'subtitle': context.tr('serviceBandSubtitle'),
        'icon': Icons.watch_rounded,
        'route': null,
      },
      {
        'title': context.tr('servicePrayerTitle'),
        'subtitle': context.tr('servicePrayerSubtitle'),
        'icon': Icons.menu_book_rounded,
        'route': null,
      },
      {
        'title': context.tr('serviceCallTitle'),
        'subtitle': context.tr('serviceCallSubtitle'),
        'icon': Icons.phone_in_talk_rounded,
        'route': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr('independentServices'),
                style: AppTypography.titleLarge.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.tr('easyTouch'),
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.accentGoldStar : AppColors.tanMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
            // Dynamically adjust ratio if text scale is enlarged
            double ratio = cardWidth < 170 ? 0.95 : 1.05;
            if (textScale > 1.1) {
              ratio = ratio * 0.88;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: ratio,
              ),
              itemBuilder: (context, index) {
                final item = services[index];
                return _buildServiceCard(
                  context: context,
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  icon: item['icon'] as IconData,
                  route: item['route'] as String?,
                  isDark: isDark,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String? route,
    required bool isDark,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: route != null ? () => Get.toNamed(route) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.canvasCream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.goldLight : AppColors.espressoDark,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: headingColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.captionSmall.copyWith(
                  color: bodyColor,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

