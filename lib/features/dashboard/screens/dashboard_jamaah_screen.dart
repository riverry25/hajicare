import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/widgets/ribbon_fold_painter.dart';
import '../../map/screens/interactive_map_screen.dart';
import 'dart:math' as math;
import '../../notification/controllers/notification_controller.dart';
import '../../prayer/controllers/prayer_times_controller.dart';
import '../../prayer/screens/prayer_times_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../room/widgets/active_room_card.dart';
import '../../communication/widgets/communication_gesture_dialog.dart';
import '../../smartband/controllers/smartband_ldr_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/rotating_sync_button.dart';

part 'dashboard_jamaah_header.dart';
part 'dashboard_jamaah_sections.dart';
part 'dashboard_jamaah_components.dart';

class DashboardJamaahScreen extends StatelessWidget {
  const DashboardJamaahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();
    final state = Get.find<HajiCareController>();
    final prayerCtrl = Get.find<PrayerTimesController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      extendBody: true,
      body: Obx(
        () => IndexedStack(
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
        ),
      ),
      bottomNavigationBar: Obx(
        () => HajiCareBottomNavBar(
          currentIndex: dashboardCtrl.currentIndex.value,
          onTap: dashboardCtrl.changeTab,
        ),
      ),
    );
  }

  Widget _buildJamaahHome(
    BuildContext context,
    HajiCareController state,
    DashboardController dashboardCtrl,
    PrayerTimesController prayerCtrl,
  ) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    final heroGradient = LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF1B120B),
              const Color(0xFF281A11),
              const Color(0xFF332115),
            ]
          : [
              const Color(0xFF26170E),
              const Color(0xFF382317),
              const Color(0xFF4A3020),
            ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1B120B)
          : const Color(0xFF26170E),
      body: Container(
        decoration: BoxDecoration(gradient: heroGradient),
        child: Obx(() {
          final jamaah = state.self;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
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
          );
        }),
      ),
    );
  }

  // ── Hero Section (Top Card with Glowing Details) ───────────────────────────
}

/// Circular gauge painter creating a modern arc progress ring with an end-handle dot
