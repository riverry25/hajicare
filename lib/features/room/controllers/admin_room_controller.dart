import '../../../core/locales/app_localizations.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/app_startup_controller.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../models/activity_model.dart';
import '../models/room_member_model.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';

class AdminRoomController extends GetxController {
  final RoomService _roomService = RoomService();

  // Core Room State
  final rooms = <RoomModel>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final selectedRoom = Rxn<RoomModel>();
  final roomMembers = <RoomMemberModel>[].obs;

  // Realtime Command Center Metrics
  final totalJamaah = 0.obs;
  final totalPendamping = 0.obs;
  final activeSosCount = 0.obs;
  final activeSosList = <Map<String, dynamic>>[].obs;
  final resolvedSosList = <Map<String, dynamic>>[].obs;
  final allUsers = <Map<String, dynamic>>[].obs;
  final activities = <ActivityModel>[].obs;
  final roomBreakdowns = <String, Map<String, int>>{}.obs;

  // Paginated Activity State (10 records per batch)
  final paginatedActivities = <ActivityModel>[].obs;
  final isActivitiesPageLoading = false.obs;
  final isActivitiesPageLoadingMore = false.obs;
  final hasMoreActivities = true.obs;
  DocumentSnapshot? _lastActivityDoc;
  String _currentActivityFilter = 'Semua';

  // Room Management Search & Filter
  final searchQuery = ''.obs;
  final statusFilter = 'all'.obs; // 'all' | 'active' | 'inactive'

  // Stream Subscriptions
  StreamSubscription? _roomsSub;
  StreamSubscription? _membersSub;
  StreamSubscription? _activitiesSub;
  StreamSubscription? _sosSub;
  StreamSubscription? _resolvedSosSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _countsSub;
  StreamSubscription? _breakdownSub;

  @override
  void onInit() {
    super.onInit();
    subscribeToAllStreams();
  }

  void subscribeToAllStreams() {
    isLoading.value = true;

    // 1. Rooms Stream
    _roomsSub?.cancel();
    _roomsSub = _roomService.getRoomsStream().listen(
      (roomList) {
        rooms.value = roomList;
        isLoading.value = false;
      },
      onError: (e) {
        debugPrint('[AdminRoomController] Error fetching rooms: $e');
        isLoading.value = false;
      },
    );

    // 2. Activities Stream
    _activitiesSub?.cancel();
    _activitiesSub = _roomService.getRecentActivitiesStream().listen(
      (actList) {
        activities.value = actList;
      },
      onError: (e) {
        debugPrint('[AdminRoomController] Error fetching activities: $e');
      },
    );

    // 3. Active SOS Events Stream
    _sosSub?.cancel();
    _sosSub = _roomService.getActiveSosEventsStream().listen(
      (sosList) {
        activeSosList.value = sosList;
        activeSosCount.value = sosList.length;
      },
      onError: (e) {
        debugPrint('[AdminRoomController] Error fetching SOS events: $e');
      },
    );

    // 4. Resolved SOS Events Stream (for history)
    _resolvedSosSub?.cancel();
    _resolvedSosSub = _roomService.getResolvedSosEventsStream().listen(
      (resList) {
        resolvedSosList.value = resList;
      },
      onError: (e) {
        debugPrint('[AdminRoomController] Error fetching resolved SOS: $e');
      },
    );

    // 5. All Users Stream (realtime jamaah & pendamping data)
    _usersSub?.cancel();
    _usersSub = _roomService.getAllUsersStream().listen(
      (userList) {
        allUsers.value = userList;
        totalJamaah.value = userList
            .where((u) => (u['role'] as String?)?.toLowerCase() == 'jamaah')
            .length;
        totalPendamping.value = userList
            .where((u) => (u['role'] as String?)?.toLowerCase() == 'pendamping')
            .length;
      },
      onError: (e) {
        debugPrint('[AdminRoomController] Error fetching all users: $e');
      },
    );

    // 6. Global Member Counts Stream (fallback)
    _countsSub?.cancel();
    _countsSub = _roomService.getGlobalMemberCountsStream().listen(
      (counts) {
        if (allUsers.isEmpty) {
          totalJamaah.value = counts['jamaah'] ?? 0;
          totalPendamping.value = counts['pendamping'] ?? 0;
        }
      },
      onError: (e) {
        debugPrint('[AdminRoomController] Error fetching member counts: $e');
      },
    );

    // 7. Per-Room Member & SOS Breakdown Stream
    _breakdownSub?.cancel();
    _breakdownSub = _roomService.getAllRoomMemberBreakdownStream().listen(
      (data) {
        roomBreakdowns.value = data;
      },
      onError: (e) {
        debugPrint('[AdminRoomController] Error fetching breakdowns: $e');
      },
    );
  }

