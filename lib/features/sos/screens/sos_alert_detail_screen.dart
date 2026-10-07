import '../../../core/locales/app_localizations.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../notification/controllers/notification_controller.dart';

/// Full SOS Alert Detail screen for pendamping / admin.
///
/// Receives a [sosData] map (from Firestore sos_events) and, if [sosEventId]
/// is provided, subscribes to live Firestore updates so the mini-map marker
/// moves in real time as the jamaah's location is updated.
class SosAlertDetailScreen extends StatefulWidget {
  const SosAlertDetailScreen({super.key});

  @override
  State<SosAlertDetailScreen> createState() => _SosAlertDetailScreenState();
}

class _SosAlertDetailScreenState extends State<SosAlertDetailScreen> {
  late HajiCareController _state;
  late fmap.MapController _miniMapCtrl;

  Map<String, dynamic> _sosData = {};
  String? _eventId;
  StreamSubscription<Map<String, dynamic>?>? _eventSub;

  // Parsed live state
  GeoPoint? _liveLocation;
  DateTime? _locationUpdatedAt;
  bool _isSosResolved = false;

  @override
  void initState() {
    super.initState();
    _state = Get.find<HajiCareController>();
    _miniMapCtrl = fmap.MapController();

    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      _sosData = Map<String, dynamic>.from(args);
      _eventId = _sosData['id'] as String?;
    }

