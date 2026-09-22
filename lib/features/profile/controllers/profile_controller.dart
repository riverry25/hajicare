import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  int _lifecycleGeneration = 0;

  // ── Reactive state ─────────────────────────────────────────────────────────
  final displayName = ''.obs;
  final isSavingName = false.obs;

  // ── Medical & Emergency & Identification Data ─────────────────────────────
  final bloodType = ''.obs;
  final allergies = ''.obs;
  final conditions = ''.obs;
  final emergencyContact = ''.obs;
  final passportNumber = ''.obs;
  final nik = ''.obs;
  final nomorPorsi = ''.obs;
  final isSavingMedical = false.obs;

  bool get hasMedicalData =>
      nik.value.trim().isNotEmpty ||
      nomorPorsi.value.trim().isNotEmpty ||
      bloodType.value.trim().isNotEmpty ||
      allergies.value.trim().isNotEmpty ||
      conditions.value.trim().isNotEmpty ||
      emergencyContact.value.trim().isNotEmpty ||
      passportNumber.value.trim().isNotEmpty;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadUserData(_lifecycleGeneration);
  }

  Future<void> reloadUserData() async {
    await _loadUserData(_lifecycleGeneration);
  }

  Future<void> _loadUserData(int generation) async {
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

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (generation != _lifecycleGeneration) return;
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          bloodType.value = (data['bloodType'] as String?) ?? '';
          allergies.value = (data['allergies'] as String?) ?? '';
          conditions.value = (data['conditions'] as String?) ?? '';
          emergencyContact.value = (data['emergencyContact'] as String?) ?? '';
          passportNumber.value =
              (data['passportNumber'] as String?) ??
              (data['passport'] as String?) ??
              '';
          nik.value = (data['nik'] as String?)?.trim() ?? '';
          nomorPorsi.value =
              ((data['nomorPorsi'] as String?) ?? (data['porsi'] as String?))
                  ?.trim() ??
              '';
        }
      }
    } catch (e) {
      debugPrint('[ProfileController] Error loading medical data: $e');
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
    final generation = _lifecycleGeneration;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    isSavingName.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // 1. Update Firebase Auth displayName
      await user.updateDisplayName(trimmed);
      await user.reload();
      if (generation != _lifecycleGeneration) return;

      // 2. Update Firestore with merge (safe even if doc doesn't exist)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': trimmed,
      }, SetOptions(merge: true));
      if (generation != _lifecycleGeneration) return;

      // 3. Reflect in reactive state immediately
      displayName.value = trimmed;

      debugPrint('[ProfileController] displayName updated to: $trimmed');
    } catch (e) {
      debugPrint('[ProfileController] updateDisplayName error: $e');
      rethrow; // Let the UI handle the snackbar
    } finally {
      if (generation == _lifecycleGeneration) {
        isSavingName.value = false;
      }
    }
  }

  // ── Update medical & identity data ─────────────────────────────────────────
  Future<void> updateMedicalData({
    required String bloodTypeVal,
    required String allergiesVal,
    required String conditionsVal,
    required String emergencyContactVal,
    String passportNumberVal = '',
    String nikVal = '',
    String nomorPorsiVal = '',
  }) async {
    final generation = _lifecycleGeneration;
    isSavingMedical.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final trimmedBlood = bloodTypeVal.trim();
      final trimmedAllergies = allergiesVal.trim();
      final trimmedConditions = conditionsVal.trim();
      final trimmedContact = emergencyContactVal.trim();
      final trimmedPassport = passportNumberVal.trim();
      final trimmedNik = nikVal.trim();
      final trimmedPorsi = nomorPorsiVal.trim();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'bloodType': trimmedBlood,
        'allergies': trimmedAllergies,
        'conditions': trimmedConditions,
        'emergencyContact': trimmedContact,
        'passportNumber': trimmedPassport,
        'passport': trimmedPassport,
        'nik': trimmedNik,
        'nomorPorsi': trimmedPorsi,
        'porsi': trimmedPorsi,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (generation != _lifecycleGeneration) return;

      bloodType.value = trimmedBlood;
      allergies.value = trimmedAllergies;
      conditions.value = trimmedConditions;
      emergencyContact.value = trimmedContact;
      passportNumber.value = trimmedPassport;
      nik.value = trimmedNik;
      nomorPorsi.value = trimmedPorsi;

      debugPrint(
        '[ProfileController] profile & medical data updated successfully',
      );
    } catch (e) {
      debugPrint('[ProfileController] updateMedicalData error: $e');
      rethrow;
    } finally {
      if (generation == _lifecycleGeneration) {
        isSavingMedical.value = false;
      }
    }
  }

  @override
  void onClose() {
    _lifecycleGeneration++;
    super.onClose();
  }
}
