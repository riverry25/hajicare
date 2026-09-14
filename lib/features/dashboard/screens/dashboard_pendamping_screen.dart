import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/app_settings_controller.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../../map/screens/interactive_map_screen.dart';
import '../../prayer/screens/prayer_times_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/pendamping_greeting_header.dart';
import '../widgets/pendamping_jamaah_selector.dart';
import '../widgets/pendamping_radar_card.dart';
import '../widgets/pendamping_sos_banner.dart';

class DashboardPendampingScreen extends StatelessWidget {
  const DashboardPendampingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();
    final state = Get.find<HajiCareController>();

    return Obx(() {
      final selectedJamaah =
          (state.jamaahList.isNotEmpty &&
                  state.jamaahList.length >
                      dashboardCtrl.selectedJamaahIndex.value)
              ? state.jamaahList[dashboardCtrl.selectedJamaahIndex.value]
              : (state.jamaahList.isNotEmpty
                  ? state.jamaahList.first
                  : state.self);

      return Scaffold(
        backgroundColor: AppColors.scaffoldColor(context),
        extendBody: true,
        body: IndexedStack(
          index: dashboardCtrl.currentIndex.value,
          children: [
            _buildPendampingHome(context, state, selectedJamaah, dashboardCtrl),
            const InteractiveMapScreen(showBottomNav: false),
            const PrayerTimesScreen(showBottomNav: false),
            const ProfileScreen(showBottomNav: false),
          ],
        ),
        bottomNavigationBar: HajiCareBottomNavBar(
          currentIndex: dashboardCtrl.currentIndex.value,
          onTap: dashboardCtrl.changeTab,
        ),
      );
    });
  }

  Widget _buildPendampingHome(
    BuildContext context,
    HajiCareController state,
    JamaahData selectedJamaah,
    DashboardController dashboardCtrl,
  ) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg = AppColors.scaffoldColor(context);
    final headingColor = AppColors.textHeadingColor(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: HajiCareHeader(
        title: 'HajiCare',
        subtitle: context.tr('modePendampingSubtitle'),
        icon: Icons.mosque_rounded,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: headingColor,
                ),
                tooltip: context.tr('notificationTooltip'),
                onPressed: () => Get.toNamed(AppRoutes.notification),
              ),
              if (state.anySosActive)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.sosEmergency,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkScaffold : AppColors.canvasCream,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenEdgeGutter),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkOutlineVariant : AppColors.goldLight,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person,
                color: isDark ? AppColors.goldLight : AppColors.tanMedium,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdgeGutter,
          AppSpacing.sm,
          AppSpacing.screenEdgeGutter,
          100,
        ),
        children: [
          PendampingGreetingHeader(state: state),
          const SizedBox(height: AppSpacing.lg),
          if (state.anyJamaahSeparated) _buildSeparatedBanner(context, state, isDark),
          PendampingJamaahSelector(
            state: state,
            selectedIndex: dashboardCtrl.selectedJamaahIndex.value,
            onSelected: (idx) {
              dashboardCtrl.selectJamaah(idx);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          PendampingRadarCard(
            jamaah: selectedJamaah,
            onTrackMap: () => dashboardCtrl.changeTab(1),
          ),
          const SizedBox(height: AppSpacing.lg),
          PendampingSosBanner(state: state),
          const SizedBox(height: AppSpacing.lg),
          _buildMapCard(context, dashboardCtrl, selectedJamaah, isDark),
          const SizedBox(height: AppSpacing.lg),
          _buildFeatureGrid(context, dashboardCtrl, isDark),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSeparatedBanner(BuildContext context, HajiCareController state, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.sosEmergency.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.sosEmergency),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${context.tr('warningDistanceLabel')}: ${state.separatedJamaahName} ${context.tr('separatedAlertDetail')}',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.sosEmergency,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(
    BuildContext context,
    DashboardController dashboardCtrl,
    JamaahData selectedJamaah,
    bool isDark,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: AppColors.tanMedium,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm2),
                  Text(
                    context.tr('realtimePosition'),
                    style: AppTypography.labelLarge.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                context.tr('gpsAccuracy'),
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.statusSafe,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Interactive Map Preview Canvas
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              height: 160,
              width: double.infinity,
              color: isDark ? AppColors.darkSurface : AppColors.canvasCreamSubtle,
              child: Stack(
                children: [
                  // Grid Pattern Simulation
                  Positioned.fill(
                    child: CustomPaint(painter: _MiniMapPainter(isDark: isDark)),
                  ),
                  // Jamaah marker pin
                  Positioned(
                    top: 40,
                    left: 90,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkPrimaryContainer : AppColors.espressoDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${selectedJamaah.shortLabel} (${selectedJamaah.distance.toInt()}${context.tr('meterUnit')})',
                            style: AppTypography.captionSmall.copyWith(
                              color: isDark ? AppColors.darkPrimary : AppColors.surfaceWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          color: selectedJamaah.tier.color,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                  // Pendamping (Self) marker pin
                  Positioned(
                    bottom: 45,
                    right: 80,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.my_location,
                          color: AppColors.accentGoldStar,
                          size: 24,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkPrimaryContainer : AppColors.espressoDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            context.tr('youLabel'),
                            style: AppTypography.captionSmall.copyWith(
                              color: isDark ? AppColors.darkPrimary : AppColors.surfaceWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand Button Overlay
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () => dashboardCtrl.changeTab(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceContainer.withValues(alpha: 0.95)
                              : AppColors.surfaceWhite.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: isDark ? AppColors.darkOutlineVariant : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.open_in_full,
                              size: 16,
                              color: isDark ? AppColors.darkPrimary : AppColors.espressoDark,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                context.tr('openFullNavigation'),
                                style: AppTypography.captionSmall.copyWith(
                                  color: headingColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.route_rounded, color: AppColors.tanMedium, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        context.tr('elderlyRoute'),
                        style: AppTypography.caption.copyWith(
                          color: bodyColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.tr('tentMaktab'),
                style: AppTypography.captionSmall.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, DashboardController dashboardCtrl, bool isDark) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final textScale = Get.isRegistered<AppSettingsController>()
        ? Get.find<AppSettingsController>().textScaleFactor
        : 1.0;

    final features = [
      {
        'title': context.tr('serviceIntegratedMap'),
        'subtitle': context.tr('serviceIntegratedMapSub'),
        'icon': Icons.map_rounded,
        'tabIndex': 1,
        'route': null,
      },
      {
        'title': context.tr('servicePilgrimBand'),
        'subtitle': context.tr('servicePilgrimBandSub'),
        'icon': Icons.devices_other_rounded,
        'tabIndex': null,
        'route': null,
      },
      {
        'title': context.tr('serviceScheduleAgenda'),
        'subtitle': context.tr('serviceScheduleAgendaSub'),
        'icon': Icons.event_note_rounded,
        'tabIndex': 2,
        'route': null,
      },
      {
        'title': context.tr('serviceMaktabContact'),
        'subtitle': context.tr('serviceMaktabContactSub'),
        'icon': Icons.contact_phone_rounded,
        'tabIndex': null,
        'route': AppRoutes.communication,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('pendampingServices'),
          style: AppTypography.titleMedium.copyWith(
            color: headingColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
            double ratio = cardWidth < 170 ? 1.05 : 1.15;
            if (textScale > 1.1) {
              ratio = ratio * 0.88;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: features.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: ratio,
              ),
              itemBuilder: (context, index) {
                final item = features[index];
                return AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  onTap: () {
                    if (item['tabIndex'] != null) {
                      dashboardCtrl.changeTab(item['tabIndex'] as int);
                    } else if (item['route'] != null) {
                      Get.toNamed(item['route'] as String);
                    }
                  },
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
                          item['icon'] as IconData,
                          color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: AppTypography.labelLarge.copyWith(
                              color: headingColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'] as String,
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
              },
            );
          },
        ),
      ],
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  final bool isDark;

  const _MiniMapPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? AppColors.darkOutlineVariant.withValues(alpha: 0.3)
          : AppColors.tanMedium.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw route line
    final routePaint = Paint()
      ..color = AppColors.accentGoldStar.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(90, 70)
      ..quadraticBezierTo(140, 100, size.width - 80, size.height - 30);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
