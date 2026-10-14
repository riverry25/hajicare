import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/app_settings_controller.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../presentation/dashboard_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../map/screens/interactive_map_screen.dart';
import '../../map/controllers/map_controller.dart';
import '../../../core/services/app_alert_service.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../notification/models/notification_model.dart';
import '../../notification/services/notification_service.dart';
import '../../prayer/controllers/prayer_times_controller.dart';
import '../../prayer/screens/prayer_times_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../room/services/room_query_service.dart';
import '../../room/widgets/active_room_card.dart';
import '../../communication/widgets/communication_gesture_dialog.dart';
import '../../smartband/controllers/smartband_ldr_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/distance_sparkline_widget.dart';
import '../widgets/companion_contact_sheet.dart';
import '../widgets/hajj_schedule_guide_sheet.dart';
import '../widgets/jamaah_active_assistance_banner.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../services/assistance_request_service.dart';
import '../../../core/widgets/haji_transparent_dialog.dart';
import '../../../core/widgets/haji_dialog_hero_header.dart';

part 'dashboard_jamaah_header.dart';
part 'dashboard_jamaah_sections.dart';

class DashboardJamaahScreen extends StatelessWidget {
  const DashboardJamaahScreen({super.key});

  /// Menampilkan dialog pemantauan smartband (ramah lansia, tanpa lat/lng teknis)
  static void showSmartbandDialog(BuildContext context) {
    const DashboardJamaahScreen()._showSmartBandDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();
    final state = Get.find<HajiCareController>();
    final prayerCtrl = Get.find<PrayerTimesController>();
    final settings = Get.isRegistered<AppSettingsController>()
        ? Get.find<AppSettingsController>()
        : null;

    return Theme(
      data: DashboardTypography.applyTo(Theme.of(context)),
      child: Scaffold(
        backgroundColor: context.hc.canvas,
        extendBody: true,
        body: Obx(() {
          settings?.rxLocale.value;
          return IndexedStack(
            index: dashboardCtrl.currentIndex.value,
            children: [
              _buildJamaahHome(context, state, dashboardCtrl, prayerCtrl),
              if (dashboardCtrl.visitedTabs.contains(1))
                const InteractiveMapScreen(showBottomNav: false)
              else
                const SizedBox.shrink(),
              if (dashboardCtrl.visitedTabs.contains(2))
                const PrayerTimesScreen(showBottomNav: false)
              else
                const SizedBox.shrink(),
              if (dashboardCtrl.visitedTabs.contains(3))
                const ProfileScreen(showBottomNav: false)
              else
                const SizedBox.shrink(),
            ],
          );
        }),
        bottomNavigationBar: Obx(() {
          if (Get.isRegistered<MapController>()) {
            final mapCtrl = Get.find<MapController>();
            if (dashboardCtrl.currentIndex.value == 1 && mapCtrl.isNavigating) {
              return const SizedBox.shrink();
            }
          }
          return HajiCareBottomNavBar(
            currentIndex: dashboardCtrl.currentIndex.value,
            onTap: dashboardCtrl.changeTab,
          );
        }),
      ),
    );
  }

  Widget _buildJamaahHome(
    BuildContext context,
    HajiCareController state,
    DashboardController dashboardCtrl,
    PrayerTimesController prayerCtrl,
  ) {
    final isDark = context.hc.isDark;
    final headingColor = context.hc.textPrimary;
    final dashGradient = context.hc.dashboardHeroGradient;

    return Scaffold(
      backgroundColor: context.hc.canvas,
      body: Container(
        decoration: BoxDecoration(gradient: dashGradient),
        child: Obx(() {
          final jamaah = state.self;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ResponsiveCenter(
              maxWidth: AppBreakpoints.maxTabletContentWidth,
              child: Column(
                children: [
                  // ── Top Hero Card (Seamless Gradient Canvas) ─────────────
                  _buildHeroSection(
                    context: context,
                    jamaah: jamaah,
                    state: state,
                    dashboardCtrl: dashboardCtrl,
                    prayerCtrl: prayerCtrl,
                    isDark: isDark,
                  ),

                  // ── Curved White/Cream Canvas Sheet ──────────────────────
                  _buildCurvedBody(
                    context: context,
                    jamaah: jamaah,
                    state: state,
                    dashboardCtrl: dashboardCtrl,
                    isDark: isDark,
                    headingColor: headingColor,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Hero Section (Top Card with Glowing Details) ───────────────────────────
}

/// Circular gauge painter creating a modern arc progress ring with an end-handle dot
