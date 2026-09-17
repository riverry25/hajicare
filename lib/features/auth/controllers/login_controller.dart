// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:awesome_dialog/awesome_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_startup_controller.dart';
import '../../../core/state/hajicare_controller.dart';

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

      if (isClosed) return;

      // Pastikan data user & room di HajiCareController tersinkron sebelum evaluasi guard
      if (Get.isRegistered<HajiCareController>()) {
        final hajicare = Get.find<HajiCareController>();
        await hajicare.syncUserData(uid);
      }

      if (isClosed) return;

      // ============================================================
      // 4. Tampilkan AwesomeDialog saat berhasil login
      // ============================================================

      if (Get.context != null) {
        final ctx = Get.context!;
        final isDark = AppColors.isDark(ctx);
        bool hasNavigated = false;
        void navigate() {
          if (!hasNavigated) {
            hasNavigated = true;
            Get.offAllNamed(destination);
          }
        }

        AwesomeDialog(
          context: ctx,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          headerAnimationLoop: false,
          dialogBackgroundColor:
              isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderSide: BorderSide(
            color: AppColors.statusSafe.withValues(alpha: 0.35),
            width: 1.5,
          ),
          buttonsBorderRadius: BorderRadius.circular(12),
          title: 'Berhasil Masuk',
          desc: 'Selamat datang kembali di HajiCare! Menyiapkan dashboard...',
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? AppColors.darkTextHeading : AppColors.espressoDark,
          ),
          descTextStyle: TextStyle(
            fontSize: 13.5,
            color: isDark ? AppColors.darkTextBody : AppColors.textBody,
            height: 1.4,
          ),
          btnOkText: 'Lanjut',
          btnOkColor: AppColors.statusSafe,
          btnOkOnPress: navigate,
          autoHide: const Duration(milliseconds: 1500),
          onDismissCallback: (_) => navigate(),
        ).show();
      } else {
        Get.offAllNamed(destination);
      }
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
