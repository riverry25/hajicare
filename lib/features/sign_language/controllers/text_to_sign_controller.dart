import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../translator/services/speech_service.dart';
import '../models/sign_video_entry.dart';
import '../services/sign_language_asset_registry.dart';
import '../services/sign_language_repository.dart';

/// Metadata paket kategori yang dihitung secara dinamis
class CategoryPackageInfo {
  final String category;
  final String title;
  final String subtitle;
  final IconData icon;
  final int totalCount;
  final int remoteCount;

  const CategoryPackageInfo({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.totalCount,
    required this.remoteCount,
  });

  bool get isAllDownloaded => remoteCount == 0;
  bool get isFullyDownloaded => remoteCount == 0;
}

/// Controller GetX untuk fitur Text-to-Sign Language (SIBI & BISINDO).
class TextToSignController extends GetxController {
  final SignLanguageRepository _repository = SignLanguageRepository.instance;

  final TextEditingController textController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // ── REAKTIF STATE ─────────────────────────────────────────────────────────
  final RxString selectedLanguage = 'sibi'.obs; // 'sibi' atau 'bisindo'
  final RxString currentQuery = ''.obs;

  final Rx<SignSearchResult?> searchResult = Rx<SignSearchResult?>(null);
  final Rx<SignVideoEntry?> currentEntry = Rx<SignVideoEntry?>(null);
  final RxList<SignVideoEntry> availableVideos = <SignVideoEntry>[].obs;

  // ── AUTOCOMPLETE SUGGESTIONS STATE ────────────────────────────────────────
  final RxList<String> searchSuggestions = <String>[].obs;
  final RxBool showSuggestions = false.obs;

  /// Kamus kosakata umum SIBI untuk auto-suggest
  static const List<String> sibiDictionary = [
    'Aku',
    'Bantu',
    'Beli',
    'Dia',
    'Dokter',
    'Haus',
    'Hilang',
    'Kami',
    'Kamu',
    'Lapar',
    'Lelah',
    'Makan',
    'Mana',
    'Masjid',
    'Minum',
    'Obat',
    'Sakit',
    'Segera',
    'Sesat',
    'Tolong bantu saya',
    'Rumah Sakit',
    'Ambulans',
    'Air Minum',
    'Tawaf',
    'Sa\'i',
    'Hotel',
    'Maktab',
    'Kloter',
    'Polisi',
    'Darurat',
    'Kamar Mandi',
  ];

