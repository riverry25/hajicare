import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_alert_service.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/dashboard_controller.dart';

class JamaahServiceGrid extends StatelessWidget {
  const JamaahServiceGrid({super.key});

  void _showSmartbandDialog(BuildContext context) {
    final hc = context.hc;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: hc.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: hc.borderSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hc.successContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.watch_rounded, color: hc.success, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('dashboard.connectBandTitle'),
                        style: context.text.titleMedium.copyWith(
                          color: hc.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.tr('dashboard.connectBandSub'),
                        style: context.text.labelSmall.copyWith(
                          color: hc.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    icon: Icons.battery_charging_full_rounded,
                    label: context.tr('dashboard.battery'),
                    value: '-',
                    color: hc.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    icon: Icons.favorite_rounded,
                    label: context.tr('dashboard.heartRate'),
                    value: '-',
                    color: hc.danger,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    icon: Icons.directions_walk_rounded,
                    label: context.tr('dashboard.steps'),
                    value: '-',
                    color: hc.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.smartbandLdr);
                },
                icon: const Icon(Icons.bluetooth_searching_rounded),
                label: Text(context.tr('dashboard.connectBand')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hc.brand,
                  foregroundColor: hc.onBrand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.smartbandLdr);
                },
                icon: Icon(Icons.sensors_rounded, color: hc.brand),
                label: Text(
                  context.tr('dashboard.openSensorDetails'),
                  style: context.text.labelLarge.copyWith(
                    color: hc.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: hc.borderSubtle, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final hc = context.hc;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: hc.sandLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: hc.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: context.text.titleMedium.copyWith(
              color: hc.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.text.bodySmall.copyWith(color: hc.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showOfficerCallDialog(BuildContext context) {
    AppAlert.info(
      context,
      title: context.tr('dashboard.contactCompanion'),
      message: context.tr('dashboard.officerPhoneMissing'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final textScale = Get.isRegistered<AppSettingsController>()
        ? Get.find<AppSettingsController>().textScaleFactor
        : 1.0;

    final List<Map<String, dynamic>> services = [
      {
        'title': context.tr('serviceMapTitle'),
        'subtitle': context.tr('serviceMapSubtitle'),
        'icon': Icons.near_me_rounded,
        'action': () {
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().changeTab(1);
          } else {
            Get.toNamed(AppRoutes.interactiveMap);
          }
        },
      },
      {
        'title': context.tr('serviceMoneyTitle'),
        'subtitle': context.tr('serviceMoneySubtitle'),
        'icon': Icons.photo_camera_rounded,
        'action': () => Get.toNamed(AppRoutes.moneyRecognition),
      },
      {
        'title': context.tr('serviceCommTitle'),
        'subtitle': context.tr('serviceCommSubtitle'),
        'icon': Icons.record_voice_over_rounded,
        'action': () => Get.toNamed(AppRoutes.communication),
      },
      {
        'title': context.tr('serviceBandTitle'),
        'subtitle': context.tr('serviceBandSubtitle'),
        'icon': Icons.watch_rounded,
        'action': () => _showSmartbandDialog(context),
      },
      {
        'title': context.tr('servicePrayerTitle'),
        'subtitle': context.tr('servicePrayerSubtitle'),
        'icon': Icons.menu_book_rounded,
        'action': () => Get.toNamed(AppRoutes.hajjDua),
      },
      {
        'title': context.tr('serviceCallTitle'),
        'subtitle': context.tr('serviceCallSubtitle'),
        'icon': Icons.phone_in_talk_rounded,
        'action': () => _showOfficerCallDialog(context),
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
                style: context.text.titleLarge.copyWith(
                  color: hc.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hc.sandLight,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                context.tr('easyTouch'),
                style: context.text.labelSmall.copyWith(
                  color: hc.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
            double ratio = cardWidth < 170 ? 0.95 : 1.05;
            if (textScale > 1.25) {
              ratio = ratio * 0.76;
            } else if (textScale > 1.1) {
              ratio = ratio * 0.88;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: ratio,
              ),
              itemBuilder: (context, index) {
                final item = services[index];
                return _buildServiceCard(
                  context: context,
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  icon: item['icon'] as IconData,
                  onTap: item['action'] as VoidCallback?,
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
    required VoidCallback? onTap,
  }) {
    final hc = context.hc;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hc.sandLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: hc.brand, size: 24),
          ),
          const SizedBox(height: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.titleMedium.copyWith(
                  color: hc.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: context.text.bodySmall.copyWith(color: hc.textSecondary),
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
