import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:get/get.dart';

import '../../../core/models/filter_chip_item.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../controllers/map_controller.dart';
import '../widgets/location_detail_sheet.dart';
import '../widgets/map_bottom_sheet.dart';
import '../widgets/map_floating_controls.dart';
import '../widgets/map_top_header.dart';

/// Dynamic, production-ready interactive map screen for HajiCare.
/// Powered by flutter_map with CartoDB/OpenStreetMap tiles, real geolocation,
/// dynamic Jamaah & POI markers, route polyline, and safe radius visualization.
class InteractiveMapScreen extends StatefulWidget {
  final bool showBottomNav;
  const InteractiveMapScreen({super.key, this.showBottomNav = true});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  final List<FilterChipItem> _filters = const [
    FilterChipItem(
      label: 'Jamaah (Ayah)',
      icon: Icons.person_pin_circle,
      isDefault: true,
    ),
    FilterChipItem(label: 'Semua'),
    FilterChipItem(label: 'Toilet & Wudhu', icon: Icons.wc),
    FilterChipItem(label: 'Posko Medis PPIH', icon: Icons.medical_services),
    FilterChipItem(label: 'Tenda Maktab 48', icon: Icons.holiday_village),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Get.find<HajiCareController>();
    final mapCtrl = Get.isRegistered<MapController>()
        ? Get.find<MapController>()
        : Get.put(MapController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      extendBody: true,
      body: Stack(
        children: [
          // 1. Core Interactive Map Layer
          _buildInteractiveMap(state, mapCtrl),

          // 2. Top Header with live GPS tracking status and filter chips
          Obx(
            () => MapTopHeader(
              filters: _filters,
              selectedFilter: mapCtrl.selectedFilter.value,
              onFilterSelected: mapCtrl.selectFilter,
              onSosPressed: () => Get.toNamed(AppRoutes.modalSos),
            ),
          ),

          // 3. Floating Quick Action Controls (Compass, MyLocation, Layers, Band)
          Obx(
            () => MapFloatingControls(
              compassRotation: mapCtrl.compassRotation.value,
              isLocationLoading: mapCtrl.isLocationLoading.value,
              onCompassTap: mapCtrl.resetCompass,
              onLocationTap: mapCtrl.moveToCurrentLocation,
              onLayersTap: mapCtrl.toggleMapTileLayer,
              onBandTap: () => _showSmartBandDialog(context, state),
            ),
          ),

          // 4. Dynamic Contextual Bottom Sheets
          Obx(() {
            final selectedPoi = mapCtrl.selectedPoi.value;
            if (selectedPoi != null) {
              final userPos = mapCtrl.currentUserLocation.value ??
                  MapController.defaultMinaBase;
              final dist = mapCtrl.calculateDistanceMeters(
                userPos,
                selectedPoi.coordinate,
              );

              return Positioned(
                left: 0,
                right: 0,
                bottom: widget.showBottomNav ? 84.0 : 0.0,
                child: LocationDetailSheet(
                  poi: selectedPoi,
                  distanceMeters: dist,
                  onRoute: () => mapCtrl.selectPoi(selectedPoi),
                  onClose: mapCtrl.clearSelection,
                ),
              );
            }

            return MapBottomSheet(
              state: state,
              activeJamaah: mapCtrl.selectedJamaah.value,
              onNavigate: () {
                final j = mapCtrl.selectedJamaah.value ?? state.self;
                mapCtrl.selectJamaah(j);
              },
              onShareLocation: () {
                Get.snackbar(
                  'Bagikan Lokasi',
                  'Tautan koordinat langsung disalin ke papan klip.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              onCall: () {
                Get.snackbar(
                  'Memanggil Kontak',
                  'Menghubungi nomor darurat jamaah...',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              bottomOffset: widget.showBottomNav ? 84.0 : 0.0,
            );
          }),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? Obx(
              () => HajiCareBottomNavBar(
                currentIndex: mapCtrl.currentIndex.value,
                onTap: mapCtrl.changeTab,
              ),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE FLUTTER_MAP CANVAS
  // ---------------------------------------------------------------------------

  Widget _buildInteractiveMap(
    HajiCareController state,
    MapController mapCtrl,
  ) {
    return Obx(() {
      final center = mapCtrl.currentUserLocation.value ??
          MapController.defaultMinaBase;
      final tileUrl = mapCtrl.activeTileUrl.value;
      final routePoints = mapCtrl.activeRoute.toList();
      final userLocation = mapCtrl.currentUserLocation.value ??
          MapController.defaultMinaBase;

      return fmap.FlutterMap(
        mapController: mapCtrl.flutterMapController,
        options: fmap.MapOptions(
          initialCenter: center,
          initialZoom: 16.5,
          minZoom: 11.0,
          maxZoom: 19.0,
          onPositionChanged: (camera, hasGesture) {
            mapCtrl.compassRotation.value = camera.rotation;
          },
          onTap: (tapPosition, point) {
            mapCtrl.clearSelection();
          },
        ),
        children: [
          // 1. High-DPI Tile Layer
          fmap.TileLayer(
            urlTemplate: tileUrl,
            userAgentPackageName: 'com.example.hajicare',
          ),

          // 2. Safe Radius Circle Layer (200m)
          fmap.CircleLayer(
            circles: [
              fmap.CircleMarker(
                point: MapController.defaultMinaBase,
                radius: mapCtrl.safeRadiusMeters.value,
                useRadiusInMeter: true,
                color: AppColors.statusSafe.withValues(alpha: 0.08),
                borderColor: AppColors.statusSafe.withValues(alpha: 0.5),
                borderStrokeWidth: 2.0,
              ),
            ],
          ),

          // 3. Dynamic Walking Route Polyline
          if (routePoints.isNotEmpty)
            fmap.PolylineLayer(
              polylines: [
                // Outer shadow line
                fmap.Polyline(
                  points: routePoints,
                  strokeWidth: 6.0,
                  color: AppColors.espressoDark.withValues(alpha: 0.7),
                ),
                // Inner accent line
                fmap.Polyline(
                  points: routePoints,
                  strokeWidth: 3.5,
                  color: AppColors.accentGoldStar,
                ),
              ],
            ),

          // 4. Interactive Marker Layer
          fmap.MarkerLayer(
            markers: [
              // Companion Marker ("Anda")
              fmap.Marker(
                point: userLocation,
                width: 130,
                height: 70,
                child: _buildCompanionMarker(),
              ),

              // Jamaah Markers (Live from state)
              ..._buildJamaahMarkers(state, mapCtrl),

              // Filtered POI Markers
              ..._buildPoiMarkers(mapCtrl),
            ],
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // MARKER BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildCompanionMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.espressoDark,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.goldLight.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.statusSafe,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Anda',
                style: AppTypography.captionSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 38 + (_pulseController.value * 6),
                  height: 38 + (_pulseController.value * 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldLight.withValues(
                      alpha: 0.35 - (_pulseController.value * 0.2),
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.espressoDark, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<fmap.Marker> _buildJamaahMarkers(
    HajiCareController state,
    MapController mapCtrl,
  ) {
    // Only display if filter is Jamaah (0) or Semua (1)
    if (mapCtrl.selectedFilter.value != 0 && mapCtrl.selectedFilter.value != 1) {
      return [];
    }

    final list = state.jamaahList.isNotEmpty ? state.jamaahList : [state.self];

    return list.map((jamaah) {
      final coord = mapCtrl.getJamaahCoordinate(jamaah);
      final isSelected = mapCtrl.selectedJamaah.value?.id == jamaah.id;

      return fmap.Marker(
        point: coord,
        width: 140,
        height: 80,
        child: GestureDetector(
          onTap: () => mapCtrl.selectJamaah(jamaah),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Callout Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.espressoDark
                        : jamaah.tier.color,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.elderly,
                      size: 13,
                      color: jamaah.tier.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      jamaah.shortLabel,
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.espressoDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${jamaah.distance.round()}m',
                      style: AppTypography.captionSmall.copyWith(
                        color: jamaah.tier.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              // Avatar Circle
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: jamaah.tier.color,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.tanMedium,
                      size: 20,
                    ),
                  ),
                  if (jamaah.sosActive)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.sosEmergency,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<fmap.Marker> _buildPoiMarkers(MapController mapCtrl) {
    return mapCtrl.filteredPois.map((poi) {
      final isSelected = mapCtrl.selectedPoi.value?.id == poi.id;

      return fmap.Marker(
        point: poi.coordinate,
        width: 100,
        height: 60,
        child: GestureDetector(
          onTap: () => mapCtrl.selectPoi(poi),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isSelected ? 38 : 32,
                height: isSelected ? 38 : 32,
                decoration: BoxDecoration(
                  color: isSelected ? poi.color : AppColors.surfaceWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : poi.color,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: poi.color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    poi.icon,
                    color: isSelected ? Colors.white : poi.color,
                    size: isSelected ? 20 : 17,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.espressoDark.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  poi.name.split(' ').take(2).join(' '),
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showSmartBandDialog(BuildContext context, HajiCareController state) {
    Get.defaultDialog(
      title: 'Panggil Gelang Pintar',
      titleStyle: AppTypography.titleLarge.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.espressoDark,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const Icon(
              Icons.ring_volume,
              color: AppColors.accentGoldStar,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Kirimkan sinyal getar dan alarm suara ke gelang pintar ${state.self.name} untuk memandu arah kembali.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
      textConfirm: 'Kirim Sinyal',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      textCancel: 'Batal',
      cancelTextColor: AppColors.textBody,
      onConfirm: () {
        Get.back();
        Get.snackbar(
          'Sinyal Terkirim',
          'Gelang pintar bergetar dan membunyikan nada panduan.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.statusSafe,
          colorText: Colors.white,
        );
      },
    );
  }
}
