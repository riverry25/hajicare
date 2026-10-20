import '../../../core/locales/app_localizations.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../../core/widgets/app_card.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../controllers/admin_room_controller.dart';
import '../services/room_service.dart';
import '../widgets/edit_room_dialog.dart';
import '../widgets/room_qr_dialog.dart';

class RoomDetailScreen extends StatefulWidget {
  final RoomService? roomService;

  const RoomDetailScreen({super.key, this.roomService});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late final RoomService _roomService;
  AdminRoomController? _adminController;

  RoomModel? _room;
  bool _isLoadingRoom = true;
  bool _isLoadingMembers = true;

  List<RoomMemberModel> _allMembers = [];
  StreamSubscription<RoomModel?>? _roomSub;
  StreamSubscription<List<RoomMemberModel>>? _membersSub;
  bool _isProcessingAction = false;

  // Search & Filter State
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua' | 'Jamaah' | 'Pendamping'

  // Pagination State
  int _currentPage = 1;
  int _limitPerPage = 8; // Default limit per page
  static const List<int> _availableLimits = [5, 8, 15];

  User? get _currentFirebaseUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  String? get _effectiveUid {
    final authUid = _currentFirebaseUser?.uid;
    if (authUid != null && authUid.isNotEmpty) return authUid;
    if (Get.isRegistered<HajiCareController>()) {
      return Get.find<HajiCareController>().currentUid;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _roomService =
        widget.roomService ??
        (Get.isRegistered<RoomService>()
            ? Get.find<RoomService>()
            : RoomService());
    _searchController = TextEditingController();

    if (Get.isRegistered<AdminRoomController>()) {
      _adminController = Get.find<AdminRoomController>();
    }

    _resolveInitialRoom();

    // Start subscriptions safely after initial frame to prevent markNeedsBuild during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startSubscriptions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _roomSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }

  void _resolveInitialRoom() {
    final hajiCare = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;

    final resolvedRoom =
        (Get.arguments as RoomModel?) ??
        _adminController?.selectedRoom.value ??
        hajiCare?.activeRoom.value;

    if (resolvedRoom != null) {
      _room = resolvedRoom;
      _isLoadingRoom = false;
    } else {
      final roomId = hajiCare?.activeRoomId.value ?? hajiCare?.cachedRoomId;
      _isLoadingRoom = (roomId != null && roomId.isNotEmpty);
    }
  }

  void _startSubscriptions() {
    final hajiCare = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;

    final roomId =
        _room?.id ?? hajiCare?.activeRoomId.value ?? hajiCare?.cachedRoomId;

    if (roomId != null && roomId.isNotEmpty) {
      _subscribeToRoom(roomId);
      _subscribeToMembers(roomId);
    } else {
      if (mounted) {
        setState(() {
          _isLoadingRoom = false;
          _isLoadingMembers = false;
        });
      }
    }
  }

  void _subscribeToRoom(String roomId) {
    _roomSub?.cancel();
    try {
      _roomSub = _roomService
          .getRoomStream(roomId)
          .listen(
            (roomData) {
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (roomData == null || !roomData.isActive) {
                  if (!_isProcessingAction && !_isLoadingRoom) {
                    if (Navigator.of(context).canPop()) {
                      Get.back();
                    } else {
                      Get.offAllNamed(AppRoutes.dashboardJamaah);
                    }
                    AppAlert.info(
                      Get.context,
                      title: context.tr('room.roomClosedTitle'),
                      message: context.tr('room.roomClosedDesc'),
                    );
                  }
                  return;
                }
                setState(() {
                  _room = roomData;
                  _isLoadingRoom = false;
                });
              });
            },
            onError: (e) {
              debugPrint('[RoomDetailScreen] Error listening to room: $e');
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isLoadingRoom = false;
                  });
                }
              });
            },
          );
    } catch (e) {
      debugPrint('[RoomDetailScreen] Could not subscribe to room: $e');
      if (mounted) {
        setState(() {
          _isLoadingRoom = false;
        });
      }
    }
  }

  void _subscribeToMembers(String roomId) {
    _membersSub?.cancel();
    try {
      _membersSub = _roomService
          .getRoomMembersStream(roomId)
          .listen(
            (members) {
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final currentUid = _effectiveUid;
                final hajiCare = Get.isRegistered<HajiCareController>()
                    ? Get.find<HajiCareController>()
                    : null;
                final isAdmin = hajiCare?.role == UserRole.admin;
                if (!isAdmin && currentUid != null && members.isNotEmpty) {
                  final isStillMember = members.any((m) => m.uid == currentUid);
                  if (!isStillMember &&
                      !_isProcessingAction &&
                      !_isLoadingMembers) {
                    if (Navigator.of(context).canPop()) {
                      Get.back();
                    } else {
                      Get.offAllNamed(AppRoutes.dashboardJamaah);
                    }
                    AppAlert.info(
                      Get.context,
                      title: context.tr('room.membershipStatusTitle'),
                      message: context.tr('room.membershipRevokedDesc'),
                    );
                    return;
                  }
                }

                setState(() {
                  _allMembers = members;
                  _isLoadingMembers = false;

                  final maxPages = _totalPages;
                  if (_currentPage > maxPages) {
                    _currentPage = maxPages.clamp(1, 999);
                  }
                });

                // Sync with AdminRoomController safely if present
                if (_adminController != null) {
                  _adminController!.roomMembers.value = members;
                }
              });
            },
            onError: (e) {
              debugPrint('[RoomDetailScreen] Error listening to members: $e');
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isLoadingMembers = false;
                  });
                }
              });
            },
          );
    } catch (e) {
      debugPrint('[RoomDetailScreen] Could not subscribe to members: $e');
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
  }

  // Computed Getters
  bool _isMemberSos(RoomMemberModel member) {
    if (member.sosActive) return true;
    if (Get.isRegistered<HajiCareController>()) {
      return Get.find<HajiCareController>().activeSosEvents.any(
        (e) => e['userId'] == member.uid || e['jamaahId'] == member.uid,
      );
    }
    return false;
  }

  List<RoomMemberModel> get _filteredMembers {
    return _allMembers.where((m) {
      if (_selectedFilter == 'Jamaah' && !m.isJamaah) return false;
      if (_selectedFilter == 'Pendamping' && !m.isPendamping) return false;
      if (_selectedFilter == 'SOS' && !_isMemberSos(m)) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatches = m.name.toLowerCase().contains(q);
        final roleMatches = m.role.toLowerCase().contains(q);
        return nameMatches || roleMatches;
      }

      return true;
    }).toList();
  }

  int get _totalPages {
    final count = _filteredMembers.length;
    if (count == 0) return 1;
    return (count / _limitPerPage).ceil();
  }

  List<RoomMemberModel> get _pagedMembers {
    final list = _filteredMembers;
    final start = (_currentPage - 1) * _limitPerPage;
    if (start >= list.length) return [];
    final end = (start + _limitPerPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get _totalCount => _allMembers.length;
  int get _jamaahCount => _allMembers.where((m) => m.isJamaah).length;
  int get _pendampingCount => _allMembers.where((m) => m.isPendamping).length;
  int get _sosCount => _allMembers.where((m) => _isMemberSos(m)).length;

  String _formatDate(DateTime? dt, [BuildContext? ctx]) {
    if (dt == null) return '-';
    String lang = 'id';
    if (ctx != null) {
      try {
        lang = Localizations.localeOf(ctx).languageCode;
      } catch (_) {
        lang = Get.locale?.languageCode ?? 'id';
      }
    } else {
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

  String _getMemberLocationStatus(
    BuildContext context,
    RoomMemberModel member, [
    DateTime? now,
  ]) {
    if (!member.hasLocation || member.locationUpdatedAt == null) {
      return context.tr('room.locationNotAvailable');
    }
    final currentTime = now ?? DateTime.now();
    final diff = currentTime.difference(member.locationUpdatedAt!);
    final seconds = diff.inSeconds;

    if (seconds <= 30) {
      return context.tr('room.onlineStatus');
    } else if (seconds <= 120) {
      return context.tr('room.lastSeenSecondsAgo', {'seconds': seconds});
    } else {
      return context.tr('room.locationNotUpdated');
    }
  }

  String _capitalizeWords(String? input) {
    if (input == null || input.trim().isEmpty) return input ?? '';
    return input
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          if (word.length == 1) return word.toUpperCase();
          if (word == word.toUpperCase()) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  bool _canManageMembers() {
    final hajiCare = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final isJamaah = hajiCare?.role == UserRole.jamaah;
    final currentUid = _effectiveUid;
    final isAdmin = hajiCare?.role == UserRole.admin;
    final isPendampingRole = hajiCare?.role == UserRole.pendamping;
    final isCreator =
        _room != null && currentUid != null && _room!.createdBy == currentUid;
    final isPendampingMember =
        currentUid != null &&
        _allMembers.any((m) => m.uid == currentUid && m.isPendamping);

    return !isJamaah &&
        (isAdmin || isPendampingRole || isCreator || isPendampingMember);
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'Jamaah':
        return context.tr('room.roleJamaah');
      case 'Pendamping':
        return context.tr('room.roleCompanion');
      case 'SOS':
        return context.tr('room.filterSos');
      case 'Semua':
      default:
        return context.tr('room.all');
    }
  }

  /// Memeriksa apakah user berhak mengedit atau menghapus room.
  /// HANYA Admin atau Pendamping pembuat room (createdBy == currentUid).
  /// Role Jamaah selalu bernilai FALSE dan tidak memiliki akses sama sekali.
  bool _canEditOrDeleteRoom() {
    final hajiCare = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    if (hajiCare?.role == UserRole.jamaah) return false;
    final currentUid = _effectiveUid;
    final isAdmin = hajiCare?.role == UserRole.admin;
    final isCreator =
        _room != null && currentUid != null && _room!.createdBy == currentUid;

    return isAdmin || isCreator;
  }

  void _showEditRoomSheet(BuildContext context, RoomModel room) async {
    HapticFeedback.lightImpact();
    final updated = await EditRoomDialog.show(context, _room ?? room);
    if (updated == true && mounted) {
      try {
        final fresh = await _roomService.getRoomById(room.id);
        if (fresh != null && mounted) {
          setState(() {
            _room = fresh;
          });
        }
      } catch (_) {}
    }
  }

  void _handleDeleteRoom(BuildContext context, RoomModel room) {
    if (_isProcessingAction || !mounted) return;
    HapticFeedback.mediumImpact();
    AppAlert.confirm(
      context,
      title: context.tr('room.deleteRoomTitle'),
      message: context.tr('room.deleteRoomConfirmMessage'),
      confirmText: context.tr('room.deleteRoom'),
      cancelText: context.tr('common.cancel'),
      isDestructive: true,
      onConfirm: () async {
        if (_isProcessingAction || !mounted) return;
        setState(() => _isProcessingAction = true);
        AppAlert.loading(
          context,
          message: context.tr('room.deletingRoomLoading'),
        );
        try {
          final user = _currentFirebaseUser;
          final currentUid = _effectiveUid ?? '';
          final hajiCare = Get.isRegistered<HajiCareController>()
              ? Get.find<HajiCareController>()
              : null;
          final senderName = user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!
              : (hajiCare?.pendampingName.value ??
                    context.tr('room.defaultOfficerCompanion'));
          final userRole = hajiCare?.role == UserRole.admin
              ? 'admin'
              : 'pendamping';

          await _roomService.deleteRoomByCreator(
            roomId: room.id,
            currentUserId: currentUid,
            senderName: senderName,
            userRole: userRole,
          );

          await hajiCare?.clearActiveRoomSession();

          if (context.mounted) {
            AppAlert.dismissLoading(context);
            await AppAlert.success(
              Get.context,
              title: context.tr('room.roomDeleted'),
              message: context.tr('room.roomDeletedDesc', {'name': room.name}),
              autoDismissDuration: const Duration(seconds: 3),
            );
            if (!context.mounted) return;
            if (Navigator.of(context).canPop()) {
              Get.back();
            } else {
              Get.offAllNamed(
                hajiCare?.role == UserRole.pendamping
                    ? AppRoutes.dashboardPendamping
                    : AppRoutes.dashboardJamaah,
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            AppAlert.dismissLoading(context);
            AppAlert.error(
              context,
              title: context.tr('room.deleteFailed'),
              message: UserFeedbackMessage.from(
                e,
                fallback: context.tr('room.deleteFailedFallback'),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isProcessingAction = false);
          }
        }
      },
    );
  }

  void _handleSetCoOwner(
    BuildContext context,
    RoomMemberModel target,
    RoomModel room,
  ) {
    if (_isProcessingAction || !mounted) return;
    HapticFeedback.lightImpact();

    final primaryColor = context.hc.brand;

    AppAlert.confirm(
      context,
      title: room.coOwnerId != null && room.coOwnerId!.isNotEmpty
          ? context.tr('room.replaceCoOwnerBtn')
          : context.tr('room.setCoOwnerBtn'),
      message: context.tr('room.setCoOwnerConfirm', {'name': target.name}),
      confirmText: context.tr('common.confirm'),
      cancelText: context.tr('common.cancel'),
      icon: Icons.verified_user_rounded,
      confirmColor: primaryColor,
      onConfirm: () async {
        setState(() => _isProcessingAction = true);
        AppAlert.loading(
          context,
          message: context.tr('room.settingCoOwnerLoading'),
        );
        try {
          await _roomService.setCoOwner(
            roomId: room.id,
            newCoOwnerUid: target.uid,
          );
          if (context.mounted) {
            AppAlert.dismissLoading(context);
            await AppAlert.success(
              Get.context,
              title: context.tr('room.setCoOwnerSuccess'),
              message: context.tr('room.setCoOwnerSuccessDesc', {
                'name': target.name,
              }),
            );
          }
        } catch (e) {
          if (context.mounted) {
            AppAlert.dismissLoading(context);
            AppAlert.error(
              context,
              title: context.tr('room.setCoOwnerFailed'),
              message: UserFeedbackMessage.from(
                e,
                fallback: context.tr('room.setCoOwnerFailedFallback'),
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isProcessingAction = false);
        }
      },
    );
  }

  void _handleRemoveCoOwner(
    BuildContext context,
    RoomMemberModel target,
    RoomModel room,
  ) {
    if (_isProcessingAction || !mounted) return;
    HapticFeedback.lightImpact();

    AppAlert.confirm(
      context,
      title: context.tr('room.removeCoOwnerBtn'),
      message: context.tr('room.removeCoOwnerConfirm', {'name': target.name}),
      confirmText: context.tr('room.revokeAction'),
      cancelText: context.tr('common.cancel'),
      isDestructive: true,
      icon: Icons.remove_moderator_rounded,
      onConfirm: () async {
        setState(() => _isProcessingAction = true);
        AppAlert.loading(
          context,
          message: context.tr('room.removingCoOwnerLoading'),
        );
        try {
          await _roomService.removeCoOwner(roomId: room.id);
          if (context.mounted) {
            AppAlert.dismissLoading(context);
            await AppAlert.success(
              Get.context,
              title: context.tr('room.removeCoOwnerSuccess'),
              message: context.tr('room.removeCoOwnerSuccessDesc', {
                'name': target.name,
              }),
            );
          }
        } catch (e) {
          if (context.mounted) {
            AppAlert.dismissLoading(context);
            AppAlert.error(
              context,
              title: context.tr('room.removeCoOwnerFailed'),
              message: UserFeedbackMessage.from(
                e,
                fallback: context.tr('room.removeCoOwnerFailedFallback'),
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isProcessingAction = false);
        }
      },
    );
  }

  void _handleTransferOwnership(
    BuildContext context,
    RoomMemberModel target,
    RoomModel room,
  ) {
    if (_isProcessingAction || !mounted) return;
    HapticFeedback.mediumImpact();

    final primaryColor = context.hc.brand;

    AppAlert.confirm(
      context,
      title: context.tr('room.transferOwnershipBtn'),
      message: context.tr('room.transferOwnershipConfirm', {
        'name': target.name,
      }),
      confirmText: context.tr('room.transferAction'),
      cancelText: context.tr('common.cancel'),
      isDestructive: false,
      icon: Icons.admin_panel_settings_rounded,
      confirmColor: primaryColor,
      onConfirm: () async {
        setState(() => _isProcessingAction = true);
        AppAlert.loading(
          context,
          message: context.tr('room.transferringOwnershipLoading'),
        );
        try {
          await _roomService.transferOwnership(
            roomId: room.id,
            newOwnerUid: target.uid,
          );
          if (context.mounted) {
            AppAlert.dismissLoading(context);
            await AppAlert.success(
              Get.context,
              title: context.tr('room.transferOwnershipSuccess'),
              message: context.tr('room.transferOwnershipSuccessDesc', {
                'name': target.name,
              }),
            );
          }
        } catch (e) {
          if (context.mounted) {
            AppAlert.dismissLoading(context);
            AppAlert.error(
              context,
              title: context.tr('room.transferOwnershipFailed'),
              message: UserFeedbackMessage.from(
                e,
                fallback: context.tr('room.transferOwnershipFailedFallback'),
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isProcessingAction = false);
        }
      },
    );
  }

  void _showSelectSuccessorSheet(
    BuildContext context,
    RoomModel room,
    List<RoomMemberModel> candidates,
  ) {
    final isDark = context.isDarkTheme;
    final cardBg = context.hc.surface;
    final headingColor = context.hc.textPrimary;
    final bodyColor = context.hc.textSecondary;
    final dividerColor = context.hc.border;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxSheetWidth),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.supervisor_account_rounded,
                          color: Color(0xFFD97706),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('room.noCoOwnerSelectCompanionTitle'),
                              style: AppTypography.titleMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('room.noCoOwnerSelectCompanionDesc'),
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: dividerColor),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: candidates.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final candidate = candidates[index];
                        final initial = candidate.name.trim().isNotEmpty
                            ? candidate.name.trim()[0].toUpperCase()
                            : '?';
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              AppAlert.confirm(
                                context,
                                title: context.tr('room.bequeathAndLeaveTitle'),
                                message: context.tr(
                                  'room.bequeathToSelectedDesc',
                                  {'name': candidate.name},
                                ),
                                confirmText: context.tr(
                                  'room.bequeathAndLeaveAction',
                                ),
                                cancelText: context.tr('common.cancel'),
                                isDestructive: true,
                                onConfirm: () => _executeLeaveRoom(
                                  context,
                                  room,
                                  successorUid: candidate.uid,
                                  successorName: candidate.name,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(color: dividerColor),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(
                                      0xFF1D4ED8,
                                    ).withValues(alpha: 0.15),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Color(0xFF1D4ED8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      candidate.name,
                                      style: TextStyle(
                                        color: headingColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: Text(
                        context.tr('common.cancel'),
                        style: TextStyle(color: bodyColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLeaveRoom(BuildContext context, RoomModel room) {
    if (_isProcessingAction || !mounted) return;
    HapticFeedback.lightImpact();

    final currentUid = _effectiveUid;
    if (currentUid == null) return;

    final isOwner = room.isPrimaryOwner(currentUid);
    final otherPendamping = _allMembers
        .where((m) => m.isPendamping && m.uid != currentUid)
        .toList();

    if (isOwner) {
      final activeCoOwner = room.coOwnerId != null && room.coOwnerId!.isNotEmpty
          ? otherPendamping.where((m) => m.uid == room.coOwnerId).firstOrNull
          : null;

      if (activeCoOwner != null) {
        // Scenario A: Co-Owner exists and is active -> Prompt to bequeath & leave
        AppAlert.confirm(
          context,
          title: context.tr('room.bequeathAndLeaveTitle'),
          message: context.tr('room.bequeathToCoOwnerDesc', {
            'name': activeCoOwner.name,
          }),
          confirmText: context.tr('room.bequeathAndLeaveAction'),
          cancelText: context.tr('common.cancel'),
          isDestructive: true,
          onConfirm: () => _executeLeaveRoom(
            context,
            room,
            successorUid: activeCoOwner.uid,
            successorName: activeCoOwner.name,
          ),
        );
      } else if (otherPendamping.isNotEmpty) {
        // Scenario B/C: No Co-Owner or Co-Owner invalid, other companions exist -> Select Companion
        _showSelectSuccessorSheet(context, room, otherPendamping);
      } else {
        // Sole companion/owner cannot leave room orphaned
        AppAlert.warning(
          context,
          title: context.tr('room.soleOwnerCannotLeaveTitle'),
          message: context.tr('room.soleOwnerCannotLeaveDesc'),
          okText: context.tr('common.close'),
        );
      }
    } else {
      // Scenario D: Regular companion or jamaah leaving
      AppAlert.confirm(
        context,
        title: context.tr('room.leaveRoomTitle'),
        message: context.tr('room.leaveRoomDesc'),
        confirmText: context.tr('room.leaveRoomConfirm'),
        cancelText: context.tr('common.cancel'),
        isDestructive: true,
        onConfirm: () => _executeLeaveRoom(context, room),
      );
    }
  }

  Future<void> _executeLeaveRoom(
    BuildContext context,
    RoomModel room, {
    String? successorUid,
    String? successorName,
  }) async {
    if (_isProcessingAction || !mounted) return;
    setState(() => _isProcessingAction = true);
    AppAlert.loading(context, message: context.tr('room.leavingRoomLoading'));

    try {
      final hajiCare = Get.isRegistered<HajiCareController>()
          ? Get.find<HajiCareController>()
          : null;
      final user = _currentFirebaseUser;
      final currentUid = _effectiveUid ?? '';
      final uName = user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!
          : (hajiCare?.pendampingName.value ??
                context.tr('room.defaultMemberName'));
      final roleStr = hajiCare?.role == UserRole.pendamping
          ? 'pendamping'
          : 'jamaah';

      await _roomService.leaveRoom(
        roomId: room.id,
        uid: currentUid,
        userName: uName,
        role: roleStr,
        roomName: room.name,
        successorUid: successorUid,
      );
      await hajiCare?.clearActiveRoomSession();

      if (context.mounted) {
        AppAlert.dismissLoading(context);
        final msg = successorName != null
            ? context.tr('room.leaveRoomBequeathedSuccessDesc', {
                'name': successorName,
              })
            : context.tr('room.leaveRoomSuccessDesc');

        await AppAlert.success(
          Get.context,
          title: context.tr('room.leaveRoomSuccess'),
          message: msg,
          autoDismissDuration: const Duration(seconds: 3),
        );
        if (!context.mounted) return;
        if (Navigator.of(context).canPop()) {
          Get.back();
        } else {
          Get.offAllNamed(
            hajiCare?.role == UserRole.pendamping
                ? AppRoutes.dashboardPendamping
                : AppRoutes.dashboardJamaah,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.dismissLoading(context);
        AppAlert.error(
          context,
          title: context.tr('room.leaveRoomFailed'),
          message: UserFeedbackMessage.from(
            e,
            fallback: context.tr('room.leaveRoomFailedFallback'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkTheme;
    final scaffoldBg = context.hc.canvas;
    final cardBg = context.hc.surface;
    final headingColor = context.hc.textPrimary;
    final bodyColor = context.hc.textSecondary;
    final primaryColor = context.hc.brand;

    // Loading State
    if (_isLoadingRoom && _room == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: headingColor),
            tooltip: context.tr('common.back'),
            onPressed: () => Get.back(),
          ),
          title: Text(
            context.tr('room.roomDetailTitle'),
            style: AppTypography.headlineMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    // Room Not Found State
    if (_room == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: headingColor),
            tooltip: context.tr('common.back'),
            onPressed: () => Get.back(),
          ),
          title: Text(
            context.tr('room.roomDetailTitle'),
            style: AppTypography.headlineMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: bodyColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.room_preferences_outlined,
                    size: 38,
                    color: bodyColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr('room.roomNotFound'),
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr('room.roomNotFoundDesc'),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(context.tr('room.returnToHome')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final room = _room!;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: headingColor),
          tooltip: context.tr('common.back'),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.capitalizedName,
              style: AppTypography.headlineMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${context.tr('room.roomCode')}: ${room.code}',
              style: AppTypography.captionSmall.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),
            tooltip: context.tr('room.showQrTooltip'),
            onPressed: () => RoomQrDialog.show(context, room: room),
          ),
          if (_canEditOrDeleteRoom()) ...[
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: headingColor),
              tooltip: context.tr('room.roomOptions'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: cardBg,
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditRoomSheet(context, room);
                } else if (val == 'delete') {
                  _handleDeleteRoom(context, room);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: headingColor),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('room.editRoom'),
                        style: TextStyle(
                          color: headingColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: context.hc.danger,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('room.deleteRoom'),
                        style: TextStyle(
                          color: context.hc.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          _subscribeToRoom(room.id);
          _subscribeToMembers(room.id);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ResponsiveCenter(
          maxWidth: AppBreakpoints.maxTabletContentWidth,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // 1. Hero Room Information Card
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Main Card Body (Below floating hero
                  Container(
                    margin: const EdgeInsets.only(top: 28),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: context.hc.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.28 : 0.05,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Spacing to clear floating hero container
                        const SizedBox(height: 82),

                        // Main Body Information (Room Data & Privileged Actions
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          child: Column(
                            children: [
                              // Kode Room Banner Tile
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: context.hc.surfaceSand.withValues(
                                    alpha: 0.35,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: context.hc.border,
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(
                                          alpha: isDark ? 0.20 : 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Icon(
                                        Icons.key_rounded,
                                        size: 17,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.tr('room.roomCode'),
                                            style: TextStyle(
                                              color: bodyColor.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            room.code,
                                            style: TextStyle(
                                              color: headingColor,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2.8,
                                              fontSize: 15.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Clipboard.setData(
                                          ClipboardData(text: room.code),
                                        );
                                        AppAlert.success(
                                          context,
                                          title: context.tr('room.codeCopied'),
                                          message: context.tr(
                                            'room.codeCopiedMsg',
                                            {'code': room.code},
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 11,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                          border: Border.all(
                                            color: context.hc.border,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.copy_rounded,
                                              size: 13,
                                              color: primaryColor,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              context.tr('common.copy'),
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Maktab & Kloter Grid (Spacious 2-column cards
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 13,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.hc.surfaceSand
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: context.hc.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: context.hc.surfaceSand,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.hotel_rounded,
                                              size: 16,
                                              color: context.hc.brand,
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  context.tr('room.maktab'),
                                                  style: TextStyle(
                                                    color: bodyColor.withValues(
                                                      alpha: 0.7,
                                                    ),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 1),
                                                Text(
                                                  room.maktab?.isNotEmpty ==
                                                          true
                                                      ? _capitalizeWords(
                                                          room.maktab!,
                                                        )
                                                      : '-',
                                                  style: TextStyle(
                                                    color: headingColor,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 13,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.hc.surfaceSand
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: context.hc.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: context.hc.surfaceSand,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.flight_takeoff_rounded,
                                              size: 16,
                                              color: context.hc.brand,
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  context.tr('room.kloter'),
                                                  style: TextStyle(
                                                    color: bodyColor.withValues(
                                                      alpha: 0.7,
                                                    ),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 1),
                                                Text(
                                                  room.kloter?.isNotEmpty ==
                                                          true
                                                      ? room.kloter!
                                                      : '-',
                                                  style: TextStyle(
                                                    color: headingColor,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (room.createdAt != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_note_rounded,
                                      size: 13,
                                      color: bodyColor.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        context.tr('room.createdAtDate', {
                                          'date': _formatDate(
                                            room.createdAt,
                                            context,
                                          ),
                                        }),
                                        style: TextStyle(
                                          color: bodyColor.withValues(
                                            alpha: 0.65,
                                          ),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Aksi Room: Tombol QR Code & Keluar Room (Berdampingan secara responsif
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 360;

                                  final qrButton = SizedBox(
                                    height: 46,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: context.hc.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.pill,
                                          ),
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        context.tr('room.viewShareQrBtn'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () => RoomQrDialog.show(
                                        context,
                                        room: room,
                                      ),
                                    ),
                                  );

                                  final leaveButton = SizedBox(
                                    height: 46,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: context.hc.danger,
                                        side: BorderSide(
                                          color: context.hc.danger.withValues(
                                            alpha: isDark ? 0.6 : 0.45,
                                          ),
                                          width: 1.2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.pill,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.logout_rounded,
                                        size: 18,
                                        color: context.hc.danger,
                                      ),
                                      label: Text(
                                        context.tr('room.leaveRoomBtn'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: _isProcessingAction
                                          ? null
                                          : () =>
                                                _handleLeaveRoom(context, room),
                                    ),
                                  );

                                  if (isNarrow) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        qrButton,
                                        const SizedBox(height: 10),
                                        leaveButton,
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: qrButton),
                                      const SizedBox(width: 10),
                                      Expanded(child: leaveButton),
                                    ],
                                  );
                                },
                              ),

                              // Role Privileges: Tombol Edit & Hapus (Admin & Creator Pendamping ONLY
                              if (_canEditOrDeleteRoom()) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: headingColor,
                                          side: BorderSide(
                                            color: context.hc.border,
                                            width: 1.2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.pill,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          size: 15,
                                          color: primaryColor,
                                        ),
                                        label: Flexible(
                                          child: Text(
                                            context.tr('room.editRoom'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _showEditRoomSheet(context, room),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: context.hc.danger,
                                          side: BorderSide(
                                            color: context.hc.danger.withValues(
                                              alpha: 0.45,
                                            ),
                                            width: 1.2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.pill,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 15,
                                        ),
                                        label: Flexible(
                                          child: Text(
                                            context.tr('room.deleteRoom'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _handleDeleteRoom(context, room),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Member Breakdown Strip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: context.hc.surfaceSand.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(22),
                            ),
                            border: Border(
                              top: BorderSide(color: context.hc.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatSummaryItem(
                                  label: context.tr('room.totalMembers'),
                                  value: '$_totalCount',
                                  color: headingColor,
                                ),
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: context.hc.border,
                              ),
                              Expanded(
                                child: _buildStatSummaryItem(
                                  label: context.tr('room.roleJamaah'),
                                  value: '$_jamaahCount',
                                  color: context.hc.islamic,
                                ),
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: context.hc.border,
                              ),
                              Expanded(
                                child: _buildStatSummaryItem(
                                  label: context.tr('room.roleCompanion'),
                                  value: '$_pendampingCount',
                                  color: const Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Hero Header (Protruding at top
                  Positioned(
                    top: 0,
                    left: 14,
                    right: 14,
                    height: 96,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF38251A),
                                  const Color(0xFF1F140D),
                                ]
                              : [
                                  context.hc.brand,
                                  context.hc.brand.withValues(alpha: 0.85),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: context.hc.accent.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.hc.shadow,
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Ambient Glow Circles
                          Positioned(
                            top: -15,
                            right: -15,
                            child: Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.hc.accent.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            left: -20,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.hc.accent.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                          ),
                          // Inner Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: context.hc.accent.withValues(
                                      alpha: 0.22,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: context.hc.accent.withValues(
                                        alpha: 0.55,
                                      ),
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.meeting_room_rounded,
                                    color: context.hc.accent,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room.capitalizedName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        context.tr('room.maktabGroupSub'),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.72,
                                          ),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (room.isActive
                                                ? const Color(0xFF1B633E)
                                                : Colors.black45)
                                            .withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    border: Border.all(
                                      color: room.isActive
                                          ? const Color(0xFF4ADE80)
                                          : Colors.white30,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: room.isActive
                                              ? const Color(0xFF4ADE80)
                                              : Colors.white70,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        room.isActive
                                            ? context.tr('room.active')
                                            : context.tr('room.inactive'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
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
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Search Bar & Filter Chips
              _buildSearchAndFilters(
                context,
                cardBg,
                headingColor,
                bodyColor,
                primaryColor,
                isDark,
              ),

              const SizedBox(height: AppSpacing.md),

              // 3. Pagination Summary & Limit Selector
              _buildPaginationHeader(
                headingColor,
                bodyColor,
                primaryColor,
                isDark,
              ),

              const SizedBox(height: AppSpacing.sm),

              // 4. Members List (Paginated
              _buildMembersList(
                context,
                room,
                cardBg,
                headingColor,
                bodyColor,
                primaryColor,
                isDark,
              ),

              const SizedBox(height: AppSpacing.md),

              // 5. Pagination Footer Navigation
              if (_filteredMembers.isNotEmpty)
                _buildPaginationFooter(
                  cardBg,
                  headingColor,
                  bodyColor,
                  primaryColor,
                  isDark,
                ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 20,
                color: _searchQuery.isNotEmpty
                    ? primaryColor
                    : bodyColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: headingColor,
                    fontSize: 13.5,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('room.searchMember'),
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: bodyColor.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: bodyColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterButtonItem(
                label: context.tr('room.all'),
                count: _totalCount,
                icon: Icons.people_alt_rounded,
                isSelected: _selectedFilter == 'Semua',
                headingColor: headingColor,
                bodyColor: bodyColor,
                cardBg: cardBg,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Semua';
                    _currentPage = 1;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildFilterButtonItem(
                label: context.tr('room.roleJamaah'),
                count: _jamaahCount,
                icon: Icons.person_rounded,
                isSelected: _selectedFilter == 'Jamaah',
                headingColor: headingColor,
                bodyColor: bodyColor,
                cardBg: cardBg,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Jamaah';
                    _currentPage = 1;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildFilterButtonItem(
                label: context.tr('room.roleCompanion'),
                count: _pendampingCount,
                icon: Icons.health_and_safety_rounded,
                isSelected: _selectedFilter == 'Pendamping',
                headingColor: headingColor,
                bodyColor: bodyColor,
                cardBg: cardBg,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Pendamping';
                    _currentPage = 1;
                  });
                },
              ),
              if (_canManageMembers()) ...[
                const SizedBox(width: 8),
                _buildFilterButtonItem(
                  label: context.tr('room.filterSos'),
                  count: _sosCount,
                  icon: Icons.sos_rounded,
                  isSelected: _selectedFilter == 'SOS',
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  cardBg: cardBg,
                  isDark: isDark,
                  isSos: true,
                  onTap: () {
                    setState(() {
                      _selectedFilter = 'SOS';
                      _currentPage = 1;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButtonItem({
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
    required Color headingColor,
    required Color bodyColor,
    required Color cardBg,
    required bool isDark,
    bool isSos = false,
    required VoidCallback onTap,
  }) {
    final hasActiveSos = isSos && count > 0;

    Color itemBg;
    if (isSelected) {
      if (isSos) {
        itemBg = context.hc.danger;
      } else {
        itemBg = context.hc.brand;
      }
    } else {
      itemBg = cardBg;
    }

    Color itemBorderColor;
    if (isSelected) {
      itemBorderColor = isSos ? context.hc.danger : context.hc.accent;
    } else if (hasActiveSos) {
      itemBorderColor = context.hc.danger.withValues(alpha: 0.55);
    } else {
      itemBorderColor = context.hc.border;
    }

    Color iconColor;
    if (isSelected) {
      iconColor = isSos ? context.hc.onPrimary : context.hc.onPrimaryContainer;
    } else if (isSos) {
      iconColor = context.hc.danger;
    } else {
      iconColor = isDark ? context.hc.textSecondary : context.hc.textPrimary;
    }

    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (isSos) {
      textColor = hasActiveSos ? context.hc.danger : headingColor;
    } else {
      textColor = headingColor;
    }

    Color badgeBg;
    Color badgeTextColor;
    if (isSelected) {
      badgeBg = isSos
          ? Colors.white.withValues(alpha: 0.25)
          : context.hc.accent;
      badgeTextColor = isSos ? context.hc.onPrimary : context.hc.brand;
    } else if (isSos && count > 0) {
      badgeBg = context.hc.danger.withValues(alpha: isDark ? 0.25 : 0.14);
      badgeTextColor = context.hc.danger;
    } else {
      badgeBg = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : context.hc.surfaceSand;
      badgeTextColor = isDark ? context.hc.textSecondary : bodyColor;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: itemBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: itemBorderColor,
              width: isSelected || hasActiveSos ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: isSos
                          ? context.hc.danger.withValues(alpha: 0.25)
                          : context.hc.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.hc.onPrimary.withValues(alpha: 0.14)
                      : (isSos
                            ? context.hc.danger.withValues(alpha: 0.12)
                            : context.hc.surfaceSand),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: isSos
                              ? Colors.white.withValues(alpha: 0.5)
                              : context.hc.accent.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isSos && count > 0
                              ? context.hc.danger.withValues(alpha: 0.4)
                              : context.hc.border,
                          width: 1,
                        ),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationHeader(
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
    bool isDark,
  ) {
    final total = _filteredMembers.length;
    final start = total == 0 ? 0 : (_currentPage - 1) * _limitPerPage + 1;
    final end = (start + _limitPerPage - 1).clamp(0, total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            total == 0
                ? context.tr('room.noMembers')
                : context.tr('room.showingMembers', {
                    'start': '$start',
                    'end': '$end',
                    'total': '$total',
                  }),
            style: AppTypography.captionSmall.copyWith(
              color: bodyColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('room.limitLabel'),
              style: AppTypography.captionSmall.copyWith(
                color: bodyColor.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            ..._availableLimits.map((lim) {
              final isCurrentLimit = _limitPerPage == lim;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _limitPerPage = lim;
                    _currentPage = 1;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentLimit
                        ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isCurrentLimit
                          ? primaryColor
                          : bodyColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '$lim',
                    style: TextStyle(
                      color: isCurrentLimit ? primaryColor : bodyColor,
                      fontSize: 10.5,
                      fontWeight: isCurrentLimit
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // MEMBERS LIST (PAGABATED
  Widget _buildMembersList(
    BuildContext context,
    RoomModel room,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
    bool isDark,
  ) {
    if (_isLoadingMembers) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    final pagedList = _pagedMembers;

    if (pagedList.isEmpty) {
      if (_searchQuery.isNotEmpty || _selectedFilter != 'Semua') {
        return AppCard(
          backgroundColor: cardBg,
          borderColor: context.hc.border,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.md,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 42,
                    color: bodyColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr('room.noMemberMatchingCriteria'),
                    style: AppTypography.titleSmall.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _searchQuery.isNotEmpty
                        ? context.tr('room.noMemberSearchMatch', {
                            'query': _searchQuery,
                          })
                        : context.tr('room.noMemberCategoryMatch', {
                            'category': _getFilterLabel(_selectedFilter),
                          }),
                    textAlign: TextAlign.center,
                    style: AppTypography.captionSmall.copyWith(
                      color: bodyColor.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedFilter = 'Semua';
                        _currentPage = 1;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(context.tr('room.resetFilterSearch')),
                    style: TextButton.styleFrom(foregroundColor: primaryColor),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return AppCard(
        backgroundColor: cardBg,
        borderColor: context.hc.border,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  ),
                  child: Icon(
                    Icons.groups_outlined,
                    size: 32,
                    color: primaryColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr('room.noMembersJoinedYet'),
                  style: AppTypography.titleSmall.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('room.shareCodeToJoinDesc'),
                  textAlign: TextAlign.center,
                  style: AppTypography.captionSmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(
                      color: primaryColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: Text(
                    context.tr('room.openQrDialogBtn'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => RoomQrDialog.show(context, room: room),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final canManage = _canManageMembers();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pagedList.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final member = pagedList[index];
        return _MemberTile(
          room: room,
          member: member,
          cardBg: cardBg,
          headingColor: headingColor,
          bodyColor: bodyColor,
          primaryColor: primaryColor,
          isDark: isDark,
          canManage: canManage,
          onTap: () => _showMemberDetailModal(context, member, room, canManage),
        );
      },
    );
  }

  Widget _buildPaginationFooter(
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
    bool isDark,
  ) {
    final totalPages = _totalPages;
    if (totalPages <= 1) return const SizedBox.shrink();

    final canGoPrev = _currentPage > 1;
    final canGoNext = _currentPage < totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.hc.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: canGoPrev
                ? () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            tooltip: context.tr('room.prevPage'),
            color: headingColor,
            disabledColor: bodyColor.withValues(alpha: 0.25),
          ),
          Flexible(
            child: Text(
              context.tr('room.pageOf', {
                'current': '$_currentPage',
                'total': '$totalPages',
              }),
              style: AppTypography.captionSmall.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: canGoNext
                ? () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            tooltip: context.tr('room.nextPage'),
            color: headingColor,
            disabledColor: bodyColor.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }

  RoomMemberModel _resolveRealtimeMember(RoomMemberModel member) {
    RoomMemberModel result = member;

    if (Get.isRegistered<HajiCareController>()) {
      final hajiCtrl = Get.find<HajiCareController>();
      // 1. If active SOS, use SOS location (most critical realtime signal
      final sos = hajiCtrl.activeSosEvents.firstWhereOrNull(
        (s) =>
            (s['userId'] == member.uid || s['jamaahId'] == member.uid) &&
            s['location'] != null,
      );
      if (sos != null) {
        final loc = sos['location'];
        GeoPoint? geo;
        if (loc is GeoPoint) {
          geo = loc;
        } else if (loc is Map) {
          final lat = (loc['latitude'] as num?)?.toDouble();
          final lng = (loc['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) geo = GeoPoint(lat, lng);
        }
        if (geo != null) {
          final ts = (sos['locationUpdatedAt'] is Timestamp)
              ? (sos['locationUpdatedAt'] as Timestamp).toDate()
              : (sos['timestamp'] is Timestamp
                    ? (sos['timestamp'] as Timestamp).toDate()
                    : DateTime.now());
          result = result.copyWith(
            currentLocation: geo,
            locationUpdatedAt: ts,
            sosActive: true,
          );
        }
      } else {
        // 2. Check jamaahList
        final jamaah = hajiCtrl.jamaahList.firstWhereOrNull(
          (j) => j.id == member.uid,
        );
        if (jamaah != null && jamaah.currentLocation != null) {
          if (!result.hasLocation ||
              (jamaah.locationUpdatedAt != null &&
                  (result.locationUpdatedAt == null ||
                      jamaah.locationUpdatedAt!.isAfter(
                        result.locationUpdatedAt!,
                      )))) {
            result = result.copyWith(
              currentLocation: jamaah.currentLocation,
              locationUpdatedAt: jamaah.locationUpdatedAt,
              sosActive: jamaah.sosActive,
            );
          }
        }
      }
    }

    // 3. Check MapController.roomMembers
    if (Get.isRegistered<MapController>()) {
      final mapCtrl = Get.find<MapController>();
      final mapM = mapCtrl.roomMembers.firstWhereOrNull(
        (m) => m.uid == member.uid,
      );
      if (mapM != null && mapM.hasLocation) {
        if (!result.hasLocation ||
            (mapM.locationUpdatedAt != null &&
                (result.locationUpdatedAt == null ||
                    mapM.locationUpdatedAt!.isAfter(
                      result.locationUpdatedAt!,
                    )))) {
          result = result.copyWith(
            currentLocation: mapM.currentLocation,
            locationUpdatedAt: mapM.locationUpdatedAt,
            sosActive: mapM.sosActive || result.sosActive,
          );
        }
      }
    }

    return result;
  }

  void _showMemberDetailModal(
    BuildContext context,
    RoomMemberModel member,
    RoomModel room,
    bool canManage,
  ) {
    final effectiveMember = _resolveRealtimeMember(member);
    final isDark = context.isDarkTheme;
    final headingColor = context.hc.textPrimary;
    final bodyColor = context.hc.textSecondary;
    final primaryColor = context.hc.brand;
    final cardBg = context.hc.surface;
    final dividerColor = context.hc.border;
    final currentUid = _effectiveUid;
    final hajiCare = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final isAdmin = hajiCare?.role == UserRole.admin;
    final isViewerPrimaryOwner =
        currentUid != null && (room.isPrimaryOwner(currentUid) || isAdmin);
    final isTargetSelf =
        currentUid != null && currentUid == effectiveMember.uid;

    // Avatar background color according to role / status
    Color avatarBg;
    if (effectiveMember.sosActive) {
      avatarBg = const Color(0xFFDC2626);
    } else if (effectiveMember.isPrimaryOwner(room)) {
      avatarBg = const Color(0xFFD97706);
    } else if (effectiveMember.isCoOwner(room)) {
      avatarBg = const Color(0xFF7C3AED);
    } else if (effectiveMember.isPendamping) {
      avatarBg = const Color(0xFF1D4ED8);
    } else if (effectiveMember.isJamaah) {
      avatarBg = context.hc.islamic;
    } else {
      avatarBg = primaryColor;
    }

    // Role badge color scheme
    Color roleBadgeBg;
    Color roleBadgeTextColor;
    String roleBadgeLabel;
    IconData roleBadgeIcon;

    if (effectiveMember.isPrimaryOwner(room)) {
      roleBadgeBg = isDark
          ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
          : const Color(0xFFFEF3C7);
      roleBadgeTextColor = isDark
          ? const Color(0xFFFBBF24)
          : const Color(0xFFB45309);
      roleBadgeLabel = context.tr('room.rolePrimaryOwner');
      roleBadgeIcon = Icons.stars_rounded;
    } else if (effectiveMember.isCoOwner(room)) {
      roleBadgeBg = isDark
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
          : const Color(0xFFEDE9FE);
      roleBadgeTextColor = isDark
          ? const Color(0xFFA78BFA)
          : const Color(0xFF6D28D9);
      roleBadgeLabel = context.tr('room.roleCoOwner');
      roleBadgeIcon = Icons.verified_user_rounded;
    } else if (effectiveMember.isPendamping) {
      roleBadgeBg = isDark
          ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
          : const Color(0xFFE0E7FF);
      roleBadgeTextColor = isDark
          ? const Color(0xFF93C5FD)
          : const Color(0xFF1D4ED8);
      roleBadgeLabel = context.tr('room.roleCompanion');
      roleBadgeIcon = Icons.health_and_safety_rounded;
    } else if (effectiveMember.isJamaah) {
      roleBadgeBg = context.hc.success.withValues(alpha: isDark ? 0.25 : 0.12);
      roleBadgeTextColor = context.hc.success;
      roleBadgeLabel = context.tr('room.roleJamaah');
      roleBadgeIcon = Icons.person_rounded;
    } else {
      roleBadgeBg = primaryColor.withValues(alpha: 0.12);
      roleBadgeTextColor = primaryColor;
      roleBadgeLabel = context.tr('room.roleAdmin');
      roleBadgeIcon = Icons.admin_panel_settings_rounded;
    }

    final distanceText = _getMemberDistance(effectiveMember);

    // Primary action button colors adaptive to theme (vibrant pill
    final actionBtnBg = effectiveMember.isPendamping
        ? context.hc.accent
        : context.hc.islamic;
    final actionBtnFg = context.hc.onPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxSheetWidth),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Clearance for the overlapping floating avatar
                      const SizedBox(height: 48),

                      // Member Name (centered like title in
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          effectiveMember.name,
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

                      // Role Badge / Subtitle (centered like subtitle in
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  roleBadgeIcon,
                                  size: 12,
                                  color: roleBadgeTextColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  roleBadgeLabel.toUpperCase(),
                                  style: TextStyle(
                                    color: roleBadgeTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (effectiveMember.sosActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.hc.danger.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                context.tr('room.sosActiveBadge'),
                                style: TextStyle(
                                  color: context.hc.danger,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

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
                                      color: effectiveMember.hasLocation
                                          ? context.hc.islamic
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _getMemberLocationStatus(
                                        context,
                                        effectiveMember,
                                      ),
                                      style: TextStyle(
                                        color: headingColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

                            // Row 2: Distance from User (Jarak
                            _buildDetailHorizontalRow(
                              label: context.tr('room.distanceFromYou'),
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
                              valueText: effectiveMember.joinedAt != null
                                  ? _formatDate(
                                      effectiveMember.joinedAt,
                                      context,
                                    )
                                  : context.tr('room.unknown'),
                              headingColor: headingColor,
                              bodyColor: bodyColor,
                            ),

                            // Row 4: Coordinates (if available
                            if (effectiveMember.hasLocation) ...[
                              Divider(
                                height: 22,
                                thickness: 0.8,
                                color: dividerColor,
                              ),
                              _buildDetailHorizontalRow(
                                label: context.tr('room.locationCoordinates'),
                                valueText:
                                    '${effectiveMember.latitude!.toStringAsFixed(5)}, ${effectiveMember.longitude!.toStringAsFixed(5)}',
                                headingColor: headingColor,
                                bodyColor: bodyColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          children: [
                            if (effectiveMember.hasLocation)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    final targetMember = _resolveRealtimeMember(
                                      effectiveMember,
                                    );
                                    final targetCoord = LatLng(
                                      targetMember.latitude!,
                                      targetMember.longitude!,
                                    );
                                    if (Get.isRegistered<MapController>()) {
                                      final mapCtrl = Get.find<MapController>();
                                      mapCtrl.selectedFilter.value = 0;
                                      mapCtrl.selectedMember.value =
                                          targetMember;
                                      mapCtrl.pendingFocusCoordinate =
                                          targetCoord;
                                      mapCtrl.pendingFocusZoom = 17.5;
                                    }
                                    if (Get.isRegistered<
                                      DashboardController
                                    >()) {
                                      Get.find<DashboardController>().changeTab(
                                        1,
                                      );
                                      Get.until((route) => route.isFirst);
                                      Future.delayed(
                                        const Duration(milliseconds: 250),
                                        () {
                                          if (Get.isRegistered<
                                            MapController
                                          >()) {
                                            final mapCtrl =
                                                Get.find<MapController>();
                                            mapCtrl.focusOnMember(
                                              targetMember,
                                              autoRoute: false,
                                            );
                                            mapCtrl.focusCoordinate(
                                              targetCoord,
                                              destZoom: 17.5,
                                            );
                                          }
                                        },
                                      );
                                    } else {
                                      if (Get.isRegistered<MapController>()) {
                                        Get.find<MapController>().focusOnMember(
                                          targetMember,
                                          autoRoute: false,
                                        );
                                      }
                                      Get.back();
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.near_me_rounded,
                                    size: 18,
                                  ),
                                  label: Flexible(
                                    child: Text(
                                      context.tr('room.viewOnMap'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                            if (canManage && effectiveMember.isJamaah) ...[
                              if (effectiveMember.hasLocation)
                                const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _handleRemoveMember(
                                      context,
                                      effectiveMember,
                                      room,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.person_remove_rounded,
                                    size: 16,
                                  ),
                                  label: Flexible(
                                    child: Text(
                                      context.tr('room.removeFromRoom'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.hc.danger,
                                    side: BorderSide(
                                      color: context.hc.danger.withValues(
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
                            // Co-Owner and Ownership actions for Primary Owner viewing another Companion
                            if (isViewerPrimaryOwner &&
                                !isTargetSelf &&
                                effectiveMember.isPendamping) ...[
                              if (effectiveMember.hasLocation)
                                const SizedBox(height: 10),

                              // Button 1: Set / Replace / Remove Co-Owner
                              if (effectiveMember.isCoOwner(room))
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _handleRemoveCoOwner(
                                        context,
                                        effectiveMember,
                                        room,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.remove_moderator_rounded,
                                      size: 16,
                                    ),
                                    label: Flexible(
                                      child: Text(
                                        context.tr('room.removeCoOwnerBtn'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark
                                          ? const Color(0xFFA78BFA)
                                          : const Color(0xFF7C3AED),
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(
                                                0xFFA78BFA,
                                              ).withValues(alpha: 0.4)
                                            : const Color(
                                                0xFF7C3AED,
                                              ).withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _handleSetCoOwner(
                                        context,
                                        effectiveMember,
                                        room,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.verified_user_rounded,
                                      size: 16,
                                    ),
                                    label: Flexible(
                                      child: Text(
                                        room.coOwnerId != null &&
                                                room.coOwnerId!.isNotEmpty
                                            ? context.tr(
                                                'room.replaceCoOwnerBtn',
                                              )
                                            : context.tr('room.setCoOwnerBtn'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark
                                          ? const Color(0xFFA78BFA)
                                          : const Color(0xFF7C3AED),
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(
                                                0xFFA78BFA,
                                              ).withValues(alpha: 0.4)
                                            : const Color(
                                                0xFF7C3AED,
                                              ).withValues(alpha: 0.4),
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

                              const SizedBox(height: 10),

                              // Button 2: Transfer Primary Ownership
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _handleTransferOwnership(
                                      context,
                                      effectiveMember,
                                      room,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.stars_rounded,
                                    size: 16,
                                  ),
                                  label: Flexible(
                                    child: Text(
                                      context.tr('room.transferOwnershipBtn'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFFD97706),
                                    side: BorderSide(
                                      color: isDark
                                          ? const Color(
                                              0xFFFBBF24,
                                            ).withValues(alpha: 0.4)
                                          : const Color(
                                              0xFFD97706,
                                            ).withValues(alpha: 0.4),
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

                // Overlapping Circular Avatar (top center
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
                        color: avatarBg,
                        border: Border.all(color: context.hc.surface, width: 4),
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
                          effectiveMember.sosActive
                              ? 'SOS'
                              : (effectiveMember.name.isNotEmpty
                                    ? effectiveMember.name[0].toUpperCase()
                                    : '?'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: effectiveMember.sosActive ? 20 : 28,
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
      },
    );
  }

  String _getMemberDistance(RoomMemberModel member) {
    if (!member.hasLocation) return context.tr('room.locationNotAvailable');
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
      return context.tr('room.notDetected');
    }

    final meters = Geolocator.distanceBetween(
      userLat,
      userLng,
      member.latitude!,
      member.longitude!,
    );

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
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: bodyColor.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  void _handleRemoveMember(
    BuildContext context,
    RoomMemberModel member,
    RoomModel room,
  ) {
    HapticFeedback.mediumImpact();
    AppAlert.confirm(
      context,
      title: context.tr('room.removeMemberTitle'),
      message: context.tr('room.removeConfirmPrompt', {'name': member.name}),
      confirmText: context.tr('room.removeAction'),
      cancelText: context.tr('common.cancel'),
      isDestructive: true,
      onConfirm: () async {
        try {
          final user = _currentFirebaseUser;
          final actorUid = _effectiveUid ?? 'petugas';
          final actorName = user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!
              : context.tr('room.defaultActorOfficer');

          await _roomService.removeJamaahFromRoom(
            roomId: room.id,
            jamaahUid: member.uid,
            actorUid: actorUid,
            actorRole: 'pendamping',
            actorName: actorName,
            roomName: room.name,
          );

          if (context.mounted) {
            AppAlert.success(
              context,
              title: context.tr('room.memberRemoved'),
              message: context.tr('room.memberRemovedSuccess', {
                'name': member.name,
              }),
            );
          }
        } catch (e) {
          if (context.mounted) {
            AppAlert.error(
              context,
              title: context.tr('room.memberRemoveFailed'),
              message: UserFeedbackMessage.from(
                e,
                fallback: context.tr('room.memberRemoveFailedFallback'),
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildStatSummaryItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.captionSmall.copyWith(
            color: color.withValues(alpha: 0.8),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final RoomModel room;
  final RoomMemberModel member;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final Color primaryColor;
  final bool isDark;
  final bool canManage;
  final VoidCallback onTap;

  const _MemberTile({
    required this.room,
    required this.member,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.primaryColor,
    required this.isDark,
    required this.canManage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeTextColor;
    String roleLabel;
    IconData roleIcon;

    if (member.isPrimaryOwner(room)) {
      badgeBg = isDark
          ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
          : const Color(0xFFFEF3C7);
      badgeTextColor = isDark
          ? const Color(0xFFFBBF24)
          : const Color(0xFFB45309);
      roleLabel = context.tr('room.rolePrimaryOwner');
      roleIcon = Icons.stars_rounded;
    } else if (member.isCoOwner(room)) {
      badgeBg = isDark
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
          : const Color(0xFFEDE9FE);
      badgeTextColor = isDark
          ? const Color(0xFFA78BFA)
          : const Color(0xFF6D28D9);
      roleLabel = context.tr('room.roleCoOwner');
      roleIcon = Icons.verified_user_rounded;
    } else if (member.isPendamping) {
      badgeBg = isDark
          ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
          : const Color(0xFFE0E7FF);
      badgeTextColor = isDark
          ? const Color(0xFF93C5FD)
          : const Color(0xFF1D4ED8);
      roleLabel = context.tr('room.roleCompanion');
      roleIcon = Icons.health_and_safety_rounded;
    } else if (member.isJamaah) {
      badgeBg = context.hc.success.withValues(alpha: isDark ? 0.25 : 0.12);
      badgeTextColor = context.hc.success;
      roleLabel = context.tr('room.roleJamaah');
      roleIcon = Icons.person_rounded;
    } else {
      badgeBg = primaryColor.withValues(alpha: isDark ? 0.25 : 0.15);
      badgeTextColor = primaryColor;
      roleLabel = context.tr('room.roleAdmin');
      roleIcon = Icons.admin_panel_settings_rounded;
    }

    final initial = member.name.trim().isNotEmpty
        ? member.name.trim()[0].toUpperCase()
        : '?';

    // Check if this member has an active SOS event
    final hasSos = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>().activeSosEvents.any(
            (e) => e['userId'] == member.uid || e['jamaahId'] == member.uid,
          )
        : false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AppCard(
          backgroundColor: cardBg,
          borderColor: context.hc.border,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: hasSos
                          ? context.hc.danger.withValues(alpha: 0.18)
                          : badgeBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: hasSos
                            ? context.hc.danger.withValues(alpha: 0.6)
                            : badgeTextColor.withValues(alpha: 0.3),
                        width: hasSos ? 1.8 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: hasSos
                          ? Icon(
                              Icons.sos_rounded,
                              color: context.hc.danger,
                              size: 22,
                            )
                          : Text(
                              initial,
                              style: TextStyle(
                                color: badgeTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),
                  // SOS pulse dot
                  if (hasSos)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: context.hc.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm + 4),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.name,
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (hasSos) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.hc.danger.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: context.hc.danger.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sos_rounded,
                                  size: 9,
                                  color: context.hc.danger,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  context.tr('room.sosActiveBadge'),
                                  style: TextStyle(
                                    color: context.hc.danger,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                        ] else if (member.hasLocation) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: context.hc.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            member.joinedAt != null
                                ? context.tr('room.joinedAtDate', {
                                    'date':
                                        '${member.joinedAt!.day}/${member.joinedAt!.month}/${member.joinedAt!.year}',
                                  })
                                : context.tr('room.justJoined'),
                            style: AppTypography.captionSmall.copyWith(
                              color: bodyColor.withValues(alpha: 0.70),
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: badgeTextColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, size: 12, color: badgeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      roleLabel,
                      style: AppTypography.captionSmall.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: bodyColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
