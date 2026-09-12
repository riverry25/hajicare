import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/jamaah_data.dart';
import '../../../core/repositories/mock_auth_repository.dart';

class RegisterController extends GetxController {
  final AuthRepository authRepository;

  RegisterController({AuthRepository? authRepository})
      : authRepository = authRepository ?? MockAuthRepository();

  final obscurePassword = true.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final fullNameController = TextEditingController();
  final nikOrPorsiController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> register() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final success = await authRepository.register(
        fullNameController.text.trim(),
        phoneController.text.trim(),
        passwordController.text,
        UserRole.jamaah,
      );

      if (success) {
        Get.back();
        if (Get.context != null) {
          Get.snackbar(
            'Pendaftaran Berhasil',
            'Akun berhasil dibuat. Silakan masuk menggunakan nomor telepon Anda.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade800,
            colorText: Colors.white,
          );
        }
      } else {
        errorMessage.value = 'Gagal mendaftarkan akun. Silakan coba lagi.';
        if (Get.context != null) {
          Get.snackbar(
            'Gagal Mendaftar',
            errorMessage.value!,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade800,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: $e';
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
    fullNameController.dispose();
    nikOrPorsiController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