    _parseSosData(_sosData);
    _subscribeToLiveUpdates();
  }

  void _parseSosData(Map<String, dynamic> data) {
    final loc = data['location'];
    if (loc is GeoPoint) {
      _liveLocation = loc;
    }
    final updatedAt = data['locationUpdatedAt'];
    if (updatedAt is Timestamp) {
      _locationUpdatedAt = updatedAt.toDate();
    }
    final status = (data['status'] as String?)?.toLowerCase();
    _isSosResolved =
        status == 'resolved' || status == 'cancelled' || status == 'selesai';
  }

  void _subscribeToLiveUpdates() {
    final id = _eventId;
    if (id == null || id.isEmpty) return;

    _eventSub = _state.sosService.watchSosEvent(id).listen((data) {
      if (!mounted || data == null) return;
      setState(() {
        _sosData = data;
        _parseSosData(data);
      });
      // Pan mini-map to updated location only while SOS is still active
      if (_liveLocation != null && !_isSosResolved) {
        _safeMiniMapMove(
          LatLng(_liveLocation!.latitude, _liveLocation!.longitude),
        );
      }
    });
  }

  void _safeMiniMapMove(LatLng target) {
    try {
      _miniMapCtrl.move(target, _miniMapCtrl.camera.zoom);
    } catch (_) {}
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _miniMapCtrl.dispose();
    super.dispose();
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  String _formatTime(dynamic ts) {
    if (ts == null) return 'Tidak diketahui';
    DateTime? dt;
    if (ts is Timestamp) dt = ts.toDate();
    if (dt == null) return 'Tidak diketahui';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m · ${dt.day}/${dt.month}/${dt.year}';
  }

  String _locationFreshness() {
    final updated = _locationUpdatedAt;
    if (updated == null) return 'Belum ada data lokasi';
    final diff = DateTime.now().difference(updated);
    if (diff.inSeconds < 30) return 'Baru saja diperbarui';
    if (diff.inMinutes < 1) return '${diff.inSeconds}d yang lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    return '${diff.inHours} jam yang lalu';
  }

  Color _freshnessColor() {
    final updated = _locationUpdatedAt;
    if (updated == null) return AppColors.statusDanger;
    final diff = DateTime.now().difference(updated);
    if (diff.inMinutes < 2) return AppColors.statusSafe;
    if (diff.inMinutes < 10) return AppColors.statusWarning;
    return AppColors.statusDanger;
  }

  String _distanceText() {
    final loc = _liveLocation;
    if (loc == null) return 'Koordinat tidak tersedia';
    final myPos = _state.myCurrentPosition.value;
    if (myPos == null) {
      return 'Lat: ${loc.latitude.toStringAsFixed(4)}, '
          'Lng: ${loc.longitude.toStringAsFixed(4)}';
    }
    final m = Geolocator.distanceBetween(
      myPos.latitude,
      myPos.longitude,
      loc.latitude,
      loc.longitude,
    );
    if (m < 1000) return 'Jarak ±${m.round()} meter dari Anda';
    return 'Jarak ±${(m / 1000).toStringAsFixed(1)} km dari Anda';
  }

  LatLng? get _targetLatLng {
    final loc = _liveLocation;
    if (loc == null) return null;
    return LatLng(loc.latitude, loc.longitude);
  }

  // ── ACTIONS ────────────────────────────────────────────────────────────────

  Future<void> _openRoute() async {
    final target = _targetLatLng;
    if (target == null) {
      AppAlert.warning(
        context,
        title: context.tr('maps.locationUnavailable'),
        message: 'Posisi jamaah belum dikirimkan. Coba lagi sebentar.',
      );
      return;
    }

    final userId =
        _sosData['userId'] as String? ??
        _sosData['jamaahId'] as String? ??
        _sosData['uid'] as String? ??
        '';
    final userName =
        _sosData['userName'] as String? ??
        _sosData['name'] as String? ??
        'Jamaah SOS';
    final roomId = _sosData['roomId'] as String?;

    // 1. Sync active room in HajiCareController if present
    if (roomId != null &&
        roomId.isNotEmpty &&
        Get.isRegistered<HajiCareController>()) {
      final hajiCtrl = Get.find<HajiCareController>();
      hajiCtrl.activeRoomId.value = roomId;
    }

    // 2. Prepare MapController and select the jamaah member
    final mapCtrl = Get.isRegistered<MapController>()
        ? Get.find<MapController>()
        : Get.put(MapController());

    final member = RoomMemberModel(
      uid: userId,
      name: userName,
      role: 'jamaah',
      currentLocation:
          _liveLocation ?? GeoPoint(target.latitude, target.longitude),
      locationUpdatedAt: _locationUpdatedAt ?? DateTime.now(),
      sosActive: !_isSosResolved,
    );

    mapCtrl.selectedFilter.value =
        0; // Filter "Semua" so member markers are visible
    mapCtrl.selectedPoi.value = null;
    mapCtrl.selectedJamaah.value = null;
    mapCtrl.selectedMember.value = member;
    mapCtrl.isBottomSheetOpen.value = true;
    mapCtrl.pendingFocusCoordinate = target;
    mapCtrl.pendingFocusZoom = 17.5;

    // Helper to focus camera directly on the jamaah's pin
    void triggerFocus() {
      if (mapCtrl.isMapAttached) {
        mapCtrl.animatedMove(target, 17.5);
      } else {
        mapCtrl.focusCoordinate(target, destZoom: 17.5);
      }
    }

    // 3. Navigate directly to Interactive Map tab or route
    if (Get.isRegistered<DashboardController>()) {
      final dashboardCtrl = Get.find<DashboardController>();
      dashboardCtrl.changeTab(1);
      Get.until((route) => route.isFirst);
    } else {
      Get.until(
        (route) =>
            route.settings.name == AppRoutes.interactiveMap ||
            route.settings.name == AppRoutes.map ||
            route.isFirst,
      );
      if (Get.currentRoute != AppRoutes.interactiveMap &&
          Get.currentRoute != AppRoutes.map) {
        Get.toNamed(AppRoutes.interactiveMap);
      }
    }

    // 4. Repeatedly trigger focus across post-frame and transition animations
    triggerFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      triggerFocus();
      Future.delayed(const Duration(milliseconds: 150), triggerFocus);
      Future.delayed(const Duration(milliseconds: 350), triggerFocus);
      Future.delayed(const Duration(milliseconds: 600), triggerFocus);
    });

    // 5. If companion/admin has current GPS location, request route calculation in background
    if (mapCtrl.currentUserLocation.value != null) {
      mapCtrl.requestRouteToMember(member);
    }
  }

  Future<void> _openGoogleMaps() async {
    final target = _targetLatLng;
    if (target == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${target.latitude},${target.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _dismissSos() async {
    final userId =
        _sosData['userId'] as String? ?? _sosData['jamaahId'] as String? ?? '';
    final name = (_sosData['userName'] as String?)?.trim().isNotEmpty == true
        ? _sosData['userName'] as String
        : 'Jamaah ini';

    AppAlert.confirm(
      context,
      title: context.tr('sos.completeDialogTitle'),
      message: 'Apakah situasi darurat untuk "$name" sudah ditangani?',
      confirmText: context.tr('sos.yesComplete'),
      cancelText: context.tr('common.cancel'),
      onConfirm: () async {
        if (userId.isNotEmpty) _state.dismissedSosIds.add(userId);
        if (_eventId != null && _eventId!.isNotEmpty) {
          _state.dismissedSosIds.add(_eventId!);
        }

        if (Get.isRegistered<NotificationController>()) {
          final notifCtrl = Get.find<NotificationController>();
          final toDelete = notifCtrl.notifications
              .where(
                (n) =>
                    n.isSosAlert &&
                    (n.id == _eventId ||
                        n.relatedId == _eventId ||
                        n.senderId == userId ||
                        n.targetUserId == userId),
              )
              .map((n) => n.id)
              .toList();
          for (final notifId in toDelete) {
            notifCtrl.deleteNotification(notifId);
          }
        }

        final success = await _state.dismissSos(userId, eventId: _eventId);
        if (mounted) {
          if (success) {
            AppAlert.success(
              context,
              title: context.tr('sos.completed'),
              message: 'Panggilan SOS untuk "$name" telah diakhiri.',
            );
            Get.back();
          } else {
            AppAlert.error(
              context,
              title: context.tr('sos.statusNotChanged'),
              message: 'Periksa koneksi internet, lalu coba lagi.',
              okText: 'Coba Lagi',
            );
          }
        }
      },
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    final userName =
        (_sosData['userName'] as String?)?.trim().isNotEmpty == true
        ? _sosData['userName'] as String
        : 'Jamaah Tanpa Nama';
    final userId =
        _sosData['userId'] as String? ?? _sosData['jamaahId'] as String? ?? '-';
    final roomName =
        (_sosData['roomName'] as String?)?.trim().isNotEmpty == true
        ? _sosData['roomName'] as String
        : 'Di luar rombongan';
    final kloter = _sosData['kloter'] as String?;
    final maktab = _sosData['maktab'] as String?;
    final timeStr = _formatTime(_sosData['timestamp'] ?? _sosData['createdAt']);
    final status = _sosData['status'] as String? ?? 'active';

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: headingColor),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Darurat SOS',
              style: AppTypography.headlineMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              _isSosResolved ? 'Sudah Diselesaikan' : 'Aktif · Pantau Lokasi',
              style: AppTypography.captionSmall.copyWith(
                color: _isSosResolved
                    ? AppColors.statusSafe
                    : AppColors.sosEmergency,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isSosResolved)
            Container(
              margin: const EdgeInsets.only(right: 14, left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sosEmergency,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emergency_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'DARURAT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── 0. Floating Hero Header Card (same pattern as RoomDetailScreen) ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Main body card underneath
              Container(
                margin: const EdgeInsets.only(top: 30),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.28 : 0.05,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 52, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Identity info rows
                      _buildInfoTile(
                        icon: Icons.badge_rounded,
                        label: 'ID Jamaah',
                        value: userId == '-' ? 'Tidak diketahui' : userId,
                        color: primaryColor,
                        headingColor: headingColor,
                        bodyColor: bodyColor,
                        isDark: isDark,
                        cardBg: cardBg,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoTile(
                        icon: Icons.groups_2_rounded,
                        label: 'Rombongan',
                        value: roomName,
                        color: primaryColor,
                        headingColor: headingColor,
                        bodyColor: bodyColor,
                        isDark: isDark,
                        cardBg: cardBg,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoTile(
                              icon: Icons.flight_takeoff_rounded,
                              label: 'Kloter',
                              value: (kloter != null && kloter.isNotEmpty)
                                  ? kloter
                                  : '-',
                              color: primaryColor,
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                              isDark: isDark,
                              cardBg: cardBg,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoTile(
                              icon: Icons.hotel_rounded,
                              label: 'Maktab',
                              value: (maktab != null && maktab.isNotEmpty)
                                  ? maktab
                                  : '-',
                              color: primaryColor,
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                              isDark: isDark,
                              cardBg: cardBg,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoTile(
                        icon: Icons.access_time_rounded,
                        label: 'Waktu SOS',
                        value: timeStr,
                        color: AppColors.sosEmergency,
                        headingColor: headingColor,
                        bodyColor: bodyColor,
                        isDark: isDark,
                        cardBg: cardBg,
                      ),
                    ],
                  ),
                ),
              ),

              // Floating hero header (protrudes above card)
              Positioned(
                top: 0,
                left: 14,
                right: 14,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.sosEmergency.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sosEmergency.withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Glow circles
                      Positioned(
                        top: -10,
                        right: -10,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -15,
                        left: -15,
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.sos_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Menekan Tombol Darurat SOS',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(
                              status: status,
                              isResolved: _isSosResolved,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 2. Location Status Card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _freshnessColor().withValues(alpha: 0.35),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _freshnessColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.near_me_rounded,
                    size: 18,
                    color: _freshnessColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationFreshness(),
                        style: AppTypography.captionSmall.copyWith(
                          color: _freshnessColor(),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _distanceText(),
                        style: AppTypography.bodySmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_liveLocation != null)
                  GestureDetector(
                    onTap: () {
                      final loc = _liveLocation!;
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              '${loc.latitude.toStringAsFixed(6)}, '
                              '${loc.longitude.toStringAsFixed(6)}',
                        ),
                      );
                      AppAlert.success(
                        context,
                        title: context.tr('sos.coordinatesCopied'),
                        message: 'Koordinat GPS jamaah sudah disalin.',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppColors.canvasCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.canvasCreamSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: AppColors.goldPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Salin',
                            style: TextStyle(
                              color: AppColors.goldPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 3. Mini Map ───────────────────────────────────────────────────
          _buildMiniMap(isDark, cardBg),
          const SizedBox(height: AppSpacing.md),

          // ── 4. Action Buttons ─────────────────────────────────────────────
          if (!_isSosResolved) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4DC4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text(
                  'Buat Rute ke Jamaah',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _openRoute,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: headingColor,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.lightCardBorder,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text(
                      'Google Maps',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    onPressed: _liveLocation != null ? _openGoogleMaps : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusSafe,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text(
                      'Selesaikan SOS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    onPressed: _dismissSos,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.statusSafe.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.statusSafe.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.statusSafe.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.statusSafe,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Darurat Sudah Ditangani',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.statusSafe,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Panggilan darurat ini telah diselesaikan oleh petugas.',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.statusSafe.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// Builds a premium info tile matching RoomDetailScreen visual language.
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color headingColor,
    required Color bodyColor,
    required bool isDark,
    required Color cardBg,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 13,
        vertical: compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.canvasCream.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : AppColors.lightCardBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.canvasCreamSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: bodyColor.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: headingColor,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMap(bool isDark, Color cardBg) {
    final target = _targetLatLng;
    final initialCenter = target ?? const LatLng(21.4135, 39.8930);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            fmap.FlutterMap(
              mapController: _miniMapCtrl,
              options: fmap.MapOptions(
                initialCenter: initialCenter,
                initialZoom: target != null ? 16.5 : 12.0,
                interactionOptions: const fmap.InteractionOptions(
                  flags:
                      fmap.InteractiveFlag.pinchZoom |
                      fmap.InteractiveFlag.drag,
                ),
              ),
              children: [
                fmap.TileLayer(
                  urlTemplate: isDark
                      ? AppConstants.cartoDarkMatterUrl
                      : AppConstants.cartoVoyagerUrl,
                  userAgentPackageName: 'com.example.hajicare',
                ),
                if (target != null)
                  fmap.MarkerLayer(
                    markers: [
                      fmap.Marker(
                        point: target,
                        width: 42,
                        height: 42,
                        alignment: Alignment.topCenter,
                        child: const _SosPinMarker(),
                      ),
                    ],
                  ),
                const fmap.RichAttributionWidget(
                  attributions: [
                    fmap.TextSourceAttribution('OpenStreetMap contributors'),
                    fmap.TextSourceAttribution('CARTO'),
                  ],
                ),
              ],
            ),

            // Overlay: no location yet
            if (target == null)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off_rounded,
                        color: Colors.white70,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Menunggu data lokasi\ndari jamaah...',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Live tracking pill
            Positioned(
              top: 8,
              right: 8,
              child: _LivePill(isLive: target != null && !_isSosResolved),
            ),

            // Center-on-jamaah FAB
            if (target != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _safeMiniMapMove(target),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      size: 18,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isResolved;

  const _StatusBadge({required this.status, required this.isResolved});

  @override
  Widget build(BuildContext context) {
    final color = isResolved ? AppColors.statusSafe : AppColors.sosEmergency;
    final label = isResolved ? 'SELESAI' : status.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 9.5,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SosPinMarker extends StatelessWidget {
  const _SosPinMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.sosEmergency,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.sosEmergency.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_pin_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        CustomPaint(size: const Size(10, 6), painter: _PinTailPainter()),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.sosEmergency;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _LivePill extends StatelessWidget {
  final bool isLive;

  const _LivePill({required this.isLive});

  @override
  Widget build(BuildContext context) {
    final color = isLive ? AppColors.statusSafe : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isLive ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
