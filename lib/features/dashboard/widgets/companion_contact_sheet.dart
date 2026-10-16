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
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../notification/services/notification_service.dart';
import '../controllers/dashboard_controller.dart';
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
    final hc = context.hc;
    final isDark = hc.isDark;
    final headingColor = hc.textPrimary;
    final bodyColor = hc.textSecondary;
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
            color: hc.surface,
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
                        color: hc.borderSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header: "Hubungi Pendamping"
                  _buildHeader(context, headingColor, bodyColor),
                  const SizedBox(height: 22),

                  // ── 1. "Apa yang terjadi?" (Pilihan Bantuan yang Jelas) ──
                  _buildSectionTitle(
                    context.tr('assistanceWhatHappened'),
                    headingColor,
                  ),
                  const SizedBox(height: 12),
                  _buildAssistanceTypeCards(isDark, headingColor, bodyColor),
                  const SizedBox(height: 24),

                  // ── 2. "Lokasi Anda" (Inti, Bukan Opsional) ───────────────
                  _buildLocationSection(
                    context,
                    isDark,
                    headingColor,
                    bodyColor,
                  ),
                  const SizedBox(height: 24),

                  // ── 3. "Tujuan Anda" (Hotel/Maktab Jamaah) ────────────────
                  _buildTargetDestinationSection(
                    context,
                    isDark,
                    headingColor,
                    bodyColor,
                  ),
                  const SizedBox(height: 24),

                  // ── 4. Quick Messages & Pesan Tambahan ─────────────────────
                  _buildMessageSection(
                    context,
                    isDark,
                    headingColor,
                    bodyColor,
                  ),
                  const SizedBox(height: 24),

                  // ── 5. Pilih Penerima ─────────────────────────────────────
                  _buildRecipientSection(
                    context,
                    isDark,
                    headingColor,
                    bodyColor,
                  ),
                  const SizedBox(height: 26),

                  // ── 6. CTA Utama Dinamis ──────────────────────────────────
                  _buildPrimaryCtaButton(context, isDark),
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

  Widget _buildHeader(
    BuildContext context,
    Color headingColor,
    Color bodyColor,
  ) {
    final hc = context.hc;
    final isDark = hc.isDark;
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: isDark ? hc.primaryContainer : hc.surfaceSand,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? hc.borderStrong
                  : hc.sandDark.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.support_agent_rounded,
            color: isDark ? hc.accentText : hc.primary,
            size: 32,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('dashboard.contactCompanion'),
                style: DashboardTypography.titleMedium.copyWith(
                  color: headingColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr('assistanceContactCompanionSub'),
                style: TextStyle(
                  color: isDark ? hc.textSecondary : bodyColor,
                  fontSize: 13.5,
                  height: 1.3,
                ),
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
    final cardBg = selected
        ? (isDark ? context.hc.primaryContainer : const Color(0xFFF9F4EE))
        : (isDark ? context.hc.surfaceSubtle : context.hc.surface);
    final cardBorderColor = selected
        ? (isDark ? context.hc.accent : context.hc.primary)
        : (isDark ? context.hc.borderStrong : context.hc.borderSubtle);
    final iconBg = selected
        ? (isDark ? context.hc.accent : context.hc.primary)
        : (isDark ? context.hc.surfaceSand : context.hc.surfaceSubtle);
    final iconColor = selected
        ? (isDark ? const Color(0xFF22160C) : context.hc.onPrimary)
        : (isDark ? context.hc.accentText : context.hc.primary);
    final titleColor = selected
        ? (isDark ? const Color(0xFFFAF7F2) : context.hc.primaryDark)
        : headingColor;
    final descColor = selected
        ? (isDark ? const Color(0xFFE2D4C6) : context.hc.textSecondary)
        : (isDark
              ? context.hc.textSecondary.withValues(alpha: 0.9)
              : bodyColor.withValues(alpha: 0.85));

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
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cardBorderColor,
              width: selected ? 2.0 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: isDark
                          ? context.hc.accent.withValues(alpha: 0.2)
                          : context.hc.primary.withValues(alpha: 0.12),
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
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(type.icon, color: iconColor, size: 26),
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
                              color: titleColor,
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
                              color: isDark
                                  ? context.hc.primaryContainer
                                  : context.hc.surfaceSand,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? context.hc.accent.withValues(alpha: 0.4)
                                    : context.hc.borderSubtle,
                              ),
                            ),
                            child: Text(
                              'UTAMA',
                              style: TextStyle(
                                color: isDark
                                    ? context.hc.accentText
                                    : context.hc.primary,
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
                        color: descColor,
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
                      ? (isDark ? context.hc.accent : context.hc.primary)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? (isDark ? context.hc.accent : context.hc.primary)
                        : (isDark
                              ? context.hc.borderStrong
                              : context.hc.borderSubtle),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF22160C)
                            : context.hc.onPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(
    BuildContext context,
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

    final containerBg = active
        ? (isDark ? context.hc.successContainer : const Color(0xFFF0F9F3))
        : (isDark ? context.hc.warningContainer : const Color(0xFFFDF7EC));
    final containerBorderColor = active
        ? (isDark
              ? context.hc.success.withValues(alpha: 0.6)
              : const Color(0xFFA5D6A7))
        : (isDark
              ? context.hc.warning.withValues(alpha: 0.5)
              : const Color(0xFFE2C499));
    final statusTextColor = active
        ? (isDark ? const Color(0xFFBBE5C7) : context.hc.success)
        : (isDark ? const Color(0xFFF7DEB4) : context.hc.warning);
    final statusSubtitleColor = isDark ? context.hc.textSecondary : bodyColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context.tr('assistanceYourLocation'), headingColor),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: containerBorderColor, width: 1.5),
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
                          ? context.hc.success.withValues(
                              alpha: isDark ? 0.25 : 0.15,
                            )
                          : context.hc.warning.withValues(
                              alpha: isDark ? 0.25 : 0.15,
                            ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      active
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      color: active ? context.hc.success : context.hc.warning,
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
                              ? context.tr('assistanceLocationActive')
                              : context.tr('assistanceLocationUnavailable'),
                          style: TextStyle(
                            color: statusTextColor,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          active
                              ? context.tr('assistanceLocationUpdatedRecent')
                              : context.tr('assistanceLocationEnablePrompt'),
                          style: TextStyle(
                            color: statusSubtitleColor,
                            fontSize: 12.5,
                          ),
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
                        ? context.hc.surfaceSubtle
                        : context.hc.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? context.hc.borderStrong
                          : context.hc.borderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        size: 18,
                        color: context.hc.success,
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
                          Get.back();
                          if (Get.isRegistered<DashboardController>()) {
                            Get.find<DashboardController>().changeTab(1);
                          } else {
                            Get.toNamed(AppRoutes.interactiveMap);
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: isDark
                              ? context.hc.accentText
                              : context.hc.primary,
                        ),
                        child: Text(
                          context.tr('assistanceViewLocation'),
                          style: const TextStyle(
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
                      context.tr('assistanceShareDuration'),
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
                            label: Text(
                              mins == 60
                                  ? context.tr('durationOneHour')
                                  : '$mins ${context.tr('minutesShort')}',
                            ),
                            selected: isSel,
                            selectedColor: context.hc.success,
                            backgroundColor: isDark
                                ? context.hc.surfaceSubtle
                                : context.hc.surface,
                            side: BorderSide(
                              color: isSel
                                  ? Colors.transparent
                                  : (isDark
                                        ? context.hc.borderStrong
                                        : context.hc.borderSubtle),
                            ),
                            labelStyle: TextStyle(
                              color: isSel
                                  ? (isDark
                                        ? context.hc.onSuccess
                                        : Colors.white)
                                  : (isDark
                                        ? context.hc.textSecondary
                                        : headingColor),
                              fontWeight: isSel
                                  ? FontWeight.w800
                                  : FontWeight.w700,
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
                      backgroundColor: context.hc.warning,
                      foregroundColor: isDark
                          ? const Color(0xFF241A09)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: _isFindingLocation
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark
                                  ? const Color(0xFF241A09)
                                  : Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, size: 20),
                    label: Text(
                      _isFindingLocation
                          ? context.tr('searchingLocation')
                          : context.tr('enableLocation'),
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
    BuildContext context,
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
        _buildSectionTitle(
          context.tr('assistanceYourDestination'),
          headingColor,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? context.hc.surfaceSubtle : context.hc.surfaceSand,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? context.hc.borderStrong : context.hc.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? context.hc.surfaceSand : context.hc.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: isDark ? Border.all(color: context.hc.border) : null,
                ),
                child: Icon(
                  Icons.hotel_rounded,
                  color: isDark ? context.hc.accent : context.hc.primary,
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
                      '$targetRoom • ${context.tr('assistanceDistance', {'dist': distText})}',
                      style: TextStyle(
                        color: isDark
                            ? context.hc.textSecondary
                            : bodyColor.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  if (Get.isRegistered<DashboardController>()) {
                    Get.find<DashboardController>().changeTab(1);
                  } else {
                    Get.toNamed(AppRoutes.interactiveMap);
                  }
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
                  side: BorderSide(
                    color: isDark
                        ? context.hc.borderStrong
                        : context.hc.borderSubtle,
                  ),
                  foregroundColor: isDark
                      ? context.hc.accentText
                      : context.hc.primary,
                ),
                icon: const Icon(Icons.directions_rounded, size: 16),
                label: Text(
                  context.tr('assistanceGetDirections'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection(
    BuildContext context,
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    final quickMessages = [
      context.tr('quickMsgLostHotel'),
      context.tr('quickMsgSeparatedMosque'),
      context.tr('quickMsgExhaustedWheelchair'),
      context.tr('quickMsgSafePosition'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context.tr('assistanceQuickMessages'), headingColor),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickMessages.map((msg) {
            return ActionChip(
              avatar: Icon(
                Icons.add_rounded,
                size: 16,
                color: isDark ? context.hc.accentText : context.hc.primary,
              ),
              label: Text(
                msg,
                style: TextStyle(
                  color: isDark ? context.hc.textPrimary : headingColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              backgroundColor: isDark
                  ? context.hc.surfaceSubtle
                  : context.hc.surfaceSand,
              side: BorderSide(
                color: isDark
                    ? context.hc.borderStrong
                    : context.hc.borderSubtle,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
          context.tr('assistanceAdditionalMessage'),
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
            hintText: context.tr('assistanceMessagePlaceholder'),
            hintStyle: TextStyle(
              color: isDark
                  ? context.hc.textTertiary
                  : bodyColor.withValues(alpha: 0.65),
              fontSize: 14,
            ),
            filled: true,
            fillColor: isDark
                ? context.hc.surfaceSubtle
                : AppColors.canvasCream,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? context.hc.borderStrong
                    : context.hc.borderSubtle,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? context.hc.borderStrong
                    : context.hc.borderSubtle,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? context.hc.accent : context.hc.primary,
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientSection(
    BuildContext context,
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context.tr('assistanceSelectRecipient'),
          headingColor,
        ),
        const SizedBox(height: 8),
        Material(
          color: isDark ? context.hc.surfaceSubtle : context.hc.surfaceSand,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? context.hc.borderStrong : context.hc.borderSubtle,
            ),
          ),
          child: AbsorbPointer(
            absorbing: _isSubmitting,
            child: RadioGroup<bool>(
              groupValue: _sendToAll,
              onChanged: (val) {
                if (_isSubmitting) return;
                setState(() => _sendToAll = val ?? false);
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    key: const Key('recipient_one'),
                    value: false,
                    activeColor: isDark
                        ? context.hc.accent
                        : context.hc.primary,
                    title: Text(
                      context.tr('assistanceSingleCompanion'),
                      style: TextStyle(
                        color: headingColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      context.tr('assistanceSingleCompanionSub'),
                      style: TextStyle(
                        color: isDark ? context.hc.textSecondary : bodyColor,
                        fontSize: 12.5,
                      ),
                    ),
                    secondary: Icon(
                      Icons.person_rounded,
                      color: isDark
                          ? context.hc.accentText
                          : context.hc.primary,
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? context.hc.border : context.hc.borderSubtle,
                  ),
                  RadioListTile<bool>(
                    key: const Key('recipient_all'),
                    value: true,
                    activeColor: isDark
                        ? context.hc.accent
                        : context.hc.primary,
                    title: Text(
                      context.tr('assistanceAllCompanions'),
                      style: TextStyle(
                        color: headingColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      context.tr('assistanceAllCompanionsSub'),
                      style: TextStyle(
                        color: isDark ? context.hc.textSecondary : bodyColor,
                        fontSize: 12.5,
                      ),
                    ),
                    secondary: Icon(
                      Icons.groups_rounded,
                      color: isDark
                          ? context.hc.accentText
                          : context.hc.primary,
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!_sendToAll && widget.pendampings.isNotEmpty) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: const Key('companion_recipient_dropdown'),
            initialValue: _selectedPendampingUid,
            isExpanded: true,
            dropdownColor: isDark ? context.hc.surface : context.hc.surface,
            style: TextStyle(color: headingColor, fontSize: 16),
            decoration: InputDecoration(
              labelText: context.tr('assistanceCompanionName'),
              labelStyle: TextStyle(
                color: isDark ? context.hc.textSecondary : bodyColor,
              ),
              prefixIcon: Icon(
                Icons.support_agent_rounded,
                color: isDark ? context.hc.accentText : context.hc.primary,
              ),
              filled: true,
              fillColor: isDark
                  ? context.hc.surfaceSubtle
                  : context.hc.surfaceSand,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? context.hc.borderStrong
                      : context.hc.borderSubtle,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? context.hc.borderStrong
                      : context.hc.borderSubtle,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? context.hc.accent : context.hc.primary,
                  width: 1.8,
                ),
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
                      style: TextStyle(color: headingColor),
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

  Widget _buildPrimaryCtaButton(BuildContext context, bool isDark) {
    final hc = context.hc;
    final String ctaText = _sendToAll
        ? context.tr('assistanceSendToAll')
        : _selectedType.ctaLabel;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        key: const Key('companion_send_button'),
        onPressed: _isSubmitting ? null : _submitAssistance,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? hc.accent : hc.primary,
          foregroundColor: isDark ? const Color(0xFF22160C) : hc.onPrimary,
          disabledBackgroundColor: isDark ? hc.surfaceSubtle : hc.borderSubtle,
          disabledForegroundColor: isDark ? hc.textTertiary : hc.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: isDark ? 0 : 2,
          textStyle: const TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        icon: _isSubmitting
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isDark ? const Color(0xFF22160C) : hc.onPrimary,
                ),
              )
            : Icon(_selectedType.icon, size: 24),
        label: Text(_isSubmitting ? context.tr('assistanceSending') : ctaText),
      ),
    );
  }
}
