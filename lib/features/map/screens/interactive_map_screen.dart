import 'dart:async';
import 'dart:ui' as ui;
import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final MapController _mapController;

  List<FilterChipItem> _getFilters(BuildContext context) => [
    FilterChipItem(
      label: context.tr('maps.all'),
      icon: Icons.grid_view_rounded,
      isDefault: true,
    ),
    FilterChipItem(
      label: context.tr('maps.pilgrims'),
      icon: Icons.person_rounded,
    ),
    FilterChipItem(
      label: context.tr('maps.companions'),
      icon: Icons.shield_rounded,
    ),
    FilterChipItem(
      label: context.tr('maps.medicalPostPoi'),
      icon: Icons.medical_services_rounded,
    ),
    FilterChipItem(
      label: context.tr('maps.toiletAndWudhu'),
      icon: Icons.wc_rounded,
    ),
    FilterChipItem(
      label: context.tr('maps.maktabPoi'),
      icon: Icons.holiday_village_rounded,
    ),
    FilterChipItem(
      label: context.tr('maps.guardPost'),
      icon: Icons.flag_rounded,
    ),
    FilterChipItem(
      label: context.tr('maps.hotelPoi'),
      icon: Icons.hotel_rounded,
    ),
  ];

  Timer? _mapIdleTimer;
  bool _isMapInteracting = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(_onSearchTextUpdated);
    _mapController = Get.find<MapController>();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  void _onSearchTextUpdated() {
    if (mounted) setState(() {});
  }

  void _onUserMapInteraction() {
    _mapIdleTimer?.cancel();
    if (!_isMapInteracting) {
      setState(() {
        _isMapInteracting = true;
      });
    }
    // Collapse member panel back to compact mode when map is moving
    if (_mapController.isBottomSheetOpen.value &&
        _mapController.selectedPoi.value == null) {
      _mapController.closeBottomSheet();
    }
    _mapIdleTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isMapInteracting = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _mapIdleTimer?.cancel();
    _searchCtrl.removeListener(_onSearchTextUpdated);
    _searchCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Get.find<HajiCareController>();
    final mapCtrl = _mapController;

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Core Interactive Map Layer (Layer Peta)
          RepaintBoundary(child: _buildInteractiveMap(state, mapCtrl)),

          // 2. Dynamic Contextual Bottom Sheets & Compact Member Pill (Panel Anggota & Pendamping)
          Obx(() {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            final sheetBottomOffset = widget.showBottomNav
                ? (84.0 + bottomPadding)
                : (AppSpacing.md + bottomPadding);

            if (!mapCtrl.isBottomSheetOpen.value) {
              final isSearchActive =
                  mapCtrl.searchState.value != MapSearchState.idle ||
                  _searchCtrl.text.trim().isNotEmpty;
              final isPillVisible = !_isMapInteracting && !isSearchActive;

              return _CompactMemberPill(
                mapCtrl: mapCtrl,
                sheetBottomOffset: sheetBottomOffset,
                isVisible: isPillVisible,
              );
            }

            final selectedPoi = mapCtrl.selectedPoi.value;
            if (selectedPoi != null) {
              final userPos = mapCtrl.currentUserLocation.value;
              final dist = userPos == null
                  ? null
                  : mapCtrl.calculateDistanceMeters(
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
                    isRouteLoading: mapCtrl.isRouteLoading.value,
                    routeError: mapCtrl.routeError.value,
                    routeDistanceMeters: mapCtrl.routeDistanceMeters.value,
                    routeDurationSeconds: mapCtrl.routeDurationSeconds.value,
                    onRoute: () {
                      debugPrint('[2] ROUTE BUTTON PRESSED');
                      mapCtrl.requestRouteToPoi(selectedPoi);
                    },
                    onCenterOnDestination: () {
                      mapCtrl.animatedMove(selectedPoi.coordinate, 16.5);
                    },
                    userCoordinate: mapCtrl.currentUserLocation.value,
                    onShare: () async {
                      final coordinate = selectedPoi.coordinate;
                      final url =
                          selectedPoi.openStreetMapUri?.toString() ??
                          'https://www.openstreetmap.org/?mlat=${coordinate.latitude}&mlon=${coordinate.longitude}#map=18/${coordinate.latitude}/${coordinate.longitude}';
                      await Clipboard.setData(
                        ClipboardData(text: '${selectedPoi.name}\n$url'),
                      );
                      if (context.mounted) {
                        AppAlert.success(
                          context,
                          title: context.tr('maps.locationCopied'),
                          message: 'Tautan lokasi siap dibagikan.',
                        );
                      }
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
              onCenterOnMember: () {
                final m = mapCtrl.selectedMember.value;
                if (m?.hasLocation == true) {
                  mapCtrl.animatedMove(
                    LatLng(m!.latitude!, m.longitude!),
                    17.0,
                  );
                } else if (mapCtrl.selectedJamaah.value?.currentLocation !=
                    null) {
                  final loc = mapCtrl.selectedJamaah.value!.currentLocation!;
                  mapCtrl.animatedMove(
                    LatLng(loc.latitude, loc.longitude),
                    17.0,
                  );
                }
              },
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
              onShareLocation: () async {
                final member = mapCtrl.selectedMember.value;
                final jamaah = mapCtrl.selectedJamaah.value;
                final coordinate = member?.hasLocation == true
                    ? LatLng(member!.latitude!, member.longitude!)
                    : jamaah?.currentLocation != null
                    ? mapCtrl.getJamaahCoordinate(jamaah!)
                    : null;
                if (coordinate == null) {
                  AppAlert.warning(
                    context,
                    title: context.tr('maps.locationUnavailable'),
                    message:
                        'Tunggu sampai lokasi jamaah muncul, lalu coba lagi.',
                  );
                  return;
                }
                final name = member?.name ?? jamaah?.name ?? 'Lokasi jamaah';
                final url =
                    'https://www.openstreetmap.org/?mlat=${coordinate.latitude}&mlon=${coordinate.longitude}#map=18/${coordinate.latitude}/${coordinate.longitude}';
                await Clipboard.setData(ClipboardData(text: '$name\n$url'));
                if (context.mounted) {
                  AppAlert.success(
                    context,
                    title: context.tr('maps.locationCopied'),
                    message:
                        'Tautan lokasi sudah disalin dan siap ditempel ke pesan.',
                  );
                }
              },
              onCall: () {
                AppAlert.info(
                  context,
                  title: context.tr('maps.phoneUnavailable'),
                  message:
                      'Nomor telepon jamaah belum tersimpan. Hubungi pendamping melalui rombongan.',
                );
              },
              bottomOffset: sheetBottomOffset,
            );
          }),

          // 3. POI Status Overlay
          Obx(() => _buildPoiStatusOverlay(context, mapCtrl)),

          // 4. Floating Quick Action Controls (Hamburger, Compass, MyLocation, Zoom In/Out, Focus All, Layers, Band)
          Obx(() {
            final isSearchActive =
                mapCtrl.searchState.value != MapSearchState.idle ||
                _searchCtrl.text.trim().isNotEmpty;
            final showHamburger = !_isMapInteracting && !isSearchActive;

            return MapFloatingControls(
              isVisible: showHamburger,
              compassRotation: mapCtrl.compassRotation.value,
              isLocationLoading: mapCtrl.isLocationLoading.value,
              isLiveTracking: mapCtrl.isLiveTracking.value,
              onCompassTap: mapCtrl.resetCompass,
              onLocationTap: mapCtrl.focusToMe,
              onFitAllTap: mapCtrl.focusToAllMembers,
              onLayersTap: mapCtrl.toggleMapTileLayer,
              onBandTap: () => _showSmartBandDialog(context, state),
              onZoomInTap: mapCtrl.zoomIn,
              onZoomOutTap: mapCtrl.zoomOut,
            );
          }),

          // 5. Top Header with live GPS tracking status, room status, legend, and filter chips
          Obx(
            () => MapTopHeader(
              filters: _getFilters(context),
              selectedFilter: mapCtrl.selectedFilter.value,
              onFilterSelected: mapCtrl.selectFilter,
              onSosPressed: () => Get.toNamed(AppRoutes.modalSos),
              searchController: _searchCtrl,
              onSearchChanged: mapCtrl.onSearchQueryChanged,
              onClearSearch: () => mapCtrl.clearSearch(clearMarker: false),
              onSearchFocused: mapCtrl.showSearchHistory,
              isLiveTracking: mapCtrl.isLiveTracking.value,
              gpsAccuracy: mapCtrl.gpsAccuracy.value,
              roomName: mapCtrl.activeRoomName.value,
              memberSummary: mapCtrl.roomMembers.isNotEmpty
                  ? '${mapCtrl.jamaahMembers.length} ${context.tr('maps.pilgrims')} · ${mapCtrl.pendampingMembers.length} ${context.tr('maps.companions')}'
                  : null,
              nearestInfo: mapCtrl.nearestMemberInfo,
              onRoomTap: mapCtrl.openBottomSheet,
            ),
          ),

          // 6. Floating Search Dropdown Overlay (Always on top of all other controls)
          Positioned(
            top: MediaQuery.of(context).padding.top + 116,
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
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const HajiCareBottomNavBar(currentIndex: 1)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// COMPACT FLOATING MEMBER PILL (TAP / SWIPE UP TO OPEN FULL PANEL)
// ---------------------------------------------------------------------------

class _CompactMemberPill extends StatelessWidget {
  final MapController mapCtrl;
  final double sheetBottomOffset;
  final bool isVisible;

  const _CompactMemberPill({
    required this.mapCtrl,
    required this.sheetBottomOffset,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final count = mapCtrl.filteredMembers.length;
    final roleFilter = mapCtrl.selectedRoleFilter.value;
    final label = roleFilter == 1
        ? '$count ${context.tr('maps.pilgrims')}'
        : roleFilter == 2
        ? '$count ${context.tr('maps.companions')}'
        : '$count Anggota & Pendamping';

    return Positioned(
      left: 0,
      right: 0,
      bottom: sheetBottomOffset,
      child: RepaintBoundary(
        child: AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0.0;
                  if (v < -120.0) {
                    mapCtrl.openBottomSheet();
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: mapCtrl.openBottomSheet,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface.withValues(alpha: 0.95)
                            : AppColors.surfaceWhite.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : AppColors.goldLight.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.35 : 0.10,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Left Icon Badge
                          Container(
                            width: 28,
                            height: 28,
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
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Dynamic Label
                          Text(
                            label,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.espressoDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Compact "Buka ▲" badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainer
                                  : AppColors.canvasCream,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.goldPrimary.withValues(
                                        alpha: 0.3,
                                      )
                                    : AppColors.goldPrimary.withValues(
                                        alpha: 0.25,
                                      ),
                                width: 0.8,
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: isDark
                                      ? AppColors.goldPrimary
                                      : AppColors.espressoDark,
                                  size: 14,
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
          ),
        ),
      ),
    );
  }
}

extension _InteractiveMapScreenExt on _InteractiveMapScreenState {
  Widget _buildPoiStatusOverlay(BuildContext context, MapController mapCtrl) {
    final loading = mapCtrl.isPoiLoading.value;
    final error = mapCtrl.poiError.value;
    final searchArea = mapCtrl.showSearchThisArea.value;
    if (!loading && error == null && !searchArea) {
      return const SizedBox.shrink();
    }

    final isDark = AppColors.isDark(context);
    final label = loading
        ? 'Memuat tempat nyata di sekitar…'
        : error != null
        ? 'Coba muat tempat lagi'
        : 'Cari di area ini';
    final icon = loading
        ? null
        : error != null
        ? Icons.refresh_rounded
        : Icons.search_rounded;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 156,
      left: 72,
      right: 72,
      child: Center(
        child: Semantics(
          button: !loading,
          label: label,
          child: Material(
            color: isDark ? AppColors.darkSurface : Colors.white,
            elevation: 5,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              onTap: loading ? null : mapCtrl.searchThisArea,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(icon, size: 18, color: AppColors.goldPrimary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.espressoDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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

  // ---------------------------------------------------------------------------
  // INTERACTIVE FLUTTER_MAP CANVAS
  // ---------------------------------------------------------------------------

  Widget _buildInteractiveMap(HajiCareController state, MapController mapCtrl) {
    return fmap.FlutterMap(
      mapController: mapCtrl.flutterMapController,
      options: fmap.MapOptions(
        initialCenter:
            mapCtrl.pendingFocusCoordinate ??
            mapCtrl.currentUserLocation.value ??
            MapController.defaultMinaBase,
        initialZoom: mapCtrl.pendingFocusCoordinate != null
            ? (mapCtrl.pendingFocusZoom ?? 17.0)
            : 16.5,
        minZoom: 11.0,
        maxZoom: 19.0,
        onMapReady: mapCtrl.handleMapReady,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) {
            _onUserMapInteraction();
          }
          mapCtrl.onMapPositionChanged(
            camera.center,
            camera.zoom,
            hasGesture: hasGesture,
          );
          if ((mapCtrl.compassRotation.value - camera.rotation).abs() > 0.05) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Get.isRegistered<MapController>()) {
                mapCtrl.compassRotation.value = camera.rotation;
              }
            });
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

        // 3. Safe Radius Circle Layer — changes on GPS update (only if real GPS is available)
        Obx(() {
          final userLocation = mapCtrl.currentUserLocation.value;
          if (userLocation == null) {
            return const SizedBox.shrink();
          }
          return fmap.CircleLayer(
            circles: [
              fmap.CircleMarker(
                point: userLocation,
                radius: mapCtrl.safeRadiusMeters.value,
                useRadiusInMeter: true,
                color: AppColors.statusSafe.withValues(alpha: 0.08),
                borderColor: AppColors.statusSafe.withValues(alpha: 0.5),
                borderStrokeWidth: 2.0,
              ),
            ],
          );
        }),

        // 4. Marker Layer — rebuilds on room members, location, and filter change
        Obx(() {
          final userLocation = mapCtrl.currentUserLocation.value;
          final searchResult = mapCtrl.selectedSearchResult.value;

          return fmap.MarkerLayer(
            markers: [
              // Current User Marker ("Anda") - Exactly ONE, rendered ONLY when real GPS exists
              if (userLocation != null)
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
              if (searchResult != null &&
                  mapCtrl.selectedPoi.value?.id != 'search_${searchResult.id}')
                _buildSearchMarker(searchResult),
            ],
          );
        }),
        const fmap.RichAttributionWidget(
          attributions: [
            fmap.TextSourceAttribution('OpenStreetMap contributors'),
            fmap.TextSourceAttribution('CARTO'),
          ],
        ),
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
    final members = List<RoomMemberModel>.from(mapCtrl.filteredMembers);
    if (mapCtrl.selectedMember.value != null &&
        !members.any((m) => m.uid == mapCtrl.selectedMember.value!.uid)) {
      members.add(mapCtrl.selectedMember.value!);
    }
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
      final isSelected =
          mapCtrl.selectedMember.value?.uid == member.uid ||
          mapCtrl.selectedJamaah.value?.id == member.uid;
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
    final source = state.jamaahList.isNotEmpty
        ? state.jamaahList
        : [state.self];
    final list = source.where((jamaah) => jamaah.currentLocation != null);

    return list.map((jamaah) {
      final coord = mapCtrl.getJamaahCoordinate(jamaah);
      final isSelected =
          mapCtrl.selectedJamaah.value?.id == jamaah.id ||
          mapCtrl.selectedMember.value?.uid == jamaah.id;

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
                    children: [
                      Icon(
                        Icons.elderly_rounded,
                        size: 13,
                        color: jamaah.tier.color,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          jamaah.shortLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.captionSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextHeading
                                : AppColors.espressoDark,
                            fontWeight: FontWeight.w800,
                          ),
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
    final userPos = mapCtrl.currentUserLocation.value;

    return mapCtrl.filteredPois.map((poi) {
      final isSelected = mapCtrl.selectedPoi.value?.id == poi.id;
      final showLabel = isSelected || mapCtrl.mapZoom.value >= 15.5;
      final distText = userPos == null
          ? null
          : MapController.formatDistance(
              mapCtrl.calculateDistanceMeters(userPos, poi.coordinate),
            );

      return fmap.Marker(
        point: poi.coordinate,
        width: 130,
        height: showLabel ? 82 : 52,
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
                                color: poi.color.withValues(
                                  alpha: isSelected ? 0.55 : 0.35,
                                ),
                                blurRadius: isSelected ? 12 : 8,
                                spreadRadius: isSelected ? 1 : 0,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.15,
                                ),
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

                if (showLabel) const SizedBox(height: 2),

                // ── FLOATING CALLOUT LABEL PILL ──
                if (showLabel)
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
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.12,
                          ),
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
                              color: isDark
                                  ? Colors.white
                                  : AppColors.espressoDark,
                              fontSize: 9.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (distText != null) ...[
                          const SizedBox(width: 3),
                          Text(
                            '· $distText',
                            style: TextStyle(
                              color: isSelected
                                  ? poi.color
                                  : (isDark
                                        ? Colors.white60
                                        : AppColors.textMuted),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
    AppAlert.info(
      context,
      title: context.tr('maps.bandDisconnected'),
      message:
          'Hubungkan gelang pintar milik ${state.self.name}, lalu coba lagi.',
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
