import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/trusted_backend_service.dart';
import '../../../core/state/app_startup_controller.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/utils/app_dialog.dart';
import '../../../core/utils/input_sanitizer.dart';

class RegisterController extends GetxController {
  final obscurePassword = true.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _nikController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  TextEditingController get fullNameController {
    if (_isControllerDisposed(_fullNameController)) {
      _fullNameController = TextEditingController();
    }
    return _fullNameController;
  }

  set fullNameController(TextEditingController value) {
    _fullNameController = value;
  }

  TextEditingController get nikController {
    if (_isControllerDisposed(_nikController)) {
      _nikController = TextEditingController();
    }
    return _nikController;
  }

  set nikController(TextEditingController value) {
    _nikController = value;
  }

  TextEditingController get porsiController => nikController;

  TextEditingController get emailController {
    if (_isControllerDisposed(_emailController)) {
      _emailController = TextEditingController();
    }
    return _emailController;
  }

  set emailController(TextEditingController value) {
    _emailController = value;
  }

  TextEditingController get passwordController {
    if (_isControllerDisposed(_passwordController)) {
      _passwordController = TextEditingController();
    }
    return _passwordController;
  }

  set passwordController(TextEditingController value) {
    _passwordController = value;
  }

  static bool _isControllerDisposed(TextEditingController c) {
    try {
      void dummy() {}
      c.addListener(dummy);
      c.removeListener(dummy);
      return false;
    } catch (_) {
      return true;
    }
  }

  final selectedRole = 'jamaah'.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void setRole(String role) {
    selectedRole.value = role;
  }

  Future<void> register() async {
    if (isLoading.value || isClosed) return;
    isLoading.value = true;
    errorMessage.value = null;

    final name = InputSanitizer.sanitizeDisplayName(fullNameController.text);
    final nik = InputSanitizer.sanitizeText(nikController.text, maxLength: 30);
    final email = InputSanitizer.sanitizeText(
      emailController.text,
      maxLength: 254,
    );
    final password = passwordController.text;
    final chosenRole = selectedRole.value.trim().toLowerCase();
    final effectiveRole =
        (chosenRole == 'pendamping' || chosenRole == 'petugas')
        ? 'pendamping'
        : 'jamaah';

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      errorMessage.value = AppTranslations.tr('auth.errFillAllRegister');
      _showErrorSnackbar(errorMessage.value!);
      isLoading.value = false;
      return;
    }

    if (!InputSanitizer.isValidPassword(password, minLength: 6)) {
      errorMessage.value = AppTranslations.tr('auth.errWeakPassword');
      _showErrorSnackbar(errorMessage.value!);
      isLoading.value = false;
      return;
    }

    User? newUser;
    try {
      // Buat akun Firebase Authentication
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      newUser = credential.user;

      if (newUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: AppTranslations.tr('auth.errCreateUserFailed'),
        );
      }

      final uid = newUser.uid;

      // Update Firebase Auth displayName
      try {
        await newUser.updateDisplayName(name);
      } catch (_) {}

      // Simpan data profil pengguna ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'displayName': name,
        'email': email,
        'normalizedEmail': email.toLowerCase(),
        'nik': nik,
        'role': effectiveRole,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isGpsActive': false,
      }, SetOptions(merge: true));
      debugPrint(
        '=== Direct Firestore write succeeded for uid: $uid, role: $effectiveRole',
      );

      // Sinkronisasi data pengguna ke server
      try {
        await TrustedBackendService().call('ensureUserProfile', {
          'name': name,
          'nik': nik,
          'requestedRole': effectiveRole,
        });
        debugPrint('=== Cloud Function ensureUserProfile succeeded');
      } catch (cfError) {
        debugPrint(
          '=== Cloud Function ensureUserProfile skipped/failed (non-fatal): $cfError',
        );
      }

      // Simpan sesi login dan sinkronisasi state
      final startup = Get.find<AppStartupController>();
      await startup.handleSuccessfulLogin(rememberMe: true);

      if (Get.isRegistered<HajiCareController>()) {
        final hajicare = Get.find<HajiCareController>();
        await hajicare.applyUserData(
          roleStr: effectiveRole,
          roomId: null,
          name: name,
        );
      }

      // Navigasi ke dashboard sesuai role pengguna
      if (effectiveRole == 'pendamping') {
        Get.offAllNamed(AppRoutes.dashboardPendamping);
      } else {
        Get.offAllNamed(AppRoutes.dashboardJamaah);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('=== ERROR AUTH ===: ${e.code} - ${e.message}');
      errorMessage.value = _friendlyRegisterError(e.code, e.message);
      _showErrorSnackbar(errorMessage.value!);
    } catch (e, stackTrace) {
      debugPrint('=== ERROR UMUM ===: $e\n$stackTrace');
      // If Firestore write failed completely, delete the orphaned Auth user
      // so the user can retry registration with the same email.
      if (newUser != null) {
        try {
          await newUser.delete();
          debugPrint('=== Orphaned Auth user deleted after total failure.');
        } catch (deleteErr) {
          debugPrint('=== Could not delete orphaned Auth user: $deleteErr');
        }
      }
      errorMessage.value = AppTranslations.tr('auth.errRegisterFailed');
      _showErrorSnackbar(errorMessage.value!);
    } finally {
      isLoading.value = false;
    }
  }

  String _friendlyRegisterError(String code, [String? message]) {
    switch (code) {
      case 'email-already-in-use':
        return AppTranslations.tr('auth.errEmailAlreadyInUse');
      case 'weak-password':
        return AppTranslations.tr('auth.errWeakPassword');
      case 'invalid-email':
        return AppTranslations.tr('auth.errInvalidEmailRegister');
      case 'operation-not-allowed':
        return AppTranslations.tr('auth.errRegisterDisabled');
      case 'network-request-failed':
        return AppTranslations.tr('auth.errNetworkFailed');
      default:
        return AppTranslations.tr('auth.errRegisterGeneral');
    }
  }

  void _showErrorSnackbar(String msg) {
    AppDialog.error(
      title: AppTranslations.tr('auth.registerFailedTitle'),
      message: msg,
      okText: AppTranslations.tr('auth.tryAgain'),
    );
  }


}
