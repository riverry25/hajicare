// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/utils/app_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trusted_backend_service.dart';
import '../../../core/state/app_startup_controller.dart';
import '../../../core/state/hajicare_controller.dart';

class LoginController extends GetxController {
  final selectedRole = 'jamaah'.obs;
  final obscurePassword = true.obs;
  final rememberMe = true.obs;
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final errorMessage = RxnString();

  static const String _googleServerClientId =
      '130436723221-l3spcu8ngaano7f8msjsgsh1v00bmnqf.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitialization;

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

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize(
      serverClientId: _googleServerClientId,
    );
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
      errorMessage.value = AppTranslations.tr('auth.errorFillEmailPassword');
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
          errorMessage.value = AppTranslations.tr('auth.errorUserNotFound');
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

      // Self-heal: ensure user doc exists in Firestore even if previous registration was interrupted
      try {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid);
        final userDoc = await userDocRef.get().timeout(
          const Duration(seconds: 3),
        );
        if (!userDoc.exists) {
          final authUser = userCredential.user;
          final fallbackName = authUser?.displayName ?? email.split('@').first;
          await userDocRef.set({
            'uid': uid,
            'name': fallbackName,
            'displayName': fallbackName,
            'email': email,
            'normalizedEmail': email.toLowerCase(),
            'role': 'jamaah',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isGpsActive': false,
          }, SetOptions(merge: true));
        }
      } catch (docErr) {
        debugPrint('[LoginController] User doc self-heal check: $docErr');
      }

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
      // 4. Tampilkan feedback dialog saat berhasil login
      // ============================================================

      bool hasNavigated = false;
      void navigate() {
        if (!hasNavigated) {
          hasNavigated = true;
          Get.offAllNamed(destination);
        }
      }

      AppDialog.success(
        title: AppTranslations.tr('auth.loginSuccessTitle'),
        message: AppTranslations.tr('auth.loginSuccessMessage'),
        okText: AppTranslations.tr('next'),
        onOk: navigate,
        autoDismissDuration: const Duration(milliseconds: 1500),
        onDismiss: navigate,
      );
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;

      errorMessage.value = _friendlyAuthError(e.code, e.message);

      _showErrorSnackbar(errorMessage.value!);
    } catch (e) {
      if (isClosed) return;

      errorMessage.value = AppTranslations.tr('auth.loginGeneralError');

      _showErrorSnackbar(errorMessage.value!);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  void _showErrorSnackbar(String msg) {
    if (isClosed) return;
    AppDialog.error(
      title: AppTranslations.tr('auth.loginFailedTitle'),
      message: msg,
      okText: AppTranslations.tr('auth.tryAgain'),
    );
  }

  Future<void> loginWithGoogle() async {
    if (isLoading.value || isGoogleLoading.value || isClosed) return;

    isLoading.value = true;
    isGoogleLoading.value = true;
    errorMessage.value = null;

    final shouldRemember = rememberMe.value;

    try {
      await _ensureGoogleSignInInitialized();

      // CATATAN: Jangan panggil signOut() sebelum authenticate() di Credential Manager v7.
      // signOut() menyebabkan race condition yang membuat Credential Manager
      // melaporkan "canceled" meski user sudah memilih akun.

      debugPrint('[LoginController] Memulai Google Sign-In authenticate()...');

      // Buka pemilih akun Google
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      debugPrint(
        '[LoginController] authenticate() berhasil: ${googleUser.email}',
      );

      // Di google_sign_in v7, authentication adalah getter sinkron (bukan Future).
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        // idToken bisa null jika serverClientId salah atau SHA-1 tidak terdaftar
        // di Firebase Console. Coba refresh token sekali sebelum menyerah.
        debugPrint(
          '[LoginController] idToken null setelah authenticate. '
          'Pastikan serverClientId dan SHA-1 terdaftar di Firebase Console.',
        );
        throw StateError(
          'ID Token Google tidak tersedia. '
          'Pastikan SHA-1 debug key terdaftar di Firebase Console.',
        );
      }

      // Buat credential Firebase
      // Di google_sign_in v7, accessToken tidak lagi tersedia di public API.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      // Login ke Firebase Authentication
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (isClosed) return;

      final user = userCredential.user;
      if (user == null) {
        errorMessage.value = 'Data akun Google tidak ditemukan.';
        _showErrorDialog(errorMessage.value!);
        return;
      }

      final uid = user.uid;
      final userEmail = user.email ?? '';
      final displayName = user.displayName ?? 'Pengguna Google';
      final photoUrl = user.photoURL;

      // Pastikan profile user tersedia di Firestore.
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      DocumentSnapshot userDoc;
      try {
        userDoc = await userDocRef.get().timeout(
          const Duration(seconds: 5),
          onTimeout: () =>
              userDocRef.get(const GetOptions(source: Source.cache)),
        );
      } catch (_) {
        // Jika Firestore offline sepenuhnya, anggap doc tidak ada
        userDoc = await userDocRef
            .get(const GetOptions(source: Source.cache))
            .catchError((_) async {
              // Cache juga kosong; lanjutkan saja, profile akan dibuat
              return userDocRef.get();
            });
      }

      String chosenRole = selectedRole.value;

      if (!userDoc.exists) {
        // Pengguna baru — tanyakan role
        if (Get.context != null) {
          final selected = await _promptRoleSelection(Get.context!);
          if (selected != null) chosenRole = selected;
        }

        // Coba via Cloud Function dulu; jika gagal, tulis langsung ke Firestore
        bool profileCreated = false;
        try {
          await TrustedBackendService()
              .call('ensureUserProfile', {
                'name': displayName,
                'photoUrl': photoUrl,
                'requestedRole': chosenRole,
              })
              .timeout(const Duration(seconds: 10));
          profileCreated = true;
        } catch (e) {
          debugPrint(
            '[LoginController] ensureUserProfile CF gagal, fallback Firestore: $e',
          );
        }

        if (!profileCreated) {
          // Fallback: tulis langsung ke Firestore
          final normalizedMail = userEmail.toLowerCase();
          await userDocRef.set({
            'uid': uid,
            'name': displayName,
            'displayName': displayName,
            'email': userEmail,
            'normalizedEmail': normalizedMail,
            'photoUrl': photoUrl,
            'role': chosenRole,
            'requestedRole': chosenRole,
            'pendampingApprovalStatus': chosenRole == 'pendamping'
                ? 'approved'
                : null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isGpsActive': false,
          }, SetOptions(merge: true));
        }
      } else {
        // Pengguna lama — update profil via CF atau Firestore
        try {
          await TrustedBackendService()
              .call('ensureUserProfile')
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint(
            '[LoginController] ensureUserProfile CF gagal untuk user lama, '
            'lanjut tanpa update: $e',
          );
          // Tidak perlu fallback — data sudah ada di Firestore
        }
      }

      if (isClosed) return;

      // Simpan remember me.
      final startup = Get.find<AppStartupController>();
      await startup.handleSuccessfulLogin(rememberMe: shouldRemember);

      if (isClosed) return;

      // Sync state to HajiCareController
      if (Get.isRegistered<HajiCareController>()) {
        final hajicare = Get.find<HajiCareController>();
        await hajicare.syncUserData(uid);
      }

      // Tentukan dashboard.
      final destination = await startup.resolveUserRoleDestination(uid);

      if (isClosed) return;

      bool hasNavigatedGoogle = false;
      void navigateGoogle() {
        if (!hasNavigatedGoogle) {
          hasNavigatedGoogle = true;
          Get.offAllNamed(destination);
        }
      }

      AppDialog.success(
        title: AppTranslations.tr('auth.welcomeAlertTitle'),
        message: 'Anda berhasil masuk dengan Google.',
        okText: 'Masuk Sekarang',
        onOk: navigateGoogle,
        autoDismissDuration: const Duration(milliseconds: 1500),
        onDismiss: navigateGoogle,
      );
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;
      debugPrint(
        '[LoginController] FirebaseAuthException: ${e.code} — ${e.message}',
      );
      errorMessage.value = _friendlyAuthError(e.code, e.message);
      _showErrorDialog(errorMessage.value!);
    } on GoogleSignInException catch (e) {
      if (isClosed) return;
      debugPrint(
        '[LoginController] GoogleSignInException code=${e.code} desc=${e.description}',
      );
      // Jangan silent-return untuk SEMUA kode canceled.
      // Jika user benar-benar memilih akun tapi canceled ter-throw,
      // tampilkan pesan agar user tahu ada masalah konfigurasi.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // Tunjukkan pesan ringan — mungkin user menekan back, atau ada issue SHA-1
        errorMessage.value =
            'Masuk dengan Google dibatalkan. Jika Anda sudah memilih akun, '
            'coba lagi atau restart aplikasi.';
        _showErrorDialog(errorMessage.value!);
        return;
      }
      errorMessage.value = 'Gagal masuk dengan Google. Silakan coba lagi.';
      _showErrorDialog(errorMessage.value!);
    } catch (e, st) {
      if (isClosed) return;
      debugPrint('[LoginController] loginWithGoogle error: $e\n$st');

      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
        return;
      }

      if (errorStr.contains('network') ||
          errorStr.contains('socket') ||
          errorStr.contains('connection')) {
        errorMessage.value =
            'Gagal masuk dengan Google. Periksa koneksi internet Anda.';
      } else if (errorStr.contains('sha') || errorStr.contains('id token')) {
        errorMessage.value =
            'Konfigurasi login Google belum lengkap. Hubungi developer.';
      } else {
        errorMessage.value = 'Gagal masuk dengan Google. Silakan coba lagi.';
      }

      _showErrorDialog(errorMessage.value!);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
        isGoogleLoading.value = false;
      }
    }
  }

  /// Maps Firebase error codes to user-friendly Indonesian messages.
  String _friendlyAuthError(String code, [String? message]) {
    final lowerMessage = message?.toLowerCase() ?? '';
    if (code == 'invalid-credential' ||
        code == 'wrong-password' ||
        lowerMessage.contains('credential is incorrect') ||
        lowerMessage.contains('malformed or has expired') ||
        lowerMessage.contains('invalid password') ||
        lowerMessage.contains('wrong password')) {
      return 'Email atau kata sandi yang Anda masukkan salah.';
    }
    switch (code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'invalid-email':
        return 'Format email tidak valid. Pastikan penulisan email sudah benar.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Silakan hubungi administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan masuk yang gagal. Silakan coba beberapa saat lagi.';
      case 'network-request-failed':
        return 'Sambungan internet bermasalah. Periksa internet, lalu coba lagi.';
      case 'operation-not-allowed':
        return 'Metode masuk ini sedang dinonaktifkan.';
      case 'channel-error':
        return 'Harap isi semua kolom email dan kata sandi.';
      case 'account-exists-with-different-credential':
        return 'Akun sudah terdaftar dengan metode masuk yang berbeda.';
      default:
        if (lowerMessage.contains('network') ||
            lowerMessage.contains('connection')) {
          return 'Sambungan internet bermasalah. Periksa internet, lalu coba lagi.';
        }
        return 'Gagal masuk. Periksa kembali email dan kata sandi Anda.';
    }
  }

  void _showErrorDialog(String message) {
    if (isClosed) return;
    AppDialog.error(
      title: AppTranslations.tr('auth.cannotLoginAlertTitle'),
      message: message,
      okText: 'Coba Lagi',
    );
  }

  Future<String?> _promptRoleSelection(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = AppColors.isDark(ctx);
        final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
        final headingColor = isDark
            ? AppColors.darkTextHeading
            : AppColors.espressoDark;
        final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
        final primaryColor = isDark
            ? AppColors.goldLight
            : AppColors.goldPrimary;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Peran Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: headingColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Peran ini akan disimpan permanen ke akun Anda dan tidak dapat diubah.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: bodyColor, height: 1.4),
              ),
              const SizedBox(height: 20),
              // Role Option: Jamaah
              InkWell(
                onTap: () => Navigator.of(ctx).pop('jamaah'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: primaryColor.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jamaah Haji / Umrah',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Akses panduan ibadah, peta, jadwal sholat & monitoring pendamping',
                              style: TextStyle(fontSize: 12, color: bodyColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Role Option: Pendamping
              InkWell(
                onTap: () => Navigator.of(ctx).pop('pendamping'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.statusSafe.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.statusSafe.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusSafe.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: AppColors.statusSafe,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pendamping / Muthawif',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kelola room, undang jamaah & pantau pergerakan radar realtime',
                              style: TextStyle(fontSize: 12, color: bodyColor),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.statusSafe,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();

    super.onClose();
  }
}
