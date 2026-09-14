import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/filter_chip_item.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
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

/// Fullscreen Interactive Map screen powered by CartoDB/OSM and reactive GetX.
/// Displays real-time GPS tracking of Jamaah and Pendamping within the same Room.
class InteractiveMapScreen extends StatefulWidget {
  final bool showBottomNav;

  const InteractiveMapScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  final List<FilterChipItem> _filters = const [
    FilterChipItem(label: 'Semua', icon: Icons.grid_view, isDefault: true),
    FilterChipItem(label: 'Jamaah', icon: Icons.person),
    FilterChipItem(label: 'Pendamping', icon: Icons.shield),
    FilterChipItem(label: 'Posko Medis', icon: Icons.medical_services),
    FilterChipItem(label: 'Toilet & Wudhu', icon: Icons.wc),
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

          // 2. Top Header with live GPS tracking status, room status, legend, and filter chips
          Obx(
            () => MapTopHeader(
              filters: _filters,
              selectedFilter: mapCtrl.selectedFilter.value,
              onFilterSelected: mapCtrl.selectFilter,
              onSosPressed: () => Get.toNamed(AppRoutes.modalSos),
              isLiveTracking: mapCtrl.isLiveTracking.value,
              gpsAccuracy: mapCtrl.gpsAccuracy.value,
              roomName: mapCtrl.activeRoomName.value,
              memberSummary: mapCtrl.roomMembers.isNotEmpty
                  ? '${mapCtrl.jamaahMembers.length} Jamaah · ${mapCtrl.pendampingMembers.length} Pendamping'
                  : null,
              nearestInfo: mapCtrl.nearestMemberInfo,
            ),
          ),

          // 3. Floating Quick Action Controls (Compass, MyLocation, Focus All, Layers, Band)
          Obx(
            () => MapFloatingControls(
              compassRotation: mapCtrl.compassRotation.value,
              isLocationLoading: mapCtrl.isLocationLoading.value,
              isLiveTracking: mapCtrl.isLiveTracking.value,
              onCompassTap: mapCtrl.resetCompass,
              onLocationTap: mapCtrl.focusToMe,
              onFitAllTap: mapCtrl.focusToAllMembers,
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
              selectedMember: mapCtrl.selectedMember.value,
              roomMembers: mapCtrl.filteredMembers,
              getMemberDistanceText: mapCtrl.getMemberDistanceText,
              onMemberTap: (m) => mapCtrl.selectMember(m),
              onCloseMemberDetail: () => mapCtrl.clearSelection(),
              activeJamaah: mapCtrl.selectedJamaah.value,
              onNavigate: () {
                if (mapCtrl.selectedMember.value != null) {
                  mapCtrl.selectMember(mapCtrl.selectedMember.value!);
                } else {
                  final j = mapCtrl.selectedJamaah.value ?? state.self;
                  mapCtrl.selectJamaah(j);
                }
              },
              onShareLocation: () {
                AppAlert.success(
                  context,
                  title: 'Bagikan Lokasi',
                  message: 'Tautan koordinat langsung disalin ke papan klip.',
                );
              },
              onCall: () {
                AppAlert.info(
                  context,
                  title: 'Memanggil Kontak',
                  message: 'Menghubungi nomor darurat anggota room...',
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
                point: mapCtrl.currentUserLocation.value ??
                    MapController.defaultMinaBase,
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
                fmap.Polyline(
                  points: routePoints,
                  strokeWidth: 6.0,
                  color: AppColors.espressoDark.withValues(alpha: 0.7),
                ),
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
              // Current User Marker ("Anda") - Exactly ONE
              fmap.Marker(
                point: userLocation,
                width: 130,
                height: 70,
                child: _buildCompanionMarker(),
              ),

              // Room Member Markers (Filtered by role, strictly excluding current user)
              if (mapCtrl.roomMembers.isNotEmpty)
                ..._buildRoomMemberMarkers(mapCtrl)
              else
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

  List<fmap.Marker> _buildRoomMemberMarkers(MapController mapCtrl) {
    if (mapCtrl.selectedFilter.value > 2) {
      return [];
    }

    final currentUid = mapCtrl.currentUserId;
    final members = mapCtrl.filteredMembers;
    final markers = <fmap.Marker>[];

    for (final member in members) {
      // 1. Never render current user twice! (Anti-duplication)
      if (currentUid != null && member.uid == currentUid) {
        continue;
      }

      // 2. Only render marker if member has actual GPS location
      if (!member.hasLocation) {
        continue;
      }

      final coord = LatLng(member.latitude!, member.longitude!);
      final isSelected = mapCtrl.selectedMember.value?.uid == member.uid;
      final isPendamping = member.isPendamping;
      final markerColor = isPendamping
          ? AppColors.accentGoldStar
          : AppColors.statusSafe;
      final distText = mapCtrl.getMemberDistanceText(member);

      markers.add(
        fmap.Marker(
          point: coord,
          width: 140,
          height: 75,
          child: GestureDetector(
            onTap: () => mapCtrl.selectMember(member),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Callout Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isSelected ? AppColors.espressoDark : markerColor,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPendamping ? Icons.shield : Icons.person,
                        size: 12,
                        color: markerColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          member.name.split(' ').take(2).join(' '),
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.espressoDark,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: markerColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // Avatar Icon Pin
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.espressoDark : markerColor,
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isPendamping ? Icons.shield : Icons.person,
                    color: markerColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  List<fmap.Marker> _buildJamaahMarkers(
    HajiCareController state,
    MapController mapCtrl,
  ) {
    if (mapCtrl.selectedFilter.value > 2) {
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
    AppAlert.confirm(
      context,
      title: 'Panggil Gelang Pintar',
      message: 'Kirimkan sinyal getar dan alarm suara ke gelang pintar ${state.self.name} untuk memandu arah kembali.',
      confirmText: 'Kirim Sinyal',
      cancelText: 'Batal',
      onConfirm: () {
        AppAlert.success(
          context,
          title: 'Sinyal Terkirim',
          message: 'Gelang pintar bergetar dan membunyikan nada panduan.',
        );
      },
    );
  }
}
