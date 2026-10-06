import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../translator/services/speech_service.dart';
import '../models/sign_video_entry.dart';
import '../services/sign_language_repository.dart';

/// Controller GetX untuk fitur Text-to-Sign Language (SIBI & BISINDO).
class TextToSignController extends GetxController {
  final SignLanguageRepository _repository = SignLanguageRepository.instance;

  final TextEditingController textController = TextEditingController();

  // ── REAKTIF STATE ─────────────────────────────────────────────────────────
  final RxString selectedLanguage = 'sibi'.obs; // 'sibi' atau 'bisindo'
  final RxString currentQuery = ''.obs;

  final Rx<SignSearchResult?> searchResult = Rx<SignSearchResult?>(null);
  final Rx<SignVideoEntry?> currentEntry = Rx<SignVideoEntry?>(null);
  final RxList<SignVideoEntry> availableVideos = <SignVideoEntry>[].obs;

  final RxBool isLoadingVideos = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;

  final RxString statusMessage = ''.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  // ── VIDEO PLAYER STATE ───────────────────────────────────────────────────
  VideoPlayerController? _playerController;
  VideoPlayerController? get playerController => _playerController;

  final RxBool isVideoInitialized = false.obs;
  final RxBool isVideoPlaying = false.obs;
  final Rx<Duration> videoPosition = Duration.zero.obs;
  final Rx<Duration> videoDuration = Duration.zero.obs;

