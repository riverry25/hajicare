import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
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
import '../../room/widgets/active_room_card.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../notification/widgets/notification_composer_dialog.dart';

class DashboardPendampingScreen extends StatelessWidget {
  const DashboardPendampingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();
    final state = Get.find<HajiCareController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      extendBody: true,
      body: Obx(
        () => IndexedStack(
          index: dashboardCtrl.currentIndex.value,
          children: [
            _buildPendampingHome(context, state, dashboardCtrl),
            const InteractiveMapScreen(showBottomNav: false),
            const PrayerTimesScreen(showBottomNav: false),
            const ProfileScreen(showBottomNav: false),
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

  Widget _buildPendampingHome(
    BuildContext context,
    HajiCareController state,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Broadcast Button
              IconButton(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.campaign_outlined, color: headingColor, size: 24),
                tooltip: 'Kirim Notifikasi Room',
                onPressed: () => NotificationComposerDialog.show(context),
              ),
              const SizedBox(width: 4),
              // Notification Bell with single clean badge
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.notifications_outlined, color: headingColor, size: 24),
                    tooltip: context.tr('notificationTooltip'),
                    onPressed: () => Get.toNamed(AppRoutes.notification),
                  ),
                  Obx(() {
                    final notifCtrl = Get.isRegistered<NotificationController>()
                        ? Get.find<NotificationController>()
                        : null;
                    final totalUnread = notifCtrl != null
                        ? notifCtrl.unreadCount.value + notifCtrl.pendingInvitations.length
                        : 0;
                    final hasSos = state.anySosActive;

                    if (totalUnread <= 0 && !hasSos) return const SizedBox.shrink();

                    if (totalUnread > 0) {
                      return Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.sosEmergency,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkScaffold
                                  : AppColors.canvasCream,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              totalUnread > 9 ? '9+' : '$totalUnread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Only SOS active without unread notification
                      return Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.sosEmergency,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkScaffold
                                  : AppColors.canvasCream,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }
                  }),
                ],
              ),
              const SizedBox(width: 8),
              // Profile Avatar
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.screenEdgeGutter),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.goldLight,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: isDark ? AppColors.goldLight : AppColors.tanMedium,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        final selectedJamaah =
            (state.jamaahList.isNotEmpty &&
                state.jamaahList.length > dashboardCtrl.selectedJamaahIndex.value)
            ? state.jamaahList[dashboardCtrl.selectedJamaahIndex.value]
            : (state.jamaahList.isNotEmpty ? state.jamaahList.first : state.self);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdgeGutter,
            AppSpacing.sm,
            AppSpacing.screenEdgeGutter,
            100,
          ),
          children: [
            PendampingGreetingHeader(state: state),
            const SizedBox(height: AppSpacing.md),
            const ActiveRoomCard(isPendamping: true),
            const SizedBox(height: AppSpacing.lg),
            if (state.activeRoomId.value != null &&
                state.jamaahList.isNotEmpty) ...[
              if (state.anyJamaahSeparated)
                _buildSeparatedBanner(context, state, isDark),
              PendampingJamaahSelector(
                state: state,
                selectedIndex: dashboardCtrl.selectedJamaahIndex.value,
                onSelected: (idx) {
                  dashboardCtrl.selectJamaah(idx);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            PendampingRadarCard(
              jamaah: selectedJamaah,
              onTrackMap: () => dashboardCtrl.changeTab(1),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.activeRoomId.value != null) ...[
              PendampingSosBanner(
                state: state,
                onDismissSos: (jamaahId) async {
                  AppAlert.confirm(
                    context,
                    title: 'Akhiri Darurat SOS',
                    message:
                        'Apakah situasi darurat jamaah sudah teratasi? Sinyal SOS akan dinonaktifkan.',
                    confirmText: 'Ya, Akhiri SOS',
                    cancelText: 'Batal',
                    onConfirm: () async {
                      await state.dismissSos(jamaahId);
                      if (context.mounted) {
                        AppAlert.success(
                          context,
                          title: 'SOS Diakhiri',
                          message: 'Sinyal darurat berhasil dinonaktifkan.',
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _buildMapCard(context, state, dashboardCtrl, selectedJamaah, isDark),
            const SizedBox(height: AppSpacing.lg),
            _buildFeatureGrid(context, dashboardCtrl, isDark),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      }),
    );
  }

  Widget _buildSeparatedBanner(
    BuildContext context,
    HajiCareController state,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.sosEmergency.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.sosEmergency,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '${context.tr('warningDistanceLabel')}: ${state.separatedJamaahName} ${context.tr('separatedAlertDetail')}',
              style: AppTypography.caption.copyWith(
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
    HajiCareController state,
    DashboardController dashboardCtrl,
    JamaahData selectedJamaah,
    bool isDark,
  ) {
    final headingColor = AppColors.textHeadingColor(context);

    // Resolve map center from pendamping's current GPS, or fall back to Mina
    final myPos = state.myCurrentPosition.value;
    final pendGeo = state.pendampingLocation.value;
    final jamaahGeo = selectedJamaah.currentLocation;

    LatLng mapCenter = myPos != null
        ? LatLng(myPos.latitude, myPos.longitude)
        : (pendGeo != null
              ? LatLng(pendGeo.latitude, pendGeo.longitude)
              : const LatLng(21.3891, 39.8579)); // Mina fallback

    final LatLng? targetJamaahLatLng = jamaahGeo != null
        ? LatLng(jamaahGeo.latitude, jamaahGeo.longitude)
        : null;

    final LatLng? selfLatLng = myPos != null
        ? LatLng(myPos.latitude, myPos.longitude)
        : null;

    final hasPositions = selfLatLng != null && targetJamaahLatLng != null;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      color: AppColors.tanMedium,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.tr('realtimePosition'),
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color:
                      (state.isMyGpsActive.value
                              ? AppColors.statusSafe
                              : AppColors.error)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: state.isMyGpsActive.value
                            ? AppColors.statusSafe
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      state.isMyGpsActive.value ? 'GPS Aktif' : 'GPS Mati',
                      style: AppTypography.captionSmall.copyWith(
                        color: state.isMyGpsActive.value
                            ? AppColors.statusSafe
                            : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // FlutterMap Mini-Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: SizedBox(
              height: 180,
              child: AbsorbPointer(
                child: fmap.FlutterMap(
                  options: fmap.MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: hasPositions ? 16.0 : 14.0,
                    interactionOptions: const fmap.InteractionOptions(
                      flags: fmap.InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    fmap.TileLayer(
                      urlTemplate:
                          'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png?key=cb1_3juo_1_5f067ded7575ce8152ef26fc',
                      userAgentPackageName: 'com.example.hajicare',
                    ),
                    if (selfLatLng != null && targetJamaahLatLng != null)
                      fmap.PolylineLayer(
                        polylines: [
                          fmap.Polyline(
                            points: [selfLatLng, targetJamaahLatLng],
                            strokeWidth: 4,
                            color: AppColors.goldPrimary.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    fmap.MarkerLayer(
                      markers: [
                        if (selfLatLng != null)
                          fmap.Marker(
                            point: selfLatLng,
                            width: 44,
                            height: 44,
                            child: _buildMapPin(
                              label: context.tr('youLabel'),
                              icon: Icons.my_location,
                              color: AppColors.goldPrimary,
                            ),
                          ),
                        if (targetJamaahLatLng != null)
                          fmap.Marker(
                            point: targetJamaahLatLng,
                            width: 60,
                            height: 60,
                            child: _buildMapPin(
                              label: selectedJamaah.shortLabel,
                              icon: Icons.person_pin_circle_rounded,
                              color: selectedJamaah.tier.color,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => dashboardCtrl.changeTab(1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.open_in_full,
                    size: 15,
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.espressoDark,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.tr('openFullNavigation'),
                      style: AppTypography.labelLarge.copyWith(
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
        ],
      ),
    );
  }

  Widget _buildMapPin({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.espressoDark,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.surfaceWhite,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Icon(icon, color: color, size: 24),
      ],
    );
  }

  Widget _buildFeatureGrid(
    BuildContext context,
    DashboardController dashboardCtrl,
    bool isDark,
  ) {
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
          style: AppTypography.titleLarge.copyWith(
            color: headingColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
            double ratio = cardWidth < 170 ? 1.0 : 1.12;
            if (textScale > 1.25) {
              ratio = ratio * 0.76;
            } else if (textScale > 1.1) {
              ratio = ratio * 0.88;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: features.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: ratio,
              ),
              itemBuilder: (context, index) {
                final item = features[index];
                return AppCard(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimaryContainer
                              : AppColors.canvasCream,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.espressoDark,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: AppTypography.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['subtitle'] as String,
                            style: AppTypography.caption.copyWith(
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
