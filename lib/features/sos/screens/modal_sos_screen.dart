import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../notification/controllers/notification_controller.dart';

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

  final _dismissedSosIds = <String>{}.obs;

  int _countdown = 3;
  bool _isCountingDown = false;
  bool _sosSent = false;

  @override
  void initState() {
    super.initState();
    state = Get.find<HajiCareController>();
    state.refreshSosEvents();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-start countdown ONLY for Jamaah who have an active room and do not already have an active SOS
    final isOfficer =
        state.role == UserRole.pendamping || state.role == UserRole.admin;
    final isSelfSosActive = state.self.sosActive;
    final hasRoom =
        (state.activeRoomId.value?.trim().isNotEmpty ?? false) ||
        state.activeRoom.value != null;

    if (!isOfficer && !isSelfSosActive && hasRoom) {
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
    final hasRoom =
        (state.activeRoomId.value?.trim().isNotEmpty ?? false) ||
        state.activeRoom.value != null;
    if (!hasRoom) {
      AppAlert.warning(
        context,
        title: 'Belum Terdaftar di Room',
        message:
            'Anda harus bergabung ke room pantau rombongan terlebih dahulu untuk menggunakan fitur SOS darurat.',
        okText: 'Gabung Room',
        onOk: () => Get.toNamed(AppRoutes.joinRoom),
      );
      return;
    }
    HapticFeedback.heavyImpact();
    final success = await state.triggerSos();
    if (mounted) {
      if (success) {
        setState(() {
          _sosSent = true;
        });
        Get.toNamed(AppRoutes.sosScanning);
      } else {
        setState(() {
          _sosSent = false;
        });
        AppAlert.error(
          context,
          title: context.tr('sos.failedToSend'),
          message:
              'Periksa internet, lalu tekan tombol SOS lagi. Jika keadaan mendesak, segera minta bantuan orang terdekat.',
          okText: 'Coba Lagi',
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

  String _getWaitTimeNumber(dynamic timestamp) {
    if (timestamp == null) return '<1';
    DateTime? dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    }
    if (dt == null) return '<1';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes <= 0) return '<1';
    if (diff.inHours >= 1) return diff.inHours.toString().padLeft(2, '0');
    return diff.inMinutes.toString().padLeft(2, '0');
  }

  String _getWaitTimeUnit(dynamic timestamp) {
    if (timestamp == null) return 'mnt';
    DateTime? dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    }
    if (dt == null) return 'mnt';
    final diff = DateTime.now().difference(dt);
    if (diff.inHours >= 1) return 'jam';
    return 'mnt';
  }

  String _getFormattedClockTime(dynamic timestamp) {
    if (timestamp == null) return '--:--';
    DateTime? dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    }
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isItemDismissed(String? id, [String? secondaryId]) {
    if (id != null && id.isNotEmpty) {
      if (_dismissedSosIds.contains(id) || state.isSosDismissed(id)) {
        return true;
      }
    }
    if (secondaryId != null && secondaryId.isNotEmpty) {
      if (_dismissedSosIds.contains(secondaryId) ||
          state.isSosDismissed(secondaryId)) {
        return true;
      }
    }
    return false;
  }

  /// Combines all active SOS sources: Firestore sos_events stream,
  /// room jamaahList with sosActive flag, and incoming sos_alert notifications.
  /// Deduplication is done by BOTH eventId AND userId so the same jamaah
  /// never appears twice across the three sources.
  List<Map<String, dynamic>> _resolveActiveSosList() {
    final list = <Map<String, dynamic>>[];
    // seenEventIds: prevents duplicate Firestore event docs
    final seenEventIds = <String>{};
    // seenUserIds: prevents the same user from appearing in multiple sources
    final seenUserIds = <String>{};

    // 1. From Firestore sos_events stream in state (canonical / highest priority)
    for (final event in state.activeSosEvents) {
      final eventId = event['id']?.toString();
      final uId =
          event['userId']?.toString() ?? event['jamaahId']?.toString() ?? '';
      if (_isItemDismissed(eventId, uId)) continue;
      if (uId.isNotEmpty && seenUserIds.contains(uId)) continue;
      if (eventId != null && seenEventIds.add(eventId)) {
        if (uId.isNotEmpty) seenUserIds.add(uId);
        list.add(Map<String, dynamic>.from(event));
      }
    }

    // 2. From room jamaahList (only add if userId not already covered by source 1)
    for (final j in state.jamaahList) {
      if (_isItemDismissed(j.id)) continue;
      if (!j.sosActive) continue;
      if (seenUserIds.contains(j.id)) continue; // already from Firestore event
      seenUserIds.add(j.id);
      seenEventIds.add(j.id);
      list.add({
        'id': j.id,
        'userId': j.id,
        'jamaahId': j.id,
        'userName': j.name,
        'roomName': state.activeRoom.value?.name ?? 'Rombongan',
        'status': 'active',
        'timestamp': j.locationUpdatedAt ?? DateTime.now(),
        if (j.currentLocation != null) 'location': j.currentLocation,
        if (state.pendampingKloter.value != null)
          'kloter': state.pendampingKloter.value,
        if (state.pendampingMaktab.value != null)
          'maktab': state.pendampingMaktab.value,
      });
    }

    // 3. From incoming unhandled notifications of type sos_alert
    // Only used as fallback if neither source 1 nor 2 covered this user.
    if (Get.isRegistered<NotificationController>()) {
      final notifCtrl = Get.find<NotificationController>();
      for (final n in notifCtrl.notifications) {
        if (!n.isSosAlert || n.isRead) continue;
        final senderId = n.senderId ?? n.targetUserId;
        final eventId = n.relatedId ?? senderId;
        if (_isItemDismissed(n.id, eventId) || _isItemDismissed(senderId)) {
          continue;
        }
        // Skip if this userId is already represented
        if (senderId != null && seenUserIds.contains(senderId)) continue;
        if (eventId != null && seenEventIds.add(eventId)) {
          if (senderId != null) seenUserIds.add(senderId);
          final lat = (n.metadata?['latitude'] as num?)?.toDouble();
          final lng = (n.metadata?['longitude'] as num?)?.toDouble();
          list.add({
            'id': eventId,
            'userId': senderId ?? eventId,
            'jamaahId': senderId ?? eventId,
            'userName': n.senderName ?? 'Jamaah',
            'roomName':
                n.metadata?['roomName'] ??
                (n.targetRoomId != null ? 'Rombongan' : 'Di luar rombongan'),
            'status': 'active',
            'timestamp': n.createdAt ?? DateTime.now(),
            if (lat != null && lng != null) 'location': GeoPoint(lat, lng),
            if (n.metadata?['kloter'] != null) 'kloter': n.metadata!['kloter'],
            if (n.metadata?['maktab'] != null) 'maktab': n.metadata!['maktab'],
          });
        }
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isOfficer =
        state.role == UserRole.pendamping || state.role == UserRole.admin;

    // ── Khusus Pendamping: Tampilan baru bergradien mewah mengikuti Gambar 2 ─
    if (isOfficer) {
      return Obx(() {
        final activeSosList = _resolveActiveSosList();
        return _buildResponderView(context, activeSosList, isDark);
      });
    }

    // ── Jamaah: Tampilan Emergency Trigger Panel ────────────────────────────
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;

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
            Expanded(
              child: Text(
                context.tr('sosCenterTitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headlineMedium.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _buildJamaahSenderView(
        context,
        isDark,
        cardBg,
        headingColor,
        bodyColor,
      ),
    );
  }

  // ===========================================================================
  // RESPONDER / OFFICER VIEW (REFERENSI GAMBAR 2: HERO GRADIENT & FLOATING ISLAND)
  // ===========================================================================

  Widget _buildResponderView(
    BuildContext context,
    List<Map<String, dynamic>> activeSosList,
    bool isDark,
  ) {
    final activeCount = activeSosList.length;
    final hasActiveSos = activeCount > 0;
    final mq = MediaQuery.of(context);
    final topPadding = mq.padding.top;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.canvasCream,
      body: Stack(
        children: [
          // ── 1. Top Hero Gradient Background (Merah Crimson & Kaaba Espresso)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 310 + topPadding,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF7F1D1D),
                          Color(0xFF5B1111),
                          Color(0xFF2E1C12),
                        ]
                      : const [
                          Color(0xFFDC2626),
                          Color(0xFFB91C1C),
                          Color(0xFF38251A),
                        ],
                ),
              ),
              child: Stack(
                children: [
                  // Subtle decorative watermark circles
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 2. Scrollable Content Layer ──────────────────────────────────
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Custom Navigation Bar (Frosted back & title)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        // Frosted circular back button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Get.back(),
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('sosCenterTitle'),
                                style: const TextStyle(
                                  fontFamily: AppTypography.headingFontFamily,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Pusat Respon Darurat Jamaah',
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFontFamily,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Active Badge Pill
                        if (hasActiveSos)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.sosEmergency,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$activeCount AKTIF',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.headingFontFamily,
                                    color: AppColors.sosEmergency,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Top Command Card (Meniru Floating Box pada Gambar 2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                    child: _buildTopCommandCard(
                      context,
                      isDark,
                      activeCount,
                      hasActiveSos,
                    ),
                  ),
                ),

                // The Curved Bottom Sheet (White/Cream Island)
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.canvasCream,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkOutline.withValues(alpha: 0.6)
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.6,
                                    ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section Header: Incoming Calls List
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('sosIncomingCallsList', {
                                  'count': activeCount,
                                }),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextHeading
                                      : AppColors.espressoDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (hasActiveSos)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sosEmergency.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  'Perlu Tindakan',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.sosEmergency,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Active SOS Cards or Safe Empty State
                        if (!hasActiveSos)
                          _buildSafeEmptyState(context, isDark)
                        else
                          ...activeSosList.map(
                            (sos) =>
                                _buildReferenceSosCard(context, sos, isDark),
                          ),

                        const SizedBox(height: 16),

                        // Emergency Hotline Card
                        _buildHotlineCard(context, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Command Card (Meniru Visual Box "From / To" pada Gambar 2) ─────────

  Widget _buildTopCommandCard(
    BuildContext context,
    bool isDark,
    int activeCount,
    bool hasActiveSos,
  ) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final subColor = isDark ? AppColors.darkTextBody : AppColors.textMuted;

    final roomName = state.activeRoom.value?.name ?? 'Rombongan Pantau';
    final kloter = state.pendampingKloter.value;
    final maktab = state.pendampingMaktab.value;
    final officerSub = [
      if (kloter != null && kloter.isNotEmpty) 'Kloter $kloter',
      if (maktab != null && maktab.isNotEmpty) 'Maktab $maktab',
      if ((kloter == null || kloter.isEmpty) &&
          (maktab == null || maktab.isEmpty))
        roomName,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.espressoDark.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Row 1: Posko Pendamping (Green point)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POSKO PENDAMPING',
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Siaga Respon Cepat Terhubung',
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: headingColor,
                      ),
                    ),
                    if (officerSub.isNotEmpty)
                      Text(
                        officerSub,
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 11,
                          color: subColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Vertical connector line
          Padding(
            padding: const EdgeInsets.only(left: 7.5, top: 2, bottom: 2),
            child: Row(
              children: [
                Container(
                  width: 1.5,
                  height: 18,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),

          // Row 2: Status Panggilan Darurat (Red pulsing point)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (hasActiveSos
                              ? AppColors.sosEmergency
                              : const Color(0xFF22C55E))
                          .withValues(alpha: 0.15),
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: hasActiveSos
                        ? _pulseAnimation
                        : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasActiveSos
                            ? AppColors.sosEmergency
                            : const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS DARURAT JAMAAH',
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasActiveSos
                          ? '$activeCount Jamaah Perlu Bantuan Segera'
                          : 'Kondisi Aman Terkendali',
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: hasActiveSos
                            ? AppColors.sosEmergency
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SOS Card Mengikuti Desain Referensi Gambar 2 ───────────────────────────

  Widget _buildReferenceSosCard(
    BuildContext context,
    Map<String, dynamic> sos,
    bool isDark,
  ) {
    final userName = (sos['userName'] as String?)?.trim().isNotEmpty == true
        ? (sos['userName'] as String).trim()
        : 'Jamaah Tanpa Nama';
    final userId = sos['userId'] as String? ?? sos['jamaahId'] as String? ?? '';
    final eventId = sos['id'] as String?;
    final roomName = (sos['roomName'] as String?)?.trim().isNotEmpty == true
        ? (sos['roomName'] as String).trim()
        : 'Di luar rombongan';
    final loc = sos['location'];
    final hasLocation = loc is GeoPoint;
    final timestamp = sos['timestamp'] ?? sos['createdAt'];
    final timeStr = _formatSosTime(timestamp);
    final clockTime = _getFormattedClockTime(timestamp);
    final waitTimeNum = _getWaitTimeNumber(timestamp);
    final waitTimeUnit = _getWaitTimeUnit(timestamp);

    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.sosEmergency.withValues(alpha: isDark ? 0.35 : 0.20),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sosEmergency.withValues(
              alpha: isDark ? 0.18 : 0.07,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Bookmark Ribbon in Top Right Corner (Meniru Ribbon "AC" di Gambar 2)
            Positioned(
              top: 0,
              right: 18,
              child: Column(
                children: [
                  ClipPath(
                    clipper: _RibbonClipper(),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clockTime,
                    style: AppTypography.captionSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextBody
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Card Main Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Left: Large wait time typography (matching reference "10 min")
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WAKTU TUNGGU',
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextBody
                                  : AppColors.textMuted,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                waitTimeNum,
                                style: TextStyle(
                                  fontFamily: AppTypography.headingFontFamily,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  color: headingColor,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                waitTimeUnit,
                                style: const TextStyle(
                                  fontFamily: AppTypography.bodyFontFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.sosEmergency,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // GPS Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (hasLocation
                                              ? const Color(0xFF22C55E)
                                              : AppColors.sosEmergency)
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasLocation
                                          ? Icons.gps_fixed_rounded
                                          : Icons.gps_off_rounded,
                                      size: 11,
                                      color: hasLocation
                                          ? const Color(0xFF16A34A)
                                          : AppColors.sosEmergency,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasLocation ? 'GPS Aktif' : 'GPS Mati',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: hasLocation
                                            ? const Color(0xFF16A34A)
                                            : AppColors.sosEmergency,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Route/Timeline Steps (2 Points: Jamaah & Lokasi)
                  Container(
                    margin: const EdgeInsets.only(top: 14, bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkOutline.withValues(alpha: 0.2)
                            : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Dots & Line
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF22C55E,
                                ).withValues(alpha: 0.2),
                                border: Border.all(
                                  color: const Color(0xFF22C55E),
                                  width: 3,
                                ),
                              ),
                            ),
                            Container(
                              width: 1.5,
                              height: 22,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.35),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF3B82F6,
                                ).withValues(alpha: 0.2),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6),
                                  width: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: headingColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                roomName,
                                style: AppTypography.captionSmall.copyWith(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextBody
                                      : AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                hasLocation
                                    ? '📍 Lokasi GPS terdeteksi — tap Lihat Detail'
                                    : '📍 Lokasi belum tersedia',
                                style: AppTypography.captionSmall.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: hasLocation
                                      ? const Color(0xFF16A34A)
                                      : AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                timeStr,
                                style: AppTypography.captionSmall.copyWith(
                                  fontSize: 10.5,
                                  color: isDark
                                      ? AppColors.darkTextBody.withValues(
                                          alpha: 0.7,
                                        )
                                      : AppColors.textMuted.withValues(
                                          alpha: 0.8,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons (Text Scale Responsive)
                  LayoutBuilder(
                    builder: (context, btnConstraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final bool stackButtons =
                          textScale > 1.35 || btnConstraints.maxWidth < 280;

                      final detailBtn = Container(
                        constraints: const BoxConstraints(minHeight: 42),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.38),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: const Text(
                            'Lihat Detail',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () {
                            Get.toNamed(
                              AppRoutes.sosAlertDetail,
                              arguments: Map<String, dynamic>.from(sos),
                            );
                          },
                        ),
                      );

                      final finishBtn = ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 42),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: headingColor,
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutline.withValues(
                                      alpha: 0.35,
                                    )
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.6,
                                    ),
                              width: 1.1,
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'Selesai',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () => _handleCompleteSos(
                            context,
                            sos,
                            userName,
                            userId,
                            eventId,
                          ),
                        ),
                      );

                      if (stackButtons) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            detailBtn,
                            const SizedBox(height: 8),
                            finishBtn,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(flex: 3, child: detailBtn),
                          const SizedBox(width: 10),
                          Expanded(flex: 2, child: finishBtn),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Safe Empty State ───────────────────────────────────────────────────────

  Widget _buildSafeEmptyState(BuildContext context, bool isDark) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF16A34A),
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('sosSafeConditionTitle'),
            style: AppTypography.titleMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('sosSafeConditionDesc'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: bodyColor),
          ),
        ],
      ),
    );
  }

  // ── Hotline Darurat Card ───────────────────────────────────────────────────

  Widget _buildHotlineCard(BuildContext context, bool isDark) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.canvasCreamSubtle.withValues(alpha: 0.6);
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutline.withValues(alpha: 0.2)
              : AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.sosEmergency.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_in_talk_rounded,
              color: AppColors.sosEmergency,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
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
    );
  }

  // ── Handler Selesaikan SOS ─────────────────────────────────────────────────

  void _handleCompleteSos(
    BuildContext context,
    Map<String, dynamic> sos,
    String userName,
    String userId,
    String? eventId,
  ) {
    AppAlert.confirm(
      context,
      title: context.tr('sos.completeDialogTitle'),
      message:
          'Apakah situasi darurat untuk "$userName" sudah berhasil ditangani?',
      confirmText: context.tr('sos.yesComplete'),
      cancelText: context.tr('common.cancel'),
      onConfirm: () async {
        if (userId.isNotEmpty) {
          _dismissedSosIds.add(userId);
        }
        if (eventId != null && eventId.isNotEmpty) {
          _dismissedSosIds.add(eventId);
        }
        final rawId = sos['id'] as String?;
        if (rawId != null && rawId.isNotEmpty) {
          _dismissedSosIds.add(rawId);
        }

        if (Get.isRegistered<NotificationController>()) {
          final notifCtrl = Get.find<NotificationController>();
          final toDelete = notifCtrl.notifications
              .where(
                (n) =>
                    n.isSosAlert &&
                    (n.id == rawId ||
                        n.id == eventId ||
                        n.relatedId == rawId ||
                        n.relatedId == eventId ||
                        n.senderId == userId ||
                        n.targetUserId == userId),
              )
              .map((n) => n.id)
              .toList();
          for (final notifId in toDelete) {
            notifCtrl.deleteNotification(notifId);
          }
        }

        final success = await state.dismissSos(userId, eventId: eventId);

        if (mounted) {
          setState(() {});
        }
        if (context.mounted) {
          if (success) {
            AppAlert.success(
              context,
              title: context.tr('sos.completed'),
              message: 'Panggilan SOS untuk "$userName" sudah diakhiri.',
            );
          } else {
            AppAlert.error(
              context,
              title: context.tr('sos.statusNotChanged'),
              message: 'Periksa internet, lalu coba akhiri SOS sekali lagi.',
              okText: 'Coba Lagi',
            );
          }
        }
      },
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
    final hasRoom =
        (state.activeRoomId.value?.trim().isNotEmpty ?? false) ||
        state.activeRoom.value != null;
    final isSosAlreadyActive = (self.sosActive || _sosSent) && hasRoom;

    if (!hasRoom) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.distanceWarning.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.distanceWarning.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.meeting_room_outlined,
                  size: 46,
                  color: AppColors.distanceWarning,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belum Terdaftar di Room Pantau',
              style: AppTypography.titleLarge.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tombol SOS darurat dinonaktifkan karena Anda belum masuk ke room pantau rombongan. Bergabunglah ke rombongan Anda agar pendamping dan petugas dapat memantau lokasi dan menerima sinyal darurat.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: bodyColor.withValues(alpha: 0.85),
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.joinRoom),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.group_add_rounded, size: 20),
              label: const Text(
                'Gabung ke Room Pantau',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }

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
                ? context.tr('sosSignalActiveNow')
                : (_isCountingDown
                      ? context.tr('sosSendingSignal')
                      : context.tr('sosReadyToSend')),
            style: AppTypography.titleLarge.copyWith(
              color: isSosAlreadyActive ? AppColors.sosEmergency : headingColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isSosAlreadyActive
                ? context.tr('sosLocationSentToCompanion')
                : (_isCountingDown
                      ? context.tr('sosTapToCancelCountdown')
                      : context.tr('sosUsagePrompt')),
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
                label: Text(
                  context.tr('sosCancelSending'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                  backgroundColor: const Color(0xFF1E60CC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.radar_rounded),
                label: Text(
                  context.tr('sosTrackRadarCompanion'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => Get.toNamed(AppRoutes.sosScanning),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
                label: Text(
                  context.tr('sosDismissSignal'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final uid = state.currentUid;
                  if (uid != null) {
                    if (uid.isNotEmpty) _dismissedSosIds.add(uid);
                    final success = await state.dismissSos(uid);
                    if (success) {
                      setState(() {
                        _sosSent = false;
                      });
                    }
                    if (context.mounted) {
                      if (success) {
                        AppAlert.success(
                          context,
                          title: context.tr('sos.signalDisabled'),
                          message: 'Status darurat Anda sudah diakhiri.',
                        );
                      } else {
                        AppAlert.error(
                          context,
                          title: context.tr('sos.signalDisableFailed'),
                          message:
                              'Periksa internet, lalu coba akhiri SOS sekali lagi.',
                          okText: 'Coba Lagi',
                        );
                      }
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
                label: Text(
                  context.tr('sosSendNow'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                      ? context.tr('sosLocationFoundAccuracy', {
                          'accuracy': state.myCurrentPosition.value!.accuracy
                              .round(),
                        })
                      : context.tr('sosSearchingGps'),
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

/// Custom swallowtail ribbon clipper matching the bookmark badge from reference design.
class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width / 2, size.height - 6);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
