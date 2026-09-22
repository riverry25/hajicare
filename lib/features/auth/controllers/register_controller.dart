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
    if (isLoading.value || isClosed) return;
    isLoading.value = true;
    errorMessage.value = null;

    final name = fullNameController.text.trim();
    final porsi = porsiController.text.trim();
    final email = emailController.text.trim();
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

    User? newUser;
    try {
      // ── Step 1: Create Firebase Auth user ───────────────────────────────
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

      // ── Step 2: Direct Firestore write ──────────────────────────────────
      // Write profile directly to Firestore so the user document is immediately
      // created and never left in an orphaned Auth-only state.
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'displayName': name,
        'email': email,
        'normalizedEmail': email.toLowerCase(),
        'nomorPorsi': porsi,
        'porsi': porsi,
        'role': effectiveRole,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isGpsActive': false,
      }, SetOptions(merge: true));
      debugPrint(
        '=== Direct Firestore write succeeded for uid: $uid, role: $effectiveRole',
      );

      // ── Step 3: Server synchronization via Cloud Functions ──────────────
      // Non-fatal: if functions are not deployed or cold-starting, the Firestore
      // write in Step 2 already guarantees the account works.
      try {
        await TrustedBackendService().call('ensureUserProfile', {
          'name': name,
          'nomorPorsi': porsi,
          'requestedRole': effectiveRole,
        });
        debugPrint('=== Cloud Function ensureUserProfile succeeded');
      } catch (cfError) {
        debugPrint(
          '=== Cloud Function ensureUserProfile skipped/failed (non-fatal): $cfError',
        );
      }

      // ── Step 4: Persist session & sync state ────────────────────────────
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

      // ── Step 5: Navigate directly to respective role dashboard ──────────
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

  @override
  void onClose() {
    fullNameController.dispose();
    porsiController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
