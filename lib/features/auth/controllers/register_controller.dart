import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/app_startup_controller.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/utils/app_dialog.dart';

class RegisterController extends GetxController {
  final obscurePassword = true.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final fullNameController = TextEditingController();
  final porsiController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final selectedRole = 'jamaah'.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void setRole(String role) {
    selectedRole.value = role;
  }

  Future<void> register() async {
    isLoading.value = true;
    errorMessage.value = null;

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        fullNameController.text.isEmpty) {
      errorMessage.value = 'Isi nama, email, dan kata sandi terlebih dahulu.';
      _showErrorSnackbar(errorMessage.value!);
      isLoading.value = false;
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      final uid = userCredential.user!.uid;

      // Create standard user payload
      final userPayload = {
        'name': fullNameController.text.trim(),
        'porsi': porsiController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole.value,
        'activeRoomId': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (selectedRole.value == 'jamaah') {
        userPayload['distance'] = 20.0;
        userPayload['separatedMode'] = false;
        userPayload['sosActive'] = false;
        userPayload['shortLabel'] = fullNameController.text
            .trim()
            .split(' ')
            .first;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userPayload);

      // Persist onboarding status & Remember Me setting
      final startup = Get.find<AppStartupController>();
      await startup.handleSuccessfulLogin(rememberMe: true);

      // Pre-set user role in HajiCareController
      if (Get.isRegistered<HajiCareController>()) {
        final hajicare = Get.find<HajiCareController>();
        await hajicare.applyUserData(
          roleStr: selectedRole.value,
          roomId: null,
          name: fullNameController.text.trim(),
        );
      }

      // Navigate directly to respective role dashboard (basic features available without room)
      if (selectedRole.value == 'pendamping') {
        Get.offAllNamed(AppRoutes.dashboardPendamping);
      } else {
        Get.offAllNamed(AppRoutes.dashboardJamaah);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('=== ERROR AUTH ===: ${e.code} - ${e.message}');
      errorMessage.value = _friendlyRegisterError(e.code, e.message);
      _showErrorSnackbar(errorMessage.value!);
    } on FirebaseException catch (e) {
      debugPrint('=== ERROR FIRESTORE ===: ${e.code} - ${e.message}');
      errorMessage.value = 'Profil belum dapat disimpan. Silakan coba lagi.';
      _showErrorSnackbar(errorMessage.value!);
    } catch (e, stackTrace) {
      debugPrint('=== ERROR UMUM ===: $e\n$stackTrace');
      errorMessage.value = 'Pendaftaran belum berhasil. Silakan coba lagi.';
      _showErrorSnackbar(errorMessage.value!);
    } finally {
      isLoading.value = false;
    }
  }

  String _friendlyRegisterError(String code, [String? message]) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan masuk atau gunakan email lain.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
      case 'invalid-email':
        return 'Penulisan email belum benar. Periksa kembali email Anda.';
      case 'operation-not-allowed':
        return 'Pendaftaran akun sedang dinonaktifkan.';
      case 'network-request-failed':
        return 'Sambungan internet bermasalah. Periksa internet, lalu coba lagi.';
      default:
        return 'Pendaftaran gagal. Periksa kembali data yang Anda masukkan.';
    }
  }

  void _showErrorSnackbar(String msg) {
    AppDialog.error(
      title: 'Pendaftaran Belum Berhasil',
      message: msg,
      okText: 'Coba Lagi',
    );
  }

  @override
  void onClose() {
    fullNameController.dispose();
    porsiController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
