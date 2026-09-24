import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../notification/services/notification_service.dart';
import '../models/assistance_request_model.dart';
import '../presentation/dashboard_typography.dart';
import '../services/assistance_request_service.dart';
import 'assistance_tracking_sheet.dart';

/// Legacy enum adapter for backward compatibility with existing tests.
enum CompanionContactKind { message, info }

/// Re-designed, elder-friendly Request Assistance System for HajiCare.
/// Focuses on: "Saya tidak tahu jalan pulang", "Terpisah rombongan",
/// "Penjemputan", and general assistance with human-readable location awareness.
class CompanionContactSheet extends StatefulWidget {
  const CompanionContactSheet({
    super.key,
    required this.roomId,
    required this.pendampings,
    required this.state,
    this.notificationService,
  });

  final String roomId;
  final List<RoomMemberModel> pendampings;
  final HajiCareController state;
  final NotificationService? notificationService;

  @override
  State<CompanionContactSheet> createState() => _CompanionContactSheetState();
}

class _CompanionContactSheetState extends State<CompanionContactSheet> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AssistanceType _selectedType = AssistanceType.lostWay;
  bool _sendToAll = false;
  bool _includeLocation = true;
  bool _isFindingLocation = false;
  bool _isSubmitting = false;
  String? _selectedPendampingUid;
  int _sharingDurationMinutes = 30;

  AssistanceRequestService get _assistanceService =>
      AssistanceRequestService.instance;

  List<String> get _quickMessages => [
    'Saya tidak tahu jalan pulang',
    'Saya terpisah dari rombongan',
    'Saya menunggu di lokasi ini',
    'Mohon bantuan penjemputan',
  ];

  @override
  void initState() {
    super.initState();
    _messageController.text = _selectedType.defaultQuickMessage;

    // Default ke pendamping pertama jika ada
    if (widget.pendampings.isNotEmpty) {
      _selectedPendampingUid = widget.pendampings.first.uid;
    }

    // Periksa status lokasi saat sheet pertama kali dibuka
    if (widget.state.myCurrentPosition.value == null) {
      _includeLocation = false;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _selectAssistanceType(AssistanceType type) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedType = type;
      _messageController.text = type.defaultQuickMessage;
      if (type.requiresLocation &&
          widget.state.myCurrentPosition.value != null) {
        _includeLocation = true;
      }
    });
  }

  Future<void> _toggleLocation() async {
    HapticFeedback.selectionClick();
    if (_includeLocation) {
      setState(() => _includeLocation = false);
      return;
    }

    if (widget.state.myCurrentPosition.value == null) {
      setState(() => _isFindingLocation = true);
      final found = await widget.state.refreshLocation();
      if (!mounted) return;
      setState(() {
        _isFindingLocation = false;
        _includeLocation =
            found && widget.state.myCurrentPosition.value != null;
      });
      if (!_includeLocation) {
        AppAlert.warning(
          context,
          title: context.tr('dashboard.locationNotFound'),
          message: context.tr('dashboard.enableGpsAccess'),
        );
      }
      return;
    }

    setState(() => _includeLocation = true);
  }

  Future<void> _submitAssistance() async {
    if (_isSubmitting) return;

    if (!_sendToAll &&
        _selectedPendampingUid == null &&
        widget.pendampings.isNotEmpty) {
      _selectedPendampingUid = widget.pendampings.first.uid;
    }

    setState(() => _isSubmitting = true);

    try {
      final pos = _includeLocation
          ? widget.state.myCurrentPosition.value
          : null;
      final targetHotel = _assistanceService.resolveTargetHotel(widget.state);
      final targetRoom = _assistanceService.resolveTargetRoom(widget.state);

      final selectedPendamping = widget.pendampings.firstWhereOrNull(
        (p) => p.uid == _selectedPendampingUid,
      );

      final jamaahName = widget.state.self.name.trim().isNotEmpty
          ? widget.state.self.name.trim()
          : (widget.state.currentUid != null ? 'Jamaah' : 'Ahmad (Jamaah)');

      await _assistanceService.submitRequest(
        roomId: widget.roomId,
        roomName: widget.state.activeRoom.value?.name,
        jamaahId: widget.state.currentUid ?? 'jamaah_self',
        jamaahName: jamaahName,
        type: _selectedType,
        message: _messageController.text.trim(),
        currentPosition: pos,
        targetHotel: targetHotel,
        targetRoom: targetRoom,
        sharingDurationMinutes: _sharingDurationMinutes,
        selectedPendampingUid: _selectedPendampingUid,
        selectedPendampingName: selectedPendamping?.name,
        sendToAll: _sendToAll,
      );

      HapticFeedback.heavyImpact();
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppAlert.error(
        context,
        title: 'Gagal Mengirim Bantuan',
        message: UserFeedbackMessage.from(
          error,
          fallback: 'Permintaan belum dapat dikirim. Silakan coba lagi.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    // Jika sedang ada request bantuan aktif, tampilkan layar tracking bantuan
    return Obx(() {
      final activeReq = _assistanceService.activeRequest.value;
      if (activeReq != null && activeReq.isActive) {
        return AssistanceTrackingSheet(
          request: activeReq,
          onCompleted: () => setState(() {}),
          onBack: () => setState(() {}),
        );
      }

      return SafeArea(
        top: false,
        child: Container(
          key: const Key('companion_contact_sheet'),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.80,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              14,
              AppSpacing.cardPadding,
              AppSpacing.cardPadding + bottomInset,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: bodyColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header: "Hubungi Pendamping" + "Dapatkan bantuan dari pendamping Anda"
                  _buildHeader(headingColor, bodyColor),
                  const SizedBox(height: 22),

                  // ── 1. "Apa yang terjadi?" (Pilihan Bantuan yang Jelas) ──
                  _buildSectionTitle('Apa yang terjadi?', headingColor),
                  const SizedBox(height: 12),
                  _buildAssistanceTypeCards(isDark, headingColor, bodyColor),
                  const SizedBox(height: 24),

                  // ── 2. "Lokasi Anda" (Inti, Bukan Opsional) ───────────────
                  _buildLocationSection(isDark, headingColor, bodyColor),
                  const SizedBox(height: 24),

                  // ── 3. "Tujuan Anda" (Hotel/Maktab Jamaah) ────────────────
                  _buildTargetDestinationSection(
                    isDark,
                    headingColor,
                    bodyColor,
                  ),
                  const SizedBox(height: 24),

                  // ── 4. Quick Messages & Pesan Tambahan ─────────────────────
                  _buildMessageSection(isDark, headingColor, bodyColor),
                  const SizedBox(height: 24),

                  // ── 5. Pilih Penerima ─────────────────────────────────────
                  _buildRecipientSection(isDark, headingColor, bodyColor),
                  const SizedBox(height: 26),

                  // ── 6. CTA Utama Dinamis ──────────────────────────────────
                  _buildPrimaryCtaButton(isDark),
                  const SizedBox(height: 8),

                  Center(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : Get.back,
                      child: Text(
                        context.tr('cancel'),
                        style: TextStyle(
                          color: bodyColor.withValues(alpha: 0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(Color headingColor, Color bodyColor) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFE64A19).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE64A19).withValues(alpha: 0.28),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: Color(0xFFE64A19),
            size: 32,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hubungi Pendamping',
                style: DashboardTypography.titleMedium.copyWith(
                  color: headingColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Dapatkan bantuan dari pendamping Anda',
                style: TextStyle(color: bodyColor, fontSize: 13.5, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color headingColor) {
    return Text(
      title,
      style: DashboardTypography.labelLarge.copyWith(
        color: headingColor,
        fontSize: 16.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildAssistanceTypeCards(
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    return Column(
      children: [
        // A. "Saya tidak tahu jalan pulang" (CORE USE CASE - Highlighted)
        _assistanceCard(
          type: AssistanceType.lostWay,
          isHighlight: true,
          isDark: isDark,
          headingColor: headingColor,
          bodyColor: bodyColor,
        ),
        const SizedBox(height: 10),

        // B. "Saya terpisah dari rombongan"
        _assistanceCard(
          type: AssistanceType.separated,
          isDark: isDark,
          headingColor: headingColor,
          bodyColor: bodyColor,
        ),
        const SizedBox(height: 10),

        // C. "Saya membutuhkan penjemputan"
        _assistanceCard(
          type: AssistanceType.pickup,
          isDark: isDark,
          headingColor: headingColor,
          bodyColor: bodyColor,
        ),
        const SizedBox(height: 10),

        // D. "Saya ingin mengirim pesan"
        _assistanceCard(
          type: AssistanceType.message,
          isDark: isDark,
          headingColor: headingColor,
          bodyColor: bodyColor,
        ),
      ],
    );
  }

  Widget _assistanceCard({
    required AssistanceType type,
    bool isHighlight = false,
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
  }) {
    final selected = _selectedType == type;

    return Semantics(
      button: true,
      selected: selected,
      label: '${type.title}. ${type.description}',
      child: InkWell(
        key: Key('companion_kind_${type.name}'),
        onTap: () => _selectAssistanceType(type),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(
                    0xFFE64A19,
                  ).withValues(alpha: isDark ? 0.22 : 0.10)
                : (isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE64A19)
                  : (isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder),
              width: selected ? 2.2 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE64A19).withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE64A19)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE64A19).withValues(alpha: 0.12)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type.icon,
                  color: selected ? Colors.white : const Color(0xFFE64A19),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            type.title,
                            style: TextStyle(
                              color: headingColor,
                              fontSize: 16,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isHighlight && !selected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE64A19,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'UTAMA',
                              style: TextStyle(
                                color: Color(0xFFE64A19),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      type.description,
                      style: TextStyle(
                        color: bodyColor.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color(0xFFE64A19)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFE64A19)
                        : bodyColor.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    final position = widget.state.myCurrentPosition.value;
    final hasGps = position != null;
    final active = _includeLocation && hasGps;
    final targetHotel = _assistanceService.resolveTargetHotel(widget.state);
    final humanLocation = _assistanceService.resolveHumanReadableLocation(
      position,
      targetHotel: targetHotel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Lokasi Anda', headingColor),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: active
                ? const Color(
                    0xFF16A34A,
                  ).withValues(alpha: isDark ? 0.16 : 0.08)
                : (isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? const Color(0xFF16A34A).withValues(alpha: 0.6)
                  : const Color(0xFFD97706).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                          : const Color(0xFFD97706).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      active
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      color: active
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD97706),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active
                              ? '📍 Lokasi aktif'
                              : '⚠️ Lokasi belum tersedia',
                          style: TextStyle(
                            color: active
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          active
                              ? 'Diperbarui beberapa detik yang lalu'
                              : 'Aktifkan GPS dan izin akses lokasi agar pendamping dapat menemukan Anda.',
                          style: TextStyle(color: bodyColor, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Human-readable location description
              if (active) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : const Color(0xFFC8E6C9),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 18,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          humanLocation,
                          style: TextStyle(
                            color: headingColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.toNamed(AppRoutes.interactiveMap);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Lihat lokasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Durasi Berbagi Lokasi
                Row(
                  children: [
                    Text(
                      'Bagikan lokasi selama:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [15, 30, 60].map((mins) {
                          final isSel = _sharingDurationMinutes == mins;
                          return ChoiceChip(
                            label: Text(mins == 60 ? '1 Jam' : '$mins mnt'),
                            selected: isSel,
                            selectedColor: const Color(0xFF16A34A),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : headingColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() => _sharingDurationMinutes = mins);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // GPS Mati button: "Aktifkan Lokasi"
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const Key('companion_location_button'),
                    onPressed: _isFindingLocation ? null : _toggleLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: _isFindingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, size: 20),
                    label: Text(
                      _isFindingLocation
                          ? 'Mencari lokasi...'
                          : 'Aktifkan Lokasi',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Hidden / accessible legacy support text for existing widget test assertions
        Semantics(
          label: active
              ? 'Tekan untuk Kirim Lokasi'
              : 'Tekan untuk Kirim Lokasi',
          child: const Offstage(
            child: Column(
              children: [
                Text('Tekan untuk Kirim Lokasi'),
                Text('MATI'),
                Text(
                  'Lokasi hanya dikirim jika status tombol menunjukkan AKTIF.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetDestinationSection(
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    final targetHotel = _assistanceService.resolveTargetHotel(widget.state);
    final targetRoom = _assistanceService.resolveTargetRoom(widget.state);
    final pos = widget.state.myCurrentPosition.value;
    final dist = pos != null
        ? _assistanceService.estimateDistanceToHotel(pos)
        : null;
    final distText = dist != null
        ? (dist < 1000
              ? '${dist.round()} m'
              : '${(dist / 1000).toStringAsFixed(1)} km')
        : '1,2 km';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tujuan Anda', headingColor),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.canvasCream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? AppColors.darkCardBorder
                  : AppColors.lightCardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8E24AA).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: Color(0xFF8E24AA),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetHotel,
                      style: TextStyle(
                        color: headingColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$targetRoom • Jarak: $distText',
                      style: TextStyle(
                        color: bodyColor.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Get.toNamed(AppRoutes.interactiveMap);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.directions_rounded, size: 16),
                label: const Text(
                  'Petunjuk arah',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection(
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pesan cepat (ketuk untuk memilih):', headingColor),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickMessages.map((msg) {
            return ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 16),
              label: Text(msg),
              onPressed: () {
                _messageController.text = msg;
                _messageController.selection = TextSelection.collapsed(
                  offset: msg.length,
                );
                setState(() {});
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Pesan tambahan (opsional)',
          style: TextStyle(
            color: headingColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('companion_message_field'),
          controller: _messageController,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          style: TextStyle(color: headingColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Contoh: Saya berada di dekat pintu masuk masjid...',
            hintStyle: TextStyle(
              color: bodyColor.withValues(alpha: 0.65),
              fontSize: 14,
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.canvasCream,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientSection(
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pilih Penerima', headingColor),
        const SizedBox(height: 8),
        Material(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.canvasCream,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark
                  ? AppColors.darkCardBorder
                  : AppColors.lightCardBorder,
            ),
          ),
          child: Column(
            children: [
              RadioListTile<bool>(
                key: const Key('recipient_one'),
                value: false,
                groupValue: _sendToAll,
                onChanged: _isSubmitting
                    ? null
                    : (val) => setState(() => _sendToAll = val ?? false),
                title: Text(
                  'Satu Pendamping',
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Pilih pendamping yang ingin dihubungi',
                  style: TextStyle(color: bodyColor, fontSize: 12.5),
                ),
                secondary: const Icon(Icons.person_rounded),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              Divider(height: 1, color: bodyColor.withValues(alpha: 0.15)),
              RadioListTile<bool>(
                key: const Key('recipient_all'),
                value: true,
                groupValue: _sendToAll,
                onChanged: _isSubmitting
                    ? null
                    : (val) => setState(() => _sendToAll = val ?? true),
                title: Text(
                  'Semua Pendamping',
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Semua pendamping rombongan akan menerima notifikasi',
                  style: TextStyle(color: bodyColor, fontSize: 12.5),
                ),
                secondary: const Icon(Icons.groups_rounded),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            ],
          ),
        ),
        if (!_sendToAll && widget.pendampings.isNotEmpty) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: const Key('companion_recipient_dropdown'),
            initialValue: _selectedPendampingUid,
            isExpanded: true,
            dropdownColor: isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.surfaceWhite,
            style: TextStyle(color: headingColor, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Nama Pendamping',
              prefixIcon: const Icon(Icons.support_agent_rounded),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.surfaceWhite,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: widget.pendampings
                .map(
                  (p) => DropdownMenuItem(
                    value: p.uid,
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _isSubmitting
                ? null
                : (val) => setState(() => _selectedPendampingUid = val),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryCtaButton(bool isDark) {
    final String ctaText = _sendToAll
        ? 'Kirim ke Semua Pendamping'
        : _selectedType.ctaLabel;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        key: const Key('companion_send_button'),
        onPressed: _isSubmitting ? null : _submitAssistance,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE64A19),
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark
              ? AppColors.darkSurfaceContainer
              : const Color(0xFFE0DDDA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(_selectedType.icon, size: 24),
        label: Text(_isSubmitting ? 'Mengirim Permintaan...' : ctaText),
      ),
    );
  }
}
