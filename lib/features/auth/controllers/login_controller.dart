import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/repositories/mock_auth_repository.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/hajicare_controller.dart';

class LoginController extends GetxController {
  final AuthRepository authRepository;

  LoginController({AuthRepository? authRepository})
      : authRepository = authRepository ?? MockAuthRepository();

  final selectedRole = 'jamaah'.obs;
  final obscurePassword = true.obs;
  final rememberMe = true.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final phoneOrEmailController = TextEditingController();
  final passwordController = TextEditingController();

  void setRole(String role) {
    selectedRole.value = role;
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void setRememberMe(bool value) {
    rememberMe.value = value;
  }

  Future<void> login() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final roleEnum = selectedRole.value == 'jamaah'
          ? UserRole.jamaah
          : UserRole.pendamping;

      final success = await authRepository.login(
        phoneOrEmailController.text.trim(),
        passwordController.text,
        roleEnum,
      );

      if (success) {
        final hajicare = Get.find<HajiCareController>();
        hajicare.setRole(roleEnum);

        Get.offAllNamed(
          selectedRole.value == 'jamaah'
              ? AppRoutes.dashboardJamaah
              : AppRoutes.dashboardPendamping,
        );
      } else {
        errorMessage.value = 'Nomor telepon atau kata sandi salah';
        if (Get.context != null) {
          Get.snackbar(
            'Gagal Masuk',
            errorMessage.value!,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade800,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan saat masuk: $e';
      if (Get.context != null) {
        Get.snackbar(
          'Kesalahan',
          errorMessage.value!,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneOrEmailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