  void subscribeToRoomMembers(String roomId) {
    _membersSub?.cancel();
    _membersSub = _roomService
        .getRoomMembersStream(roomId)
        .listen(
          (members) {
            roomMembers.value = members;
          },
          onError: (e) {
            debugPrint('[AdminRoomController] Error fetching room members: $e');
          },
        );
  }

  // ── Computed Getters ────────────────────────────────────────────────────────
  int get activeRoomsCount => rooms.where((r) => r.isActive).length;
  int get inactiveRoomsCount => rooms.where((r) => !r.isActive).length;

  List<RoomModel> get activeRooms => rooms.where((r) => r.isActive).toList();

  List<Map<String, dynamic>> get allJamaah => allUsers
      .where((u) => (u['role'] as String?)?.toLowerCase() == 'jamaah')
      .toList();

  List<Map<String, dynamic>> get allPendamping => allUsers
      .where((u) => (u['role'] as String?)?.toLowerCase() == 'pendamping')
      .toList();

  List<Map<String, dynamic>> get attentionJamaahList {
    final now = DateTime.now();
    return allJamaah.where((u) {
      final hasRoom =
          u['activeRoomId'] != null &&
          (u['activeRoomId'] as String).trim().isNotEmpty;
      final isSos = u['sosActive'] == true;
      if (!hasRoom || isSos) return false;

      final locTimestamp = u['locationUpdatedAt'];
      if (locTimestamp == null) return true;
      if (locTimestamp is Timestamp) {
        final diff = now.difference(locTimestamp.toDate());
        return diff.inMinutes > 15 || u['isGpsActive'] == false;
      }
      return u['isGpsActive'] == false;
    }).toList();
  }

  int getRoomJamaahCount(String roomId) =>
      roomBreakdowns[roomId]?['jamaah'] ?? 0;
  int getRoomPendampingCount(String roomId) =>
      roomBreakdowns[roomId]?['pendamping'] ?? 0;
  int getRoomSosCount(String roomId) => roomBreakdowns[roomId]?['sos'] ?? 0;

  List<RoomModel> get recentActiveRooms {
    return rooms.where((r) => r.isActive).take(2).toList();
  }

  // ── Cursor-based Activity Pagination (10 per page) ──────────────────────────

  Future<void> loadInitialActivities({String filter = 'Semua'}) async {
    _currentActivityFilter = filter;
    _lastActivityDoc = null;
    hasMoreActivities.value = true;
    isActivitiesPageLoading.value = true;
    paginatedActivities.clear();

    final result = await _roomService.getActivitiesPaginated(
      limit: 10,
      startAfterDoc: null,
      categoryFilter: filter,
    );

    paginatedActivities.assignAll(result.items);
    _lastActivityDoc = result.lastDoc;
    hasMoreActivities.value = result.hasMore;
    isActivitiesPageLoading.value = false;
  }

  Future<void> loadMoreActivities() async {
    if (!hasMoreActivities.value ||
        isActivitiesPageLoadingMore.value ||
        _lastActivityDoc == null) {
      return;
    }

    isActivitiesPageLoadingMore.value = true;

    final result = await _roomService.getActivitiesPaginated(
      limit: 10,
      startAfterDoc: _lastActivityDoc,
      categoryFilter: _currentActivityFilter,
    );

    paginatedActivities.addAll(result.items);
    _lastActivityDoc = result.lastDoc;
    hasMoreActivities.value = result.hasMore;
    isActivitiesPageLoadingMore.value = false;
  }

