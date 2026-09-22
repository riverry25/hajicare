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
import '../../../core/widgets/app_card.dart';
import '../../map/controllers/map_controller.dart';
import '../../map/models/map_poi.dart';

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

    final poi = MapPoi(
      id: 'sos_${_eventId ?? 'alert'}',
      name: _sosData['userName'] as String? ?? 'Jamaah SOS',
      category: PoiCategory.place,
      coordinate: target,
      statusLabel: 'SOS Aktif',
    );

    // Pop modals and navigate to map screen
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
      mapCtrl.animatedMove(target, 17.5);
      await mapCtrl.requestRouteToPoi(poi);
    } else {
      Get.until((route) => route.isFirst);
      await Get.toNamed(AppRoutes.map);
      if (Get.isRegistered<MapController>()) {
        final mapCtrl = Get.find<MapController>();
        mapCtrl.animatedMove(target, 17.5);
        await mapCtrl.requestRouteToPoi(poi);
      }
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.sosEmergency,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Detail SOS — $userName',
                style: AppTypography.headlineMedium.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isSosResolved)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sosEmergency,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text(
                'AKTIF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── 1. Identity Card ──────────────────────────────────────────────
          AppCard(
            backgroundColor: cardBg,
            borderColor: AppColors.sosEmergency.withValues(alpha: 0.45),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.sosEmergency.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.sosEmergency.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.person_pin_circle_rounded,
                        color: AppColors.sosEmergency,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: AppTypography.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            roomName,
                            style: AppTypography.captionSmall.copyWith(
                              color: bodyColor.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: status, isResolved: _isSosResolved),
                  ],
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.fingerprint_rounded,
                  label: context.tr('sos.pilgrimId'),
                  value: userId,
                  color: bodyColor,
                  headingColor: headingColor,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.flight_rounded,
                  label: context.tr('sos.kloterLabel'),
                  value: (kloter != null && kloter.isNotEmpty) ? kloter : '-',
                  color: bodyColor,
                  headingColor: headingColor,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.holiday_village_rounded,
                  label: context.tr('sos.maktabLabel'),
                  value: (maktab != null && maktab.isNotEmpty) ? maktab : '-',
                  color: bodyColor,
                  headingColor: headingColor,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: context.tr('sos.sosTime'),
                  value: timeStr,
                  color: bodyColor,
                  headingColor: headingColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 2. Location Status ────────────────────────────────────────────
          AppCard(
            backgroundColor: cardBg,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      size: 16,
                      color: _freshnessColor(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _locationFreshness(),
                        style: AppTypography.captionSmall.copyWith(
                          color: _freshnessColor(),
                          fontWeight: FontWeight.w700,
                        ),
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
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 15,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _distanceText(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.sosEmergency,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 3. Mini Map ───────────────────────────────────────────────────
          _buildMiniMap(isDark),
          const SizedBox(height: AppSpacing.md),

          // ── 4. Action Buttons ─────────────────────────────────────────────
          if (!_isSosResolved) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E60CC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text(
                  'Buat Rute ke Jamaah',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                            ? AppColors.darkCardBorder
                            : AppColors.canvasCreamSubtle,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text(
                      'Buka di Google Maps',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                        fontSize: 12,
                      ),
                    ),
                    onPressed: _dismissSos,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Already resolved
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.statusSafe.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.statusSafe.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.statusSafe,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Panggilan darurat ini sudah diselesaikan.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.statusSafe,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildMiniMap(bool isDark) {
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color headingColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.headingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color.withValues(alpha: 0.65)),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: color.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: AppTypography.captionSmall.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
