import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
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
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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

  String _getDistanceText() {
    if (widget.jamaah.currentLocation == null) return 'Lokasi belum tersedia';
    Position? userPos;
    if (Get.isRegistered<HajiCareController>()) {
      userPos = Get.find<HajiCareController>().myCurrentPosition.value;
    }
    double? userLat = userPos?.latitude;
    double? userLng = userPos?.longitude;

    if (userLat == null && Get.isRegistered<MapController>()) {
      final mapLoc = Get.find<MapController>().currentUserLocation.value;
      if (mapLoc != null) {
        userLat = mapLoc.latitude;
        userLng = mapLoc.longitude;
      }
    }

    if (userLat == null || userLng == null) {
      return 'Belum terdeteksi';
    }

    final meters = Geolocator.distanceBetween(
      userLat,
      userLng,
      widget.jamaah.currentLocation!.latitude,
      widget.jamaah.currentLocation!.longitude,
    );

    if (meters < 1000) {
      return '±${meters.toStringAsFixed(0)} m dari Anda';
    } else {
      return '±${(meters / 1000).toStringAsFixed(1)} km dari Anda';
    }
  }

  Widget _buildDetailHorizontalRow({
    required String label,
    String? valueText,
    Widget? valueWidget,
    Color? headingColor,
    required Color bodyColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: bodyColor.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child:
              valueWidget ??
              Text(
                valueText ?? '-',
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
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
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final dividerColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.canvasCreamSubtle;
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

    final roleBadgeBg = isDark
        ? AppColors.emeraldIslamic.withValues(alpha: 0.25)
        : AppColors.statusSafe.withValues(alpha: 0.12);
    final roleBadgeTextColor = isDark
        ? const Color(0xFF6EE7B7)
        : AppColors.statusSafe;

    final distanceText = _getDistanceText();

    final actionBtnBg = isDark
        ? AppColors.darkPrimary
        : AppColors.emeraldIslamic;
    final actionBtnFg = isDark ? AppColors.darkOnPrimary : Colors.white;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Card Container ──
            Container(
              margin: const EdgeInsets.only(top: 36),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: dividerColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Space for overlapping floating avatar
                  const SizedBox(height: 48),

                  // Member Name (centered like title in reference)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      widget.jamaah.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Role Badge (centered like subtitle in reference)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: roleBadgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'JAMAAH',
                        style: TextStyle(
                          color: roleBadgeTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Horizontal Data Rows (matching Image 1 layout) ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Row 1: Attendance Status
                        _buildDetailHorizontalRow(
                          label: context.tr('room.attendanceStatus'),
                          valueWidget: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasLocation
                                      ? AppColors.emeraldIslamic
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getLocationStatus(),
                                style: TextStyle(
                                  color: headingColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          bodyColor: bodyColor,
                        ),
                        Divider(
                          height: 22,
                          thickness: 0.8,
                          color: dividerColor,
                        ),

                        // Row 2: Distance from User (Jarak)
                        _buildDetailHorizontalRow(
                          label: 'Jarak dari Anda',
                          valueText: distanceText,
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                        ),
                        Divider(
                          height: 22,
                          thickness: 0.8,
                          color: dividerColor,
                        ),

                        // Row 3: Join Date
                        _buildDetailHorizontalRow(
                          label: context.tr('room.joinDate'),
                          valueText: _joinedAt != null
                              ? _formatDate(_joinedAt)
                              : 'Tidak diketahui',
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                        ),

                        // Row 4: Coordinates (if available)
                        if (hasLocation) ...[
                          Divider(
                            height: 22,
                            thickness: 0.8,
                            color: dividerColor,
                          ),
                          _buildDetailHorizontalRow(
                            label: context.tr('room.locationCoordinates'),
                            valueText:
                                '${widget.jamaah.currentLocation!.latitude.toStringAsFixed(5)}, ${widget.jamaah.currentLocation!.longitude.toStringAsFixed(5)}',
                            headingColor: headingColor,
                            bodyColor: bodyColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // ── Bottom Action Button(s) (Image 1 "Get Directions" style) ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        if (hasLocation)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _handleViewOnMap,
                              icon: const Icon(Icons.near_me_rounded, size: 18),
                              label: const Text(
                                'Lihat di Peta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: actionBtnBg,
                                foregroundColor: actionBtnFg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        if (canManage) ...[
                          if (hasLocation) const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: _isRemoving
                                  ? null
                                  : _handleRemoveJamaah,
                              icon: _isRemoving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.error,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_remove_rounded,
                                      size: 16,
                                    ),
                              label: const Text(
                                'Keluarkan dari Rombongan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                  color: AppColors.error.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Overlapping Circular Avatar (top center) ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.emeraldIslamic,
                    border: Border.all(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.14,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
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