  List<RoomModel> get filteredRooms {
    final query = searchQuery.value.trim().toLowerCase();
    final filter = statusFilter.value;

    return rooms.where((room) {
      final matchesSearch =
          query.isEmpty ||
          room.name.toLowerCase().contains(query) ||
          room.code.toLowerCase().contains(query);

      final matchesFilter =
          filter == 'all' ||
          (filter == 'active' && room.isActive) ||
          (filter == 'inactive' && !room.isActive);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ── Room CRUD Actions with AppAlert ─────────────────────────────────────────

  Future<void> createRoom(BuildContext context, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      AppAlert.warning(
        context,
        title: context.tr('room.attention'),
        message: context.tr('room.emptyRoomName'),
      );
      return;
    }
    if (trimmed.length > 100) {
      AppAlert.warning(
        context,
        title: context.tr('room.nameTooLong'),
        message: context.tr('room.nameMax100'),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    isSubmitting.value = true;
    try {
      final newRoom = await _roomService.createRoom(
        name: trimmed,
        adminUid: currentUser.uid,
      );
      if (context.mounted) {
        Navigator.of(context).pop(); // Close creation modal/sheet
        AppAlert.success(
          context,
          title: context.tr('room.roomCreated'),
          message: context.tr('room.roomCreatedDesc', {
            'name': newRoom.name,
            'code': newRoom.code,
          }),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.error(
          context,
          title: context.tr('room.roomCreateFailed'),
          message: UserFeedbackMessage.from(
            e,
            fallback: context.tr('room.createFailedFallback'),
          ),
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updateRoomName(
    BuildContext context,
    String roomId,
    String newName,
  ) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      AppAlert.warning(
        context,
        title: context.tr('room.attention'),
        message: context.tr('room.emptyRoomName'),
      );
      return;
    }
    if (trimmed.length > 100) {
      AppAlert.warning(
        context,
        title: context.tr('room.nameTooLong'),
        message: context.tr('room.nameMax100'),
      );
      return;
    }

    try {
      await _roomService.updateRoom(roomId: roomId, name: trimmed);
      if (context.mounted) {
        AppAlert.success(
          context,
          title: context.tr('room.roomNameChanged'),
          message: context.tr('room.roomNameChangedDesc', {'name': trimmed}),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.error(
          context,
          title: context.tr('room.roomNameChangeFailed'),
          message: UserFeedbackMessage.from(
            e,
            fallback: context.tr('room.roomNameChangeFailedFallback'),
          ),
        );
      }
    }
  }

  void promptToggleRoomStatus(BuildContext context, RoomModel room) {
    if (room.isActive) {
      AppAlert.confirm(
        context,
        title: context.tr('room.deactivateRoomTitle'),
        message: context.tr('room.deactivateRoomDesc', {'name': room.name}),
        confirmText: context.tr('room.deactivate'),
        cancelText: context.tr('common.cancel'),
        isDestructive: true,
        onConfirm: () => _executeToggleRoomStatus(context, room.id, true),
      );
    } else {
      _executeToggleRoomStatus(context, room.id, false);
    }
  }

  Future<void> _executeToggleRoomStatus(
    BuildContext context,
    String roomId,
    bool currentStatus,
  ) async {
    try {
      await _roomService.toggleRoomStatus(roomId, currentStatus);
      final label = !currentStatus ? 'diaktifkan' : 'dinonaktifkan';
      if (context.mounted) {
        AppAlert.success(
          context,
          title: context.tr('room.statusUpdated'),
          message: context.tr('room.statusUpdatedDesc', {'status': label}),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.error(
          context,
          title: context.tr('room.statusUpdateFailed'),
          message: UserFeedbackMessage.from(
            e,
            fallback: context.tr('room.statusChangeFailedFallback'),
          ),
        );
      }
    }
  }

  void promptDeleteRoom(BuildContext context, RoomModel room) {
    AppAlert.confirm(
      context,
      title: context.tr('room.deleteRoomTitle'),
      message: context.tr('room.deleteRoomDesc', {'name': room.name}),
      confirmText: context.tr('room.delete'),
      cancelText: context.tr('common.cancel'),
      isDestructive: true,
      onConfirm: () async {
        try {
          await _roomService.deleteRoom(room.id, roomName: room.name);
          if (context.mounted) {
            AppAlert.success(
              context,
              title: context.tr('room.roomDeleted'),
              message: context.tr('room.roomDeletedDesc', {'name': room.name}),
            );
          }
        } catch (e) {
          if (context.mounted) {
            AppAlert.error(
              context,
              title: context.tr('room.deleteFailed'),
              message: UserFeedbackMessage.from(
                e,
                fallback: context.tr('room.deleteFailedFallback'),
              ),
            );
          }
        }
      },
    );
  }

  void promptSignOut(BuildContext context) {
    AppAlert.confirm(
      context,
      title: context.tr('room.exitAdminTitle'),
      message: context.tr('room.exitAdminDesc'),
      confirmText: context.tr('common.logout'),
      cancelText: context.tr('common.cancel'),
      isDestructive: true,
      onConfirm: () async {
        try {
          final startup = Get.find<AppStartupController>();
          await startup.signOut();
        } catch (_) {
          Get.offAllNamed(AppRoutes.login);
        }
      },
    );
  }

  @override
  void onClose() {
    _roomsSub?.cancel();
    _membersSub?.cancel();
    _activitiesSub?.cancel();
    _sosSub?.cancel();
    _resolvedSosSub?.cancel();
    _usersSub?.cancel();
    _countsSub?.cancel();
    _breakdownSub?.cancel();
    super.onClose();
  }
}
