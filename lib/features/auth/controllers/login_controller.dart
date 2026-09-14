import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      final value = await startup.isRememberMe();

      if (!isClosed) {
        rememberMe.value = value;
      }
    } catch (_) {
      // Gunakan default true jika gagal membaca preference.
    }
  }

  void setRole(String role) {
    selectedRole.value = role;
  }

  void togglePasswordVisibility() {
    if (isClosed) return;

    obscurePassword.value = !obscurePassword.value;
  }

  void setRememberMe(bool value) {
    if (isClosed) return;

    rememberMe.value = value;
  }

  Future<void> login() async {
    if (isLoading.value || isClosed) return;

    // ============================================================
    // PENTING:
    // Ambil text SEKALI sebelum await.
    // Setelah ini jangan membaca TextEditingController lagi.
    // ============================================================

    final email = emailController.text.trim();
    final password = passwordController.text;
    final shouldRemember = rememberMe.value;

    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Harap isi email dan password';
      _showErrorSnackbar(errorMessage.value!);
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      // ============================================================
      // 1. Firebase Authentication
      // ============================================================

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (isClosed) return;

      final uid = userCredential.user?.uid;

      if (uid == null) {
        if (!isClosed) {
          errorMessage.value = 'Data pengguna tidak ditemukan.';
          _showErrorSnackbar(errorMessage.value!);
        }
        return;
      }

      // ============================================================
      // 2. Simpan onboarding + remember me
      // ============================================================

      final startup = Get.find<AppStartupController>();

      await startup.handleSuccessfulLogin(rememberMe: shouldRemember);

      // Jangan melakukan update UI LoginController setelah async
      // jika controller sudah dihancurkan.
      if (isClosed) return;

      // ============================================================
      // 3. Tentukan dashboard berdasarkan role
      // ============================================================

      final destination = await startup.resolveUserRoleDestination(uid);

      // ============================================================
      // 4. Navigasi adalah operasi terakhir.
      // Setelah ini LoginController boleh dihancurkan.
      // ============================================================

      if (isClosed) return;

      Get.offAllNamed(destination);
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;

      errorMessage.value = e.message ?? e.code;

      _showErrorSnackbar('Error Auth: ${errorMessage.value}');
    } catch (e) {
      if (isClosed) return;

      errorMessage.value = 'Terjadi kesalahan: $e';

      _showErrorSnackbar(errorMessage.value!);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  void _showErrorSnackbar(String msg) {
    if (isClosed) return;

    Get.snackbar(
      'Gagal Masuk',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();

    super.onClose();
  }
}
