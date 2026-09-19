import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../map/controllers/map_controller.dart';

class ModalSosScreen extends StatefulWidget {
  const ModalSosScreen({super.key});

  @override
  State<ModalSosScreen> createState() => _ModalSosScreenState();
}

class _ModalSosScreenState extends State<ModalSosScreen>
    with SingleTickerProviderStateMixin {
  late final HajiCareController state;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _countdown = 3;
  bool _isCountingDown = false;
  bool _sosSent = false;

  @override
  void initState() {
    super.initState();
    state = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : Get.put(HajiCareController());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-start countdown ONLY for Jamaah who do not already have an active SOS
    final isOfficer =
        state.role == UserRole.pendamping || state.role == UserRole.admin;
    final hasActiveSos = state.anySosActive;

    if (!isOfficer && !hasActiveSos) {
      _startCountdown();
    }
  }

  void _startCountdown() async {
    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });

    for (int i = 3; i >= 0; i--) {
      if (!mounted || !_isCountingDown) return;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isCountingDown) return;

      setState(() {
        _countdown = i;
        if (i == 0) {
          _isCountingDown = false;
          _sosSent = true;
          _sendSos();
        }
      });
    }
  }

  void _cancelCountdown() {
    setState(() {
      _isCountingDown = false;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _sendSos() async {
    HapticFeedback.heavyImpact();
    final success = await state.triggerSos();
    if (mounted) {
      if (success) {
        AppAlert.error(
          context,
          title: 'Sinyal SOS Terkirim!',
          message:
              'Posisi darurat Anda telah disiarkan ke Pendamping dan Petugas Maktab.',
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatSosTime(dynamic timestamp) {
    if (timestamp == null) return 'Baru saja';
    DateTime? dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    }
    if (dt == null) return 'Baru saja';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} (${dt.day}/${dt.month}/${dt.year})';
  }

  String _calculateDistanceStr(dynamic location) {
    if (location == null) return 'Koordinat tidak tersedia';
    double? lat;
    double? lng;

    if (location is GeoPoint) {
      lat = location.latitude;
      lng = location.longitude;
    } else if (location is Map) {
      lat =
          (location['latitude'] as num?)?.toDouble() ??
          (location['lat'] as num?)?.toDouble();
      lng =
          (location['longitude'] as num?)?.toDouble() ??
          (location['lng'] as num?)?.toDouble();
    }

    if (lat == null || lng == null) return 'Koordinat tidak tersedia';

    final myPos = state.myCurrentPosition.value;
    if (myPos == null) {
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    }

    final meters = Geolocator.distanceBetween(
      myPos.latitude,
      myPos.longitude,
      lat,
      lng,
    );
    if (meters < 1000) {
      return 'Jarak ±${meters.round()} meter dari Anda';
    }
    return 'Jarak ±${(meters / 1000).toStringAsFixed(1)} km dari Anda';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final isOfficer =
        state.role == UserRole.pendamping || state.role == UserRole.admin;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: headingColor),
          tooltip: 'Kembali',
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
            Text(
              'Pusat Darurat SOS',
              style: AppTypography.headlineMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            final activeCount = state.activeSosCount.value;
            if (activeCount <= 0) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sosEmergency,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$activeCount AKTIF',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final activeSosList = state.activeSosEvents;
        final hasActiveSos = activeSosList.isNotEmpty;

        // If Officer OR there are active SOS events from Firestore, show Responder Panel
        if (isOfficer || hasActiveSos) {
          return _buildResponderView(
            context,
            activeSosList,
            isDark,
            cardBg,
            headingColor,
            bodyColor,
          );
        }

        // Otherwise (Jamaah in Standby), show Emergency Sender Panel
        return _buildJamaahSenderView(
          context,
          isDark,
          cardBg,
          headingColor,
          bodyColor,
        );
      }),
    );
  }

  // ===========================================================================
  // RESPONDER / OFFICER VIEW (REALTIME ACTIVE SOS LIST FROM FIRESTORE)
  // ===========================================================================

  Widget _buildResponderView(
    BuildContext context,
    List<Map<String, dynamic>> activeSosList,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── 1. Siren Alert Header Banner ────────────────────────────────────
        if (activeSosList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PANGGILAN DARURAT AKTIF',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ada ${activeSosList.length} jamaah membutuhkan pertolongan segera.',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── 2. Real Active SOS Cards from Firestore ─────────────────────────
        if (activeSosList.isEmpty) ...[
          AppCard(
            backgroundColor: cardBg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.statusSafe.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.statusSafe,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Kondisi Aman',
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tidak ada panggilan darurat SOS aktif saat ini. Seluruh jamaah terpantau dalam batas aman.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: bodyColor),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Text(
            'Daftar Panggilan Masuk (${activeSosList.length})',
            style: AppTypography.titleSmall.copyWith(
              color: headingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          ...activeSosList.map((sos) {
            final userName =
                (sos['userName'] as String?)?.trim().isNotEmpty == true
                ? (sos['userName'] as String).trim()
                : 'Jamaah Tanpa Nama';
            final userId =
                sos['userId'] as String? ?? sos['jamaahId'] as String? ?? '';
            final eventId = sos['id'] as String?;
            final roomName =
                (sos['roomName'] as String?)?.trim().isNotEmpty == true
                ? (sos['roomName'] as String).trim()
                : 'Darurat Bebas / Tanpa Room';
            final status = sos['status'] as String? ?? 'active';
            final timeStr = _formatSosTime(
              sos['timestamp'] ?? sos['createdAt'],
            );
            final distanceStr = _calculateDistanceStr(sos['location']);

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                backgroundColor: cardBg,
                borderColor: AppColors.sosEmergency.withValues(alpha: 0.6),
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: User Name + Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.sosEmergency.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(
                                    color: AppColors.sosEmergency.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle_rounded,
                                  color: AppColors.sosEmergency,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: AppTypography.titleSmall.copyWith(
                                        color: headingColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      roomName,
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                            color: bodyColor.withValues(
                                              alpha: 0.8,
                                            ),
                                            fontSize: 11,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sosEmergency.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.sosEmergency.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.sosEmergency,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.sosEmergency,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Metadata Row: Time & Distance
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: bodyColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 14,
                          color: AppColors.sosEmergency,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceStr,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.sosEmergency,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Action Buttons (Buka Peta & Selesaikan)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.sosEmergency,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons.navigation_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Buka di Peta',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            onPressed: () {
                              final loc = sos['location'];
                              LatLng? targetCoord;
                              if (loc is GeoPoint) {
                                targetCoord = LatLng(
                                  loc.latitude,
                                  loc.longitude,
                                );
                              } else if (loc is Map) {
                                final lat =
                                    (loc['latitude'] as num?)?.toDouble() ??
                                    (loc['lat'] as num?)?.toDouble();
                                final lng =
                                    (loc['longitude'] as num?)?.toDouble() ??
                                    (loc['lng'] as num?)?.toDouble();
                                if (lat != null && lng != null) {
                                  targetCoord = LatLng(lat, lng);
                                }
                              }

                              Get.back(); // Close modal
                              if (Get.isRegistered<MapController>() &&
                                  targetCoord != null) {
                                final mapCtrl = Get.find<MapController>();
                                mapCtrl.animatedMove(targetCoord, 17.5);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: headingColor,
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.canvasCreamSubtle,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Selesai',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            onPressed: () {
                              AppAlert.confirm(
                                context,
                                title: 'Selesaikan Darurat SOS?',
                                message:
                                    'Apakah situasi darurat untuk "$userName" sudah berhasil ditangani?',
                                confirmText: 'Ya, Selesaikan',
                                cancelText: 'Batal',
                                onConfirm: () async {
                                  await state.dismissSos(
                                    userId,
                                    eventId: eventId,
                                  );
                                  if (context.mounted) {
                                    AppAlert.success(
                                      context,
                                      title: 'Status Diperbarui',
                                      message:
                                          'Panggilan SOS untuk "$userName" telah ditandai selesai.',
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        const SizedBox(height: AppSpacing.lg),

        // ── 3. Emergency Hotline Info ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color:
                (isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCreamSubtle)
                    .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.phone_in_talk_rounded,
                color: AppColors.sosEmergency,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hotline Darurat Haji Indonesia',
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Pusat Krisis Kemenag: 800-119-999 • Ambulans: 997',
                      style: AppTypography.captionSmall.copyWith(
                        color: bodyColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // JAMAAH SENDER VIEW (EMERGENCY TRIGGER WITH LIVE FIREBASE SYNC)
  // ===========================================================================

  Widget _buildJamaahSenderView(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
  ) {
    final self = state.self;
    final isSosAlreadyActive = self.sosActive || _sosSent;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          // ── Pulsing SOS Radar ─────────────────────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sosEmergency.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sosEmergency.withValues(alpha: 0.3),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_isCountingDown) {
                    _cancelCountdown();
                  } else if (!isSosAlreadyActive) {
                    _sendSos();
                  }
                },
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFE53935),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isCountingDown
                        ? Text(
                            '$_countdown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Status Title & Subtitle ────────────────────────────────────────
          Text(
            isSosAlreadyActive
                ? 'Sinyal Darurat Sedang Aktif!'
                : (_isCountingDown
                      ? 'Mengirim Sinyal SOS...'
                      : 'Siap Mengirim Darurat SOS'),
            style: AppTypography.titleLarge.copyWith(
              color: isSosAlreadyActive ? AppColors.sosEmergency : headingColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isSosAlreadyActive
                ? 'Koordinat GPS Anda telah disiarkan secara real-time ke Pendamping dan Petugas Maktab.'
                : (_isCountingDown
                      ? 'Ketuk tombol SOS untuk membatalkan sebelum hitungan mundur selesai.'
                      : 'Gunakan saat terpisah jauh dari rombongan atau membutuhkan bantuan darurat segera.'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: bodyColor.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Action Buttons ────────────────────────────────────────────────
          if (_isCountingDown) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: headingColor,
                  side: BorderSide(color: headingColor.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.close_rounded),
                label: const Text(
                  'Batalkan Pengiriman',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _cancelCountdown,
              ),
            ),
          ] else if (isSosAlreadyActive) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusSafe,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text(
                  'Akhiri / Batalkan Sinyal SOS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final uid = state.currentUid;
                  if (uid != null) {
                    await state.dismissSos(uid);
                    setState(() {
                      _sosSent = false;
                    });
                    if (context.mounted) {
                      AppAlert.success(
                        context,
                        title: 'Sinyal SOS Dinonaktifkan',
                        message: 'Status darurat Anda telah diakhiri.',
                      );
                    }
                  }
                },
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sosEmergency,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.emergency_rounded),
                label: const Text(
                  'Kirim Sinyal SOS Sekarang',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _sendSos,
              ),
            ),
          ],

          const Spacer(),

          // ── GPS Telemetry Strip ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.canvasCreamSubtle,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.gps_fixed_rounded,
                  size: 14,
                  color: AppColors.statusSafe,
                ),
                const SizedBox(width: 6),
                Text(
                  state.myCurrentPosition.value != null
                      ? 'GPS Akurat (±${state.myCurrentPosition.value!.accuracy.round()}m)'
                      : 'Menghubungkan GPS...',
                  style: AppTypography.captionSmall.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
