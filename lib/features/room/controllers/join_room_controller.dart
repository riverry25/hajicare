import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/app_startup_controller.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../services/room_service.dart';
import '../widgets/room_qr_dialog.dart';

class JoinRoomController extends GetxController {
  final RoomService _roomService = RoomService();

  // Mode for pendamping: 0 = Buat Room, 1 = Gabung Room
  final selectedMode = 0.obs;

  // Gabung Room Fields
  final roomCodeController = TextEditingController();

  // Buat Room Fields (Pendamping)
  final createRoomNameController = TextEditingController();
  final createMaktabController = TextEditingController();
  final createKloterController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = RxnString();

  Worker? _roomWorker;

  bool get isPendamping {
    if (!Get.isRegistered<HajiCareController>()) return false;
    return Get.find<HajiCareController>().role == UserRole.pendamping;
  }

  @override
  void onInit() {
    super.onInit();
    // Default mode for jamaah is always Gabung Room (mode 1)
    if (!isPendamping) {
      selectedMode.value = 1;
    }
    _checkExistingRoomAndListen();
  }

  void _checkExistingRoomAndListen() {
    if (!Get.isRegistered<HajiCareController>()) return;
    final state = Get.find<HajiCareController>();

    final existingRoom =
        (state.activeRoomId.value != null &&
            state.activeRoomId.value!.trim().isNotEmpty)
        ? state.activeRoomId.value!.trim()
        : (state.cachedRoomId != null && state.cachedRoomId!.trim().isNotEmpty
              ? state.cachedRoomId!.trim()
              : null);

    if (existingRoom != null && existingRoom.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToDashboard();
      });
      return;
    }

    _roomWorker = ever<String?>(state.activeRoomId, (roomId) {
      if (roomId != null && roomId.trim().isNotEmpty) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    if (isClosed) return;
    final state = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final isP = state?.role == UserRole.pendamping;
    Get.offAllNamed(
      isP ? AppRoutes.dashboardPendamping : AppRoutes.dashboardJamaah,
    );
  }

  /// Pendamping: Buat Room baru dengan auto-generated unique code
  Future<void> createRoom() async {
    if (isLoading.value || isClosed) return;
    final name = createRoomNameController.text.trim();
    final maktab = createMaktabController.text.trim();
    final kloter = createKloterController.text.trim();

    if (name.isEmpty) {
      errorMessage.value = 'Isi nama rombongan terlebih dahulu.';
      _showErrorAlert(errorMessage.value!);
      return;
    }
    if (name.length > 100 || maktab.length > 60 || kloter.length > 60) {
      errorMessage.value =
          'Nama maksimal 100 karakter; maktab dan kloter maksimal 60 karakter.';
      _showErrorAlert(errorMessage.value!);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    final state = Get.find<HajiCareController>();
    final userName = currentUser.displayName?.trim().isNotEmpty == true
        ? currentUser.displayName!.trim()
        : (currentUser.email?.trim().isNotEmpty == true
              ? currentUser.email!.split('@').first
              : 'Pendamping');

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final room = await _roomService.createRoomByPendamping(
        name: name,
        pendampingUid: currentUser.uid,
        pendampingName: userName,
        maktab: maktab.isNotEmpty ? maktab : null,
        kloter: kloter.isNotEmpty ? kloter : null,
      );

      // Reactively apply to state
      await state.applyUserData(roleStr: 'pendamping', roomId: room.id);
      state.activeRoom.value = room;

      isLoading.value = false;

      // Show Room Created Success Modal with Code & QR
      if (Get.context != null) {
        await _showRoomCreatedDialog(Get.context!, room);
      }

      _navigateToDashboard();
    } on RoomException catch (e) {
      isLoading.value = false;
      errorMessage.value = e.message;
      _showErrorAlert(e.message);
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = UserFeedbackMessage.from(
        e,
        fallback: 'Rombongan belum dapat dibuat. Silakan coba lagi.',
      );
      _showErrorAlert(errorMessage.value!);
    }
  }

  /// Jamaah atau Pendamping: Gabung ke room menggunakan 6-digit room code
  Future<void> joinRoom([String? explicitCode]) async {
    if (isLoading.value || isClosed) return;
    if (explicitCode != null && explicitCode.trim().isNotEmpty) {
      roomCodeController.text = explicitCode.trim().toUpperCase();
    }
    final roomCode = roomCodeController.text.trim().toUpperCase();

    if (roomCode.isEmpty) {
      errorMessage.value = 'Masukkan kode rombongan.';
      _showErrorAlert(errorMessage.value!);
      return;
    }
    if (!RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(roomCode)) {
      errorMessage.value = 'Format kode rombongan tidak valid (hanya huruf dan angka).';
      _showErrorAlert(errorMessage.value!);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    final state = Get.find<HajiCareController>();
    String effectiveRole = state.role == UserRole.pendamping ? 'pendamping' : 'jamaah';
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        final r = (userDoc.data()?['role'] as String?)?.toLowerCase();
        if (r == 'pendamping' || r == 'petugas') {
          effectiveRole = 'pendamping';
        }
      }
    } catch (_) {}

    final userName = currentUser.displayName?.trim().isNotEmpty == true
        ? currentUser.displayName!.trim()
        : (currentUser.email?.trim().isNotEmpty == true
              ? currentUser.email!.split('@').first
              : 'Pengguna');

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final joinedRoom = await _roomService.joinRoomByCode(
        roomCode: roomCode,
        uid: currentUser.uid,
        userName: userName,
        role: effectiveRole,
      );

      await state.applyUserData(roleStr: effectiveRole, roomId: joinedRoom.id);
      state.activeRoom.value = joinedRoom;

      isLoading.value = false;

      if (Get.context != null) {
        AppAlert.success(
          Get.context,
          title: 'Berhasil Bergabung',
          message:
              'Anda sudah bergabung dengan rombongan "${joinedRoom.name}".',
        );
      }

      _navigateToDashboard();
    } on RoomException catch (e) {
      isLoading.value = false;
      errorMessage.value = e.message;
      _showErrorAlert(e.message);
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = UserFeedbackMessage.from(
        e,
        fallback:
            'Belum dapat bergabung. Periksa kode rombongan, lalu coba lagi.',
      );
      _showErrorAlert(errorMessage.value!);
    }
  }

  Future<void> _showRoomCreatedDialog(
    BuildContext context,
    RoomModel room,
  ) async {
    await RoomQrDialog.show(context, room: room);
  }

  Future<void> switchAccount() async {
    try {
      final startup = Get.find<AppStartupController>();
      await startup.signOut();
    } catch (_) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _showErrorAlert(String msg) {
    if (Get.context != null) {
      AppAlert.error(
        Get.context!,
        title: 'Belum Berhasil',
        message: msg,
        okText: 'Coba Lagi',
      );
    }
  }

  @override
  void onClose() {
    _roomWorker?.dispose();
    roomCodeController.dispose();
    createRoomNameController.dispose();
    createMaktabController.dispose();
    createKloterController.dispose();
    super.onClose();
  }
}
