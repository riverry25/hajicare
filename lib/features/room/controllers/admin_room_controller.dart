import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/app_startup_controller.dart';
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
  final activities = <ActivityModel>[].obs;
  final roomBreakdowns = <String, Map<String, int>>{}.obs;

  // Room Management Search & Filter
  final searchQuery = ''.obs;
  final statusFilter = 'all'.obs; // 'all' | 'active' | 'inactive'

  // Stream Subscriptions
  StreamSubscription? _roomsSub;
  StreamSubscription? _membersSub;
  StreamSubscription? _activitiesSub;
  StreamSubscription? _sosSub;
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
    _roomsSub = _roomService.getRoomsStream().listen((roomList) {
      rooms.value = roomList;
      isLoading.value = false;
    }, onError: (e) {
      debugPrint('[AdminRoomController] Error fetching rooms: $e');
      isLoading.value = false;
    });

    // 2. Activities Stream
    _activitiesSub?.cancel();
    _activitiesSub = _roomService.getRecentActivitiesStream().listen((actList) {
      activities.value = actList;
    }, onError: (e) {
      debugPrint('[AdminRoomController] Error fetching activities: $e');
    });

    // 3. Active SOS Events Stream
    _sosSub?.cancel();
    _sosSub = _roomService.getActiveSosEventsStream().listen((sosList) {
      activeSosList.value = sosList;
      activeSosCount.value = sosList.length;
    }, onError: (e) {
      debugPrint('[AdminRoomController] Error fetching SOS events: $e');
    });

    // 4. Global Member Counts Stream
    _countsSub?.cancel();
    _countsSub = _roomService.getGlobalMemberCountsStream().listen((counts) {
      totalJamaah.value = counts['jamaah'] ?? 0;
      totalPendamping.value = counts['pendamping'] ?? 0;
    }, onError: (e) {
      debugPrint('[AdminRoomController] Error fetching member counts: $e');
    });

    // 5. Per-Room Member & SOS Breakdown Stream
    _breakdownSub?.cancel();
    _breakdownSub = _roomService.getAllRoomMemberBreakdownStream().listen((data) {
      roomBreakdowns.value = data;
    }, onError: (e) {
      debugPrint('[AdminRoomController] Error fetching breakdowns: $e');
    });
  }

  void subscribeToRoomMembers(String roomId) {
    _membersSub?.cancel();
    _membersSub = _roomService.getRoomMembersStream(roomId).listen((members) {
      roomMembers.value = members;
    }, onError: (e) {
      debugPrint('[AdminRoomController] Error fetching room members: $e');
    });
  }

  // ── Computed Getters ────────────────────────────────────────────────────────
  int get activeRoomsCount => rooms.where((r) => r.isActive).length;
  int get inactiveRoomsCount => rooms.where((r) => !r.isActive).length;

  int getRoomJamaahCount(String roomId) => roomBreakdowns[roomId]?['jamaah'] ?? 0;
  int getRoomPendampingCount(String roomId) => roomBreakdowns[roomId]?['pendamping'] ?? 0;
  int getRoomSosCount(String roomId) => roomBreakdowns[roomId]?['sos'] ?? 0;

  List<RoomModel> get recentActiveRooms {
    return rooms.where((r) => r.isActive).take(5).toList();
  }

  List<RoomModel> get filteredRooms {
    final query = searchQuery.value.trim().toLowerCase();
    final filter = statusFilter.value;

    return rooms.where((room) {
      final matchesSearch = query.isEmpty ||
          room.name.toLowerCase().contains(query) ||
          room.code.toLowerCase().contains(query);

      final matchesFilter = filter == 'all' ||
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
        title: 'Perhatian',
        message: 'Nama room tidak boleh kosong.',
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
          title: 'Room Berhasil Dibuat',
          message: 'Room "${newRoom.name}" berhasil dibuat dengan kode ${newRoom.code}.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.error(
          context,
          title: 'Terjadi kesalahan',
          message: 'Gagal membuat room: $e',
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updateRoomName(BuildContext context, String roomId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      AppAlert.warning(
        context,
        title: 'Perhatian',
        message: 'Nama room tidak boleh kosong.',
      );
      return;
    }

    try {
      await _roomService.updateRoom(roomId: roomId, name: trimmed);
      if (context.mounted) {
        AppAlert.success(
          context,
          title: 'Berhasil',
          message: 'Nama room berhasil diperbarui menjadi "$trimmed".',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.error(
          context,
          title: 'Terjadi kesalahan',
          message: 'Gagal mengubah nama room: $e',
        );
      }
    }
  }

  void promptToggleRoomStatus(BuildContext context, RoomModel room) {
    if (room.isActive) {
      AppAlert.confirm(
        context,
        title: 'Nonaktifkan Room?',
        message: 'Room "${room.name}" akan dinonaktifkan sementara. Anggota tidak dapat check-in selama nonaktif.',
        confirmText: 'Nonaktifkan',
        cancelText: 'Batal',
        isDestructive: true,
        onConfirm: () => _executeToggleRoomStatus(context, room.id, true),
      );
    } else {
      _executeToggleRoomStatus(context, room.id, false);
    }
  }

  Future<void> _executeToggleRoomStatus(BuildContext context, String roomId, bool currentStatus) async {
    try {
      await _roomService.toggleRoomStatus(roomId, currentStatus);
      final label = !currentStatus ? 'diaktifkan' : 'dinonaktifkan';
      if (context.mounted) {
        AppAlert.success(
          context,
          title: 'Status Diperbarui',
          message: 'Room berhasil $label.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.error(
          context,
          title: 'Terjadi kesalahan',
          message: 'Gagal mengubah status room: $e',
        );
      }
    }
  }

  void promptDeleteRoom(BuildContext context, RoomModel room) {
    AppAlert.confirm(
      context,
      title: 'Hapus room?',
      message: 'Semua anggota akan kehilangan akses ke room "${room.name}". Tindakan ini tidak dapat dibatalkan.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDestructive: true,
      onConfirm: () async {
        try {
          await _roomService.deleteRoom(room.id, roomName: room.name);
          if (context.mounted) {
            AppAlert.success(
              context,
              title: 'Room Dihapus',
              message: 'Room "${room.name}" beserta datanya telah dihapus.',
            );
          }
        } catch (e) {
          if (context.mounted) {
            AppAlert.error(
              context,
              title: 'Terjadi kesalahan',
              message: 'Gagal menghapus room: $e',
            );
          }
        }
      },
    );
  }

  void promptSignOut(BuildContext context) {
    AppAlert.confirm(
      context,
      title: 'Keluar dari Admin?',
      message: 'Anda akan keluar dari sesi administrator Command Center.',
      confirmText: 'Keluar',
      cancelText: 'Batal',
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
    _countsSub?.cancel();
    _breakdownSub?.cancel();
    super.onClose();
  }
}
