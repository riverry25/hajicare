import 'dart:async';
import 'dart:ui' as ui;
import '../../../core/locales/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../dashboard/models/assistance_request_model.dart';
import '../../dashboard/services/assistance_request_service.dart';
import '../controllers/map_controller.dart';
import '../models/map_search_result.dart';
import '../widgets/location_detail_sheet.dart';
import '../widgets/map_bottom_sheet.dart';
import '../widgets/map_floating_controls.dart';
import '../widgets/map_search_dropdown.dart';
import '../widgets/map_top_header.dart';
import '../widgets/navigation/navigation_arrival_card.dart';
import '../widgets/navigation/navigation_bottom_panel.dart';
import '../widgets/navigation/navigation_map_view.dart';
import '../widgets/navigation/navigation_recenter_button.dart';
import '../widgets/navigation/navigation_top_card.dart';

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
    _mapController = Get.isRegistered<MapController>()
        ? Get.find<MapController>()
        : Get.put(MapController());
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isMapInteracting) {
          setState(() {
            _isMapInteracting = true;
          });
        }
      });
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
          // 1. Core Map Layer (Normal 2D flutter_map OR 3D Perspective NavigationMapView)
          Obx(() {
            if (mapCtrl.isNavigating) {
              return RepaintBoundary(
                child: NavigationMapView(mapCtrl: mapCtrl),
              );
            }
            return RepaintBoundary(child: _buildInteractiveMap(state, mapCtrl));
          }),

          // 2. Normal Mode: Dynamic Contextual Bottom Sheets & Compact Member Pill
          Obx(() {
            if (mapCtrl.isNavigating) return const SizedBox.shrink();

            final bottomPadding = MediaQuery.of(context).padding.bottom;
            // When hosted inside dashboard Scaffold (with extendBody: true),
            // Scaffold._BodyBuilder sets MediaQuery bottom padding to include
            // the full HajiCareBottomNavBar layout height (approx. 88-120px).
            // When standalone (showBottomNav: true) or when bottom padding is only
            // the device window inset, we add the bottom nav bar height (84px).
            final navBarHeight = (widget.showBottomNav || bottomPadding < 60)
                ? 84.0
                : 0.0;
            // 12px margin places the card cleanly right above the center mic button and dock.
            final sheetBottomOffset = bottomPadding + navBarHeight + 12.0;

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
                      if (mapCtrl.activeRoute.isNotEmpty) {
                        mapCtrl.startNavigation();
                      } else {
                        mapCtrl.requestRouteToPoi(selectedPoi);
                      }
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
                if (mapCtrl.activeRoute.isNotEmpty) {
                  mapCtrl.startNavigation();
                } else if (mapCtrl.selectedMember.value != null) {
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

          // 3. Normal Mode: POI Status Overlay
          Obx(() {
            if (mapCtrl.isNavigating) return const SizedBox.shrink();
            return _buildPoiStatusOverlay(context, mapCtrl);
          }),

          // 4. Normal Mode: Floating Quick Action Controls
          Obx(() {
            if (mapCtrl.isNavigating) return const SizedBox.shrink();
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

          // 5. Normal Mode: Top Header with live GPS tracking status
          Obx(() {
            if (mapCtrl.isNavigating) return const SizedBox.shrink();
            return MapTopHeader(
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
            );
          }),

          // 6. Normal Mode: Floating Search Dropdown Overlay
          Obx(() {
            if (mapCtrl.isNavigating) return const SizedBox.shrink();
            return Positioned(
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
            );
          }),

          // 7. Navigation Mode HUD Overlays
          Obx(() {
            if (!mapCtrl.isNavigating) return const SizedBox.shrink();
            return Stack(
              children: [
                // Top Direction Card
                NavigationTopCard(mapCtrl: mapCtrl),

                // Re-center Floating Button
                NavigationRecenterButton(mapCtrl: mapCtrl),

                // Bottom Navigation Information Panel
                NavigationBottomPanel(mapCtrl: mapCtrl),

                // Arrival Card
                if (mapCtrl.mapMode.value == MapMode.arrived)
                  NavigationArrivalCard(mapCtrl: mapCtrl),
              ],
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(() {
        if (mapCtrl.isNavigating) return const SizedBox.shrink();
        return widget.showBottomNav
            ? const HajiCareBottomNavBar(currentIndex: 1)
            : const SizedBox.shrink();
      }),
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
        : context.tr('maps.membersAndCompanions', {'count': count.toString()});

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
                                  context.tr('maps.openSheet'),
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
        ? context.tr('maps.loadingNearbyPois')
        : error != null
        ? context.tr('maps.retryLoadPois')
        : context.tr('maps.searchThisArea');
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

        // 4. Marker Layer — rebuilds on room members, location, filter change, and emergency SOS alerts
        Obx(() {
          // Reactively observe SOS state changes so emergency markers update in real time
          final _ = state.activeSosCount.value;
          final _ = state.activeSosEvents.length;

          final userLocation = mapCtrl.currentUserLocation.value;
          final searchResult = mapCtrl.selectedSearchResult.value;
          final assistanceReq =
              mapCtrl.activeAssistanceRequest.value ??
              AssistanceRequestService.instance.activeRequest.value;
          final hasAssistanceMarker =
              assistanceReq != null &&
              assistanceReq.isActive &&
              assistanceReq.latitude != null &&
              assistanceReq.longitude != null;

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

              // Active Assistance Request Pin Marker (Prominent Jemputan / Bantuan Pin)
              if (hasAssistanceMarker)
                _buildAssistanceMarker(assistanceReq, mapCtrl),

              // Room Member Markers (filtered, single marker per person, turns RED on SOS)
              if (mapCtrl.roomMembers.isNotEmpty)
                ..._buildRoomMemberMarkers(
                  state,
                  mapCtrl,
                  excludeUid: hasAssistanceMarker
                      ? assistanceReq.jamaahId
                      : null,
                )
              else
                ..._buildJamaahMarkers(
                  state,
                  mapCtrl,
                  excludeUid: hasAssistanceMarker
                      ? assistanceReq.jamaahId
                      : null,
                ),

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

  fmap.Marker _buildAssistanceMarker(
    AssistanceRequestModel req,
    MapController mapCtrl,
  ) {
    final coord = LatLng(req.latitude!, req.longitude!);
    final isSelected =
        mapCtrl.selectedMember.value?.uid == req.jamaahId ||
        mapCtrl.activeAssistanceRequest.value?.id == req.id;

    return fmap.Marker(
      point: coord,
      width: 170,
      height: 82,
      alignment: Alignment.topCenter,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            mapCtrl.focusOnAssistanceRequest(req, autoRoute: false);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Callout Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE64A19), Color(0xFFD84315)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 2.2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE64A19).withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        req.jamaahName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Pin Icon with pulsing ring
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE64A19).withValues(alpha: 0.22),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE64A19), Color(0xFFBF360C)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE64A19).withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_run_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                context.tr('youLabel'),
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldPrimary.withValues(alpha: 0.22),
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
          ),
        ),
      ],
    );
  }

  List<fmap.Marker> _buildRoomMemberMarkers(
    HajiCareController state,
    MapController mapCtrl, {
    String? excludeUid,
  }) {
    if (mapCtrl.selectedFilter.value > 2) {
      return [];
    }

    final isDark = AppColors.isDark(context);
    final currentUid = mapCtrl.currentUserId ?? state.currentUid;
    final selfName = state.self.name.trim().toLowerCase();

    // 1. Collect room members from current filter
    final members = List<RoomMemberModel>.from(mapCtrl.filteredMembers);
    if (mapCtrl.selectedMember.value != null &&
        !members.any((m) => m.uid == mapCtrl.selectedMember.value!.uid)) {
      members.add(mapCtrl.selectedMember.value!);
    }

    // 2. Incorporate active SOS events not yet present in room members
    for (final sos in state.activeSosEvents) {
      final sosId = sos['id']?.toString();
      final sosUid = sos['userId']?.toString() ?? sos['jamaahId']?.toString();
      final sosRawName = (sos['userName'] as String?)?.trim();
      final sosName = (sosRawName != null && sosRawName.isNotEmpty)
          ? sosRawName
          : 'Jamaah SOS';
      final normSosName = sosName.toLowerCase();

      if (state.isSosDismissed(sosId) ||
          (sosUid != null && state.isSosDismissed(sosUid))) {
        continue;
      }

      final isAlreadyPresent = members.any((m) {
        final mName = m.name.trim().toLowerCase();
        return (sosUid != null && m.uid == sosUid) ||
            (normSosName != 'jamaah sos' &&
                (mName == normSosName ||
                    mName.contains(normSosName) ||
                    normSosName.contains(mName)));
      });

      if (!isAlreadyPresent) {
        double? lat;
        double? lng;
        final locField = sos['location'];
        if (locField is GeoPoint) {
          lat = locField.latitude;
          lng = locField.longitude;
        } else if (sos['latitude'] != null && sos['longitude'] != null) {
          lat = (sos['latitude'] as num).toDouble();
          lng = (sos['longitude'] as num).toDouble();
        }

        if (lat != null && lng != null) {
          members.add(
            RoomMemberModel(
              uid:
                  sosUid ??
                  'sos_${sosId ?? DateTime.now().millisecondsSinceEpoch}',
              name: sosName,
              role: 'jamaah',
              currentLocation: GeoPoint(lat, lng),
              locationUpdatedAt: DateTime.now(),
              sosActive: true,
            ),
          );
        }
      }
    }

    final markers = <fmap.Marker>[];
    final seenMarkerUids = <String>{};
    final seenCoords = <LatLng>[];

    for (final member in members) {
      // Never render current user twice (already rendered as "Anda")
      if (currentUid != null && member.uid == currentUid) {
        continue;
      }
      if (currentUid != null &&
          member.name.trim().toLowerCase() == selfName &&
          !member.isJamaah) {
        continue;
      }

      // Exclude assistance target to prevent duplicate marker
      if (excludeUid != null && member.uid == excludeUid) {
        continue;
      }

      // Deduplicate by UID: strictly ONE marker per user
      if (seenMarkerUids.contains(member.uid)) {
        continue;
      }

      // Check if this member is in SOS emergency state
      final matchingSos = state.activeSosEvents.firstWhereOrNull((e) {
        if (state.isSosDismissed(e['id']?.toString())) return false;
        final uid = e['userId']?.toString() ?? e['jamaahId']?.toString();
        final name = e['userName']?.toString().trim().toLowerCase();
        final mName = member.name.trim().toLowerCase();
        return ((uid != null && uid == member.uid) ||
                (name != null &&
                    name.isNotEmpty &&
                    (name == mName ||
                        name.contains(mName) ||
                        mName.contains(name)))) &&
            !state.isSosDismissed(e['id']?.toString());
      });
      final isEmergency = member.sosActive || matchingSos != null;

      // Extract coordinates (prefer member coordinates, fallback to SOS coordinates)
      double? lat = member.latitude;
      double? lng = member.longitude;
      if ((lat == null || lng == null) && matchingSos != null) {
        final locField = matchingSos['location'];
        if (locField is GeoPoint) {
          lat = locField.latitude;
          lng = locField.longitude;
        } else if (matchingSos['latitude'] != null &&
            matchingSos['longitude'] != null) {
          lat = (matchingSos['latitude'] as num).toDouble();
          lng = (matchingSos['longitude'] as num).toDouble();
        }
      }

      if (lat == null || lng == null) {
        continue;
      }

      final coord = LatLng(lat, lng);

      // Coordinate-level duplicate guard
      if (seenCoords.any(
        (c) =>
            (c.latitude - coord.latitude).abs() < 0.0001 &&
            (c.longitude - coord.longitude).abs() < 0.0001,
      )) {
        continue;
      }

      seenMarkerUids.add(member.uid);
      seenCoords.add(coord);

      final isSelected =
          mapCtrl.selectedMember.value?.uid == member.uid ||
          mapCtrl.selectedJamaah.value?.id == member.uid;
      final isPendamping = member.isPendamping;
      final markerColor = isEmergency
          ? AppColors.sosEmergency
          : (isPendamping ? AppColors.goldPrimary : AppColors.statusSafe);
      final distMeters = mapCtrl.getDistanceToMember(member);
      final distText = distMeters != null
          ? MapController.formatDistance(distMeters)
          : '';

      markers.add(
        fmap.Marker(
          point: coord,
          width: isEmergency ? 165 : 145,
          height: isEmergency ? 82 : 75,
          child: RepaintBoundary(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                if (mapCtrl.selectedMember.value?.uid == member.uid &&
                    mapCtrl.isBottomSheetOpen.value) {
                  mapCtrl.closeBottomSheet();
                } else {
                  mapCtrl.selectMember(member);
                  mapCtrl.animatedMove(coord, 17.0);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Callout Banner
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isEmergency ? 9 : 8,
                      vertical: isEmergency ? 4 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: isEmergency
                          ? AppColors.sosEmergency
                          : (isDark
                                ? AppColors.darkSurface
                                : AppColors.surfaceWhite),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isEmergency
                            ? Colors.white
                            : (isSelected
                                  ? (isDark
                                        ? AppColors.goldPrimary
                                        : AppColors.espressoDark)
                                  : markerColor),
                        width: isEmergency ? 2.0 : (isSelected ? 2.5 : 1.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isEmergency
                                      ? AppColors.sosEmergency
                                      : Colors.black)
                                  .withValues(alpha: isEmergency ? 0.5 : 0.18),
                          blurRadius: isEmergency ? 10 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEmergency
                              ? Icons.warning_amber_rounded
                              : (isPendamping
                                    ? Icons.shield_rounded
                                    : Icons.person_rounded),
                          size: isEmergency ? 13 : 12,
                          color: isEmergency ? Colors.white : markerColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isEmergency
                                ? 'SOS • ${member.name.split(' ').first}'
                                : member.name.split(' ').take(2).join(' '),
                            style: AppTypography.captionSmall.copyWith(
                              color: isEmergency
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.darkTextHeading
                                        : AppColors.espressoDark),
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (distText.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            distText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isEmergency
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : markerColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Avatar Icon Pin (with pulsing red halo if SOS active)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isEmergency)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final pulse = _pulseController.value;
                            return Container(
                              width: 34 + (12 * pulse),
                              height: 34 + (12 * pulse),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sosEmergency.withValues(
                                  alpha: (0.35 * (1.0 - pulse)).clamp(0.0, 1.0),
                                ),
                              ),
                            );
                          },
                        ),
                      Container(
                        width: isEmergency ? 36 : 34,
                        height: isEmergency ? 36 : 34,
                        decoration: BoxDecoration(
                          color: isEmergency
                              ? AppColors.sosEmergency
                              : (isDark
                                    ? AppColors.darkSurfaceContainer
                                    : AppColors.surfaceWhite),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isEmergency
                                ? Colors.white
                                : (isSelected
                                      ? (isDark
                                            ? AppColors.goldPrimary
                                            : AppColors.espressoDark)
                                      : markerColor),
                            width: isEmergency ? 2.5 : 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isEmergency
                                          ? AppColors.sosEmergency
                                          : Colors.black)
                                      .withValues(
                                        alpha: isEmergency ? 0.45 : 0.2,
                                      ),
                              blurRadius: isEmergency ? 8 : 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          isEmergency
                              ? Icons.sos_rounded
                              : (isPendamping
                                    ? Icons.shield_rounded
                                    : Icons.person_rounded),
                          color: isEmergency ? Colors.white : markerColor,
                          size: isEmergency ? 18 : 19,
                        ),
                      ),
                    ],
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
    MapController mapCtrl, {
    String? excludeUid,
  }) {
    if (mapCtrl.selectedFilter.value > 2) {
      return [];
    }

    final isDark = AppColors.isDark(context);
    final source = state.jamaahList.isNotEmpty
        ? List<JamaahData>.from(state.jamaahList)
        : [state.self];

    // Include any active SOS event not yet present in jamaahList
    for (final sos in state.activeSosEvents) {
      final sosId = sos['id']?.toString();
      final sosUid = sos['userId']?.toString() ?? sos['jamaahId']?.toString();
      final sosRawName = (sos['userName'] as String?)?.trim();
      final sosName = (sosRawName != null && sosRawName.isNotEmpty)
          ? sosRawName
          : 'Jamaah SOS';
      final normSosName = sosName.toLowerCase();

      if (state.isSosDismissed(sosId) ||
          (sosUid != null && state.isSosDismissed(sosUid))) {
        continue;
      }

      final isAlreadyPresent = source.any((j) {
        final jName = j.name.trim().toLowerCase();
        return (sosUid != null && j.id == sosUid) ||
            (normSosName != 'jamaah sos' &&
                (jName == normSosName ||
                    jName.contains(normSosName) ||
                    normSosName.contains(jName)));
      });

      if (!isAlreadyPresent) {
        double? lat;
        double? lng;
        final locField = sos['location'];
        if (locField is GeoPoint) {
          lat = locField.latitude;
          lng = locField.longitude;
        } else if (sos['latitude'] != null && sos['longitude'] != null) {
          lat = (sos['latitude'] as num).toDouble();
          lng = (sos['longitude'] as num).toDouble();
        }

        if (lat != null && lng != null) {
          source.add(
            JamaahData(
              id:
                  sosUid ??
                  'sos_${sosId ?? DateTime.now().millisecondsSinceEpoch}',
              name: sosName,
              shortLabel: sosName.split(' ').first,
              distance: 0,
              currentLocation: GeoPoint(lat, lng),
              locationUpdatedAt: DateTime.now(),
              sosActive: true,
            ),
          );
        }
      }
    }

    final seenUids = <String>{};
    final seenCoords = <LatLng>[];
    final markers = <fmap.Marker>[];
    final currentUid = mapCtrl.currentUserId ?? state.currentUid;
    final selfName = state.self.name.trim().toLowerCase();

    for (final jamaah in source) {
      // Skip current user (rendered as "Anda")
      if (currentUid != null && jamaah.id == currentUid) {
        continue;
      }
      if (jamaah.id == 'self') {
        continue;
      }
      if (currentUid != null &&
          jamaah.name.trim().toLowerCase() == selfName &&
          jamaah.id == state.self.id) {
        continue;
      }

      // Exclude assistance target to prevent duplicate marker
      if (excludeUid != null && jamaah.id == excludeUid) {
        continue;
      }

      // Deduplicate by ID
      if (seenUids.contains(jamaah.id)) {
        continue;
      }

      final matchingSos = state.activeSosEvents.firstWhereOrNull((e) {
        if (state.isSosDismissed(e['id']?.toString())) return false;
        final uid = e['userId']?.toString() ?? e['jamaahId']?.toString();
        final name = e['userName']?.toString().toLowerCase();
        final jName = jamaah.name.toLowerCase();
        return ((uid != null && uid == jamaah.id) ||
                (name != null &&
                    name.isNotEmpty &&
                    (name == jName ||
                        name.contains(jName) ||
                        jName.contains(name)))) &&
            !state.isSosDismissed(e['id']?.toString());
      });
      final isEmergency = jamaah.sosActive || matchingSos != null;

      double? lat = jamaah.currentLocation?.latitude;
      double? lng = jamaah.currentLocation?.longitude;
      if ((lat == null || lng == null) && matchingSos != null) {
        final locField = matchingSos['location'];
        if (locField is GeoPoint) {
          lat = locField.latitude;
          lng = locField.longitude;
        } else if (matchingSos['latitude'] != null &&
            matchingSos['longitude'] != null) {
          lat = (matchingSos['latitude'] as num).toDouble();
          lng = (matchingSos['longitude'] as num).toDouble();
        }
      }

      if (lat == null || lng == null) {
        continue;
      }

      final coord = LatLng(lat, lng);

      if (seenCoords.any(
        (c) =>
            (c.latitude - coord.latitude).abs() < 0.0001 &&
            (c.longitude - coord.longitude).abs() < 0.0001,
      )) {
        continue;
      }

      seenUids.add(jamaah.id);
      seenCoords.add(coord);

      final isSelected =
          mapCtrl.selectedJamaah.value?.id == jamaah.id ||
          mapCtrl.selectedMember.value?.uid == jamaah.id;
      final markerColor = isEmergency
          ? AppColors.sosEmergency
          : jamaah.tier.color;

      markers.add(
        fmap.Marker(
          point: coord,
          width: isEmergency ? 165 : 150,
          height: isEmergency ? 82 : 85,
          child: RepaintBoundary(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                mapCtrl.animatedMove(coord, 17.0);
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
                      color: isEmergency
                          ? AppColors.sosEmergency
                          : (isDark
                                ? AppColors.darkSurface
                                : AppColors.surfaceWhite),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isEmergency
                            ? Colors.white
                            : (isSelected
                                  ? (isDark
                                        ? AppColors.goldPrimary
                                        : AppColors.espressoDark)
                                  : markerColor),
                        width: isEmergency ? 2.0 : (isSelected ? 2.5 : 1.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isEmergency
                                      ? AppColors.sosEmergency
                                      : Colors.black)
                                  .withValues(alpha: isEmergency ? 0.5 : 0.18),
                          blurRadius: isEmergency ? 10 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEmergency
                              ? Icons.warning_amber_rounded
                              : Icons.elderly_rounded,
                          size: 13,
                          color: isEmergency ? Colors.white : markerColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isEmergency
                                ? 'SOS • ${jamaah.shortLabel}'
                                : jamaah.shortLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.captionSmall.copyWith(
                              color: isEmergency
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.darkTextHeading
                                        : AppColors.espressoDark),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          jamaah.formattedDistance,
                          style: AppTypography.captionSmall.copyWith(
                            color: isEmergency
                                ? Colors.white.withValues(alpha: 0.9)
                                : markerColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isEmergency)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final pulse = _pulseController.value;
                            return Container(
                              width: 36 + (12 * pulse),
                              height: 36 + (12 * pulse),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sosEmergency.withValues(
                                  alpha: (0.35 * (1.0 - pulse)).clamp(0.0, 1.0),
                                ),
                              ),
                            );
                          },
                        ),
                      Container(
                        width: isEmergency ? 38 : 36,
                        height: isEmergency ? 38 : 36,
                        decoration: BoxDecoration(
                          color: isEmergency
                              ? AppColors.sosEmergency
                              : (isDark
                                    ? AppColors.darkSurfaceContainer
                                    : AppColors.surfaceWhite),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isEmergency ? Colors.white : markerColor,
                            width: isEmergency ? 2.5 : 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isEmergency
                                          ? AppColors.sosEmergency
                                          : Colors.black)
                                      .withValues(
                                        alpha: isEmergency ? 0.45 : 0.25,
                                      ),
                              blurRadius: isEmergency ? 8 : 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          isEmergency
                              ? Icons.sos_rounded
                              : Icons.person_rounded,
                          color: isEmergency ? Colors.white : markerColor,
                          size: isEmergency ? 18 : 20,
                        ),
                      ),
                    ],
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
