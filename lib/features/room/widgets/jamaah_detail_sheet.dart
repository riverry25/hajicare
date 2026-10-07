import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../services/room_service.dart';

/// Modal bottom sheet displaying Jamaah details matching the reference
/// style of `_showMemberDetailModal` in `room_detail_screen.dart`.
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
    final isDark = AppColors.isDark(context);
    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
  DateTime? _joinedAt;

  @override
  void initState() {
    super.initState();
    _loadJoinedAt();
  }

  Future<void> _loadJoinedAt() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('members')
          .doc(widget.jamaah.id)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          final rawTimestamp = data['joinedAt'];
          DateTime? dt;
          if (rawTimestamp is Timestamp) {
            dt = rawTimestamp.toDate();
          } else if (rawTimestamp is DateTime) {
            dt = rawTimestamp;
          }
          if (dt != null && mounted) {
            setState(() {
              _joinedAt = dt;
            });
          }
        }
      }
    } catch (_) {}
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Tidak diketahui';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _getLocationStatus([DateTime? now]) {
    final loc = widget.jamaah.currentLocation;
    final time = widget.jamaah.locationUpdatedAt;
    if (loc == null || time == null) {
      return 'Lokasi belum tersedia';
    }
    final currentTime = now ?? DateTime.now();
    final diff = currentTime.difference(time);
    final seconds = diff.inSeconds;

    if (seconds <= 30) {
      return 'Online';
    } else if (seconds <= 120) {
      return 'Terakhir terlihat $seconds dtk lalu';
    } else {
      return 'Lokasi tidak diperbarui';
    }
  }

  void _handleViewOnMap() {
    Navigator.of(context).pop();
    if (Get.currentRoute == AppRoutes.roomDetail) {
      Get.back();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changeTab(1);
      Future.delayed(const Duration(milliseconds: 250), () {
        if (Get.isRegistered<MapController>()) {
          Get.find<MapController>().focusOnJamaah(
            widget.jamaah,
            autoRoute: false,
          );
        }
      });
    } else if (Get.isRegistered<MapController>()) {
      Get.find<MapController>().focusOnJamaah(widget.jamaah, autoRoute: false);
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

    HapticFeedback.mediumImpact();
    AppAlert.confirm(
      context,
      title: context.tr('room.removeMemberTitle'),
      message: 'Keluarkan "${widget.jamaah.name}" dari rombongan ini?',
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
          Navigator.of(context).pop();

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

  Widget _buildModalInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color headingColor,
    required Color bodyColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: bodyColor.withValues(alpha: 0.7),
                fontSize: 10.5,
              ),
            ),
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: headingColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;
    final initial = widget.jamaah.name.trim().isNotEmpty
        ? widget.jamaah.name.trim()[0].toUpperCase()
        : '?';

    final controller = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final canManage =
        controller?.role == UserRole.admin ||
        controller?.role == UserRole.pendamping;
    final hasLocation = widget.jamaah.currentLocation != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: bodyColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Avatar + Name + JAMAAH Badge
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.emeraldIslamic.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.emeraldIslamic,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.jamaah.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldIslamic.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'JAMAAH',
                          style: TextStyle(
                            color: AppColors.emeraldIslamic,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info tiles matching reference
            _buildModalInfoTile(
              icon: Icons.access_time_rounded,
              label: context.tr('room.attendanceStatus'),
              value: _getLocationStatus(),
              color: primaryColor,
              headingColor: headingColor,
              bodyColor: bodyColor,
            ),
            const SizedBox(height: 10),
            _buildModalInfoTile(
              icon: Icons.calendar_today_rounded,
              label: context.tr('room.joinDate'),
              value: _joinedAt != null
                  ? _formatDate(_joinedAt)
                  : 'Tidak diketahui',
              color: primaryColor,
              headingColor: headingColor,
              bodyColor: bodyColor,
            ),
            if (hasLocation) ...[
              const SizedBox(height: 10),
              _buildModalInfoTile(
                icon: Icons.location_on_rounded,
                label: context.tr('room.locationCoordinates'),
                value:
                    '${widget.jamaah.currentLocation!.latitude.toStringAsFixed(5)}, ${widget.jamaah.currentLocation!.longitude.toStringAsFixed(5)}',
                color: primaryColor,
                headingColor: headingColor,
                bodyColor: bodyColor,
              ),
            ],

            const SizedBox(height: 20),

            // Action buttons matching reference
            Row(
              children: [
                if (hasLocation)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleViewOnMap,
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('Lihat di Peta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (hasLocation && canManage) const SizedBox(width: 10),
                if (canManage)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isRemoving ? null : _handleRemoveJamaah,
                      icon: _isRemoving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.person_remove_rounded, size: 16),
                      label: const Text('Keluarkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
