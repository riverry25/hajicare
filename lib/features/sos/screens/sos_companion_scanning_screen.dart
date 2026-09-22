import '../../../core/locales/app_localizations.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

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

  // State Machine
  SosScanningState _currentState = SosScanningState.detectingGps;
  List<CandidateCompanion> _candidates = [];
  CandidateCompanion? _closestCompanion;
  String? _statusDetail;
  StreamSubscription? _gpsPositionSub;

  @override
  void initState() {
    super.initState();
    _state = Get.find<HajiCareController>();

    // 1. Continuous radar sweep line
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 2. Outward expanding ripple waves
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 3. Center SOS breathing pulse
    _centerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // 4. Lock-on focus animation when target companion is found
    _lockOnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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

  // ── REAL DATA DETECTION PIPELINE (NO FAKE TIMERS) ──────────────────────────

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
    _lockOnController.forward();

    // Smoothly slow down the radar sweep into a gentle glow
    _sweepController.animateTo(
      _sweepController.value + 0.5,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );

    if (!mounted) return;
    setState(() {
      _currentState = SosScanningState.companionFound;
      _closestCompanion = closest;
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

        // Add or enrich existing member with phone
        if (results.containsKey(uid)) {
          final existing = results[uid]!;
          results[uid] = existing.copyWith(
            phone: phone ?? existing.phone,
            location: existing.location ?? geoPoint,
            distanceMeters: existing.distanceMeters ?? distance,
            bearingDegrees: existing.bearingDegrees ?? bearing,
          );
        } else {
          results[uid] = CandidateCompanion(
            uid: uid,
            name: name,
            phone: phone,
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
    final comp = _closestCompanion;
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

  // ── STATUS TEXT HELPER ─────────────────────────────────────────────────────

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
        return AppColors.accentGoldStar;
      case SosScanningState.searchingClosest:
        return const Color(0xFF29B6F6); // Light blue pulse
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
    final scaffoldBg = isDark
        ? const Color(0xFF0F141C)
        : const Color(0xFF131B26);
    const textColor = Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Radar Deteksi Pendamping',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sosEmergency.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.sosEmergency.withValues(alpha: 0.6),
              ),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Status Banner Top ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Column(
                  key: ValueKey(_statusTitle),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_statusIcon, color: _statusColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _statusTitle,
                          style: AppTypography.titleMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_statusDetail != null)
                      Text(
                        _statusDetail!,
                        style: AppTypography.captionSmall.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Radar Canvas Visualization ─────────────────────────────────
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _sweepController,
                    _pulseController,
                    _centerPulseController,
                    _lockOnController,
                  ]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RadarPainter(
                        sweepProgress: _sweepController.value,
                        pulseProgress: _pulseController.value,
                        centerPulse: _centerPulseController.value,
                        lockOnProgress: _lockOnController.value,
                        state: _currentState,
                        candidates: _candidates,
                        closestCandidate: _closestCompanion,
                      ),
                    );
                  },
                ),
              ),
            ),

            const Spacer(),

            // ── Bottom Section: Found Candidate Card or Fallback ───────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdgeGutter,
                vertical: AppSpacing.md,
              ),
              child: _buildBottomPanel(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(bool isDark) {
    if (_currentState == SosScanningState.companionFound &&
        _closestCompanion != null) {
      final comp = _closestCompanion!;
      return AppCard(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        borderColor: AppColors.statusSafe.withValues(alpha: 0.6),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.statusSafe.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.statusSafe.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_pin_circle_rounded,
                    color: AppColors.statusSafe,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
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
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                      const SizedBox(height: 2),
                      Text(
                        comp.formattedDistance,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.statusSafe,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (comp.phone != null && comp.phone!.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.goldPrimary,
                        side: const BorderSide(color: AppColors.goldPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                      label: const Text(
                        'Hubungi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                      backgroundColor: const Color(0xFF1E60CC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 16),
                    label: const Text(
                      'Lihat di Peta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Belum Ada Pendamping di Sekitar',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.sosEmergency,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Sinyal SOS Anda tetap tersimpan di sistem darurat pusat. Dekatkan ponsel Anda dan tunggu petugas merespons.',
              style: AppTypography.captionSmall.copyWith(
                color: isDark ? AppColors.darkTextBody : AppColors.textBody,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? Colors.white
                      : AppColors.espressoDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Pindai Ulang'),
                onPressed: _startDetectionPipeline,
              ),
            ),
          ],
        ),
      );
    }

    // Still scanning / detecting
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Memindai sinyal radio & GPS...',
            style: AppTypography.captionSmall.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM RADAR PAINTER ─────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final double sweepProgress;
  final double pulseProgress;
  final double centerPulse;
  final double lockOnProgress;
  final SosScanningState state;
  final List<CandidateCompanion> candidates;
  final CandidateCompanion? closestCandidate;

  _RadarPainter({
    required this.sweepProgress,
    required this.pulseProgress,
    required this.centerPulse,
    required this.lockOnProgress,
    required this.state,
    required this.candidates,
    required this.closestCandidate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 1. Radar Circular Range Grids
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF204060).withValues(alpha: 0.4);

    final rangeRatios = [0.25, 0.5, 0.75, 1.0];
    for (final ratio in rangeRatios) {
      canvas.drawCircle(center, maxRadius * ratio, gridPaint);
    }

    // 2. Crosshair Axes
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF204060).withValues(alpha: 0.3);

    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      axisPaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      axisPaint,
    );

    // 3. Expanding Ripple Waves (Pulse)
    if (state != SosScanningState.companionFound &&
        state != SosScanningState.noCompanionAvailable) {
      for (int i = 0; i < 2; i++) {
        final rippleOffset = (pulseProgress + (i * 0.5)) % 1.0;
        final rippleRadius = maxRadius * rippleOffset;
        final rippleAlpha = (1.0 - rippleOffset).clamp(0.0, 0.4);

        final ripplePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = AppColors.sosEmergency.withValues(alpha: rippleAlpha);

        canvas.drawCircle(center, rippleRadius, ripplePaint);
      }
    }

    // 4. Rotating Sweep Gradient Arc
    if (state != SosScanningState.noCompanionAvailable) {
      final sweepAngle = sweepProgress * 2 * math.pi;

      final sweepPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: math.pi / 2,
          colors: [
            Colors.transparent,
            AppColors.sosEmergency.withValues(alpha: 0.22),
          ],
          transform: GradientRotation(sweepAngle - (math.pi / 2)),
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

      canvas.drawCircle(center, maxRadius, sweepPaint);

      // Leading sweep line
      final lineEnd = Offset(
        center.dx + maxRadius * math.cos(sweepAngle),
        center.dy + maxRadius * math.sin(sweepAngle),
      );
      final sweepLinePaint = Paint()
        ..color = AppColors.sosEmergency.withValues(alpha: 0.7)
        ..strokeWidth = 1.5;
      canvas.drawLine(center, lineEnd, sweepLinePaint);
    }

    // 5. Candidate Blips on the Radar
    for (final cand in candidates) {
      final isClosest = closestCandidate?.uid == cand.uid;
      final radiusRatio = cand.getRadarRadiusRatio();
      final angle = cand.getRadarAngleRadians();

      final blipDist = maxRadius * radiusRatio;
      // 0 rad is North (-Y axis)
      final blipPos = Offset(
        center.dx + blipDist * math.sin(angle),
        center.dy - blipDist * math.cos(angle),
      );

      // Draw blip dot
      final blipColor = isClosest
          ? AppColors.statusSafe
          : AppColors.accentGoldStar;

      final dotPaint = Paint()
        ..color = blipColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(blipPos, 4.0, dotPaint);

      // Blip outer glow
      final glowPaint = Paint()
        ..color = blipColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(blipPos, 8.0, glowPaint);

      // 6. Closest Candidate Lock-on Reticle
      if (isClosest && state == SosScanningState.companionFound) {
        final lockScale = 1.0 + (0.35 * (1.0 - lockOnProgress));
        final ringRadius = 14.0 * lockScale;

        final lockPaint = Paint()
          ..color = AppColors.statusSafe
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(blipPos, ringRadius, lockPaint);

        // Connector line from center to candidate
        final connectorPaint = Paint()
          ..color = AppColors.statusSafe.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawLine(center, blipPos, connectorPaint);
      }
    }

    // 7. Center SOS Hub
    final centerRadius = 24.0 + (2.5 * centerPulse);

    // Glowing outer ring of hub
    final hubGlow = Paint()
      ..color = AppColors.sosEmergency.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerRadius + 6, hubGlow);

    // Solid core of hub
    final hubCore = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
      ).createShader(Rect.fromCircle(center: center, radius: centerRadius));
    canvas.drawCircle(center, centerRadius, hubCore);

    // White text "SOS" inside center core
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'SOS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
