import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/constants/app_constants.dart';
import '../../../core/models/filter_chip_item.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../controllers/map_controller.dart';
import '../models/map_search_result.dart';
import '../widgets/location_detail_sheet.dart';
import '../widgets/map_bottom_sheet.dart';
import '../widgets/map_floating_controls.dart';
import '../widgets/map_search_dropdown.dart';
import '../widgets/map_top_header.dart';

/// Fullscreen Interactive Map screen powered by CartoDB/OSM and reactive GetX.
/// Displays real-time GPS tracking of Jamaah and Pendamping within the same Room.
class InteractiveMapScreen extends StatefulWidget {
  final bool showBottomNav;

  const InteractiveMapScreen({super.key, this.showBottomNav = true});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late final TextEditingController _searchCtrl;

  static const List<FilterChipItem> _filters = [
    FilterChipItem(
      label: 'Semua',
      icon: Icons.grid_view_rounded,
      isDefault: true,
    ),
    FilterChipItem(label: 'Jamaah', icon: Icons.person_rounded),
    FilterChipItem(label: 'Pendamping', icon: Icons.shield_rounded),
    FilterChipItem(label: 'Posko Medis', icon: Icons.medical_services_rounded),
    FilterChipItem(label: 'Toilet & Wudhu', icon: Icons.wc_rounded),
    FilterChipItem(label: 'Maktab', icon: Icons.holiday_village_rounded),
    FilterChipItem(label: 'Pos Pantau', icon: Icons.flag_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Core Interactive Map Layer
          RepaintBoundary(child: _buildInteractiveMap(state, mapCtrl)),

          // 2. Top Header with live GPS tracking status, room status, legend, and filter chips
          Obx(
            () => MapTopHeader(
              filters: _filters,
              selectedFilter: mapCtrl.selectedFilter.value,
              onFilterSelected: mapCtrl.selectFilter,
              onSosPressed: () => Get.toNamed(AppRoutes.modalSos),
              searchController: _searchCtrl,
              onSearchChanged: mapCtrl.onSearchQueryChanged,
              onClearSearch: () => mapCtrl.clearSearch(clearMarker: false),
              isLiveTracking: mapCtrl.isLiveTracking.value,
              gpsAccuracy: mapCtrl.gpsAccuracy.value,
              roomName: mapCtrl.activeRoomName.value,
              memberSummary: mapCtrl.roomMembers.isNotEmpty
                  ? '${mapCtrl.jamaahMembers.length} Jamaah · ${mapCtrl.pendampingMembers.length} Pendamping'
                  : null,
              nearestInfo: mapCtrl.nearestMemberInfo,
              onRoomTap: mapCtrl.openBottomSheet,
            ),
          ),

          // 2.5 Floating Search Dropdown Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 90,
            left: 0,
            right: 0,
            child: MapSearchDropdown(
              mapCtrl: mapCtrl,
              onSelect: (result) {
                _searchCtrl.text = result.name;
                mapCtrl.selectSearchResult(result);
              },
            ),
          ),

          // 3. Floating Quick Action Controls (Compass, MyLocation, Zoom In/Out, Focus All, Layers, Band)
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
              onZoomInTap: () {
                final cam = mapCtrl.flutterMapController.camera;
                mapCtrl.flutterMapController.move(
                  cam.center,
                  (cam.zoom + 1.0).clamp(11.0, 19.0),
                );
              },
              onZoomOutTap: () {
                final cam = mapCtrl.flutterMapController.camera;
                mapCtrl.flutterMapController.move(
                  cam.center,
                  (cam.zoom - 1.0).clamp(11.0, 19.0),
                );
              },
            ),
          ),

          // 4. Dynamic Contextual Bottom Sheets
          Obx(() {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            final sheetBottomOffset = widget.showBottomNav
                ? (84.0 + bottomPadding)
                : (AppSpacing.md + bottomPadding);

            if (!mapCtrl.isBottomSheetOpen.value) {
              return _CollapsedMemberBar(
                mapCtrl: mapCtrl,
                sheetBottomOffset: sheetBottomOffset,
              );
            }

            final selectedPoi = mapCtrl.selectedPoi.value;
            if (selectedPoi != null) {
              final userPos =
                  mapCtrl.currentUserLocation.value ??
                  MapController.defaultMinaBase;
              final dist = mapCtrl.calculateDistanceMeters(
                userPos,
                selectedPoi.coordinate,
              );

              return Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: sheetBottomOffset,
                child: RepaintBoundary(
                  child: LocationDetailSheet(
                    poi: selectedPoi,
                    distanceMeters: dist,
                    onRoute: () {
                      debugPrint('[2] ROUTE BUTTON PRESSED');
                      mapCtrl.requestRouteToPoi(selectedPoi);
                    },
                    onClose: mapCtrl.closeBottomSheet,
                  ),
                ),
              );
            }

            return MapBottomSheet(
              state: state,
              selectedMember: mapCtrl.selectedMember.value,
              roomMembers: mapCtrl.filteredMembers,
              getMemberDistanceText: mapCtrl.getMemberDistanceText,
              onMemberTap: (m) => mapCtrl.selectMember(m),
              onCloseMemberDetail: mapCtrl.closeBottomSheet,
              onBackToList: mapCtrl.selectedMember.value != null
                  ? mapCtrl.backToMembersList
                  : null,
              activeJamaah: mapCtrl.selectedJamaah.value,
              onNavigate: () {
                debugPrint('[2] ROUTE BUTTON PRESSED');
                if (mapCtrl.selectedMember.value != null) {
                  mapCtrl.requestRouteToMember(mapCtrl.selectedMember.value!);
                } else {
                  final j = mapCtrl.selectedJamaah.value ?? state.self;
                  mapCtrl.requestRouteToJamaah(j);
                }
              },
              isRouteLoading: mapCtrl.isRouteLoading.value,
              routeDistanceMeters: mapCtrl.routeDistanceMeters.value,
              routeDurationSeconds: mapCtrl.routeDurationSeconds.value,
              routeError: mapCtrl.routeError.value,
              onRetryRoute: mapCtrl.retryRoute,
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
              bottomOffset: sheetBottomOffset,
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
  // COLLAPSED DYNAMIC PEEK BAR
  // ---------------------------------------------------------------------------
}

// ---------------------------------------------------------------------------
// COLLAPSED DYNAMIC PEEK BAR (WITH DRAG-UP & TAP TO OPEN)
// ---------------------------------------------------------------------------

class _CollapsedMemberBar extends StatefulWidget {
  final MapController mapCtrl;
  final double sheetBottomOffset;

  const _CollapsedMemberBar({
    required this.mapCtrl,
    required this.sheetBottomOffset,
  });

  @override
  State<_CollapsedMemberBar> createState() => _CollapsedMemberBarState();
}

class _CollapsedMemberBarState extends State<_CollapsedMemberBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  Animation<double>? _slideAnim;
  double _dragUpOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    // Smooth entrance glide up from +28px to 0.0
    _dragUpOffset = 28.0;
    _slideAnim = Tween<double>(begin: 28.0, end: 0.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    )..addListener(_onAnimTick);
    _animCtrl.forward();
  }

  void _onAnimTick() {
    if (mounted && _slideAnim != null) {
      setState(() {
        _dragUpOffset = _slideAnim!.value;
      });
    }
  }

  @override
  void dispose() {
    _slideAnim?.removeListener(_onAnimTick);
    _animCtrl.dispose();
    super.dispose();
  }

  void _springBackAnimation() {
    if (_dragUpOffset == 0.0) return;
    final startOffset = _dragUpOffset;
    _slideAnim?.removeListener(_onAnimTick);
    _animCtrl.duration = const Duration(milliseconds: 180);
    _slideAnim = Tween<double>(begin: startOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    )..addListener(_onAnimTick);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_animCtrl.isAnimating) _animCtrl.stop();
    if (details.primaryDelta != null) {
      setState(() {
        _dragUpOffset = (_dragUpOffset + details.primaryDelta!).clamp(
          -70.0,
          15.0,
        );
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragUpOffset < -25.0 || velocity < -180.0) {
      widget.mapCtrl.openBottomSheet();
    } else {
      _springBackAnimation();
    }
  }

  void _onVerticalDragCancel() {
    _springBackAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final count = widget.mapCtrl.filteredMembers.length;
    final roleFilter = widget.mapCtrl.selectedRoleFilter.value;
    final label = roleFilter == 1
        ? '$count Jamaah'
        : roleFilter == 2
        ? '$count Pendamping'
        : '$count Anggota & Pendamping';

    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: widget.sheetBottomOffset,
      child: RepaintBoundary(
        child: Opacity(
          opacity: (1.0 - (_dragUpOffset.abs() / 140.0)).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _dragUpOffset),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.mapCtrl.openBottomSheet,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              onVerticalDragCancel: _onVerticalDragCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.espressoDark.withValues(alpha: 0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withValues(
                        alpha: isDark ? 0.25 : 0.16,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: isDark
                          ? AppColors.goldPrimary
                          : AppColors.espressoDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: AppTypography.titleSmall.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.espressoDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tarik ke atas atau ketuk untuk detail',
                          style: AppTypography.captionSmall.copyWith(
                            color: isDark ? Colors.white60 : AppColors.textBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isDark
                            ? AppColors.goldPrimary.withValues(alpha: 0.3)
                            : AppColors.espressoDark.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Buka',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.goldPrimary
                                : AppColors.espressoDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.espressoDark,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

extension _InteractiveMapScreenExt on _InteractiveMapScreenState {
  // ---------------------------------------------------------------------------
  // INTERACTIVE FLUTTER_MAP CANVAS
  // ---------------------------------------------------------------------------

  Widget _buildInteractiveMap(HajiCareController state, MapController mapCtrl) {
    return fmap.FlutterMap(
      mapController: mapCtrl.flutterMapController,
      options: fmap.MapOptions(
        initialCenter:
            mapCtrl.currentUserLocation.value ?? MapController.defaultMinaBase,
        initialZoom: 16.5,
        minZoom: 11.0,
        maxZoom: 19.0,
        onPositionChanged: (camera, hasGesture) {
          if ((mapCtrl.compassRotation.value - camera.rotation).abs() > 0.05) {
            mapCtrl.compassRotation.value = camera.rotation;
          }
        },
        onTap: (tapPosition, point) {
          FocusScope.of(context).unfocus();
          mapCtrl.clearSearch(clearMarker: false);
          mapCtrl.closeBottomSheet();
        },
      ),
      children: [
        // 1. Tile Layer — changes only on layer toggle & dark mode
        Obx(() {
          final isDark = AppColors.isDark(context);
          final currentUrl = mapCtrl.activeTileUrl.value;
          final effectiveUrl = isDark
              ? (currentUrl == AppConstants.cartoVoyagerUrl
                    ? AppConstants.cartoDarkMatterUrl
                    : currentUrl)
              : currentUrl;

          return fmap.TileLayer(
            urlTemplate: effectiveUrl,
            userAgentPackageName: 'com.example.hajicare',
            panBuffer: 1,
          );
        }),

        // 2. Walking Route Polyline Layer
        Obx(() {
          final isDark = AppColors.isDark(context);
          final routePoints = mapCtrl.activeRoute;

          if (routePoints.length < 2) {
            return const SizedBox.shrink();
          }

          return fmap.PolylineLayer(
            polylines: [
              fmap.Polyline<Object>(
                points: routePoints.toList(),
                strokeWidth: 8.0,
                color: isDark ? AppColors.goldPrimary : const Color(0xFF1E60CC),
                borderStrokeWidth: 2.5,
                borderColor: isDark
                    ? const Color(0xFF3E2800)
                    : const Color(0xFF0D254C),
              ),
            ],
          );
        }),

        // 3. Safe Radius Circle Layer — changes on GPS update
        Obx(
          () => fmap.CircleLayer(
            circles: [
              fmap.CircleMarker(
                point:
                    mapCtrl.currentUserLocation.value ??
                    MapController.defaultMinaBase,
                radius: mapCtrl.safeRadiusMeters.value,
                useRadiusInMeter: true,
                color: AppColors.statusSafe.withValues(alpha: 0.08),
                borderColor: AppColors.statusSafe.withValues(alpha: 0.5),
                borderStrokeWidth: 2.0,
              ),
            ],
          ),
        ),

        // 4. Marker Layer — rebuilds on room members, location, and filter change
        Obx(() {
          final userLocation =
              mapCtrl.currentUserLocation.value ??
              MapController.defaultMinaBase;
          final searchResult = mapCtrl.selectedSearchResult.value;

          return fmap.MarkerLayer(
            markers: [
              // Current User Marker ("Anda") - Exactly ONE
              fmap.Marker(
                point: userLocation,
                width: 130,
                height: 75,
                child: RepaintBoundary(child: _buildCompanionMarker()),
              ),

              // Room Member Markers (filtered, excluding current user)
              if (mapCtrl.roomMembers.isNotEmpty)
                ..._buildRoomMemberMarkers(mapCtrl)
              else
                ..._buildJamaahMarkers(state, mapCtrl),

              // Filtered POI Markers
              ..._buildPoiMarkers(mapCtrl),

              // Dedicated Search Location Marker (isolated logic)
              if (searchResult != null) _buildSearchMarker(searchResult),
            ],
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MARKER BUILDERS
  // ---------------------------------------------------------------------------

  fmap.Marker _buildSearchMarker(MapSearchResult result) {
    final isDark = AppColors.isDark(context);
    return fmap.Marker(
      point: result.coordinate,
      width: 150,
      height: 75,
      alignment: Alignment.topCenter,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.espressoDark,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.goldPrimary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 13,
                    color: AppColors.goldPrimary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      result.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFC62828)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_searching_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanionMarker() {
    final isDark = AppColors.isDark(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.espressoDark,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.goldPrimary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.statusSafe,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Anda',
                style: AppTypography.captionSmall.copyWith(
                  color: isDark ? AppColors.darkTextHeading : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 38 + (_pulseController.value * 8),
                    height: 38 + (_pulseController.value * 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.goldPrimary.withValues(
                        alpha: 0.35 - (_pulseController.value * 0.22),
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.surfaceWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.goldPrimary
                            : AppColors.espressoDark,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: AppColors.goldPrimary,
                      size: 19,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<fmap.Marker> _buildRoomMemberMarkers(MapController mapCtrl) {
    if (mapCtrl.selectedFilter.value > 2) {
      return [];
    }

    final isDark = AppColors.isDark(context);
    final currentUid = mapCtrl.currentUserId;
    final members = mapCtrl.filteredMembers;
    final markers = <fmap.Marker>[];

    for (final member in members) {
      // 1. Never render current user twice
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
          ? AppColors.goldPrimary
          : AppColors.statusSafe;
      final distText = mapCtrl.getMemberDistanceText(member);

      markers.add(
        fmap.Marker(
          point: coord,
          width: 140,
          height: 75,
          child: RepaintBoundary(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (mapCtrl.selectedMember.value?.uid == member.uid &&
                    mapCtrl.isBottomSheetOpen.value) {
                  mapCtrl.closeBottomSheet();
                } else {
                  mapCtrl.selectMember(member);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Callout Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.espressoDark)
                            : markerColor,
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
                          isPendamping
                              ? Icons.shield_rounded
                              : Icons.person_rounded,
                          size: 12,
                          color: markerColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            member.name.split(' ').take(2).join(' '),
                            style: AppTypography.captionSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextHeading
                                  : AppColors.espressoDark,
                              fontWeight: FontWeight.w800,
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
                            fontWeight: FontWeight.w800,
                            color: markerColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Avatar Icon Pin
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.surfaceWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.espressoDark)
                            : markerColor,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isPendamping
                          ? Icons.shield_rounded
                          : Icons.person_rounded,
                      color: markerColor,
                      size: 19,
                    ),
                  ),
                ],
              ),
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

    final isDark = AppColors.isDark(context);
    final list = state.jamaahList.isNotEmpty ? state.jamaahList : [state.self];

    return list.map((jamaah) {
      final coord = mapCtrl.getJamaahCoordinate(jamaah);
      final isSelected = mapCtrl.selectedJamaah.value?.id == jamaah.id;

      return fmap.Marker(
        point: coord,
        width: 140,
        height: 80,
        child: RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (mapCtrl.selectedJamaah.value?.id == jamaah.id &&
                  mapCtrl.isBottomSheetOpen.value) {
                mapCtrl.closeBottomSheet();
              } else {
                mapCtrl.selectJamaah(jamaah);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isSelected
                          ? (isDark
                                ? AppColors.goldPrimary
                                : AppColors.espressoDark)
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
                        Icons.elderly_rounded,
                        size: 13,
                        color: jamaah.tier.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        jamaah.shortLabel,
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextHeading
                              : AppColors.espressoDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        jamaah.formattedDistance,
                        style: AppTypography.captionSmall.copyWith(
                          color: jamaah.tier.color,
                          fontWeight: FontWeight.w800,
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
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.surfaceWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: jamaah.tier.color, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: isDark ? AppColors.goldPrimary : AppColors.tanMedium,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<fmap.Marker> _buildPoiMarkers(MapController mapCtrl) {
    final isDark = AppColors.isDark(context);
    final userPos = mapCtrl.currentUserLocation.value ?? MapController.defaultMinaBase;

    return mapCtrl.filteredPois.map((poi) {
      final isSelected = mapCtrl.selectedPoi.value?.id == poi.id;
      final distMeters = mapCtrl.calculateDistanceMeters(userPos, poi.coordinate);
      final distText = MapController.formatDistance(distMeters);

      return fmap.Marker(
        point: poi.coordinate,
        width: 130,
        height: 82,
        alignment: Alignment.topCenter,
        child: RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (mapCtrl.selectedPoi.value?.id == poi.id &&
                  mapCtrl.isBottomSheetOpen.value) {
                mapCtrl.closeBottomSheet();
              } else {
                mapCtrl.selectPoi(poi);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── GOOGLE MAPS FLOATING PIN WITH POINTER ──
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Pulsing Halo Glow when Selected
                    if (isSelected)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 44 + (_pulseController.value * 12),
                            height: 44 + (_pulseController.value * 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: poi.color.withValues(
                                alpha: 0.40 - (_pulseController.value * 0.25),
                              ),
                            ),
                          );
                        },
                      ),

                    // Pin Marker Shape (Circle + Pointer)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circular Pin Head
                        Container(
                          width: isSelected ? 40 : 34,
                          height: isSelected ? 40 : 34,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.lerp(poi.color, Colors.white, 0.18)!,
                                poi.color,
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 2.5 : 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: poi.color.withValues(alpha: isSelected ? 0.55 : 0.35),
                                blurRadius: isSelected ? 12 : 8,
                                spreadRadius: isSelected ? 1 : 0,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              poi.icon,
                              color: Colors.white,
                              size: isSelected ? 21 : 18,
                            ),
                          ),
                        ),

                        // Downward Pointer Triangle
                        Transform.translate(
                          offset: const Offset(0, -2.5),
                          child: CustomPaint(
                            size: const Size(10, 6),
                            painter: _TrianglePointerPainter(
                              color: poi.color,
                              borderColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // ── FLOATING CALLOUT LABEL PILL ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isSelected
                          ? poi.color
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.08)),
                      width: isSelected ? 1.5 : 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: poi.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          poi.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.espressoDark,
                            fontSize: 9.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '· $distText',
                        style: TextStyle(
                          color: isSelected ? poi.color : (isDark ? Colors.white60 : AppColors.textMuted),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showSmartBandDialog(BuildContext context, HajiCareController state) {
    AppAlert.confirm(
      context,
      title: 'Panggil Gelang Pintar',
      message:
          'Kirimkan sinyal getar dan alarm suara ke gelang pintar ${state.self.name} untuk memandu arah kembali.',
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

class _TrianglePointerPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  const _TrianglePointerPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePointerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}