  /// Kamus alfabet dan kosakata BISINDO untuk auto-suggest
  static const List<String> bisindoDictionary = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    'Air',
    'Apa',
    'Apa Kabar',
    'Baik',
    'Berapa',
    'Berdiri',
    'Dia',
    'Dimana',
    'Duduk',
    'Halo',
    'Kalian',
    'Kami',
    'Kamu',
    'Kapan',
    'Kemana',
    'Kita',
    'Mandi',
    'Minum',
    'Siapa',
    'Terima Kasih',
    'Tuli',
  ];

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
  final Map<String, CancelToken> _categoryCancelTokens = {};

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
    searchFocusNode.dispose();
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

  // ── 2. AUTOCOMPLETE & TEXT-TO-SIGN SEARCH ─────────────────────────────────

  /// Memperbarui query pencarian dan memfilter saran kosakata (autocomplete).
  void updateSearchQuery(String text) {
    currentQuery.value = text;
    currentVocabPage.value = 1;
    final clean = text.trim().toLowerCase();

    if (clean.isEmpty) {
      searchSuggestions.clear();
      showSuggestions.value = false;
      return;
    }

    final candidatePool = <String>{};

    // 1. Kamus bawaan berdasarkan bahasa aktif
    if (selectedLanguage.value == 'sibi') {
      candidatePool.addAll(sibiDictionary);
    } else {
      candidatePool.addAll(bisindoDictionary);
    }

    // 2. Dari katalog video yang saat ini dimuat
    for (final v in availableVideos) {
      candidatePool.add(v.label);
    }

    // 3. Dari registry bundled offline assets
    for (final b in SignLanguageAssetRegistry.getByLanguage(
      selectedLanguage.value,
    )) {
      candidatePool.add(b.label);
    }

    // Filter kandidat: cocokkan awalan kata atau substring
    final prefixMatches = <String>[];
    final containsMatches = <String>[];

    for (final item in candidatePool) {
      final itemLower = item.toLowerCase();
      if (itemLower.startsWith(clean)) {
        prefixMatches.add(item);
      } else if (itemLower.contains(clean)) {
        containsMatches.add(item);
      }
    }

    // Urutkan prefix match lebih dulu
    prefixMatches.sort((a, b) => a.length.compareTo(b.length));
    containsMatches.sort((a, b) => a.length.compareTo(b.length));

    final combined = [...prefixMatches, ...containsMatches].take(6).toList();

    searchSuggestions.assignAll(combined);
    showSuggestions.value = combined.isNotEmpty;
  }

  /// Memilih salah satu saran autocomplete, mengisi input, dan langsung memicu pemutaran video.
  void selectSuggestion(String suggestion) {
    textController.text = suggestion;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    currentQuery.value = suggestion;
    currentVocabPage.value = 1;
    showSuggestions.value = false;
    searchSuggestions.clear();
    searchFocusNode.unfocus();
    searchSign(suggestion);
  }

  /// Menutup popover saran autocomplete.
  void dismissSuggestions() {
    showSuggestions.value = false;
  }

  /// Menghapus teks input pencarian dan mereset hasil pencarian.
  void clearSearch() {
    textController.clear();
    currentQuery.value = '';
    currentVocabPage.value = 1;
    searchSuggestions.clear();
    showSuggestions.value = false;
    searchSign('');
  }

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

  /// Menghasilkan daftar kategori paket secara dinamis berdasarkan video yang ada
  List<CategoryPackageInfo> get dynamicPackageCategories {
    final Map<String, List<SignVideoEntry>> grouped = {};
    for (final v in availableVideos) {
      grouped.putIfAbsent(v.category.toLowerCase().trim(), () => []).add(v);
    }

    final List<CategoryPackageInfo> list = [];
    grouped.forEach((category, videos) {
      final remoteCount = videos
          .where((v) => v.source == SignVideoSource.remote)
          .length;
      final totalCount = videos.length;

      list.add(
        CategoryPackageInfo(
          category: category,
          title: _getCategoryDisplayTitle(category),
          subtitle: _getCategoryDisplaySubtitle(videos),
          icon: _getCategoryDisplayIcon(category),
          totalCount: totalCount,
          remoteCount: remoteCount,
        ),
      );
    });

    // Urutkan paket: yang masih memiliki video untuk diunduh didahulukan
    list.sort((a, b) {
      if (a.remoteCount > 0 && b.remoteCount == 0) return -1;
      if (a.remoteCount == 0 && b.remoteCount > 0) return 1;
      return a.title.compareTo(b.title);
    });

    return list;
  }

  static String _getCategoryDisplayTitle(String cat) {
    switch (cat.toLowerCase().trim()) {
      case 'health':
        return 'Paket Kesehatan';
      case 'hajj':
        return 'Paket Ibadah & Haji';
      case 'emergency':
        return 'Paket Darurat';
      case 'alphabet':
        return 'Paket Alfabet';
      case 'question':
        return 'Paket Tanya Jawab';
      case 'pronoun':
        return 'Paket Kata Ganti';
      case 'movement':
        return 'Paket Gerakan';
      case 'activity':
        return 'Paket Aktivitas';
      case 'greeting':
        return 'Paket Salam & Sapaan';
      case 'general':
        return 'Paket Umum';
      default:
        return 'Paket ${cat.capitalizeFirst ?? cat.toUpperCase()}';
    }
  }

  static String _getCategoryDisplaySubtitle(List<SignVideoEntry> videos) {
    final sample = videos.map((v) => v.label).take(3).join(', ');
    if (videos.length > 3) {
      return '$sample, dsb. (${videos.length} video)';
    }
    return '$sample (${videos.length} video)';
  }

  static IconData _getCategoryDisplayIcon(String cat) {
    switch (cat.toLowerCase().trim()) {
      case 'health':
        return Icons.local_hospital_rounded;
      case 'hajj':
        return Icons.mosque_rounded;
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'alphabet':
        return Icons.spellcheck_rounded;
      case 'question':
        return Icons.help_outline_rounded;
      case 'pronoun':
        return Icons.people_outline_rounded;
      case 'movement':
        return Icons.accessibility_new_rounded;
      case 'activity':
        return Icons.directions_run_rounded;
      case 'greeting':
        return Icons.waving_hand_rounded;
      case 'general':
        return Icons.category_rounded;
      default:
        return Icons.folder_special_rounded;
    }
  }

  /// Mengunduh paket kategori (misal: 'health', 'hajj', 'alphabet').
  Future<void> downloadCategoryPackage(String category) async {
    if (categoryDownloading[category] == true) return;

    final cancelToken = CancelToken();
    _categoryCancelTokens[category] = cancelToken;

    try {
      categoryDownloading[category] = true;
      categoryDownloadProgress[category] = 0.0;

      await _repository.downloadCategory(
        category: category,
        language: selectedLanguage.value,
        cancelToken: cancelToken,
        onProgress: (completed, total, progress) {
          categoryDownloadProgress[category] = progress;
        },
      );

      // Refresh list video agar status icon berubah menjadi tersimpan lokal
      await loadAvailableVideos();

      // Refresh status currentEntry jika bagian dari paket ini
      if (currentEntry.value != null &&
          currentEntry.value!.category.toLowerCase() ==
              category.toLowerCase()) {
        final reResolved = await _repository.resolveVideoSource(
          currentEntry.value!,
        );
        currentEntry.value = reResolved;
        if (reResolved.source == SignVideoSource.localCached &&
            !isVideoPlaying.value) {
          await playEntry(reResolved);
        }
      }

      Get.snackbar(
        'Unduhan Berhasil',
        'Paket ${_getCategoryDisplayTitle(category)} telah siap digunakan offline.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } catch (e) {
      if (cancelToken.isCancelled) {
        debugPrint(
          '[TextToSignCtrl] downloadCategoryPackage cancelled for $category',
        );
        Get.snackbar(
          'Unduhan Dibatalkan',
          'Pengunduhan paket ${_getCategoryDisplayTitle(category)} telah dibatalkan.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
      } else {
        debugPrint('[TextToSignCtrl] downloadCategoryPackage error: $e');
        Get.snackbar(
          'Unduhan Terkendala',
          'Beberapa video paket gagal diunduh. Silakan coba kembali saat internet stabil.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
        );
      }
    } finally {
      categoryDownloading[category] = false;
      categoryDownloadProgress[category] = 1.0;
      _categoryCancelTokens.remove(category);
    }
  }

  /// Membatalkan pengunduhan paket kategori yang sedang berlangsung
  void cancelCategoryPackageDownload(String category) {
    if (_categoryCancelTokens.containsKey(category)) {
      _categoryCancelTokens[category]?.cancel('Dibatalkan oleh pengguna');
      _categoryCancelTokens.remove(category);
    }
    categoryDownloading[category] = false;
    categoryDownloadProgress[category] = 0.0;
  }

  // ── 6. CACHE MANAGEMENT ──────────────────────────────────────────────────

  /// Menghapus semua video yang telah diunduh dari internet (aset bawaan tidak akan terhapus).
  Future<void> clearDownloadedVideos() async {
    _disposePlayer();
    final count = await _repository.clearDownloadedVideos();
    await loadAvailableVideos();

    // Pastikan currentEntry di-refresh statusnya ke remote jika sebelumnya adalah localCached
    if (currentEntry.value != null) {
      final reResolved = await _repository.resolveVideoSource(
        currentEntry.value!,
      );
      currentEntry.value = reResolved;
      if (reResolved.source == SignVideoSource.remote) {
        _disposePlayer();
        statusMessage.value =
            'Video berada di cloud. Silakan unduh untuk memutar secara offline.';
      } else if (reResolved.source == SignVideoSource.asset) {
        await playEntry(reResolved);
      }
    }

    Get.snackbar(
      'Pembersihan Selesai',
      '$count video unduhan telah dihapus dari memori perangkat.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  /// Memastikan status currentEntry mencerminkan kondisi file di disk secara real-time
  Future<void> refreshCurrentEntrySource() async {
    if (currentEntry.value != null) {
      final resolved = await _repository.resolveVideoSource(
        currentEntry.value!,
      );
      currentEntry.value = resolved;
      if (resolved.source == SignVideoSource.remote &&
          isVideoInitialized.value) {
        _disposePlayer();
      }
    }
  }

  /// Memilih item kosakata dari daftar: mengisi teks, menyiapkan hasil, dan memutar/meminta unduh
  Future<void> selectVocabularyItem(SignVideoEntry video) async {
    textController.text = video.label;
    currentQuery.value = video.label;
    currentEntry.value = video;
    searchResult.value = SignSearchResult(
      query: video.label,
      language: selectedLanguage.value,
      exactMatch: video,
      candidates: [video],
      isFound: true,
    );
    await playEntry(video);
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
      showSuggestions.value = false;
      if (textController.text.trim().isNotEmpty) {
        searchSign(textController.text.trim());
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
        showSuggestions.value = false;
        if (textController.text.trim().isNotEmpty) {
          speechStatusMessage.value = 'Terdeteksi: "${textController.text}"';
          if (!isSearching.value) {
            searchSign(textController.text.trim());
          }
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
        final cleanWords = words.trim();
        recognizedWords.value = cleanWords;
        textController.text = cleanWords;
        textController.selection = TextSelection.fromPosition(
          TextPosition(offset: cleanWords.length),
        );
        currentQuery.value = cleanWords;
        updateSearchQuery(cleanWords);
        if (isFinal) {
          showSuggestions.value = false;
          searchSign(cleanWords);
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

  /// Menghentikan pengenalan suara secara eksplisit dan memicu pencarian jika ada teks.
  Future<void> stopVoiceRecognition() async {
    if (isListening.value) {
      await speechService.stopListening();
      isListening.value = false;
      showSuggestions.value = false;
      if (textController.text.trim().isNotEmpty) {
        searchSign(textController.text.trim());
      }
    }
  }

  // ── 8. PAGINASI KOSAKATA (MAKSIMAL 5 VIDEO PER HALAMAN) ───────────────────
  static const int vocabPageSize = 5;
  final RxInt currentVocabPage = 1.obs;

  /// Kosakata yang difilter berdasarkan query pencarian saat ini.
  /// Jika query kosong, mengembalikan seluruh [availableVideos].
  List<SignVideoEntry> get filteredVocabulary {
    final query = currentQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return availableVideos;
    }
    return availableVideos.where((v) {
      final labelMatch = v.label.toLowerCase().contains(query);
      final aliasMatch = v.aliases.any((a) => a.toLowerCase().contains(query));
      final catMatch = v.category.toLowerCase().contains(query);
      return labelMatch || aliasMatch || catMatch;
    }).toList();
  }

  /// Jumlah total halaman berdasarkan ukuran halaman 5 video.
  int get totalVocabPages {
    final list = filteredVocabulary;
    if (list.isEmpty) return 1;
    return ((list.length - 1) / vocabPageSize).floor() + 1;
  }

  /// Daftar video yang dipotong untuk halaman aktif saat ini (maksimal 5 video).
  List<SignVideoEntry> get paginatedVocabulary {
    final list = filteredVocabulary;
    if (list.isEmpty) return [];
    final total = totalVocabPages;
    final page = currentVocabPage.value.clamp(1, total);
    final start = (page - 1) * vocabPageSize;
    final end = (start + vocabPageSize).clamp(0, list.length);
    if (start >= list.length) {
      return list.take(vocabPageSize).toList();
    }
    return list.sublist(start, end);
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
