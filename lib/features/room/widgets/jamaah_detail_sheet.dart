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
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../services/room_service.dart';

/// Modal bottom sheet displaying Jamaah details
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
  StreamSubscription<DocumentSnapshot>? _roomMemberDocSub;
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
    _roomMemberDocSub?.cancel();
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
                _userFirestoreData = {
                  ...?_userFirestoreData,
                  ...?doc.data(),
                };
              });
            }
          },
          onError: (e) {
            debugPrint('[JamaahDetailSheet] Error loading user doc: $e');
          },
        );

    if (widget.roomId.isNotEmpty) {
      _roomMemberDocSub = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('members')
          .doc(widget.jamaah.id)
          .snapshots()
          .listen(
            (doc) {
              if (doc.exists && mounted) {
                setState(() {
                  _userFirestoreData = {
                    ...?_userFirestoreData,
                    ...?doc.data(),
                  };
                });
              }
            },
            onError: (e) {
              debugPrint('[JamaahDetailSheet] Error loading room member doc: $e');
            },
          );
    }
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

  // Resolved Data Getters

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

  Map<String, dynamic>? get _smartbandMap {
    if (_userFirestoreData != null && _userFirestoreData!['smartband'] is Map) {
      return _userFirestoreData!['smartband'] as Map<String, dynamic>;
    }
    return null;
  }

  bool get _isSmartbandConnected {
    if (_smartbandMap != null) {
      return (_smartbandMap!['connected'] as bool?) ?? true;
    }
    return (_userFirestoreData?['isSmartbandConnected'] as bool?) ??
        widget.jamaah.isSmartbandConnected;
  }

  String get _smartbandBraceletId {
    if (_smartbandMap != null && _smartbandMap!['braceletId'] is String) {
      return _smartbandMap!['braceletId'] as String;
    }
    return widget.jamaah.braceletId ?? 'HCG-001';
  }

  int? get _heartRate {
    if (_smartbandMap != null && _smartbandMap!['heartRate'] is num) {
      return (_smartbandMap!['heartRate'] as num).toInt();
    }
    if (_userFirestoreData?['heartRate'] is num) {
      return (_userFirestoreData!['heartRate'] as num).toInt();
    }
    return widget.jamaah.heartRate;
  }

  double? get _temperature {
    if (_smartbandMap != null && _smartbandMap!['temperature'] is num) {
      return (_smartbandMap!['temperature'] as num).toDouble();
    }
    if (_userFirestoreData?['temperature'] is num) {
      return (_userFirestoreData!['temperature'] as num).toDouble();
    }
    return widget.jamaah.temperature;
  }

  int? get _spo2 {
    if (_smartbandMap != null && _smartbandMap!['spo2'] is num) {
      return (_smartbandMap!['spo2'] as num).toInt();
    }
    if (_userFirestoreData?['spo2'] is num) {
      return (_userFirestoreData!['spo2'] as num).toInt();
    }
    return widget.jamaah.spo2;
  }

  bool get _fallDetected {
    if (_smartbandMap != null && _smartbandMap!['fallDetected'] is bool) {
      return _smartbandMap!['fallDetected'] as bool;
    }
    if (_userFirestoreData?['fallDetected'] is bool) {
      return _userFirestoreData!['fallDetected'] as bool;
    }
    return widget.jamaah.fallDetected;
  }

  String get _fallStatus {
    if (_smartbandMap != null && _smartbandMap!['fallStatus'] is String) {
      return _smartbandMap!['fallStatus'] as String;
    }
    if (_userFirestoreData?['fallStatus'] is String) {
      return _userFirestoreData!['fallStatus'] as String;
    }
    return widget.jamaah.fallStatus ?? 'NORMAL';
  }

  int? get _batteryLevel {
    if (_smartbandMap != null && _smartbandMap!['batteryLevel'] is num) {
      return (_smartbandMap!['batteryLevel'] as num).toInt();
    }
    if (_userFirestoreData?['batteryLevel'] is num) {
      return (_userFirestoreData!['batteryLevel'] as num).toInt();
    }
    return widget.jamaah.batteryLevel;
  }

  bool get _isSosActive {
    if (_smartbandMap != null && _smartbandMap!['isSos'] is bool) {
      if (_smartbandMap!['isSos'] as bool) return true;
    }
    if (_userFirestoreData?['sosActive'] is bool) {
      return _userFirestoreData!['sosActive'] as bool;
    }
    return widget.jamaah.sosActive;
  }

  bool get _isHeartRateCritical =>
      _heartRate != null && _heartRate! > 0 && (_heartRate! < 45 || _heartRate! > 120);

  bool get _isHeartRateWarning =>
      _heartRate != null &&
      _heartRate! > 0 &&
      ((_heartRate! >= 45 && _heartRate! < 50) ||
          (_heartRate! > 100 && _heartRate! <= 120));

  bool get _isTemperatureCritical =>
      _temperature != null && (_temperature! > 38.5 || _temperature! < 35.0);

  bool get _isTemperatureWarning =>
      _temperature != null && (_temperature! >= 37.6 && _temperature! <= 38.5);

  bool get _isSpo2Critical => _spo2 != null && _spo2! > 0 && _spo2! < 90;

  bool get _isSpo2Warning => _spo2 != null && _spo2! >= 90 && _spo2! < 95;

  bool get _isFallen =>
      _fallDetected || _fallStatus.toUpperCase() == 'FALLEN';

  int? get _steps {
    if (_smartbandMap != null && _smartbandMap!['steps'] is num) {
      return (_smartbandMap!['steps'] as num).toInt();
    }
    if (_userFirestoreData?['steps'] is num) {
      return (_userFirestoreData!['steps'] as num).toInt();
    }
    return widget.jamaah.steps;
  }

  double? get _stepDistanceM {
    if (_smartbandMap != null && _smartbandMap!['stepDistanceM'] is num) {
      return (_smartbandMap!['stepDistanceM'] as num).toDouble();
    }
    if (_userFirestoreData?['stepDistanceM'] is num) {
      return (_userFirestoreData!['stepDistanceM'] as num).toDouble();
    }
    return widget.jamaah.stepDistanceM;
  }

  double? get _calculatedDistanceMeters {
    final loc = _resolvedLocation;
    if (loc == null) return null;
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

    if (userLat == null || userLng == null) return null;
    return Geolocator.distanceBetween(
      userLat,
      userLng,
      loc.latitude,
      loc.longitude,
    );
  }

  bool get _isOutOfSafeRadius {
    final meters = _calculatedDistanceMeters;
    if (meters != null) {
      final safeRadius = Get.isRegistered<HajiCareController>()
          ? Get.find<HajiCareController>().safeRadiusMeters.value
          : 50.0;
      return meters > safeRadius;
    }
    return widget.jamaah.isOutOfSafeRadius;
  }

  bool get _hasCriticalAnomaly =>
      _isSosActive || _isFallen || _isHeartRateCritical || _isTemperatureCritical || _isSpo2Critical;

  bool get _hasAnyAnomaly =>
      _hasCriticalAnomaly || _isOutOfSafeRadius || _isHeartRateWarning || _isTemperatureWarning || _isSpo2Warning;

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

  DateTime? get _smartbandUpdatedAt {
    final raw = _smartbandMap != null
        ? _smartbandMap!['updatedAt']
        : _userFirestoreData?['smartbandUpdatedAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return widget.jamaah.smartbandUpdatedAt;
  }

  String get _smartbandRelativeTime {
    final dt = _smartbandUpdatedAt;
    if (dt == null) return context.tr('smartband.statusConnected');
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 10) return context.tr('smartband.justNow');
    if (diff.inSeconds < 60) return '${diff.inSeconds}d lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String? get _resolvedPhone =>
      (_userFirestoreData?['phoneNumber'] as String?)?.trim() ??
      (_userFirestoreData?['phone'] as String?)?.trim();


  String _formatDate(DateTime? dt) {
    if (dt == null) return context.tr('room.unknown');
    String lang = 'id';
    try {
      lang = Localizations.localeOf(context).languageCode;
    } catch (_) {
      lang = Get.locale?.languageCode ?? 'id';
    }

    if (lang == 'en') {
      const monthsEn = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${dt.day} ${monthsEn[dt.month - 1]} ${dt.year}';
    } else if (lang == 'su') {
      const monthsSu = [
        'Januari',
        'Pébruari',
        'Maret',
        'April',
        'Méi',
        'Juni',
        'Juli',
        'Agustus',
        'Séptémber',
        'Oktober',
        'Nopémber',
        'Désémber',
      ];
      return '${dt.day} ${monthsSu[dt.month - 1]} ${dt.year}';
    }
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
      return context.tr('room.locationNotAvailable');
    }
    final currentTime = now ?? DateTime.now();
    final diff = currentTime.difference(time);
    final seconds = diff.inSeconds;

    if (seconds <= 30) {
      return context.tr('room.onlineStatus');
    } else if (seconds <= 120) {
      return context.tr('room.lastSeenSecondsAgo', {'seconds': seconds});
    } else {
      return context.tr('room.locationNotUpdated');
    }
  }

  String _getDistanceText() {
    final meters = _calculatedDistanceMeters;
    if (meters == null) {
      if (widget.jamaah.distance > 0) {
        final d = widget.jamaah.distance;
        return d < 1000
            ? context.tr('room.metersFromYou', {'meters': d.toStringAsFixed(0)})
            : context.tr('room.kmFromYou', {'km': (d / 1000).toStringAsFixed(1)});
      }
      return context.tr('room.notDetected');
    }

    if (meters < 1000) {
      return context.tr('room.metersFromYou', {
        'meters': meters.toStringAsFixed(0),
      });
    } else {
      return context.tr('room.kmFromYou', {
        'km': (meters / 1000).toStringAsFixed(1),
      });
    }
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('room.copiedSuccess', {'label': label, 'value': value}),
        ),
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
            title: context.tr('room.callFailedTitle'),
            message: context.tr('room.callFailedDesc', {'number': phoneNumber}),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppAlert.warning(
          context,
          title: context.tr('room.callFailedTitle'),
          message: context.tr('room.callFailedDesc', {'number': phoneNumber}),
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
      message: context.tr('room.removeConfirmPrompt', {'name': _resolvedName}),
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
            roomName: widget.roomName,
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
              fallback: context.tr('room.memberRemoveFailedFallback'),
            ),
          );
        }
      },
    );
  }

  /// Opens the dedicated "Pilgrim Medical Data & History" bottom sheet
  void _showFullMedicalBottomSheet(BuildContext context) {
    final hc = context.hc;
    final headingColor = hc.textPrimary;
    final bodyColor = hc.textSecondary;
    final cardBg = hc.surfaceSand;
    final dividerColor = hc.borderSubtle;

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
              color: hc.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: hc.borderSubtle, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: hc.isDark ? 0.45 : 0.12,
                  ),
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
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: hc.borderSubtle,
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
                          color: hc.danger.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.medical_services_rounded,
                          color: hc.danger,
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
                              style: context.text.titleMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('medical.sheetSubtitle'),
                              style: context.text.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Data Container (Cream box
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
                                    color: hc.danger.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _resolvedBloodType!,
                                    style: TextStyle(
                                      color: hc.danger,
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
                                  context.tr('room.emergencyContact'),
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
                                  context.tr('profile.passportNumber'),
                                  _resolvedPassport!,
                                )
                              : null,
                        ),
                        if (_resolvedEmail != null &&
                            _resolvedEmail!.isNotEmpty) ...[
                          Divider(height: 18, color: dividerColor),
                          _buildMedSheetRow(
                            context,
                            label: context.tr('profile.email'),
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
                              foregroundColor: hc.brand,
                              side: BorderSide(color: hc.brand, width: 1.5),
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
                            label: Text(
                              context.tr('room.contactCall'),
                              style: const TextStyle(
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
                              foregroundColor: hc.brand,
                              side: BorderSide(color: hc.brand, width: 1.5),
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
                            label: Text(
                              context.tr('room.copySummary'),
                              style: const TextStyle(
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
                            backgroundColor: hc.brand,
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
            style: context.text.bodySmall.copyWith(
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
                      style: context.text.bodyMedium.copyWith(
                        color: highlight ? context.hc.warning : headingColor,
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
                      color: context.hc.islamic.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.call_rounded,
                      size: 14,
                      color: context.hc.islamic,
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

  // Row Helper for JamaahDetailSheet Main View

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
          style: context.text.bodySmall.copyWith(
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
                      style: context.text.bodyMedium.copyWith(
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
                      color: context.hc.islamic.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_rounded,
                      size: 13,
                      color: context.hc.islamic,
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
                  style: context.text.labelLarge.copyWith(
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

  Widget _buildUrgentAnomalyBanner(BuildContext context, HajiColors hc) {
    if (!_hasAnyAnomaly) return const SizedBox.shrink();

    final isCritical = _hasCriticalAnomaly;
    final bannerBg = isCritical
        ? hc.danger.withValues(alpha: 0.14)
        : hc.warning.withValues(alpha: 0.14);
    final bannerBorder = isCritical ? hc.danger : hc.warning;
    final iconColor = isCritical ? hc.danger : hc.warning;

    final anomalyItems = <Widget>[];

    if (_isSosActive) {
      anomalyItems.add(_buildAnomalyBullet(
        icon: Icons.emergency_rounded,
        text: context.tr('room.smartbandSosAlert'),
        color: hc.danger,
        isCritical: true,
      ));
    }

    if (_isFallen) {
      anomalyItems.add(_buildAnomalyBullet(
        icon: Icons.personal_injury_rounded,
        text: context.tr('room.smartbandFallenAlert'),
        color: hc.danger,
        isCritical: true,
      ));
    }

    if (_isTemperatureCritical) {
      final tempStr = _temperature?.toStringAsFixed(1) ?? '--';
      final text = (_temperature ?? 0) > 38.5
          ? context.tr('room.smartbandHeatstrokeAlert', {'temp': tempStr})
          : context.tr('room.smartbandHypothermiaAlert', {'temp': tempStr});
      anomalyItems.add(_buildAnomalyBullet(
        icon: Icons.thermostat_rounded,
        text: text,
        color: hc.danger,
        isCritical: true,
      ));
    } else if (_isTemperatureWarning) {
      final tempStr = _temperature?.toStringAsFixed(1) ?? '--';
      anomalyItems.add(_buildAnomalyBullet(
        icon: Icons.thermostat_rounded,
        text: 'Suhu Hangat/Meningkat ($tempStr°C) - Awasi Hidrasi',
        color: hc.warning,
        isCritical: false,
      ));
    }

    if (_isHeartRateCritical) {
      final bpmStr = '$_heartRate';
      final text = (_heartRate ?? 0) > 120
          ? context.tr('room.smartbandTachycardiaAlert', {'bpm': bpmStr})
          : context.tr('room.smartbandBradycardiaAlert', {'bpm': bpmStr});
      anomalyItems.add(_buildAnomalyBullet(
        icon: Icons.favorite_rounded,
        text: text,
        color: hc.danger,
        isCritical: true,
      ));
    } else if (_isHeartRateWarning) {
      anomalyItems.add(_buildAnomalyBullet(
        icon: Icons.favorite_rounded,
        text: 'Detak Jantung Waspada ($_heartRate BPM)',
        color: hc.warning,
        isCritical: false,
      ));
    }

    if (_isSpo2Critical) {
      anomalyItems.add(_buildAnomalyBullet(
        icon: Icons.air_rounded,
        text: context.tr('room.smartbandHypoxiaAlert', {'spo2': '$_spo2'}),
        color: hc.danger,
        isCritical: true,
      ));
    } else if (_isSpo2Warning) {
      anomalyItems.add(_buildAnomalyBullet(
        icon: Icons.air_rounded,
        text: 'Kadar Oksigen Menurun ($_spo2% SpO2) - Cek Pernapasan',
        color: hc.warning,
        isCritical: false,
      ));
    }

    if (_isOutOfSafeRadius) {
      final dist = _getDistanceText();
      anomalyItems.add(_buildAnomalyBullet(
        icon: Icons.radar_rounded,
        text: context.tr('room.smartbandOutOfRadiusAlert', {'dist': dist}),
        color: hc.warning,
        isCritical: false,
      ));
    }

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bannerBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bannerBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: (isCritical ? hc.danger : hc.warning).withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCritical ? Icons.warning_rounded : Icons.info_outline_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCritical
                        ? 'PERINGATAN KRITIS JAMAAH'
                        : 'PERHATIAN ANOMALI KESEHATAN',
                    style: context.text.labelLarge.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    isCritical ? 'DARURAT' : 'WASPADA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...anomalyItems,
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyBullet({
    required IconData icon,
    required String text,
    required Color color,
    required bool isCritical,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: isCritical ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartbandSection(BuildContext context, HajiColors hc) {
    final headingColor = hc.textPrimary;
    final bodyColor = hc.textSecondary;
    final sectionBg = hc.surfaceSand;
    final dividerColor = hc.borderSubtle;
    final isConnected = _isSmartbandConnected;

    final hrColor = _isHeartRateCritical
        ? hc.danger
        : _isHeartRateWarning
            ? hc.warning
            : hc.islamic;

    final tempColor = _isTemperatureCritical
        ? hc.danger
        : _isTemperatureWarning
            ? hc.warning
            : hc.islamic;

    final fallColor = _isFallen ? hc.danger : hc.islamic;
    final radiusColor = _isOutOfSafeRadius ? hc.danger : hc.islamic;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildSectionCard(
          context: context,
          title: context.tr('room.smartbandSectionTitle'),
        icon: Icons.watch_rounded,
        iconColor: hc.brand,
        cardBg: sectionBg,
        borderColor: dividerColor,
        headingColor: headingColor,
        trailingHeader: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isConnected
                ? hc.islamic.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isConnected
                  ? hc.islamic.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? hc.islamic : Colors.grey,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isConnected
                    ? context.tr('room.smartbandConnectedBadge', {'id': _smartbandBraceletId})
                    : context.tr('room.smartbandDisconnectedBadge'),
                style: TextStyle(
                  color: isConnected ? hc.islamic : bodyColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.favorite_rounded,
                  iconColor: hrColor,
                  label: context.tr('room.smartbandHeartRate'),
                  value: _heartRate != null && _heartRate! > 0 ? '$_heartRate BPM' : '--',
                  subtitle: _isHeartRateCritical
                      ? 'Kritis'
                      : _isHeartRateWarning
                          ? 'Waspada'
                          : 'Normal',
                  statusColor: hrColor,
                  hc: hc,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.thermostat_rounded,
                  iconColor: tempColor,
                  label: context.tr('room.smartbandTemperature'),
                  value: _temperature != null ? '${_temperature!.toStringAsFixed(1)}°C' : '--',
                  subtitle: _isTemperatureCritical
                      ? 'Kritis'
                      : _isTemperatureWarning
                          ? 'Demam Ringan'
                          : 'Normal',
                  statusColor: tempColor,
                  hc: hc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.directions_walk_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  label: 'Langkah Jalan',
                  value: _steps != null && _steps! > 0 ? '$_steps lkh' : '--',
                  subtitle: _steps != null && _steps! > 0 ? 'Aktif' : 'Pedo MPU6050',
                  statusColor: const Color(0xFF7C3AED),
                  hc: hc,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.personal_injury_rounded,
                  iconColor: fallColor,
                  label: context.tr('room.smartbandFallStatus'),
                  value: _isFallen ? 'TERJATUH' : 'TEGAK',
                  subtitle: _isFallen ? 'Butuh Cek!' : 'Stabil',
                  statusColor: fallColor,
                  hc: hc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.radar_rounded,
                  iconColor: radiusColor,
                  label: context.tr('room.smartbandSafeRadius'),
                  value: _isOutOfSafeRadius ? 'Di Luar Radius' : 'Dalam Radius',
                  subtitle: _getDistanceText(),
                  statusColor: radiusColor,
                  hc: hc,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: (_batteryLevel ?? 100) < 20 ? hc.warning : hc.islamic,
                  label: context.tr('room.smartbandBattery'),
                  value: _batteryLevel != null ? '$_batteryLevel%' : '--',
                  subtitle: (_batteryLevel ?? 100) < 20 ? 'Perlu Cas' : 'Daya Cukup',
                  statusColor: (_batteryLevel ?? 100) < 20 ? hc.warning : hc.islamic,
                  hc: hc,
                ),
              ),
            ],
          ),
          if (_steps != null && _steps! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.directions_walk_rounded,
                    iconColor: hc.brand,
                    label: context.tr('room.smartbandSteps'),
                    value: '$_steps langkah',
                    subtitle: '${(_stepDistanceM ?? (_steps! * 0.70)).toStringAsFixed(0)} m aktif',
                    statusColor: hc.brand,
                    hc: hc,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.speed_rounded,
                    iconColor: hc.islamic,
                    label: context.tr('room.smartbandActivityStatus'),
                    value: _steps! > 5000 ? 'Target Tercapai' : 'Sedang Bergerak',
                    subtitle: 'Sensor MPU6050',
                    statusColor: hc.islamic,
                    hc: hc,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 13,
                      color: bodyColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        context.tr('room.smartbandLastUpdated', {'time': _smartbandRelativeTime}),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: bodyColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _sendAlertToPilgrimSmartband,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: hc.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hc.brand.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.vibration_rounded, size: 13, color: hc.brand),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('room.smartbandSendAlertOledBtn'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: hc.brand,
                        ),
                      ),
                    ],
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

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
    required Color statusColor,
    required HajiColors hc,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hc.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor != hc.islamic
              ? statusColor.withValues(alpha: 0.5)
              : hc.borderSubtle,
          width: statusColor != hc.islamic ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: hc.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: hc.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendAlertToPilgrimSmartband() async {
    try {
      HapticFeedback.mediumImpact();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.jamaah.id)
          .set({
        'smartbandCommand': {
          'type': 'ALERT_BUZZER',
          'message': 'Panggilan Pendamping',
          'timestamp': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('room.smartbandOledSentSuccess')),
            backgroundColor: context.hc.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim ke gelang: $e'),
            backgroundColor: context.hc.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Main Build

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final headingColor = hc.textPrimary;
    final bodyColor = hc.textSecondary;
    final cardBg = hc.surface;
    final sectionBg = hc.surfaceSand;
    final dividerColor = hc.borderSubtle;
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
        ? hc.danger.withValues(alpha: 0.18)
        : roleText == 'PENDAMPING'
        ? hc.brand.withValues(alpha: 0.18)
        : roleText == 'ADMIN'
        ? hc.accent.withValues(alpha: 0.18)
        : hc.success.withValues(alpha: 0.12);

    final roleBadgeTextColor = isSos
        ? hc.danger
        : roleText == 'PENDAMPING'
        ? hc.brand
        : roleText == 'ADMIN'
        ? hc.accent
        : hc.success;

    final distanceText = _getDistanceText();

    final actionBtnBg = hc.brand;
    const actionBtnFg = Colors.white;

    final hasEmergencyContact =
        _resolvedEmergencyContact != null &&
        _resolvedEmergencyContact!.isNotEmpty;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Card Container
              Container(
                margin: const EdgeInsets.only(top: 36),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: dividerColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: hc.isDark ? 0.35 : 0.08,
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

                      // SOS Emergency Banner (if active
                      if (isSos) ...[
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: hc.danger.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: hc.danger, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: hc.danger,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.tr('room.sosActiveUrgentBanner'),
                                  style: context.text.labelLarge.copyWith(
                                    color: hc.danger,
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
                          style: context.text.titleLarge.copyWith(
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

                          // Kloter & Maktab Pill (if available
                          if (_resolvedKloter != null ||
                              _resolvedMaktab != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: hc.surfaceSand,
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
                                  Icon(
                                    Icons.mosque_rounded,
                                    size: 11,
                                    color: hc.brand,
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

                          // Blood Type Badge (if available
                          if (_resolvedBloodType != null &&
                              _resolvedBloodType!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: hc.danger.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bloodtype_rounded,
                                    size: 12,
                                    color: hc.danger,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Gol. $_resolvedBloodType',
                                    style: TextStyle(
                                      color: hc.danger,
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

                      // Urgent Health / Radius Anomaly Banner
                      _buildUrgentAnomalyBanner(context, hc),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionCard(
                          context: context,
                          title: context.tr('room.statusAndLocationHeader'),
                          icon: Icons.navigation_rounded,
                          iconColor: hc.islamic,
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
                                          ? hc.islamic
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
                              label: context.tr('room.distanceFromYou'),
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
                                  : context.tr('room.unknown'),
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

                      // Smartband Real-time Telemetry Section
                      _buildSmartbandSection(context, hc),
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionCard(
                          context: context,
                          title: context.tr('room.medicalEmergencyDataHeader'),
                          icon: Icons.medical_services_rounded,
                          iconColor: hc.danger,
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
                                      color: hc.brand,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: hc.brand,
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
                                  ? hc.warning
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
                                      context.tr('room.emergencyContact'),
                                      _resolvedEmergencyContact!,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionCard(
                          context: context,
                          title: context.tr('room.officialDocsHeader'),
                          icon: Icons.badge_rounded,
                          iconColor: hc.brand,
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
                                      context.tr('profile.portionNumber'),
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
                                      context.tr('profile.passportNumber'),
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
                                  ? () => _copyToClipboard(
                                      context.tr('profile.nik'),
                                      _resolvedNik!,
                                    )
                                  : null,
                            ),

                            if (_resolvedEmail != null &&
                                _resolvedEmail!.isNotEmpty) ...[
                              Divider(height: 16, color: dividerColor),
                              _buildDetailHorizontalRow(
                                label: context.tr('profile.email'),
                                valueText: _resolvedEmail!,
                                headingColor: headingColor,
                                bodyColor: bodyColor,
                                onCopy: () => _copyToClipboard(
                                  context.tr('profile.email'),
                                  _resolvedEmail!,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // BOTTOM ACTION BUTTONS
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
                                  label: Text(
                                    context.tr('room.viewOnMap'),
                                    style: const TextStyle(
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

                            // Call Pilgrim directly (if phone available)
                            if (_resolvedPhone != null &&
                                _resolvedPhone!.isNotEmpty) ...[
                              if (hasLocation) const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () => _makePhoneCall(
                                    _resolvedPhone!,
                                  ),
                                  icon: Icon(
                                    Icons.call_rounded,
                                    size: 17,
                                    color: hc.brand,
                                  ),
                                  label: Text(
                                    context.tr('room.smartbandCallBtn'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: hc.brand,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: hc.brand,
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

                            // 2. Call Emergency Contact (if available
                            if (hasEmergencyContact) ...[
                              if (hasLocation) const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () => _makePhoneCall(
                                    _resolvedEmergencyContact!,
                                  ),
                                  icon: Icon(
                                    Icons.call_rounded,
                                    size: 17,
                                    color: hc.islamic,
                                  ),
                                  label: Text(
                                    context.tr('room.callEmergencyContact', {
                                      'contact': _resolvedEmergencyContact!,
                                    }),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: hc.islamic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: hc.islamic,
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

                            // 3. Remove Member (Admin / Pendamping
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
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  hc.danger,
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_remove_rounded,
                                          size: 16,
                                        ),
                                  label: Text(
                                    context.tr('room.removeFromRoom'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: hc.danger,
                                    side: BorderSide(
                                      color: hc.danger.withValues(alpha: 0.35),
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

              // Overlapping Circular Avatar (top center
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: RepaintBoundary(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSos ? hc.danger : hc.islamic,
                        border: Border.all(color: hc.surface, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: (isSos ? hc.danger : Colors.black).withValues(
                              alpha: hc.isDark ? 0.45 : 0.18,
                            ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
