import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../../../core/state/app_startup_controller.dart';

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
        final displayName = user.displayName ?? 'Pengguna Google';

        final userPayload = <String, dynamic>{
          'name': displayName,
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'role': selectedRole.value,
          'activeRoomId': null,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (selectedRole.value == 'jamaah') {
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

      // Tentukan dashboard.
      final destination = await startup.resolveUserRoleDestination(uid);

      if (isClosed) return;

      // Tampilkan sukses lalu navigasi.
      if (Get.context != null) {
        AwesomeDialog(
          context: Get.context!,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: 'Selamat Datang!',
          desc: 'Login Google berhasil. Mengarahkan ke dashboard...',
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

      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
        return;
      }

      errorMessage.value = 'Gagal masuk dengan Google: $e';

      _showErrorDialog(errorMessage.value!);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
        isGoogleLoading.value = false;
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
      descTextStyle: const TextStyle(fontSize: 13.5, height: 1.45),
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
