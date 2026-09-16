import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_alert_service.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/dashboard_controller.dart';

class JamaahServiceGrid extends StatelessWidget {
  const JamaahServiceGrid({super.key});

  void _showSmartbandDialog(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
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
                  color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
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
                    color: AppColors.statusSafe.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.watch_rounded, color: AppColors.statusSafe, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gelang Pintar Haji',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Status: Terhubung (BLE Sync Aktif)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.statusSafe,
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
                    label: 'Baterai',
                    value: '88%',
                    color: AppColors.statusSafe,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    icon: Icons.favorite_rounded,
                    label: 'Detak Jantung',
                    value: '76 bpm',
                    color: AppColors.sosEmergency,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    icon: Icons.directions_walk_rounded,
                    label: 'Langkah',
                    value: '4.210',
                    color: AppColors.goldPrimary,
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
                  AppAlert.success(
                    context,
                    title: 'Sinkronisasi Berhasil',
                    message: 'Data vital dan lokasi gelang pintar telah diperbarui.',
                  );
                },
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sinkronisasi Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
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
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: bodyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDoaDialog(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    final doas = [
      {
        'title': 'Bacaan Talbiyah',
        'arabic': 'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ',
        'latin': 'Labbaikallaahumma labbaik, labbaika laa syariika laka labbaik...',
        'arti': 'Aku penuhi panggilan-Mu ya Allah, aku penuhi panggilan-Mu...',
      },
      {
        'title': 'Doa Tawaf (Antara Rukun Yamani & Hajar Aswad)',
        'arabic': 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        'latin': 'Rabbanaa aatinaa fid dunyaa hasanah wa fil aakhirati hasanah wa qinaa \'adzaaban naar',
        'arti': 'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat dan lindungilah kami dari azab neraka.',
      },
      {
        'title': 'Doa Masuk Masjidil Haram',
        'arabic': 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
        'latin': 'Allaahummaftah lii abwaaba rahmatik',
        'arti': 'Ya Allah, bukalah pintu-pintu rahmat-Mu untukku.',
      },
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: AppColors.tanMedium, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Doa & Panduan Manasik',
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.separated(
                itemCount: doas.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (ctx, i) {
                  final item = doas[i];
                  return AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: AppTypography.titleSmall.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['arabic']!,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.espressoDark,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['latin']!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.tanMedium,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['arti']!,
                          style: AppTypography.caption.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showOfficerCallDialog(BuildContext context) {
    AppAlert.info(
      context,
      title: 'Panggilan Petugas Siaga',
      message: 'Silakan hubungi kontak darurat berikut:\n\n'
          '• Call Center Haji Kemenag: 195\n'
          '• Posko Medis: +966 50 123 4567\n'
          '• Ketua Kloter: +966 50 987 6543',
    );
  }

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
        'action': () => _showDoaDialog(context),
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
                style: AppTypography.titleLarge.copyWith(
                  color: headingColor,
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
                color: isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.canvasCream,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                context.tr('easyTouch'),
                style: AppTypography.captionSmall.copyWith(
                  color: isDark ? AppColors.goldLight : AppColors.espressoDark,
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
            if (textScale > 1.1) {
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
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

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
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.canvasCream,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.goldLight : AppColors.espressoDark,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: bodyColor,
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
