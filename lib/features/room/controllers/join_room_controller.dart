import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/app_startup_controller.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../services/room_service.dart';

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
    final name = createRoomNameController.text.trim();
    final maktab = createMaktabController.text.trim();
    final kloter = createKloterController.text.trim();

    if (name.isEmpty) {
      errorMessage.value = 'Harap isi Nama Room / Rombongan.';
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
      errorMessage.value = 'Gagal membuat room: $e';
      _showErrorAlert(errorMessage.value!);
    }
  }

  /// Jamaah atau Pendamping: Gabung ke room menggunakan 6-digit room code
  Future<void> joinRoom([String? explicitCode]) async {
    if (explicitCode != null && explicitCode.trim().isNotEmpty) {
      roomCodeController.text = explicitCode.trim().toUpperCase();
    }
    final roomCode = roomCodeController.text.trim().toUpperCase();

    if (roomCode.isEmpty) {
      errorMessage.value = 'Harap masukkan 6 digit Kode Room.';
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
      final joinedRoom = await _roomService.joinRoomByCode(
        roomCode: roomCode,
        uid: currentUser.uid,
        userName: userName,
        role: roleStr,
      );

      await state.applyUserData(roleStr: roleStr, roomId: joinedRoom.id);
      state.activeRoom.value = joinedRoom;

      isLoading.value = false;

      if (Get.context != null) {
        AppAlert.success(
          Get.context,
          title: 'Berhasil Bergabung!',
          message:
              'Anda telah bergabung ke room "${joinedRoom.name}". Fitur monitoring kini aktif.',
        );
      }

      _navigateToDashboard();
    } on RoomException catch (e) {
      isLoading.value = false;
      errorMessage.value = e.message;
      _showErrorAlert(e.message);
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Gagal bergabung ke room: $e';
      _showErrorAlert(errorMessage.value!);
    }
  }

  Future<void> _showRoomCreatedDialog(
    BuildContext context,
    RoomModel room,
  ) async {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.goldLight : AppColors.goldPrimary;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.goldLight.withValues(alpha: 0.3),
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.statusSafe.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.statusSafe,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Room Berhasil Dibuat!',
                            style: AppTypography.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Bagikan kode room atau QR code ini kepada jamaah rombongan Anda:',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: bodyColor),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // QR Code Container with fixed dimensions
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: SizedBox(
                        width: 160,
                        height: 160,
                        child: QrImageView(
                          data: room.code,
                          version: QrVersions.auto,
                          size: 160,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Room Code Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            room.code,
                            style: AppTypography.titleLarge.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Nama: ${room.name}',
                      style: AppTypography.captionSmall.copyWith(
                        color: bodyColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isDark
                              ? AppColors.espressoDark
                              : AppColors.surfaceWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Buka Dashboard Monitoring',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
      AppAlert.error(Get.context!, title: 'Perhatian', message: msg);
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
