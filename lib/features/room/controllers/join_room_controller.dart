import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/app_startup_controller.dart';
import '../../../core/state/hajicare_controller.dart';
import '../services/room_service.dart';

class JoinRoomController extends GetxController {
  final RoomService _roomService = RoomService();

  final roomNameController = TextEditingController();
  final roomCodeController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = RxnString();

  Future<void> joinRoom() async {
    final roomName = roomNameController.text.trim();
    final roomCode = roomCodeController.text.trim().toUpperCase();

    if (roomName.isEmpty || roomCode.isEmpty) {
      errorMessage.value = 'Harap isi Nama Room dan Kode Room.';
      _showErrorAlert(errorMessage.value!);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    final state = Get.find<HajiCareController>();
    final roleStr = state.role == UserRole.pendamping ? 'pendamping' : 'jamaah';
    final userName = currentUser.displayName?.trim().isNotEmpty == true
        ? currentUser.displayName!.trim()
        : (currentUser.email?.trim().isNotEmpty == true
            ? currentUser.email!.split('@').first
            : 'Pengguna');

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final joinedRoom = await _roomService.joinRoom(
        roomName: roomName,
        roomCode: roomCode,
        uid: currentUser.uid,
        userName: userName,
        role: roleStr,
      );

      // Reflect in local state
      state.activeRoomId.value = joinedRoom.id;
      state.activeRoom.value = joinedRoom;

      // Navigate to respective dashboard
      if (state.role == UserRole.pendamping) {
        Get.offAllNamed(AppRoutes.dashboardPendamping);
      } else {
        Get.offAllNamed(AppRoutes.dashboardJamaah);
      }
    } on RoomException catch (e) {
      errorMessage.value = e.message;
      _showErrorAlert(e.message);
    } catch (e) {
      errorMessage.value = 'Gagal bergabung ke room: $e';
      _showErrorAlert(errorMessage.value!);
    } finally {
      isLoading.value = false;
    }
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
        title: 'Gagal Bergabung',
        message: msg,
      );
    }
  }

  @override
  void onClose() {
    roomNameController.dispose();
    roomCodeController.dispose();
    super.onClose();
  }
}
