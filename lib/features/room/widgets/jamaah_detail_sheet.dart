import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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
/// style of HajiCare with complete Pilgrim Medical Data & History integration.
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
  StreamSubscription<DocumentSnapshot>? _userDocSub;
  Map<String, dynamic>? _userFirestoreData;

  bool _isRemoving = false;
  DateTime? _joinedAt;

  @override
  void initState() {
    super.initState();
    _loadJoinedAt();
    _subscribeUserData();
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    super.dispose();
  }

  void _subscribeUserData() {
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.jamaah.id)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists && mounted) {
              setState(() {
                _userFirestoreData = doc.data();
              });
            }
          },
          onError: (e) {
            debugPrint('[JamaahDetailSheet] Error loading user doc: $e');
          },
        );
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

  // ── Resolved Data Getters ──────────────────────────────────────────────────

  String get _resolvedName =>
      (_userFirestoreData?['name'] as String?)?.trim() ??
      (_userFirestoreData?['displayName'] as String?)?.trim() ??
      widget.jamaah.name;

  String get _resolvedRole =>
      (_userFirestoreData?['role'] as String?)?.trim() ??
      widget.jamaah.role ??
      'jamaah';

  String? get _resolvedKloter =>
      (_userFirestoreData?['kloter'] as String?)?.trim() ??
      widget.jamaah.kloter;

  String? get _resolvedMaktab =>
      (_userFirestoreData?['maktab'] as String?)?.trim() ??
      widget.jamaah.maktab;

  String? get _resolvedBloodType =>
      (_userFirestoreData?['bloodType'] as String?)?.trim() ??
      widget.jamaah.bloodType;

  String? get _resolvedAllergies =>
      (_userFirestoreData?['allergies'] as String?)?.trim() ??
      widget.jamaah.allergies;

  String? get _resolvedConditions =>
      (_userFirestoreData?['conditions'] as String?)?.trim() ??
      widget.jamaah.conditions;

  String? get _resolvedEmergencyContact =>
      (_userFirestoreData?['emergencyContact'] as String?)?.trim() ??
      widget.jamaah.emergencyContact;

  String? get _resolvedNik =>
      (_userFirestoreData?['nik'] as String?)?.trim() ?? widget.jamaah.nik;

  String? get _resolvedPorsi =>
      ((_userFirestoreData?['nomorPorsi'] as String?) ??
              (_userFirestoreData?['porsi'] as String?))
          ?.trim() ??
      widget.jamaah.porsi;

  String? get _resolvedPassport =>
      ((_userFirestoreData?['passportNumber'] as String?) ??
              (_userFirestoreData?['passport'] as String?))
          ?.trim() ??
      widget.jamaah.passportNumber;

  String? get _resolvedEmail =>
      (_userFirestoreData?['email'] as String?)?.trim() ?? widget.jamaah.email;

  bool get _resolvedSosActive =>
      (_userFirestoreData?['sosActive'] as bool?) ?? widget.jamaah.sosActive;

  GeoPoint? get _resolvedLocation =>
      (_userFirestoreData?['currentLocation'] as GeoPoint?) ??
      widget.jamaah.currentLocation;

  DateTime? get _resolvedLocationTime {
    final raw =
        _userFirestoreData?['locationUpdatedAt'] ??
        _userFirestoreData?['updatedAt'];
    if (raw is Timestamp) return raw.toDate();
    return widget.jamaah.locationUpdatedAt;
  }

  // ── Actions & Helpers ──────────────────────────────────────────────────────

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
    final loc = _resolvedLocation;
    final time = _resolvedLocationTime;
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

  String _getDistanceText() {
    final loc = _resolvedLocation;
    if (loc == null) return 'Lokasi belum tersedia';
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
      loc.latitude,
      loc.longitude,
    );

    if (meters < 1000) {
      return '±${meters.toStringAsFixed(0)} m dari Anda';
    } else {
      return '±${(meters / 1000).toStringAsFixed(1)} km dari Anda';
    }
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin: $value'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNumber.isEmpty) return;
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          AppAlert.warning(
            context,
            title: 'Gagal Membuka Panggilan',
            message: 'Tidak dapat melakukan panggilan ke nomor $phoneNumber.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppAlert.warning(
          context,
          title: 'Gagal Membuka Panggilan',
          message: 'Terjadi kesalahan saat memanggil $phoneNumber: $e',
        );
      }
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
      message: 'Keluarkan "$_resolvedName" dari rombongan ini?',
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
              'name': _resolvedName,
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

  /// Opens the dedicated "Pilgrim Medical Data & History" bottom sheet
  /// matching reference Image 2.
  void _showFullMedicalBottomSheet(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.canvasCream;
    final dividerColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.canvasCreamSubtle;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.canvasCreamSubtle,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Medical Icon Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.sosEmergency.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: AppColors.sosEmergency,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('medical.sheetTitle'),
                              style: AppTypography.titleMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('medical.sheetSubtitle'),
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Data Container (Cream box matching Image 2)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: dividerColor, width: 1),
                    ),
                    child: Column(
                      children: [
                        _buildMedSheetRow(
                          context,
                          label: context.tr('profile.nik'),
                          value: _resolvedNik ?? '-',
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                          onCopy: _resolvedNik != null
                              ? () => _copyToClipboard('NIK', _resolvedNik!)
                              : null,
                        ),
                        Divider(height: 18, color: dividerColor),
                        _buildMedSheetRow(
                          context,
                          label: context.tr('profile.portionNumber'),
                          value: _resolvedPorsi ?? '-',
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                          onCopy: _resolvedPorsi != null
                              ? () => _copyToClipboard(
                                  'Nomor Porsi',
                                  _resolvedPorsi!,
                                )
                              : null,
                        ),
                        Divider(height: 18, color: dividerColor),
                        _buildMedSheetRow(
                          context,
                          label: context.tr('profile.bloodType'),
                          value: _resolvedBloodType ?? '-',
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                          valueBadge: _resolvedBloodType != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.sosEmergency.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _resolvedBloodType!,
                                    style: const TextStyle(
                                      color: AppColors.sosEmergency,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Divider(height: 18, color: dividerColor),
                        _buildMedSheetRow(
                          context,
                          label: context.tr('medical.allergiesLabel'),
                          value: _resolvedAllergies ?? '-',
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                        ),
                        Divider(height: 18, color: dividerColor),
                        _buildMedSheetRow(
                          context,
                          label: context.tr('profile.specialConditions'),
                          value: _resolvedConditions ?? '-',
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                          highlight:
                              _resolvedConditions != null &&
                              _resolvedConditions != '-',
                        ),
                        Divider(height: 18, color: dividerColor),
                        _buildMedSheetRow(
                          context,
                          label: context.tr('profile.emergencyContact'),
                          value: _resolvedEmergencyContact ?? '-',
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                          onCall: _resolvedEmergencyContact != null
                              ? () => _makePhoneCall(_resolvedEmergencyContact!)
                              : null,
                          onCopy: _resolvedEmergencyContact != null
                              ? () => _copyToClipboard(
                                  'Kontak Darurat',
                                  _resolvedEmergencyContact!,
                                )
                              : null,
                        ),
                        Divider(height: 18, color: dividerColor),
                        _buildMedSheetRow(
                          context,
                          label: context.tr('profile.passportNumber'),
                          value: _resolvedPassport ?? '-',
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                          onCopy: _resolvedPassport != null
                              ? () => _copyToClipboard(
                                  'Nomor Paspor',
                                  _resolvedPassport!,
                                )
                              : null,
                        ),
                        if (_resolvedEmail != null &&
                            _resolvedEmail!.isNotEmpty) ...[
                          Divider(height: 18, color: dividerColor),
                          _buildMedSheetRow(
                            context,
                            label: 'Email',
                            value: _resolvedEmail!,
                            headingColor: headingColor,
                            bodyColor: bodyColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Bottom Buttons Row
                  Row(
                    children: [
                      if (_resolvedEmergencyContact != null &&
                          _resolvedEmergencyContact!.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.goldPrimary,
                              side: const BorderSide(
                                color: AppColors.goldPrimary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () =>
                                _makePhoneCall(_resolvedEmergencyContact!),
                            icon: const Icon(Icons.call_rounded, size: 18),
                            label: const Text(
                              'Hubungi Kontak',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.goldPrimary,
                              side: const BorderSide(
                                color: AppColors.goldPrimary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () {
                              final summary =
                                  'Data Jamaah: $_resolvedName\n'
                                  'Kloter: ${_resolvedKloter ?? '-'}\n'
                                  'Maktab: ${_resolvedMaktab ?? '-'}\n'
                                  'Porsi: ${_resolvedPorsi ?? '-'}\n'
                                  'Gol. Darah: ${_resolvedBloodType ?? '-'}\n'
                                  'Alergi: ${_resolvedAllergies ?? '-'}\n'
                                  'Kondisi: ${_resolvedConditions ?? '-'}\n'
                                  'Kontak: ${_resolvedEmergencyContact ?? '-'}';
                              _copyToClipboard('Ringkasan PPIH', summary);
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text(
                              'Salin Ringkasan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.espressoDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            minimumSize: const Size(0, 48),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            context.tr('common.close'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildMedSheetRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color headingColor,
    required Color bodyColor,
    Widget? valueBadge,
    bool highlight = false,
    VoidCallback? onCall,
    VoidCallback? onCopy,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: bodyColor.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child:
                    valueBadge ??
                    Text(
                      value,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: highlight
                            ? AppColors.distanceWarning
                            : headingColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
              ),
              if (onCall != null && value != '-') ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onCall,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldIslamic.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      size: 14,
                      color: AppColors.emeraldIslamic,
                    ),
                  ),
                ),
              ],
              if (onCopy != null && value != '-') ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: bodyColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Row Helper for JamaahDetailSheet Main View ─────────────────────────────

  Widget _buildDetailHorizontalRow({
    required String label,
    String? valueText,
    Widget? valueWidget,
    Color? headingColor,
    required Color bodyColor,
    VoidCallback? onCopy,
    VoidCallback? onCall,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (onCall != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onCall,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldIslamic.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_rounded,
                      size: 13,
                      color: AppColors.emeraldIslamic,
                    ),
                  ),
                ),
              ],
              if (onCopy != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: bodyColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Section Container Helper ───────────────────────────────────────────────

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required Color borderColor,
    required Color headingColor,
    required List<Widget> children,
    Widget? trailingHeader,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              ?trailingHeader,
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  // ── Main Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final sectionBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.canvasCreamSubtle;
    final dividerColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.canvasCreamSubtle;
    final initial = _resolvedName.trim().isNotEmpty
        ? _resolvedName.trim()[0].toUpperCase()
        : '?';

    final controller = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final canManage =
        controller?.role == UserRole.admin ||
        controller?.role == UserRole.pendamping;
    final hasLocation = _resolvedLocation != null;

    final isSos = _resolvedSosActive;

    // Role styling
    final roleText = _resolvedRole.toUpperCase();
    final roleBadgeBg = isSos
        ? AppColors.sosEmergency.withValues(alpha: 0.18)
        : roleText == 'PENDAMPING'
        ? AppColors.goldPrimary.withValues(alpha: 0.18)
        : roleText == 'ADMIN'
        ? Colors.blue.withValues(alpha: 0.18)
        : (isDark
              ? AppColors.emeraldIslamic.withValues(alpha: 0.25)
              : AppColors.statusSafe.withValues(alpha: 0.12));

    final roleBadgeTextColor = isSos
        ? AppColors.sosEmergency
        : roleText == 'PENDAMPING'
        ? AppColors.goldPrimary
        : roleText == 'ADMIN'
        ? Colors.blue
        : (isDark ? const Color(0xFF6EE7B7) : AppColors.statusSafe);

    final distanceText = _getDistanceText();

    final actionBtnBg = isDark
        ? AppColors.darkPrimary
        : AppColors.emeraldIslamic;
    final actionBtnFg = isDark ? AppColors.darkOnPrimary : Colors.white;

    final hasEmergencyContact =
        _resolvedEmergencyContact != null &&
        _resolvedEmergencyContact!.isNotEmpty;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Main Card Container ──
              Container(
                margin: const EdgeInsets.only(top: 36),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: dividerColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.35 : 0.08,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Space for overlapping floating avatar
                      const SizedBox(height: 48),

                      // SOS Emergency Banner (if active)
                      if (isSos) ...[
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sosEmergency.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.sosEmergency,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.sosEmergency,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'SOS DARURAT AKTIF - Butuh Bantuan Segera!',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.sosEmergency,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Member Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _resolvedName,
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

                      // Role & Logistics Pills Row
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: roleBadgeBg,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              roleText,
                              style: TextStyle(
                                color: roleBadgeTextColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),

                          // Kloter & Maktab Pill (if available)
                          if (_resolvedKloter != null ||
                              _resolvedMaktab != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceContainerHighest
                                    : AppColors.canvasCream,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: dividerColor,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.mosque_rounded,
                                    size: 11,
                                    color: AppColors.goldPrimary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    [
                                      if (_resolvedKloter != null)
                                        'Kloter $_resolvedKloter',
                                      ?_resolvedMaktab,
                                    ].join(' • '),
                                    style: TextStyle(
                                      color: headingColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Blood Type Badge (if available)
                          if (_resolvedBloodType != null &&
                              _resolvedBloodType!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sosEmergency.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.bloodtype_rounded,
                                    size: 12,
                                    color: AppColors.sosEmergency,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Gol. $_resolvedBloodType',
                                    style: const TextStyle(
                                      color: AppColors.sosEmergency,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── SECTION 1: Status & Lokasi (Image 1 Style) ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionCard(
                          context: context,
                          title: 'STATUS & LOKASI JAMAAH',
                          icon: Icons.navigation_rounded,
                          iconColor: AppColors.emeraldIslamic,
                          cardBg: sectionBg,
                          borderColor: dividerColor,
                          headingColor: headingColor,
                          children: [
                            // Attendance Status
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
                            Divider(height: 16, color: dividerColor),

                            // Distance from User
                            _buildDetailHorizontalRow(
                              label: 'Jarak dari Anda',
                              valueText: distanceText,
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                            ),
                            Divider(height: 16, color: dividerColor),

                            // Joined Date
                            _buildDetailHorizontalRow(
                              label: context.tr('room.joinDate'),
                              valueText: _joinedAt != null
                                  ? _formatDate(_joinedAt)
                                  : 'Tidak diketahui',
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                            ),

                            // Coordinates
                            if (hasLocation) ...[
                              Divider(height: 16, color: dividerColor),
                              _buildDetailHorizontalRow(
                                label: context.tr('room.locationCoordinates'),
                                valueText:
                                    '${_resolvedLocation!.latitude.toStringAsFixed(5)}, ${_resolvedLocation!.longitude.toStringAsFixed(5)}',
                                headingColor: headingColor,
                                bodyColor: bodyColor,
                                onCopy: () => _copyToClipboard(
                                  'Koordinat',
                                  '${_resolvedLocation!.latitude}, ${_resolvedLocation!.longitude}',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── SECTION 2: Data Medis & Darurat (PPIH) ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionCard(
                          context: context,
                          title: 'DATA MEDIS & DARURAT (PPIH)',
                          icon: Icons.medical_services_rounded,
                          iconColor: AppColors.sosEmergency,
                          cardBg: sectionBg,
                          borderColor: dividerColor,
                          headingColor: headingColor,
                          trailingHeader: InkWell(
                            onTap: () => _showFullMedicalBottomSheet(context),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lembar Lengkap',
                                    style: TextStyle(
                                      color: AppColors.goldPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: AppColors.goldPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          children: [
                            // Blood Type
                            _buildDetailHorizontalRow(
                              label: context.tr('profile.bloodType'),
                              valueText: _resolvedBloodType ?? '-',
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                            ),
                            Divider(height: 16, color: dividerColor),

                            // Special Conditions / Diseases
                            _buildDetailHorizontalRow(
                              label: context.tr('profile.specialConditions'),
                              valueText: _resolvedConditions ?? '-',
                              headingColor:
                                  (_resolvedConditions != null &&
                                      _resolvedConditions != '-')
                                  ? AppColors.distanceWarning
                                  : headingColor,
                              bodyColor: bodyColor,
                            ),
                            Divider(height: 16, color: dividerColor),

                            // Food/Drug Allergies
                            _buildDetailHorizontalRow(
                              label: context.tr('medical.allergiesLabel'),
                              valueText: _resolvedAllergies ?? '-',
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                            ),
                            Divider(height: 16, color: dividerColor),

                            // Emergency Contact
                            _buildDetailHorizontalRow(
                              label: context.tr('profile.emergencyContact'),
                              valueText: _resolvedEmergencyContact ?? '-',
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                              onCall: hasEmergencyContact
                                  ? () => _makePhoneCall(
                                      _resolvedEmergencyContact!,
                                    )
                                  : null,
                              onCopy: hasEmergencyContact
                                  ? () => _copyToClipboard(
                                      'Kontak Darurat',
                                      _resolvedEmergencyContact!,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── SECTION 3: Dokumen & Identitas Haji ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionCard(
                          context: context,
                          title: 'DOKUMEN & IDENTITAS RESMI',
                          icon: Icons.badge_rounded,
                          iconColor: AppColors.goldPrimary,
                          cardBg: sectionBg,
                          borderColor: dividerColor,
                          headingColor: headingColor,
                          children: [
                            // Nomor Porsi
                            _buildDetailHorizontalRow(
                              label: context.tr('profile.portionNumber'),
                              valueText: _resolvedPorsi ?? '-',
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                              onCopy: _resolvedPorsi != null
                                  ? () => _copyToClipboard(
                                      'Nomor Porsi',
                                      _resolvedPorsi!,
                                    )
                                  : null,
                            ),
                            Divider(height: 16, color: dividerColor),

                            // Nomor Paspor
                            _buildDetailHorizontalRow(
                              label: context.tr('profile.passportNumber'),
                              valueText: _resolvedPassport ?? '-',
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                              onCopy: _resolvedPassport != null
                                  ? () => _copyToClipboard(
                                      'Nomor Paspor',
                                      _resolvedPassport!,
                                    )
                                  : null,
                            ),
                            Divider(height: 16, color: dividerColor),

                            // NIK
                            _buildDetailHorizontalRow(
                              label: context.tr('profile.nik'),
                              valueText: _resolvedNik ?? '-',
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                              onCopy: _resolvedNik != null
                                  ? () => _copyToClipboard('NIK', _resolvedNik!)
                                  : null,
                            ),

                            // Email
                            if (_resolvedEmail != null &&
                                _resolvedEmail!.isNotEmpty) ...[
                              Divider(height: 16, color: dividerColor),
                              _buildDetailHorizontalRow(
                                label: 'Email',
                                valueText: _resolvedEmail!,
                                headingColor: headingColor,
                                bodyColor: bodyColor,
                                onCopy: () =>
                                    _copyToClipboard('Email', _resolvedEmail!),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── BOTTOM ACTION BUTTONS ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // 1. Primary Action: View on Map
                            if (hasLocation)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _handleViewOnMap,
                                  icon: const Icon(
                                    Icons.near_me_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Lihat di Peta',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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

                            // 2. Call Emergency Contact (if available)
                            if (hasEmergencyContact) ...[
                              if (hasLocation) const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () => _makePhoneCall(
                                    _resolvedEmergencyContact!,
                                  ),
                                  icon: const Icon(
                                    Icons.call_rounded,
                                    size: 17,
                                    color: AppColors.emeraldIslamic,
                                  ),
                                  label: Text(
                                    'Hubungi Kontak Darurat (${_resolvedEmergencyContact!})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.emeraldIslamic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.emeraldIslamic,
                                      width: 1.2,
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

                            // 3. Remove Member (Admin / Pendamping)
                            if (canManage) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
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
                                      fontSize: 13,
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
                      color: isSos
                          ? AppColors.sosEmergency
                          : AppColors.emeraldIslamic,
                      border: Border.all(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSos ? AppColors.sosEmergency : Colors.black)
                              .withValues(alpha: isDark ? 0.45 : 0.18),
                          blurRadius: 14,
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
      ),
    );
  }
}
