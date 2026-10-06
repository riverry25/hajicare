import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk persistensi lokal penandaan jadwal dan rukun ibadah haji.
/// Menyimpan status penyelesaian tahapan (stage) dan amalan (deeds) ke SharedPreferences
/// sehingga progres tetap tersimpan saat dialog ditutup maupun saat aplikasi dibuka kembali.
class HajjGuideService extends GetxService {
  static HajjGuideService get instance {
    if (Get.isRegistered<HajjGuideService>()) {
      return Get.find<HajjGuideService>();
    }
    return Get.put(HajjGuideService(), permanent: true);
  }

  static const String _completedStagesKey = 'hajj_guide_completed_stages';
  static const String _completedDeedsKey = 'hajj_guide_completed_deeds';
  static const String _expandedStagesKey = 'hajj_guide_expanded_stages';

  final RxSet<String> completedStageIds = <String>{'tarwiyah'}.obs;
  final RxSet<String> completedDeedKeys = <String>{}.obs;
  final RxSet<String> expandedStageIds = <String>{'tarwiyah'}.obs;
  final RxBool isLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPreferences();
  }

  /// Memuat status penandaan dari SharedPreferences.
  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stages = prefs.getStringList(_completedStagesKey);
      if (stages != null) {
        completedStageIds.assignAll(stages);
      }

      final deeds = prefs.getStringList(_completedDeedsKey);
      if (deeds != null) {
        completedDeedKeys.assignAll(deeds);
      }

      final expanded = prefs.getStringList(_expandedStagesKey);
      if (expanded != null) {
        expandedStageIds.assignAll(expanded);
      }
    } catch (e) {
      debugPrint('[HajjGuideService] Gagal memuat preferensi: $e');
    } finally {
      isLoaded.value = true;
    }
  }

  /// Mengubah status penyelesaian suatu tahapan haji dan menyinkronkan amalan terkait.
  Future<void> toggleStage(String stageId, {List<String>? stageDeeds}) async {
    if (completedStageIds.contains(stageId)) {
      completedStageIds.remove(stageId);
      if (stageDeeds != null) {
        for (final deed in stageDeeds) {
          completedDeedKeys.remove('$stageId:$deed');
        }
        await _saveDeeds();
      }
    } else {
      completedStageIds.add(stageId);
      if (stageDeeds != null) {
        for (final deed in stageDeeds) {
          completedDeedKeys.add('$stageId:$deed');
        }
        await _saveDeeds();
      }
    }
    await _saveStages();
  }

  /// Mengubah status amalan (deed) individual dalam suatu tahapan haji.
  Future<void> toggleDeed(
    String stageId,
    String deed, {
    List<String>? allStageDeeds,
  }) async {
    final key = '$stageId:$deed';
    if (completedDeedKeys.contains(key)) {
      completedDeedKeys.remove(key);
      // Jika salah satu amalan dicabut, tahapan tidak lagi selesai otomatis
      completedStageIds.remove(stageId);
      await _saveStages();
    } else {
      completedDeedKeys.add(key);
      // Jika seluruh amalan tahapan ini sudah selesai, tandai tahapan sebagai selesai
      if (allStageDeeds != null && allStageDeeds.isNotEmpty) {
        final allDone = allStageDeeds.every(
          (d) => completedDeedKeys.contains('$stageId:$d'),
        );
        if (allDone) {
          completedStageIds.add(stageId);
          await _saveStages();
        }
      }
    }
    await _saveDeeds();
  }

  /// Mengubah status ekspansi tips/panduan tahapan.
  Future<void> toggleExpansion(String stageId) async {
    if (expandedStageIds.contains(stageId)) {
      expandedStageIds.remove(stageId);
    } else {
      expandedStageIds.add(stageId);
    }
    await _saveExpanded();
  }

  /// Mengecek apakah suatu tahapan sudah ditandai selesai.
  bool isStageCompleted(String stageId) => completedStageIds.contains(stageId);

  /// Mengecek apakah suatu amalan sudah ditandai selesai.
  bool isDeedCompleted(String stageId, String deed) =>
      completedDeedKeys.contains('$stageId:$deed') ||
      completedStageIds.contains(stageId);

  /// Mengecek apakah panduan tahapan sedang terbuka.
  bool isStageExpanded(String stageId) => expandedStageIds.contains(stageId);

  /// Mengatur ulang semua progres ke kondisi awal.
  Future<void> resetAll() async {
    completedStageIds.assignAll(['tarwiyah']);
    completedDeedKeys.clear();
    expandedStageIds.assignAll(['tarwiyah']);
    await _saveStages();
    await _saveDeeds();
    await _saveExpanded();
  }

  Future<void> _saveStages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_completedStagesKey, completedStageIds.toList());
    } catch (e) {
      debugPrint('[HajjGuideService] Gagal menyimpan stages: $e');
    }
  }

  Future<void> _saveDeeds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_completedDeedsKey, completedDeedKeys.toList());
    } catch (e) {
      debugPrint('[HajjGuideService] Gagal menyimpan deeds: $e');
    }
  }

  Future<void> _saveExpanded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_expandedStagesKey, expandedStageIds.toList());
    } catch (e) {
      debugPrint('[HajjGuideService] Gagal menyimpan expanded: $e');
    }
  }
}
