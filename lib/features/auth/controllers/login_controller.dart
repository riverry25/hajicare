// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/utils/app_dialog.dart';
import '../../../core/theme/app_colors.dart';
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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _googleServerClientId,
  );

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
      errorMessage.value = 'Harap isi email dan kata sandi terlebih dahulu.';
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
        title: 'Berhasil Masuk',
        message: 'Selamat datang kembali di HajiCare! Menyiapkan dashboard...',
        okText: 'Lanjut',
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

      errorMessage.value = 'Terjadi kesalahan saat masuk. Silakan coba beberapa saat lagi.';

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

  Future<void> loginWithGoogle() async {
    if (isLoading.value || isGoogleLoading.value || isClosed) return;

    isLoading.value = true;
    isGoogleLoading.value = true;
    errorMessage.value = null;

    final shouldRemember = rememberMe.value;

    try {
      // Sign out terlebih dahulu agar pemilih akun Google selalu muncul
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Buka pemilih akun Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        isLoading.value = false;
        isGoogleLoading.value = false;
        return;
      }

      // Ambil ID Token & Access Token Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw StateError('ID Token Google tidak tersedia.');
      }

      // Buat credential Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
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

      // Pastikan profile user tersedia di Firestore.
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      final userDoc = await userDocRef.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => userDocRef.get(const GetOptions(source: Source.cache)),
      );

      if (!userDoc.exists) {
        String chosenRole = selectedRole.value;
        if (Get.context != null) {
          final selected = await _promptRoleSelection(Get.context!);
          if (selected != null) {
            chosenRole = selected;
          }
        }

        final displayName = user.displayName ?? 'Pengguna Google';

        final userPayload = <String, dynamic>{
          'name': displayName,
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'role': chosenRole,
          'activeRoomId': null,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (chosenRole == 'jamaah') {
          userPayload['distance'] = 20.0;
          userPayload['separatedMode'] = false;
          userPayload['sosActive'] = false;
          userPayload['shortLabel'] = displayName.split(' ').first;
        }

        await userDocRef.set(userPayload, SetOptions(merge: true));
      }

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
        title: 'Selamat Datang!',
        message: 'Login Google berhasil. Mengarahkan ke dashboard...',
        okText: 'Masuk Sekarang',
        onOk: navigateGoogle,
        autoDismissDuration: const Duration(milliseconds: 1500),
        onDismiss: navigateGoogle,
      );
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;

      errorMessage.value = _friendlyAuthError(e.code, e.message);

      _showErrorDialog(errorMessage.value!);
    } catch (e) {
      if (isClosed) return;

      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
        return;
      }

      if (errorStr.contains('network') || errorStr.contains('socket') || errorStr.contains('connection')) {
        errorMessage.value = 'Gagal masuk dengan Google. Periksa koneksi internet Anda.';
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
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      case 'operation-not-allowed':
        return 'Metode masuk ini sedang dinonaktifkan.';
      case 'channel-error':
        return 'Harap isi semua kolom email dan kata sandi.';
      case 'account-exists-with-different-credential':
        return 'Akun sudah terdaftar dengan metode masuk yang berbeda.';
      default:
        if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
          return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
        }
        return 'Gagal masuk. Periksa kembali email dan kata sandi Anda.';
    }
  }

  void _showErrorDialog(String message) {
    if (isClosed) return;
    AppDialog.error(
      title: 'Gagal Masuk',
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
