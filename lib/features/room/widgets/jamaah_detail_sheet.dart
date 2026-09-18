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

    final controller = Get.isRegistered<HajiCareController>() ? Get.find<HajiCareController>() : null;
    final actorRole = controller?.role == UserRole.admin ? 'admin' : 'pendamping';
    final actorName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (actorRole == 'admin' ? 'Admin' : 'Pendamping');

    AppAlert.confirm(
      context,
      title: 'Keluarkan Jamaah?',
      message: 'Jamaah ini akan dikeluarkan dari room dan fitur yang membutuhkan room akan dinonaktifkan.',
      confirmText: 'Keluarkan',
      cancelText: 'Batal',
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
            title: 'Jamaah Dikeluarkan',
            message: '${widget.jamaah.name} telah berhasil dikeluarkan dari room "${widget.roomName}".',
          );
          widget.onRemoved?.call();
        } catch (e) {
          if (!mounted) return;
          setState(() => _isRemoving = false);
          AppAlert.error(
            context,
            title: 'Gagal Mengeluarkan',
            message: e.toString().replaceAll('Exception: ', ''),
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
    final initial = widget.jamaah.name.trim().isNotEmpty ? widget.jamaah.name.trim()[0].toUpperCase() : 'J';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                color: isDark ? AppColors.darkOutlineVariant : AppColors.surfaceVariant,
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
                            ? [AppColors.darkPrimaryContainer, AppColors.darkSurfaceContainerHighest]
                            : [AppColors.espressoDark, AppColors.primaryContainer],
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
                        color: widget.jamaah.isGpsActive ? AppColors.statusSafe : AppColors.outline,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cardBg,
                          width: 2,
                        ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.statusSafe.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sosEmergency,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
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
              color: isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.goldLight.withValues(alpha: 0.4),
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
                          style: AppTypography.captionSmall.copyWith(color: bodyColor),
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
                      label: widget.jamaah.isGpsActive ? context.tr('statusSafe') : 'GPS Mati',
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
                          Icon(Icons.schedule_rounded, size: 16, color: bodyColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sinkron: ${_formatTimestamp(widget.jamaah.locationUpdatedAt)}',
                              style: AppTypography.captionSmall.copyWith(color: bodyColor),
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
                            widget.jamaah.isGpsActive ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                            size: 16,
                            color: widget.jamaah.isGpsActive ? AppColors.statusSafe : AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.jamaah.isGpsActive ? 'Sensor Aktif' : 'Sensor Mati',
                            style: AppTypography.captionSmall.copyWith(
                              color: widget.jamaah.isGpsActive ? AppColors.statusSafe : AppColors.error,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      widget.roomName,
                      style: AppTypography.bodySmall.copyWith(color: headingColor, fontWeight: FontWeight.bold),
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
          const SizedBox(height: AppSpacing.lg),

          // Action 1: Kirim Notifikasi Pribadi
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              elevation: 0,
            ),
            onPressed: _isRemoving ? null : _handleSendPrivateNotification,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Kirim Notifikasi Langsung', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Action 2: Keluarkan dari Room (Destructive)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: _isRemoving ? null : _handleRemoveJamaah,
            icon: _isRemoving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2),
                  )
                : const Icon(Icons.person_remove_rounded, size: 18),
            label: Text(
              _isRemoving ? 'Mengeluarkan...' : 'Keluarkan dari Room',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
