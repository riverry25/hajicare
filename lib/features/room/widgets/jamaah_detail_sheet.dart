import '../../../core/locales/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../notification/widgets/notification_composer_dialog.dart';
import '../services/room_service.dart';

class JamaahDetailSheet extends StatefulWidget {
  final JamaahData jamaah;
  final String roomId;
  final String roomName;
  final String roomCode;
  final VoidCallback? onRemoved;

  const JamaahDetailSheet({
    super.key,
    required this.jamaah,
    required this.roomId,
    required this.roomName,
    required this.roomCode,
    this.onRemoved,
  });

  /// Shows the bottom modal sheet.
  static Future<void> show(
    BuildContext context, {
    required JamaahData jamaah,
    required String roomId,
    required String roomName,
    required String roomCode,
    VoidCallback? onRemoved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JamaahDetailSheet(
        jamaah: jamaah,
        roomId: roomId,
        roomName: roomName,
        roomCode: roomCode,
        onRemoved: onRemoved,
      ),
    );
  }

  @override
  State<JamaahDetailSheet> createState() => _JamaahDetailSheetState();
}

class _JamaahDetailSheetState extends State<JamaahDetailSheet> {
  final RoomService _roomService = RoomService();
  bool _isRemoving = false;

  bool _isLoadingUserData = true;
  String? _bloodType;
  String? _allergies;
  String? _conditions;
  String? _emergencyContact;
  String? _porsi;
  String? _passportNumber;
  String? _nik;
  bool _isMedicalExpanded = true;

  @override
  void initState() {
    super.initState();
    _porsi = widget.jamaah.porsi;
    _nik = widget.jamaah.nik;
    _bloodType = widget.jamaah.bloodType;
    _allergies = widget.jamaah.allergies;
    _conditions = widget.jamaah.conditions;
    _emergencyContact = widget.jamaah.emergencyContact;
    _passportNumber = widget.jamaah.passportNumber;

    _loadUserExtraData();
  }

