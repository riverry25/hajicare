import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/routes/app_routes.dart';

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

    if (emailController.text.isEmpty || passwordController.text.isEmpty || fullNameController.text.isEmpty) {
      errorMessage.value = 'Harap isi semua kolom wajib';
      _showErrorSnackbar(errorMessage.value!);
      isLoading.value = false;
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (selectedRole.value == 'jamaah') {
        userPayload['distance'] = 20.0;
        userPayload['separatedMode'] = false;
        userPayload['sosActive'] = false;
        userPayload['shortLabel'] = fullNameController.text.trim().split(' ').first;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userPayload);

      Get.offAllNamed(
        selectedRole.value == 'jamaah'
            ? AppRoutes.dashboardJamaah
            : AppRoutes.dashboardPendamping,
      );
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
        'Gagal Mendaftar',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
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
