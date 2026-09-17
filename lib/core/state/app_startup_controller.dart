import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';
import 'hajicare_controller.dart';

enum StartupState {
  checking,
  authenticated,
  unauthenticated,
}

/// Centralized controller & Single Source of Truth (SSOT) for:
/// - App startup bootstrap & single-destination routing
/// - Persistent onboarding status (one-time onboarding)
/// - Persistent "Remember Me" preference and session lifecycle
class AppStartupController extends GetxController {
  static const String keyOnboardingDone = 'hajicare_onboarding_done';
  static const String keyRememberMe = 'hajicare_remember_me';

  final startupState = StartupState.checking.obs;

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _initPrefs();
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[AppStartupController] Error loading SharedPreferences: $e');
    }
  }

  // ── Onboarding Persistence ──────────────────────────────────────────────────

  /// Checks if user has already completed or skipped onboarding.
  Future<bool> isOnboardingDone() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(keyOnboardingDone) ?? false;
    } catch (e) {
      debugPrint('[AppStartupController] Error reading onboarding flag: $e');
      return false;
    }
  }

  /// Permanently marks onboarding as completed.
  /// Never cleared on logout.
  Future<void> setOnboardingDone() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(keyOnboardingDone, true);
    } catch (e) {
      debugPrint('[AppStartupController] Error saving onboarding flag: $e');
    }
  }

  // ── Remember Me Persistence ─────────────────────────────────────────────────

  /// Reads whether the user chose "Remember Me" on their last login.
  /// Defaults to true.
  Future<bool> isRememberMe() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(keyRememberMe) ?? true;
    } catch (e) {
      debugPrint('[AppStartupController] Error reading rememberMe flag: $e');
      return true;
    }
  }

  /// Saves the user's "Remember Me" preference.
  Future<void> setRememberMe(bool value) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(keyRememberMe, value);
    } catch (e) {
      debugPrint('[AppStartupController] Error saving rememberMe flag: $e');
    }
  }

  /// Hook called upon successful login or registration.
  /// Ensures onboarding is marked as done and persists the rememberMe flag.
  Future<void> handleSuccessfulLogin({required bool rememberMe}) async {
    await setOnboardingDone();
    await setRememberMe(rememberMe);
    startupState.value = StartupState.authenticated;
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────

  /// Signs out the user from Firebase Auth and navigates to the Login page.
  /// IMPORTANT: Does NOT clear `keyOnboardingDone` so onboarding is never shown again.
  Future<void> signOut() async {
    try {
      debugPrint('[AppStartupController] Signing out...');
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('[AppStartupController] Error during FirebaseAuth.signOut: $e');
    }

    try {
      final prefs = await _getPrefs();
      await prefs.remove(HajiCareController.keyActiveRoomId);
      await prefs.remove(HajiCareController.keyUserRole);
      if (Get.isRegistered<HajiCareController>()) {
        await Get.find<HajiCareController>().applyUserData(roleStr: 'jamaah', roomId: null);
      }
    } catch (e) {
      debugPrint('[AppStartupController] Error clearing prefs during signOut: $e');
    } finally {
      startupState.value = StartupState.unauthenticated;
      Get.offAllNamed(AppRoutes.login);
    }
  }

  // ── Bootstrap & Initial Route Determination ─────────────────────────────────

  /// Determines exactly ONE destination route at app launch:
  /// 1. If onboarding not completed -> [AppRoutes.onboarding]
  /// 2. If onboarding done:
  ///    - If rememberMe was false -> signs out existing session -> [AppRoutes.login]
  ///    - If current Firebase user exists -> [AppRoutes.dashboardJamaah] or [AppRoutes.dashboardPendamping]
  ///    - If current user is null -> [AppRoutes.login]
  Future<String> determineInitialRoute() async {
    startupState.value = StartupState.checking;

    try {
      // 1. Check onboarding status first
      final onboardingDone = await isOnboardingDone();
      if (!onboardingDone) {
        startupState.value = StartupState.unauthenticated;
        return AppRoutes.onboarding;
      }

      // 2. Check Remember Me preference
      final rememberMe = await isRememberMe();
      if (!rememberMe) {
        // If user logged in without Remember Me, terminate persistent session on restart
        debugPrint('[AppStartupController] Remember Me was OFF. Ending session.');
        await FirebaseAuth.instance.signOut();
      }

      // 3. Inspect current Firebase Auth user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        startupState.value = StartupState.unauthenticated;
        return AppRoutes.login;
      }

      // 4. User is authenticated -> determine appropriate role dashboard
      startupState.value = StartupState.authenticated;
      return await resolveUserRoleDestination(currentUser.uid);
    } catch (e) {
      debugPrint('[AppStartupController] Error during bootstrap: $e');
      startupState.value = StartupState.unauthenticated;
      return AppRoutes.login;
    }
  }

  /// Resolves the user's role and activeRoom destination from Firestore or local cache.
  Future<String> resolveUserRoleDestination(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists) {
        final data = doc.data();
        final role = (data?['role'] as String?)?.toLowerCase() ?? 'jamaah';
        final activeRoomId = (data?['activeRoomId'] as String?)?.trim();
        final effectiveRoomId = (activeRoomId != null && activeRoomId.isNotEmpty) ? activeRoomId : null;
        final rawName = data?['name'] as String? ?? data?['displayName'] as String?;

        // Immediately sync to HajiCareController if registered
        if (Get.isRegistered<HajiCareController>()) {
          final hajicare = Get.find<HajiCareController>();
          await hajicare.applyUserData(
            roleStr: role,
            roomId: effectiveRoomId,
            name: rawName,
          );
        }

        if (role == 'admin') {
          return AppRoutes.adminDashboard;
        }

        final hasRoom = effectiveRoomId != null && effectiveRoomId.isNotEmpty;

        if (role == 'pendamping') {
          return hasRoom ? AppRoutes.dashboardPendamping : AppRoutes.joinRoom;
        }

        // Default role: jamaah
        return hasRoom ? AppRoutes.dashboardJamaah : AppRoutes.joinRoom;
      }
    } catch (e) {
      debugPrint('[AppStartupController] Firestore role check skipped/timed out: $e');
    }

    // Fallback: Check local cache if Firestore is offline or timed out
    try {
      final prefs = await _getPrefs();
      final cachedRoom = prefs.getString(HajiCareController.keyActiveRoomId)?.trim();
      final effectiveCachedRoom = (cachedRoom != null && cachedRoom.isNotEmpty) ? cachedRoom : null;
      final cachedRole = (prefs.getString(HajiCareController.keyUserRole) ?? 'jamaah').trim().toLowerCase();

      if (Get.isRegistered<HajiCareController>()) {
        final hajicare = Get.find<HajiCareController>();
        await hajicare.applyUserData(
          roleStr: cachedRole,
          roomId: effectiveCachedRoom,
        );
      }

      if (cachedRole == 'admin') {
        return AppRoutes.adminDashboard;
      }

      final hasRoom = effectiveCachedRoom != null && effectiveCachedRoom.isNotEmpty;
      if (cachedRole == 'pendamping') {
        return hasRoom ? AppRoutes.dashboardPendamping : AppRoutes.joinRoom;
      }
      return hasRoom ? AppRoutes.dashboardJamaah : AppRoutes.joinRoom;
    } catch (e) {
      debugPrint('[AppStartupController] Error reading cache fallback: $e');
    }

    // Default fallback
    return AppRoutes.login;
  }
}
