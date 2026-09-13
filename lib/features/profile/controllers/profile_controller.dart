import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  // ── Reactive state ─────────────────────────────────────────────────────────
  final displayName = ''.obs;
  final isSavingName = false.obs;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadDisplayName();
  }

  void _loadDisplayName() {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    if (user == null) return;
    final name = user.displayName;
    if (name != null && name.isNotEmpty) {
      displayName.value = name;
    } else {
      final email = user.email;
      if (email != null && email.isNotEmpty) {
        displayName.value = email.split('@').first;
      } else {
        displayName.value = 'Pengguna';
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the safe email string (never null/empty displayed)
  String get safeEmail {
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email != null && email.isNotEmpty) return email;
    } catch (_) {}
    return '';
  }

  /// Returns up to 2 initials from the display name
  /// e.g. "Fadli Hifizansyah" → "FH", "Fadli" → "F"
  String get initials {
    final name = displayName.value.trim();
    if (name.isEmpty) return '?';
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ── Update display name ────────────────────────────────────────────────────
  Future<void> updateDisplayName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    isSavingName.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // 1. Update Firebase Auth displayName
      await user.updateDisplayName(trimmed);
      await user.reload();

      // 2. Update Firestore with merge (safe even if doc doesn't exist)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'displayName': trimmed}, SetOptions(merge: true));

      // 3. Reflect in reactive state immediately
      displayName.value = trimmed;

      debugPrint('[ProfileController] displayName updated to: $trimmed');
    } catch (e) {
      debugPrint('[ProfileController] updateDisplayName error: $e');
      rethrow; // Let the UI handle the snackbar
    } finally {
      isSavingName.value = false;
    }
  }
}