  // ── CATEGORY PACKAGE DOWNLOAD STATE ──────────────────────────────────────
  final RxMap<String, double> categoryDownloadProgress = <String, double>{}.obs;
  final RxMap<String, bool> categoryDownloading = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadAvailableVideos();
  }

  @override
  void onClose() {
    _disposePlayer();
    _speechService?.dispose();
    textController.dispose();
    super.onClose();
  }

  // ── 1. PEMUATAN VIDEO & KATALOG ──────────────────────────────────────────

  /// Memuat daftar video yang tersedia untuk bahasa aktif.
  Future<void> loadAvailableVideos({bool forceRefresh = false}) async {
    try {
      isLoadingVideos.value = true;
      errorMessage.value = null;

      final videos = await _repository.getAvailableVideos(
        language: selectedLanguage.value,
        forceRefresh: forceRefresh,
      );

      availableVideos.assignAll(videos);
      currentVocabPage.value = 1;
    } catch (e) {
      debugPrint('[TextToSignCtrl] loadAvailableVideos error: $e');
      errorMessage.value = 'Gagal memuat katalog video: $e';
    } finally {
      isLoadingVideos.value = false;
    }
  }

  /// Beralih bahasa ('sibi' atau 'bisindo').
  void setLanguage(String language) {
    if (selectedLanguage.value == language) return;
    selectedLanguage.value = language;
    _disposePlayer();
    currentEntry.value = null;
    searchResult.value = null;
    currentVocabPage.value = 1;
    loadAvailableVideos();

    // Jalankan ulang pencarian jika ada teks pada text input
    if (textController.text.trim().isNotEmpty) {
      searchSign(textController.text);
    }
  }

  // ── 2. TEXT-TO-SIGN SEARCH ───────────────────────────────────────────────

  /// Mencari dan mencocokkan teks ke video bahasa isyarat.
  Future<void> searchSign(String text) async {
    final query = text.trim();
    currentQuery.value = query;
    if (query.isEmpty) {
      searchResult.value = null;
      currentEntry.value = null;
      _disposePlayer();
      return;
    }

    try {
      isSearching.value = true;
      errorMessage.value = null;

      final result = await _repository.searchSign(
        query: query,
        language: selectedLanguage.value,
      );

      searchResult.value = result;

      if (result.isFound && result.exactMatch != null) {
        final entry = result.exactMatch!;
        currentEntry.value = entry;
        await playEntry(entry);
      } else {
        currentEntry.value = null;
        _disposePlayer();
      }
    } catch (e) {
      debugPrint('[TextToSignCtrl] searchSign error: $e');
      errorMessage.value = 'Terjadi kesalahan saat mencari video: $e';
    } finally {
      isSearching.value = false;
    }
  }

  // ── 3. VIDEO PLAYBACK LIFECYCLE ──────────────────────────────────────────

  /// Memutar video berdasarkan status source (asset vs localCached vs remote).
  Future<void> playEntry(SignVideoEntry entry) async {
    // 1. Selesaikan status sumber aktual
    final resolved = await _repository.resolveVideoSource(entry);
    currentEntry.value = resolved;

    // Jika video remote dan belum di-cache, jangan inisialisasi player; beri tahu pengguna
    if (resolved.source == SignVideoSource.remote) {
      _disposePlayer();
      statusMessage.value =
          'Video ini berada di cloud dan perlu diunduh sebelum diputar.';
      return;
    }

    // 2. Buat controller berdasarkan sumber lokal
    try {
      _disposePlayer();
      statusMessage.value = 'Menyiapkan pemutar video...';

      final VideoPlayerController controller;
      if (resolved.source == SignVideoSource.asset) {
        controller = VideoPlayerController.asset(resolved.path);
      } else if (resolved.source == SignVideoSource.localCached &&
          resolved.cachedFilePath != null) {
        controller = VideoPlayerController.file(File(resolved.cachedFilePath!));
      } else {
        throw Exception('File video tidak dapat ditemukan.');
      }

      await controller.initialize();
      controller.setLooping(true);

      // Listen posisi & status
      controller.addListener(_videoPlayerListener);

      _playerController = controller;
      isVideoInitialized.value = true;
      videoDuration.value = controller.value.duration;

      // Otomatis play
      await controller.play();
      isVideoPlaying.value = true;
      statusMessage.value = resolved.source == SignVideoSource.asset
          ? 'Tersedia offline (Aset Bawaan)'
          : 'Tersedia offline (Tersimpan di HP)';
    } catch (e) {
      debugPrint('[TextToSignCtrl] playEntry error: $e');
      errorMessage.value = 'Gagal memutar video: $e';
      _disposePlayer();
    }
  }

  void _videoPlayerListener() {
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) return;

    videoPosition.value = controller.value.position;
    isVideoPlaying.value = controller.value.isPlaying;
  }

  /// Toggle play / pause.
  void togglePlayPause() {
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  /// Replay video dari awal.
  Future<void> replay() async {
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) return;

    await controller.seekTo(Duration.zero);
    await controller.play();
  }

  /// Seek ke durasi tertentu.
  Future<void> seekTo(Duration position) async {
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) return;

    await controller.seekTo(position);
  }

  void _disposePlayer() {
    if (_playerController != null) {
      _playerController!.removeListener(_videoPlayerListener);
      _playerController!.dispose();
      _playerController = null;
    }
    isVideoInitialized.value = false;
    isVideoPlaying.value = false;
    videoPosition.value = Duration.zero;
    videoDuration.value = Duration.zero;
  }

  // ── 4. DOWNLOAD VIDEO SINGLE & PLAY ──────────────────────────────────────

  /// Mengunduh video remote lalu otomatis memutarnya.
  Future<void> downloadAndPlay(SignVideoEntry entry) async {
    if (isDownloading.value) return;

    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      errorMessage.value = null;
      statusMessage.value = 'Mengunduh video (${entry.label})...';

      final downloadedEntry = await _repository.downloadVideo(
        entry,
        onProgress: (p) {
          downloadProgress.value = p;
        },
      );

      // Perbarui entry di state
      currentEntry.value = downloadedEntry;

      // Perbarui di list available videos
      final index = availableVideos.indexWhere((v) => v.id == entry.id);
      if (index != -1) {
        availableVideos[index] = downloadedEntry;
      }

      // Putar video yang baru saja di-download
      await playEntry(downloadedEntry);
    } catch (e) {
      debugPrint('[TextToSignCtrl] downloadAndPlay error: $e');
      errorMessage.value =
          'Video belum berhasil diunduh. Periksa koneksi internet dan coba lagi.';
    } finally {
      isDownloading.value = false;
      downloadProgress.value = 0.0;
    }
  }

  // ── 5. DOWNLOAD PAKET KATEGORI OFFLINE ────────────────────────────────────

  /// Mengunduh paket kategori (misal: 'health', 'hajj', 'alphabet').
  Future<void> downloadCategoryPackage(String category) async {
    if (categoryDownloading[category] == true) return;

    try {
      categoryDownloading[category] = true;
      categoryDownloadProgress[category] = 0.0;

      await _repository.downloadCategory(
        category: category,
        language: selectedLanguage.value,
        onProgress: (completed, total, progress) {
          categoryDownloadProgress[category] = progress;
        },
      );

      // Refresh list video agar status icon berubah menjadi tersimpan lokal
      await loadAvailableVideos();

      Get.snackbar(
        'Unduhan Berhasil',
        'Paket ${category.toUpperCase()} telah siap digunakan offline.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('[TextToSignCtrl] downloadCategoryPackage error: $e');
      Get.snackbar(
        'Unduhan Terkendala',
        'Beberapa video paket gagal diunduh. Silakan coba kembali saat internet stabil.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
    } finally {
      categoryDownloading[category] = false;
      categoryDownloadProgress[category] = 1.0;
    }
  }

  // ── 6. CACHE MANAGEMENT ──────────────────────────────────────────────────

  /// Menghapus semua video yang telah diunduh dari internet (aset bawaan tidak akan terhapus).
  Future<void> clearDownloadedVideos() async {
    _disposePlayer();
    final count = await _repository.clearDownloadedVideos();
    await loadAvailableVideos();

    Get.snackbar(
      'Pembersihan Selesai',
      '$count video unduhan telah dihapus dari memori perangkat.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  // ── 7. SPEECH-TO-SIGN (VOICE RECOGNITION) ──────────────────────────────────
  SpeechService? _speechService;
  SpeechService get speechService => _speechService ??= SpeechService();

  final RxBool isListening = false.obs;
  final RxString recognizedWords = ''.obs;
  final RxString speechStatusMessage = 'Tekan mikrofon & bicara kata/huruf'.obs;

  /// Memulai atau menghentikan pengenalan suara (Speech to Sign).
  Future<void> toggleVoiceRecognition() async {
    final service = speechService;
    if (isListening.value) {
      await service.stopListening();
      isListening.value = false;
      if (textController.text.trim().isNotEmpty) {
        searchSign(textController.text);
      }
      return;
    }

    recognizedWords.value = '';
    speechStatusMessage.value = 'Mendengarkan... Silakan ucapkan kata';

    service.onStatusChanged = (status, msg) {
      isListening.value = service.isListening;
      if (status == SpeechStatus.listening) {
        isListening.value = true;
        speechStatusMessage.value = 'Mendengarkan... Silakan ucapkan kata';
      } else if (status == SpeechStatus.done) {
        isListening.value = false;
        if (textController.text.trim().isNotEmpty) {
          speechStatusMessage.value = 'Terdeteksi: "${textController.text}"';
        } else {
          speechStatusMessage.value = 'Tekan mikrofon & bicara kata/huruf';
        }
      } else if (status == SpeechStatus.permissionDenied) {
        isListening.value = false;
        speechStatusMessage.value = 'Izin mikrofon diperlukan';
      } else {
        isListening.value = false;
        speechStatusMessage.value = msg;
      }
    };

    service.onResult = (words, isFinal) {
      if (words.trim().isNotEmpty) {
        recognizedWords.value = words;
        textController.text = words;
        currentQuery.value = words;
        if (isFinal) {
          searchSign(words);
        }
      }
    };

    final hasPerm = await service.init();
    if (!hasPerm) {
      isListening.value = false;
      Get.snackbar(
        'Izin Mikrofon',
        'Mohon berikan izin mikrofon untuk menggunakan fitur suara ke isyarat.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await service.startListening(languageCode: 'id');
    isListening.value = service.isListening;
  }

  /// Menghentikan pengenalan suara secara eksplisit.
  Future<void> stopVoiceRecognition() async {
    if (isListening.value) {
      await speechService.stopListening();
      isListening.value = false;
      if (textController.text.trim().isNotEmpty) {
        searchSign(textController.text);
      }
    }
  }

  // ── 8. PAGINASI KOSAKATA (MAKSIMAL 5 VIDEO PER HALAMAN) ───────────────────
  static const int vocabPageSize = 5;
  final RxInt currentVocabPage = 1.obs;

  /// Jumlah total halaman berdasarkan ukuran halaman 5 video.
  int get totalVocabPages {
    if (availableVideos.isEmpty) return 1;
    return ((availableVideos.length - 1) / vocabPageSize).floor() + 1;
  }

  /// Daftar video yang dipotong untuk halaman aktif saat ini.
  List<SignVideoEntry> get paginatedVocabulary {
    if (availableVideos.isEmpty) return [];
    final start = (currentVocabPage.value - 1) * vocabPageSize;
    if (start >= availableVideos.length) {
      currentVocabPage.value = 1;
      return availableVideos.take(vocabPageSize).toList();
    }
    final end = (start + vocabPageSize).clamp(0, availableVideos.length);
    return availableVideos.sublist(start, end);
  }

  /// Pindah ke halaman berikutnya.
  void nextVocabPage() {
    if (currentVocabPage.value < totalVocabPages) {
      currentVocabPage.value++;
    }
  }

  /// Pindah ke halaman sebelumnya.
  void previousVocabPage() {
    if (currentVocabPage.value > 1) {
      currentVocabPage.value--;
    }
  }

  /// Pindah ke nomor halaman tertentu.
  void goToVocabPage(int page) {
    if (page >= 1 && page <= totalVocabPages) {
      currentVocabPage.value = page;
    }
  }
}
