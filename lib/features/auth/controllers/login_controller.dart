import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/app_startup_controller.dart';

class LoginController extends GetxController {
  final selectedRole = 'jamaah'.obs;
  final obscurePassword = true.obs;
  final rememberMe = true.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    try {
      final startup = Get.find<AppStartupController>();
      rememberMe.value = await startup.isRememberMe();
    } catch (_) {}
  }

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

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      errorMessage.value = 'Harap isi email dan password';
      _showErrorSnackbar(errorMessage.value!);
      isLoading.value = false;
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final uid = userCredential.user?.uid;

      // Persist onboarding status & Remember Me setting
      final startup = Get.find<AppStartupController>();
      await startup.handleSuccessfulLogin(rememberMe: rememberMe.value);
      
      if (uid != null) {
        final destination = await startup.resolveUserRoleDestination(uid);
        Get.offAllNamed(destination);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? e.code;
      _showErrorSnackbar('Error Auth: ${errorMessage.value}');
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: $e';
      _showErrorSnackbar(errorMessage.value!);
    } finally {
      isLoading.value = false;
    }
  }

  void _showErrorSnackbar(String msg) {
    if (Get.context != null) {
      Get.snackbar(
        'Gagal Masuk',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
