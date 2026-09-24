import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HajjDuaService extends GetxService {
  static HajjDuaService get instance {
    if (Get.isRegistered<HajjDuaService>()) {
      return Get.find<HajjDuaService>();
    }
    return Get.put(HajjDuaService());
  }

  static const String _bookmarkKey = 'hajj_dua_bookmarks';
  static const String _recentKey = 'hajj_dua_recent';
  static const String _textScaleKey = 'hajj_dua_text_scale';

  final RxSet<String> bookmarkedIds = <String>{}.obs;
  final RxList<String> recentDuaIds = <String>[].obs;
  final RxDouble textScaleMultiplier = 1.0.obs;

  // Audio playback state
  AudioPlayer? _audioPlayer;
  final RxString currentlyPlayingId = ''.obs;
  final RxBool isAudioPlaying = false.obs;
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _completeSub;

  @override
  void onInit() {
    super.onInit();
    _loadStoredPreferences();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    try {
      _audioPlayer = AudioPlayer();
      _completeSub = _audioPlayer?.onPlayerComplete.listen((_) {
        isAudioPlaying.value = false;
        currentPosition.value = Duration.zero;
      });
      _posSub = _audioPlayer?.onPositionChanged.listen((pos) {
        currentPosition.value = pos;
      });
      _durSub = _audioPlayer?.onDurationChanged.listen((dur) {
        totalDuration.value = dur;
      });
    } catch (e) {
      debugPrint('AudioPlayer init not supported or running in test: $e');
    }
  }

  Future<void> _loadStoredPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBookmarks = prefs.getStringList(_bookmarkKey) ?? [];
      bookmarkedIds.assignAll(savedBookmarks);

      final savedRecent = prefs.getStringList(_recentKey) ?? [];
      recentDuaIds.assignAll(savedRecent);

      final savedScale = prefs.getDouble(_textScaleKey) ?? 1.0;
      textScaleMultiplier.value = savedScale;
    } catch (e) {
      debugPrint('Could not load HajjDua preferences: $e');
    }
  }

  Future<void> toggleBookmark(String duaId) async {
    if (bookmarkedIds.contains(duaId)) {
      bookmarkedIds.remove(duaId);
    } else {
      bookmarkedIds.add(duaId);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_bookmarkKey, bookmarkedIds.toList());
    } catch (_) {}
  }

  bool isBookmarked(String duaId) => bookmarkedIds.contains(duaId);

  Future<void> recordDuaOpened(String duaId) async {
    recentDuaIds.remove(duaId);
    recentDuaIds.insert(0, duaId);
    if (recentDuaIds.length > 10) {
      recentDuaIds.removeRange(10, recentDuaIds.length);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentKey, recentDuaIds.toList());
    } catch (_) {}
  }

  void cycleTextScale() {
    if (textScaleMultiplier.value < 1.15) {
      textScaleMultiplier.value = 1.2; // Large
    } else if (textScaleMultiplier.value < 1.3) {
      textScaleMultiplier.value = 1.35; // Extra Large
    } else {
      textScaleMultiplier.value = 1.0; // Normal
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble(_textScaleKey, textScaleMultiplier.value);
    }).catchError((_) {});
  }

  Future<bool> playOrPauseAudio({
    required String duaId,
    required String? audioPath,
  }) async {
    if (audioPath == null || audioPath.trim().isEmpty) {
      return false; // Audio not available
    }

    if (currentlyPlayingId.value == duaId && isAudioPlaying.value) {
      await pauseAudio();
      return true;
    }

    try {
      if (_audioPlayer == null) _initAudioPlayer();
      await _audioPlayer?.stop();
      currentlyPlayingId.value = duaId;
      isAudioPlaying.value = true;
      currentPosition.value = Duration.zero;

      if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
        await _audioPlayer?.play(UrlSource(audioPath));
      } else {
        await _audioPlayer?.play(AssetSource(audioPath));
      }
      return true;
    } catch (e) {
      debugPrint('Error playing audio: $e');
      isAudioPlaying.value = false;
      return false;
    }
  }

  Future<void> pauseAudio() async {
    try {
      await _audioPlayer?.pause();
      isAudioPlaying.value = false;
    } catch (_) {}
  }

  Future<void> stopAudio() async {
    try {
      await _audioPlayer?.stop();
      isAudioPlaying.value = false;
      currentlyPlayingId.value = '';
      currentPosition.value = Duration.zero;
    } catch (_) {}
  }

  Future<void> replayAudio({
    required String duaId,
    required String? audioPath,
  }) async {
    await stopAudio();
    await playOrPauseAudio(duaId: duaId, audioPath: audioPath);
  }

  @override
  void onClose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer?.dispose();
    super.onClose();
  }
}
