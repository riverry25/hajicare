import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

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
      errorMessage.value = 'Harap isi email dan password.';
      _showErrorDialog(errorMessage.value!);
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
          _showErrorDialog(errorMessage.value!);
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

      // Show success dialog briefly, then navigate
      if (Get.context != null) {
        AwesomeDialog(
          context: Get.context!,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: 'Selamat Datang!',
          desc: 'Login berhasil. Anda akan diarahkan ke dashboard.',
          descTextStyle: const TextStyle(fontSize: 13.5, height: 1.4),
          autoHide: const Duration(milliseconds: 1500),
          onDismissCallback: (_) => Get.offAllNamed(destination),
          btnOkText: 'Masuk Sekarang',
          btnOkColor: const Color(0xFF2E7D32),
          btnOkOnPress: () => Get.offAllNamed(destination),
        ).show();
      } else {
        Get.offAllNamed(destination);
      }
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;

      errorMessage.value = _friendlyAuthError(e.code);

      _showErrorDialog(errorMessage.value!);
    } catch (e) {
      if (isClosed) return;

      errorMessage.value = 'Terjadi kesalahan tidak terduga. Coba lagi.';

      _showErrorDialog(errorMessage.value!);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Maps Firebase error codes to user-friendly Indonesian messages.
  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password yang Anda masukkan salah.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Hubungi administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      default:
        return 'Gagal masuk. Periksa kembali email dan password Anda.';
    }
  }

  void _showErrorDialog(String message) {
    if (isClosed || Get.context == null) return;
    AwesomeDialog(
      context: Get.context!,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Gagal Masuk',
      desc: message,
      descTextStyle: const TextStyle(
        fontSize: 13.5,
        height: 1.45,
      ),
      btnOkText: 'Coba Lagi',
      btnOkColor: const Color(0xFFB71C1C),
      btnOkOnPress: () {},
    ).show();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();

    super.onClose();
  }
}
