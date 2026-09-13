import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
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
          state.jamaahList.length > dashboardCtrl.selectedJamaahIndex.value
          ? state.jamaahList[dashboardCtrl.selectedJamaahIndex.value]
          : state.jamaahList.first;

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
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: headingColor),
          onPressed: () {},
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimary : AppColors.espressoDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mosque,
                color: AppColors.surfaceWhite,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HajiCare',
                  style: AppTypography.titleLarge.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'PENDAMPING',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.tanMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: headingColor,
                ),
                onPressed: () =>
                    Get.toNamed(AppRoutes.notification),
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
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldLight, width: 2),
              ),
              child: const Icon(Icons.person, color: AppColors.tanMedium),
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
          if (state.anyJamaahSeparated) _buildSeparatedBanner(state),
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
          _buildMapCard(context, dashboardCtrl),
          const SizedBox(height: AppSpacing.lg),
          _buildFeatureGrid(context, dashboardCtrl),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSeparatedBanner(HajiCareController state) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.sosEmergency.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.sosEmergency),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Peringatan: ${state.separatedJamaahName} berada di luar radius aman (Terlalu jauh).',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.sosEmergency,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(BuildContext context, DashboardController dashboardCtrl) {
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
                    Icons.explore,
                    color: AppColors.tanMedium,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm2),
                  Text(
                    'Posisi Lapangan Real-Time',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.espressoDark,
                    ),
                  ),
                ],
              ),
              Text(
                'GPS Akurat ±3m',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.statusSafe,
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
              color: AppColors.canvasCreamSubtle,
              child: Stack(
                children: [
                  // Grid Pattern Simulation
                  Positioned.fill(
                    child: CustomPaint(painter: _MiniMapPainter()),
                  ),
                  // Jamaah marker pin
                  Positioned(
                    top: 50,
                    left: 90,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.espressoDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ayah (80m)',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.surfaceWhite,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_on,
                          color: AppColors.statusSafe,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                  // Pendamping (Self) marker pin
                  Positioned(
                    bottom: 30,
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
                            color: AppColors.espressoDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Anda',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.surfaceWhite,
                              fontSize: 10,
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
                          color: AppColors.surfaceWhite.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.open_in_full,
                              size: 16,
                              color: AppColors.espressoDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Buka Navigasi Penuh & Jalur Evakuasi',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.espressoDark,
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
              Row(
                children: [
                  const Icon(Icons.route, color: AppColors.tanMedium, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Rute: Jalur Khusus Lansia King Fahd',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
              Text(
                'Tenda Maktab 48',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.espressoDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, DashboardController dashboardCtrl) {
    final features = [
      {
        'title': 'Peta Terpadu Sektor',
        'subtitle': 'Posko medis & jalur evakuasi',
        'icon': Icons.map,
        'tabIndex': 1,
        'route': null,
      },
      {
        'title': 'Jamaah & Gelang',
        'subtitle': 'Status baterai & sensor nadi',
        'icon': Icons.devices_other,
        'tabIndex': null,
        'route': null,
      },
      {
        'title': 'Jadwal & Agenda',
        'subtitle': 'Waktu Jamarat & titik kumpul',
        'icon': Icons.event_note,
        'tabIndex': 2,
        'route': null,
      },
      {
        'title': 'Kontak Petugas Maktab',
        'subtitle': 'Akses instan layanan darurat',
        'icon': Icons.contact_phone,
        'tabIndex': null,
        'route': AppRoutes.communication,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Layanan Pendamping',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.espressoDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
            final ratio = cardWidth < 170 ? 1.05 : 1.15;

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
                        decoration: const BoxDecoration(
                          color: AppColors.canvasCream,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: AppColors.espressoDark,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.espressoDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'] as String,
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textBody,
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.tanMedium.withValues(alpha: 0.15)
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
