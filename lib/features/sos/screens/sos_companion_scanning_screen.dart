import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../map/controllers/map_controller.dart';
import '../../map/models/map_poi.dart';
import '../models/candidate_companion.dart';

/// Scanning lifecycle states driven by real GPS and Firestore data.
enum SosScanningState {
  detectingGps,
  scanningCompanions,
  searchingClosest,
  companionFound,
  noCompanionAvailable,
}

/// Distance range filters inspired by modern radar UX (Image 2).
enum RadarDistanceFilter { closest, near50m, near200m, all }

class SosCompanionScanningScreen extends StatefulWidget {
  const SosCompanionScanningScreen({super.key});

  @override
  State<SosCompanionScanningScreen> createState() =>
      _SosCompanionScanningScreenState();
}

class _SosCompanionScanningScreenState extends State<SosCompanionScanningScreen>
    with TickerProviderStateMixin {
  late final HajiCareController _state;

  // Animation Controllers
  late final AnimationController _sweepController;
  late final AnimationController _pulseController;
  late final AnimationController _centerPulseController;
  late final AnimationController _lockOnController;

  // State Machine & Data
  SosScanningState _currentState = SosScanningState.detectingGps;
  List<CandidateCompanion> _candidates = [];
  CandidateCompanion? _closestCompanion;
  CandidateCompanion? _selectedCompanion;
  RadarDistanceFilter _selectedFilter = RadarDistanceFilter.closest;
  String? _statusDetail;
  StreamSubscription? _gpsPositionSub;

  @override
  void initState() {
    super.initState();
    _state = Get.find<HajiCareController>();

    // 1. Continuous radar sweep line & glowing aura
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    // 2. Outward expanding ripple waves
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // 3. Center beacon breathing pulse
    _centerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // 4. Lock-on focus animation when target companion is selected/found
    _lockOnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Kick off real data detection pipeline
    _startDetectionPipeline();
  }

  @override
  void dispose() {
    _gpsPositionSub?.cancel();
    _sweepController.dispose();
    _pulseController.dispose();
    _centerPulseController.dispose();
    _lockOnController.dispose();
    super.dispose();
  }

  // ── REAL DATA DETECTION PIPELINE ───────────────────────────────────────────

  Future<void> _startDetectionPipeline() async {
    // ── STEP 1: "Mendeteksi lokasi Anda..." ──────────────────────────────────
    if (!mounted) return;
    setState(() {
      _currentState = SosScanningState.detectingGps;
      _statusDetail = 'Mengakses sensor GPS perangkat...';
    });

    Position? myPos = _state.myCurrentPosition.value;
    if (myPos == null) {
      await _state.refreshLocation();
      myPos = _state.myCurrentPosition.value;
    }

    // ── STEP 2: "Memindai pendamping di sekitar..." ─────────────────────────
    if (!mounted) return;
    setState(() {
      _currentState = SosScanningState.scanningCompanions;
      _statusDetail = 'Menghubungi jaringan rombongan & petugas...';
    });

    final foundCandidates = await _fetchRealCompanions(myPos);

    if (!mounted) return;

    if (foundCandidates.isEmpty) {
      // ── STATE FALLBACK: "Pendamping tidak tersedia" ────────────────────────
      _sweepController.stop();
      setState(() {
        _currentState = SosScanningState.noCompanionAvailable;
        _statusDetail = 'Tidak ada pendamping aktif terdeteksi.';
      });
      return;
    }

    // ── STEP 3: "Mencari pendamping terdekat..." ────────────────────────────
    setState(() {
      _currentState = SosScanningState.searchingClosest;
      _candidates = foundCandidates;
      _statusDetail =
          'Menghitung jarak ${foundCandidates.length} pendamping...';
    });

    // Pick the closest companion with valid distance
    CandidateCompanion? closest;
    for (final cand in foundCandidates) {
      if (cand.distanceMeters != null) {
        if (closest == null ||
            cand.distanceMeters! <
                (closest.distanceMeters ?? double.infinity)) {
          closest = cand;
        }
      }
    }
    // Fallback to first companion (e.g. room leader) if no GPS coordinates
    closest ??= foundCandidates.first;

    // ── STEP 4: "Pendamping ditemukan" ──────────────────────────────────────
    HapticFeedback.mediumImpact();
    _lockOnController.forward(from: 0.0);

    if (!mounted) return;
    setState(() {
      _currentState = SosScanningState.companionFound;
      _closestCompanion = closest;
      _selectedCompanion = closest;
      _statusDetail = closest?.formattedDistance ?? 'Terhubung';
    });
  }

  /// Fetches real companions from activeRoomMembers and Firestore users collection.
  Future<List<CandidateCompanion>> _fetchRealCompanions(Position? myPos) async {
    final results = <String, CandidateCompanion>{};

    // 1. From Active Room Members
    for (final member in _state.activeRoomMembers) {
      if (member.isPendamping) {
        double? distance;
        double? bearing;
        if (myPos != null && member.currentLocation != null) {
          distance = Geolocator.distanceBetween(
            myPos.latitude,
            myPos.longitude,
            member.currentLocation!.latitude,
            member.currentLocation!.longitude,
          );
          bearing = Geolocator.bearingBetween(
            myPos.latitude,
            myPos.longitude,
            member.currentLocation!.latitude,
            member.currentLocation!.longitude,
          );
        }
        results[member.uid] = CandidateCompanion(
          uid: member.uid,
          name: member.name,
          location: member.currentLocation,
          distanceMeters: distance,
          bearingDegrees: bearing,
          locationUpdatedAt: member.locationUpdatedAt,
          isFromRoom: true,
        );
      }
    }

    // 2. From Firestore Users Collection (role in ['pendamping', 'petugas'])
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['pendamping', 'petugas'])
          .limit(15)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = doc.id;
        final name =
            (data['name'] as String?)?.trim() ??
            (data['displayName'] as String?)?.trim() ??
            'Pendamping';
        final phone =
            (data['phone'] as String?)?.trim() ??
            (data['phoneNumber'] as String?)?.trim();
        final photoUrl =
            (data['photoUrl'] as String?) ??
            (data['avatarUrl'] as String?) ??
            (data['profileImageUrl'] as String?);
        final loc = data['currentLocation'];
        GeoPoint? geoPoint;
        if (loc is GeoPoint) {
          geoPoint = loc;
        }

        double? distance;
        double? bearing;
        if (myPos != null && geoPoint != null) {
          distance = Geolocator.distanceBetween(
            myPos.latitude,
            myPos.longitude,
            geoPoint.latitude,
            geoPoint.longitude,
          );
          bearing = Geolocator.bearingBetween(
            myPos.latitude,
            myPos.longitude,
            geoPoint.latitude,
            geoPoint.longitude,
          );
        }

        DateTime? updatedAt;
        final rawUpdated = data['locationUpdatedAt'];
        if (rawUpdated is Timestamp) {
          updatedAt = rawUpdated.toDate();
        }

        // Add or enrich existing member with phone and photo
        if (results.containsKey(uid)) {
          final existing = results[uid]!;
          results[uid] = existing.copyWith(
            phone: phone ?? existing.phone,
            photoUrl: photoUrl ?? existing.photoUrl,
            location: existing.location ?? geoPoint,
            distanceMeters: existing.distanceMeters ?? distance,
            bearingDegrees: existing.bearingDegrees ?? bearing,
          );
        } else {
          results[uid] = CandidateCompanion(
            uid: uid,
            name: name,
            phone: phone,
            photoUrl: photoUrl,
            location: geoPoint,
            distanceMeters: distance,
            bearingDegrees: bearing,
            locationUpdatedAt: updatedAt,
            isFromRoom: false,
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[SosCompanionScanningScreen] Error querying Firestore pendamping: $e',
      );
    }

    final list = results.values.toList();
    // Sort closest first (candidates with distances first, then null distances)
    list.sort((a, b) {
      if (a.distanceMeters == null && b.distanceMeters == null) return 0;
      if (a.distanceMeters == null) return 1;
      if (b.distanceMeters == null) return -1;
      return a.distanceMeters!.compareTo(b.distanceMeters!);
    });

    return list;
  }

  // ── ACTIONS ────────────────────────────────────────────────────────────────

  Future<void> _callCompanion(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      AppAlert.warning(
        context,
        title: context.tr('sos.contactUnavailable'),
        message: 'Nomor telepon pendamping belum terdaftar di sistem.',
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      AppAlert.error(
        context,
        title: context.tr('sos.callFailed'),
        message: 'Tidak dapat membuka aplikasi telepon untuk nomor $phone.',
      );
    }
  }

  Future<void> _openMapRouteToCompanion() async {
    final comp = _selectedCompanion ?? _closestCompanion;
    final loc = comp?.location;
    if (loc == null) {
      Get.toNamed(AppRoutes.map);
      return;
    }

    final target = ll.LatLng(loc.latitude, loc.longitude);
    final poi = MapPoi(
      id: 'companion_${comp!.uid}',
      name: comp.name,
      category: PoiCategory.place,
      coordinate: target,
      statusLabel: 'Pendamping Terdekat',
    );

    if (Get.isRegistered<MapController>()) {
      Get.until(
        (route) =>
            route.settings.name == AppRoutes.map ||
            route.settings.name == AppRoutes.interactiveMap ||
            route.isFirst,
      );
      if (Get.currentRoute != AppRoutes.map &&
          Get.currentRoute != AppRoutes.interactiveMap) {
        await Get.toNamed(AppRoutes.map);
      }
      final mapCtrl = Get.find<MapController>();
      mapCtrl.animatedMove(target, 17.0);
      await mapCtrl.requestRouteToPoi(poi);
    } else {
      Get.until((route) => route.isFirst);
      await Get.toNamed(AppRoutes.map);
      if (Get.isRegistered<MapController>()) {
        final mapCtrl = Get.find<MapController>();
        mapCtrl.animatedMove(target, 17.0);
        await mapCtrl.requestRouteToPoi(poi);
      }
    }
  }

  void _selectCompanion(CandidateCompanion candidate) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCompanion = candidate;
    });
    _lockOnController.forward(from: 0.0);
  }

  // ── FILTER & RADAR SCALE COMPUTATION ───────────────────────────────────────

  double get _effectiveMaxRange {
    switch (_selectedFilter) {
      case RadarDistanceFilter.closest:
        final dist = _closestCompanion?.distanceMeters;
        if (dist != null && dist > 0) {
          return math.max(40.0, dist * 1.5);
        }
        return 60.0;
      case RadarDistanceFilter.near50m:
        return 50.0;
      case RadarDistanceFilter.near200m:
        return 200.0;
      case RadarDistanceFilter.all:
        return 2000.0;
    }
  }

  List<CandidateCompanion> get _visibleCandidates {
    if (_candidates.isEmpty) return [];
    switch (_selectedFilter) {
      case RadarDistanceFilter.closest:
        if (_closestCompanion != null) {
          return [_closestCompanion!];
        }
        return _candidates.take(1).toList();
      case RadarDistanceFilter.near50m:
        final in50 = _candidates
            .where((c) => (c.distanceMeters ?? double.infinity) <= 50.0)
            .toList();
        return in50.isNotEmpty ? in50 : _candidates.take(1).toList();
      case RadarDistanceFilter.near200m:
        final in200 = _candidates
            .where((c) => (c.distanceMeters ?? double.infinity) <= 200.0)
            .toList();
        return in200.isNotEmpty ? in200 : _candidates.take(2).toList();
      case RadarDistanceFilter.all:
        return _candidates;
    }
  }

  String get _statusTitle {
    switch (_currentState) {
      case SosScanningState.detectingGps:
        return 'Mendeteksi lokasi Anda...';
      case SosScanningState.scanningCompanions:
        return 'Memindai pendamping di sekitar...';
      case SosScanningState.searchingClosest:
        return 'Mencari pendamping terdekat...';
      case SosScanningState.companionFound:
        return 'Pendamping ditemukan';
      case SosScanningState.noCompanionAvailable:
        return 'Pendamping tidak tersedia';
    }
  }

  Color get _statusColor {
    switch (_currentState) {
      case SosScanningState.detectingGps:
      case SosScanningState.scanningCompanions:
        return AppColors.goldPrimary;
      case SosScanningState.searchingClosest:
        return const Color(0xFF29B6F6);
      case SosScanningState.companionFound:
        return AppColors.statusSafe;
      case SosScanningState.noCompanionAvailable:
        return AppColors.sosEmergency;
    }
  }

  IconData get _statusIcon {
    switch (_currentState) {
      case SosScanningState.detectingGps:
        return Icons.my_location_rounded;
      case SosScanningState.scanningCompanions:
        return Icons.radar_rounded;
      case SosScanningState.searchingClosest:
        return Icons.person_search_rounded;
      case SosScanningState.companionFound:
        return Icons.check_circle_rounded;
      case SosScanningState.noCompanionAvailable:
        return Icons.person_off_rounded;
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg = AppColors.scaffoldColor(context);
    final textHeading = AppColors.textHeadingColor(context);
    final textBody = AppColors.textBodyColor(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // 1. Subtle decorative background illumination
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.1),
                    radius: 0.9,
                    colors: isDark
                        ? [
                            AppColors.goldPrimary.withValues(alpha: 0.12),
                            const Color(0xFF261912).withValues(alpha: 0.35),
                            Colors.transparent,
                          ]
                        : [
                            AppColors.goldLight.withValues(alpha: 0.28),
                            AppColors.canvasCreamSubtle.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main content with scrollable protection against text scaling overflows
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double radarBoxSize = math.min(
                  constraints.maxWidth - 48,
                  310.0,
                );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdgeGutter,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Section: App Bar + Status Pill
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            _buildTopBar(isDark),
                            const SizedBox(height: 12),
                            _buildStatusPill(isDark, textHeading, textBody),
                          ],
                        ),

                        // Center Section: Layered Organic Radar with Center Beacon & Avatars
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: radarBoxSize,
                              height: radarBoxSize,
                              child: _buildRadarStack(radarBoxSize, isDark),
                            ),
                          ),
                        ),

                        // Bottom Section: Distance Filters & Companion Action Card
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDistanceFilterRow(isDark),
                            const SizedBox(height: 14),
                            _buildBottomPanel(isDark),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP BAR & STATUS PILL (Inspired by Image 2 Header) ─────────────────────

  Widget _buildTopBar(bool isDark) {
    return Row(
      children: [
        // Rounded Close Button
        Semantics(
          button: true,
          label: 'Tutup radar',
          child: Material(
            color: isDark
                ? AppColors.darkSurfaceContainer
                : Colors.white.withValues(alpha: 0.8),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: isDark ? 0 : 2,
            shadowColor: Colors.black12,
            child: InkWell(
              onTap: () => Get.back(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : AppColors.textHeading,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Title and localized status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Radar Deteksi',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textHeadingColor(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Pantau Pendamping Terdekat',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Emergency SOS Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.sosEmergency.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.sosEmergency.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sosEmergency.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emergency_rounded,
                color: AppColors.sosEmergency,
                size: 14,
              ),
              SizedBox(width: 4),
              Text(
                'SOS AKTIF',
                style: TextStyle(
                  color: AppColors.sosEmergency,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(bool isDark, Color headingColor, Color bodyColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Icon with color
          Icon(_statusIcon, size: 16, color: _statusColor),
          const SizedBox(width: 8),

          // Status readout text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentState == SosScanningState.companionFound
                      ? '${_candidates.length} Pendamping terdeteksi • ${_selectedCompanion?.name ?? "Terdekat"}'
                      : _statusTitle,
                  style: AppTypography.captionSmall.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_statusDetail != null)
                  Text(
                    _statusDetail!,
                    style: AppTypography.captionSmall.copyWith(
                      color: bodyColor.withValues(alpha: 0.8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Quick re-scan trigger
          GestureDetector(
            onTap: _startDetectionPipeline,
            child: const Icon(
              Icons.sync_rounded,
              size: 16,
              color: AppColors.goldPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── RADAR STACK (Organic Layered Disks + Center Beacon + Floating Avatars) ──

  Widget _buildRadarStack(double size, bool isDark) {
    final center = Offset(size / 2, size / 2);
    final maxRadius = size / 2;
    final activeCompanion = _selectedCompanion ?? _closestCompanion;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _sweepController,
        _pulseController,
        _centerPulseController,
        _lockOnController,
      ]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Layered Organic Concentric Radar Disks (Image 2 style)
            CustomPaint(
              size: Size(size, size),
              painter: _WinkyOrganicRadarPainter(
                sweepProgress: _sweepController.value,
                pulseProgress: _pulseController.value,
                centerPulse: _centerPulseController.value,
                lockOnProgress: _lockOnController.value,
                state: _currentState,
                isDark: isDark,
                selectedCompanion: activeCompanion,
                maxRangeMeters: _effectiveMaxRange,
              ),
            ),

            // 2. Central Glowing Beacon (Rounded Triangle / Diamond from Image 2)
            _buildCenterBeacon(isDark),

            // 3. Floating Interactive Candidate Avatars
            ..._visibleCandidates.map((cand) {
              final isSelected = activeCompanion?.uid == cand.uid;
              final isClosest = _closestCompanion?.uid == cand.uid;
              final radiusRatio = cand.getRadarRadiusRatio(_effectiveMaxRange);
              final angle = cand.getRadarAngleRadians();

              final blipDist = maxRadius * radiusRatio;
              // 0 rad is North (-Y axis)
              final dx = center.dx + blipDist * math.sin(angle);
              final dy = center.dy - blipDist * math.cos(angle);

              return Positioned(
                left: dx - 24,
                top: dy - 24,
                child: _RadarCompanionAvatar(
                  candidate: cand,
                  isSelected: isSelected,
                  isClosest: isClosest,
                  isDark: isDark,
                  onTap: () => _selectCompanion(cand),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// Center glowing diamond/rounded triangle beacon matching Image 2
  Widget _buildCenterBeacon(bool isDark) {
    final double pulseScale = 1.0 + (0.12 * _centerPulseController.value);

    return Transform.scale(
      scale: pulseScale,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isDark
                ? [Colors.white, AppColors.goldPrimary, AppColors.espressoDark]
                : [
                    AppColors.primary,
                    AppColors.espressoDark,
                    AppColors.primaryContainer,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.goldPrimary : AppColors.primary)
                  .withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white : AppColors.espressoDark,
            ),
            child: Icon(
              Icons.my_location_rounded,
              size: 18,
              color: isDark ? AppColors.espressoDark : AppColors.goldLight,
            ),
          ),
        ),
      ),
    );
  }

  // ── DISTANCE FILTER ROW (Direct from Image 2) ──────────────────────────────

  Widget _buildDistanceFilterRow(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'JARAK JANGKAUAN',
              style: AppTypography.captionSmall.copyWith(
                color: isDark
                    ? AppColors.goldLight
                    : AppColors.textHeadingColor(context),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 11,
              ),
            ),
            Text(
              'Skala: ${_effectiveMaxRange < 1000 ? "${_effectiveMaxRange.toInt()}m" : "${(_effectiveMaxRange / 1000).toStringAsFixed(1)}km"}',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildFilterPill(
              filter: RadarDistanceFilter.closest,
              label: 'Terdekat',
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              filter: RadarDistanceFilter.near50m,
              label: '< 50m',
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              filter: RadarDistanceFilter.near200m,
              label: '< 200m',
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              filter: RadarDistanceFilter.all,
              label: 'Semua',
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterPill({
    required RadarDistanceFilter filter,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Filter jarak $label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedFilter = filter;
              });
            },
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.goldPrimary : AppColors.primary)
                    : (isDark ? AppColors.darkSurfaceContainer : Colors.white),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppColors.goldPrimary : AppColors.primary)
                      : (isDark
                            ? AppColors.darkOutline.withValues(alpha: 0.4)
                            : AppColors.lightCardBorder),
                  width: 1.2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color:
                          (isDark ? AppColors.goldPrimary : AppColors.primary)
                              .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.headingFontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (isDark ? AppColors.espressoDark : Colors.white)
                        : (isDark ? Colors.white70 : AppColors.textBody),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── BOTTOM PANEL (Companion Card or Scanning State) ────────────────────────

  Widget _buildBottomPanel(bool isDark) {
    if (_currentState == SosScanningState.companionFound &&
        (_selectedCompanion != null || _closestCompanion != null)) {
      final comp = _selectedCompanion ?? _closestCompanion!;
      final isClosest = comp.uid == _closestCompanion?.uid;

      return AppCard(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        borderColor: isClosest
            ? AppColors.statusSafe.withValues(alpha: 0.6)
            : AppColors.goldPrimary.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Avatar with presence badge
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.espressoDark,
                            AppColors.primaryContainer,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: isClosest
                              ? AppColors.statusSafe
                              : AppColors.goldPrimary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          comp.name.isNotEmpty
                              ? comp.name.substring(0, 1).toUpperCase()
                              : 'P',
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.statusSafe,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name & Distance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comp.name,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textHeadingColor(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isClosest)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusSafe.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: const Text(
                                'TERDEKAT',
                                style: TextStyle(
                                  color: AppColors.statusSafe,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: isClosest
                                ? AppColors.statusSafe
                                : AppColors.goldPrimary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            comp.formattedDistance,
                            style: AppTypography.captionSmall.copyWith(
                              color: isClosest
                                  ? AppColors.statusSafe
                                  : AppColors.goldPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${comp.isFromRoom ? "Rombongan" : "Petugas"}',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Action Buttons
            Row(
              children: [
                if (comp.phone != null && comp.phone!.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.goldLight
                            : AppColors.primary,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.primary,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                      label: const Text(
                        'Hubungi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      onPressed: () => _callCompanion(comp.phone),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.goldPrimary
                          : AppColors.primary,
                      foregroundColor: isDark
                          ? AppColors.espressoDark
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 16),
                    label: const Text(
                      'Lihat di Peta',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    onPressed: _openMapRouteToCompanion,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_currentState == SosScanningState.noCompanionAvailable) {
      return AppCard(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        borderColor: AppColors.sosEmergency.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.sosEmergency,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pendamping Belum Terdeteksi',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.sosEmergency,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tetap tenang dan jangan berpindah tempat. Sinyal SOS Anda tetap disiarkan ke posko terdekat.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textBody,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: AppColors.espressoDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: _startDetectionPipeline,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Pindai Ulang Radar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Scanning progress card
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer.withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _statusTitle,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textHeadingColor(context),
                  ),
                ),
                Text(
                  'Tetap tenang & jangan berpindah tempat',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FLOATING COMPANION AVATAR WIDGET (Image 2 style) ─────────────────────────

class _RadarCompanionAvatar extends StatelessWidget {
  final CandidateCompanion candidate;
  final bool isSelected;
  final bool isClosest;
  final bool isDark;
  final VoidCallback onTap;

  const _RadarCompanionAvatar({
    required this.candidate,
    required this.isSelected,
    required this.isClosest,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = isSelected
        ? (isDark ? AppColors.goldPrimary : AppColors.primary)
        : (isClosest ? AppColors.statusSafe : Colors.white);

    return Semantics(
      button: true,
      label:
          'Pendamping ${candidate.name}, jarak ${candidate.formattedDistance}',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Avatar Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.espressoDark, AppColors.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: ringColor,
                  width: isSelected || isClosest ? 2.5 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected || isClosest)
                        ? ringColor.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: isSelected ? 10 : 6,
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: candidate.photoUrl != null
                    ? Image.network(
                        candidate.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildFallbackInitial(),
                      )
                    : _buildFallbackInitial(),
              ),
            ),
            const SizedBox(height: 3),

            // Mini Distance Capsule Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.goldPrimary : AppColors.primary)
                    : (isDark ? Colors.black87 : Colors.white),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected ? Colors.transparent : ringColor,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                candidate.distanceMeters != null
                    ? (candidate.distanceMeters! < 1000
                          ? '±${candidate.distanceMeters!.round()}m'
                          : '±${(candidate.distanceMeters! / 1000).toStringAsFixed(1)}k')
                    : 'Aktif',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? (isDark ? AppColors.espressoDark : Colors.white)
                      : (isDark ? Colors.white : AppColors.espressoDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackInitial() {
    return Center(
      child: Text(
        candidate.name.isNotEmpty
            ? candidate.name.substring(0, 1).toUpperCase()
            : 'P',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ── ORGANIC LAYERED RADAR PAINTER (Image 2 Concentric Ripple Disks) ──────────

class _WinkyOrganicRadarPainter extends CustomPainter {
  final double sweepProgress;
  final double pulseProgress;
  final double centerPulse;
  final double lockOnProgress;
  final SosScanningState state;
  final bool isDark;
  final CandidateCompanion? selectedCompanion;
  final double maxRangeMeters;

  _WinkyOrganicRadarPainter({
    required this.sweepProgress,
    required this.pulseProgress,
    required this.centerPulse,
    required this.lockOnProgress,
    required this.state,
    required this.isDark,
    required this.selectedCompanion,
    required this.maxRangeMeters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 1. Layered Organic Concentric Disks (Image 2 style)
    // 4 Distinct smooth translucent discs layered from outermost to innermost
    final diskLayers = [
      _RadarDisk(radiusFactor: 1.00, rotationOffset: 0.00),
      _RadarDisk(radiusFactor: 0.76, rotationOffset: 0.08),
      _RadarDisk(radiusFactor: 0.54, rotationOffset: -0.05),
      _RadarDisk(radiusFactor: 0.34, rotationOffset: 0.04),
    ];

    for (int i = 0; i < diskLayers.length; i++) {
      final disk = diskLayers[i];
      final r = maxRadius * disk.radiusFactor;

      // Fill Paint (smooth gradients calibrated for Light and Dark modes)
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: isDark
              ? [
                  AppColors.goldPrimary.withValues(alpha: 0.08 + (i * 0.04)),
                  const Color(0xFF2E1C12).withValues(alpha: 0.25 + (i * 0.08)),
                ]
              : [
                  AppColors.goldLight.withValues(alpha: 0.30 + (i * 0.07)),
                  AppColors.canvasCreamSubtle.withValues(
                    alpha: 0.40 + (i * 0.09),
                  ),
                ],
        ).createShader(Rect.fromCircle(center: center, radius: r));

      canvas.drawCircle(center, r, fillPaint);

      // Delicate outer edge stroke
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isDark ? 1.0 : 1.2
        ..color = isDark
            ? AppColors.goldPrimary.withValues(alpha: 0.18 + (i * 0.08))
            : Colors.white.withValues(alpha: 0.75 + (i * 0.08));

      canvas.drawCircle(center, r, strokePaint);
    }

    // 2. Expanding Pulse Ripple Waves
    if (state != SosScanningState.noCompanionAvailable) {
      for (int i = 0; i < 2; i++) {
        final rippleOffset = (pulseProgress + (i * 0.5)) % 1.0;
        final rippleRadius = maxRadius * rippleOffset;
        final rippleAlpha = (1.0 - rippleOffset).clamp(0.0, 0.35);

        final ripplePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = (isDark ? AppColors.goldPrimary : AppColors.primary)
              .withValues(alpha: rippleAlpha);

        canvas.drawCircle(center, rippleRadius, ripplePaint);
      }
    }

    // 3. Rotating Radar Sweep Beam & Glowing Arc
    if (state != SosScanningState.noCompanionAvailable) {
      final sweepAngle = sweepProgress * 2 * math.pi;

      // Soft gradient aura arc
      final sweepPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: math.pi / 2.5,
          colors: [
            Colors.transparent,
            (isDark ? AppColors.goldPrimary : AppColors.primary).withValues(
              alpha: isDark ? 0.22 : 0.15,
            ),
          ],
          transform: GradientRotation(sweepAngle - (math.pi / 2.5)),
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

      canvas.drawCircle(center, maxRadius, sweepPaint);

      // Leading beam line
      final lineEnd = Offset(
        center.dx + maxRadius * math.cos(sweepAngle),
        center.dy + maxRadius * math.sin(sweepAngle),
      );
      final sweepLinePaint = Paint()
        ..color = (isDark ? AppColors.goldLight : AppColors.primary).withValues(
          alpha: 0.6,
        )
        ..strokeWidth = 1.4;
      canvas.drawLine(center, lineEnd, sweepLinePaint);
    }

    // 4. Connector Guide Line to Selected Companion
    if (selectedCompanion != null && state == SosScanningState.companionFound) {
      final radiusRatio = selectedCompanion!.getRadarRadiusRatio(
        maxRangeMeters,
      );
      final angle = selectedCompanion!.getRadarAngleRadians();
      final blipDist = maxRadius * radiusRatio;
      final targetPos = Offset(
        center.dx + blipDist * math.sin(angle),
        center.dy - blipDist * math.cos(angle),
      );

      final connectorPaint = Paint()
        ..color = (isDark ? AppColors.goldPrimary : AppColors.primary)
            .withValues(alpha: 0.35)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(center, targetPos, connectorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WinkyOrganicRadarPainter oldDelegate) {
    return oldDelegate.sweepProgress != sweepProgress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.centerPulse != centerPulse ||
        oldDelegate.lockOnProgress != lockOnProgress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.selectedCompanion != selectedCompanion ||
        oldDelegate.maxRangeMeters != maxRangeMeters;
  }
}

class _RadarDisk {
  final double radiusFactor;
  final double rotationOffset;

  const _RadarDisk({required this.radiusFactor, required this.rotationOffset});
}