  Future<void> _loadUserExtraData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.jamaah.id)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _bloodType = (data['bloodType'] as String?)?.trim();
            _allergies = (data['allergies'] as String?)?.trim();
            _conditions = (data['conditions'] as String?)?.trim();
            _emergencyContact = (data['emergencyContact'] as String?)?.trim();
            _porsi =
                ((data['porsi'] as String?) ?? (data['nomorPorsi'] as String?))
                    ?.trim();
            _passportNumber =
                ((data['passportNumber'] as String?) ??
                        (data['passport'] as String?))
                    ?.trim();
            _nik = (data['nik'] as String?)?.trim();
            _isLoadingUserData = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[JamaahDetailSheet] Error fetching user medical data: $e');
    }
    if (mounted) {
      setState(() => _isLoadingUserData = false);
    }
  }

  String _formatValue(String? val) {
    if (val == null || val.trim().isEmpty) return '-';
    return val.trim();
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return 'Menunggu lokasi...';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 30) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  AppStatusType _mapStatusType(DistanceTier tier) {
    switch (tier) {
      case DistanceTier.aman:
        return AppStatusType.safe;
      case DistanceTier.waspada:
        return AppStatusType.warning;
      case DistanceTier.terlalujJauh:
        return AppStatusType.danger;
    }
  }

  Future<void> _handleRemoveJamaah() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final actorRole = controller?.role == UserRole.admin
        ? 'admin'
        : 'pendamping';
    final actorName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (actorRole == 'admin' ? 'Admin' : 'Pendamping');

    AppAlert.confirm(
      context,
      title: context.tr('room.removeMemberTitle'),
      message: context.tr('room.removeConfirmMsg', {
        'name': widget.jamaah.name,
      }),
      confirmText: context.tr('room.removeAction'),
      cancelText: context.tr('common.cancel'),
      isDestructive: true,
      onConfirm: () async {
        setState(() => _isRemoving = true);
        try {
          await _roomService.removeJamaahFromRoom(
            roomId: widget.roomId,
            jamaahUid: widget.jamaah.id,
            actorUid: user.uid,
            actorName: actorName,
            actorRole: actorRole,
          );

          if (!mounted) return;
          Navigator.of(context).pop(); // Close bottom sheet

          AppAlert.success(
            context,
            title: context.tr('room.memberRemoved'),
            message: context.tr('room.memberRemovedDesc', {
              'name': widget.jamaah.name,
              'room': widget.roomName,
            }),
          );
          widget.onRemoved?.call();
        } catch (e) {
          if (!mounted) return;
          setState(() => _isRemoving = false);
          AppAlert.error(
            context,
            title: context.tr('room.memberRemoveFailed'),
            message: UserFeedbackMessage.from(
              e,
              fallback: 'Jamaah belum dapat dikeluarkan. Silakan coba lagi.',
            ),
          );
        }
      },
    );
  }

  void _handleSendPrivateNotification() {
    Navigator.of(context).pop(); // Close sheet first
    NotificationComposerDialog.show(
      context,
      initialScope: 'user',
      initialTargetUserId: widget.jamaah.id,
      initialTargetUserName: widget.jamaah.name,
      initialRoomId: widget.roomId,
      initialRoomName: widget.roomName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;
    final tierColor = widget.jamaah.tier.color;
    final initial = widget.jamaah.name.trim().isNotEmpty
        ? widget.jamaah.name.trim()[0].toUpperCase()
        : 'J';

    final controller = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final canViewMedical =
        controller?.role == UserRole.admin ||
        controller?.role == UserRole.pendamping;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Header: Avatar + Name + Close Button
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    AppColors.darkPrimaryContainer,
                                    AppColors.darkSurfaceContainerHighest,
                                  ]
                                : [
                                    AppColors.espressoDark,
                                    AppColors.primaryContainer,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
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
                            color: widget.jamaah.isGpsActive
                                ? AppColors.statusSafe
                                : AppColors.outline,
                            shape: BoxShape.circle,
                            border: Border.all(color: cardBg, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.jamaah.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusSafe.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                'Jamaah',
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.statusSafe,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (widget.jamaah.sosActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sosEmergency,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: const Text(
                                  'SOS DARURAT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: bodyColor,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Status & Radar Overview Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.goldLight.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jarak ke Pendamping',
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  widget.jamaah.distanceValue,
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: tierColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.jamaah.distanceUnit,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: bodyColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        AppStatusBadge(
                          label: widget.jamaah.isGpsActive
                              ? context.tr('statusSafe')
                              : 'GPS Mati',
                          statusType: _mapStatusType(widget.jamaah.tier),
                          icon: widget.jamaah.tier.icon,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: bodyColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Sinkron: ${_formatTimestamp(widget.jamaah.locationUpdatedAt)}',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: bodyColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                widget.jamaah.isGpsActive
                                    ? Icons.gps_fixed_rounded
                                    : Icons.gps_off_rounded,
                                size: 16,
                                color: widget.jamaah.isGpsActive
                                    ? AppColors.statusSafe
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.jamaah.isGpsActive
                                    ? 'Sensor Aktif'
                                    : 'Sensor Mati',
                                style: AppTypography.captionSmall.copyWith(
                                  color: widget.jamaah.isGpsActive
                                      ? AppColors.statusSafe
                                      : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Room Membership Info Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.roomName,
                          style: AppTypography.bodySmall.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Kode: ${widget.roomCode}',
                      style: AppTypography.captionSmall.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Data Medis & Dokumen (Read-Only for Pendamping & Admin)
              if (canViewMedical) ...[
                const SizedBox(height: AppSpacing.md),
                _buildMedicalProfileCard(context),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Action 1: Kirim Notifikasi Pribadi
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  elevation: 0,
                ),
                onPressed: _isRemoving ? null : _handleSendPrivateNotification,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Kirim Notifikasi Langsung',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Action 2: Keluarkan dari Room (Destructive)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: _isRemoving ? null : _handleRemoveJamaah,
                icon: _isRemoving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.error,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.person_remove_rounded, size: 18),
                label: Text(
                  _isRemoving ? 'Mengeluarkan...' : 'Keluarkan dari Room',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalProfileCard(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.canvasCream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : AppColors.goldLight.withValues(alpha: 0.35),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Title + Read-Only indicator + Expand/Collapse Button
            InkWell(
              onTap: () {
                setState(() {
                  _isMedicalExpanded = !_isMedicalExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.sosEmergency.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_information_rounded,
                        size: 16,
                        color: AppColors.sosEmergency,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Data Medis & Dokumen',
                            style: AppTypography.titleSmall.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              'Hanya Lihat',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isMedicalExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: bodyColor,
                    ),
                  ],
                ),
              ),
            ),

            if (_isMedicalExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: _isLoadingUserData
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          _buildMedicalInfoRow(
                            context: context,
                            icon: Icons.credit_card_rounded,
                            label: context.tr('profile.nik'),
                            value: _formatValue(_nik),
                          ),
                          const Divider(height: 8),
                          _buildMedicalInfoRow(
                            context: context,
                            icon: Icons.confirmation_number_outlined,
                            label: context.tr('profile.portionNumber'),
                            value: _formatValue(_porsi),
                          ),
                          const Divider(height: 8),
                          _buildMedicalInfoRow(
                            context: context,
                            icon: Icons.badge_outlined,
                            label: context.tr('profile.passportNumber'),
                            value: _formatValue(_passportNumber),
                          ),
                          const Divider(height: 8),
                          _buildMedicalInfoRow(
                            context: context,
                            icon: Icons.bloodtype_rounded,
                            iconColor: AppColors.sosEmergency,
                            label: context.tr('profile.bloodType'),
                            value: _formatValue(_bloodType),
                          ),
                          const Divider(height: 8),
                          _buildMedicalInfoRow(
                            context: context,
                            icon: Icons.warning_amber_rounded,
                            iconColor: AppColors.statusWarning,
                            label: context.tr('profile.allergyHistory'),
                            value: _formatValue(_allergies),
                          ),
                          const Divider(height: 8),
                          _buildMedicalInfoRow(
                            context: context,
                            icon: Icons.healing_rounded,
                            iconColor: primaryColor,
                            label: context.tr('profile.specialConditions'),
                            value: _formatValue(_conditions),
                          ),
                          const Divider(height: 8),
                          _buildMedicalInfoRow(
                            context: context,
                            icon: Icons.phone_in_talk_rounded,
                            iconColor: AppColors.statusSafe,
                            label: context.tr('profile.emergencyContact'),
                            value: _formatValue(_emergencyContact),
                            isLast: true,
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    bool isLast = false,
  }) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;
    final isEmpty = value == '-' || value.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              icon,
              size: 15,
              color: iconColor ?? primaryColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: bodyColor.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodySmall.copyWith(
                color: isEmpty
                    ? (isDark ? Colors.white38 : AppColors.textMuted)
                    : headingColor,
                fontWeight: isEmpty ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
