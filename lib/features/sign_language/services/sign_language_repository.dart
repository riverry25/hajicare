import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/sign_language_catalog.dart';
import '../models/sign_video_entry.dart';
import 'sign_language_asset_registry.dart';
import 'sign_language_cache_service.dart';
import 'sign_language_config.dart';

/// Hasil pencarian video bahasa isyarat untuk Text-to-Sign.
class SignSearchResult {
  final String query;
  final String language;
  final SignVideoEntry? exactMatch;
  final List<SignVideoEntry> candidates;
  final bool isFound;

  const SignSearchResult({
    required this.query,
    required this.language,
    this.exactMatch,
    this.candidates = const [],
    required this.isFound,
  });

  factory SignSearchResult.notFound({
    required String query,
    required String language,
  }) {
    return SignSearchResult(
      query: query,
      language: language,
      exactMatch: null,
      candidates: const [],
      isFound: false,
    );
  }
}

/// Repository terpusat untuk Text-to-Sign Language (SIBI & BISINDO).
/// Mengimplementasikan arsitektur HYBRID:
/// Bundled Offline Assets ──► Local Persistent Cache ──► Remote Firebase Hosting
class SignLanguageRepository {
  static SignLanguageRepository? _instance;
  static SignLanguageRepository get instance =>
      _instance ??= SignLanguageRepository._();

  SignLanguageRepository._() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: SignLanguageConfig.connectTimeout,
        receiveTimeout: SignLanguageConfig.receiveTimeout,
        responseType: ResponseType.plain,
      ),
    );
  }

  late final Dio _dio;
  final SignLanguageCacheService _cacheService =
      SignLanguageCacheService.instance;

  SignLanguageCatalog? _cachedCatalogInMemory;
  DateTime? _lastCatalogFetchTime;

  // ---------------------------------------------------------------------------
  // 1. CATALOG MANAGEMENT (HYBRID: Remote -> Persistent Local Storage)
  // ---------------------------------------------------------------------------

  /// Mengambil katalog video dengan strategi:
  /// 1. Gunakan cache in-memory jika belum kadaluarsa (< 5 menit) kecuali [forceRefresh]
  /// 2. Coba GET remote catalog dari Firebase Hosting (`index.json`)
  /// 3. Simpan salinan ke persistent local storage jika berhasil
  /// 4. Jika offline/gagal, baca dari persistent local storage `catalog.json`
  /// 5. Selalu integrasikan dengan bundled offline assets
  Future<List<SignVideoEntry>> getAvailableVideos({
    required String language,
    bool forceRefresh = false,
  }) async {
    final cleanLang = language.toLowerCase().trim();

    // 1. Ambil atau muat katalog remote/lokal
    final catalog = await getOrFetchCatalog(forceRefresh: forceRefresh);

    // 2. Gabungkan katalog remote dengan bundled assets lokal
    final List<SignVideoEntry> merged = [];
    final Set<String> registeredIds = {};

    // Prioritas 1: Bundled assets untuk bahasa ini selalu didaftarkan
    final bundled = SignLanguageAssetRegistry.getByLanguage(cleanLang);
    for (final item in bundled) {
      merged.add(item);
      registeredIds.add(item.id);
    }

    // Prioritas 2: Remote/Cached catalog items untuk bahasa ini
    if (catalog != null) {
      for (final rawRemote in catalog.videos) {
        if (rawRemote.language != cleanLang) continue;

        // Cek apakah sudah ada bundled asset dengan ID yang sama
        if (registeredIds.contains(rawRemote.id)) {
          // Bundled asset diprioritaskan, namun kita biarkan bundled asset tetap aktif
          continue;
        }

        // Resolusi status cache lokal untuk file remote
        final isCached = await _cacheService.isVideoCached(rawRemote);
        if (isCached) {
          final file = await _cacheService.getCachedVideoFile(rawRemote);
          merged.add(
            rawRemote.copyWith(
              source: SignVideoSource.localCached,
              cachedFilePath: file?.path,
            ),
          );
        } else {
          merged.add(rawRemote.copyWith(source: SignVideoSource.remote));
        }
        registeredIds.add(rawRemote.id);
      }
    }

    return merged;
  }

  /// Memuat katalog dari memory, network, atau persistent disk cache.
  Future<SignLanguageCatalog?> getOrFetchCatalog({
    bool forceRefresh = false,
  }) async {
    // 1. In-memory cache check (berlaku 5 menit)
    if (!forceRefresh &&
        _cachedCatalogInMemory != null &&
        _lastCatalogFetchTime != null &&
        DateTime.now().difference(_lastCatalogFetchTime!) <
            const Duration(minutes: 5)) {
      return _cachedCatalogInMemory;
    }

    // 2. Coba fetch dari remote
    try {
      final response = await _dio.get<String>(SignLanguageConfig.catalogUrl);
      if (response.statusCode == 200 && response.data != null) {
        final rawString = response.data!;
        final decoded = json.decode(rawString) as Map<String, dynamic>;
        final catalog = SignLanguageCatalog.fromJson(decoded);

        // Simpan salinan ke persistent local storage
        await _cacheService.saveCatalogJson(rawString);
        _cachedCatalogInMemory = catalog;
        _lastCatalogFetchTime = DateTime.now();
        return catalog;
      }
    } catch (e) {
      debugPrint(
        '[SignRepo] Failed to fetch remote catalog: $e (falling back to disk cache)',
      );
    }

    // 3. Fallback: Baca dari disk cache
    try {
      final cachedJson = await _cacheService.readCachedCatalogJson();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = json.decode(cachedJson) as Map<String, dynamic>;
        final catalog = SignLanguageCatalog.fromJson(decoded);
        _cachedCatalogInMemory = catalog;
        return catalog;
      }
    } catch (e) {
      debugPrint('[SignRepo] Failed to read disk catalog: $e');
    }

    return _cachedCatalogInMemory;
  }

  // ---------------------------------------------------------------------------
  // 2. SOURCE RESOLUTION (asset -> localCached -> remote)
  // ---------------------------------------------------------------------------

  /// Menyelesaikan status aktual video source untuk satu entry.
  Future<SignVideoEntry> resolveVideoSource(SignVideoEntry entry) async {
    // 1. Bundled asset selalu asset
    if (entry.source == SignVideoSource.asset) {
      return entry;
    }

    // 2. Cek apakah ada di cache lokal
    final isCached = await _cacheService.isVideoCached(entry);
    if (isCached) {
      final file = await _cacheService.getCachedVideoFile(entry);
      return entry.copyWith(
        source: SignVideoSource.localCached,
        cachedFilePath: file?.path,
      );
    }

    // 3. Masih remote
    return entry.copyWith(source: SignVideoSource.remote, cachedFilePath: null);
  }

  // ---------------------------------------------------------------------------
  // 3. TEXT-TO-SIGN SEARCH ENGINE
  // ---------------------------------------------------------------------------

  /// Mencari video berdasarkan query teks dengan tahapan:
  /// 1. Exact phrase match
  /// 2. Phrase alias match
  /// 3. Exact word match
  /// 4. Word alias match
  /// 5. Candidate words tokenization
  Future<SignSearchResult> searchSign({
    required String query,
    required String language,
  }) async {
    final cleanQuery = _normalizeText(query);
    if (cleanQuery.isEmpty) {
      return SignSearchResult.notFound(query: query, language: language);
    }

    final availableVideos = await getAvailableVideos(language: language);
    if (availableVideos.isEmpty) {
      return SignSearchResult.notFound(query: query, language: language);
    }

    // 1. Exact phrase match pada label
    for (final video in availableVideos) {
      if (_normalizeText(video.label) == cleanQuery) {
        final resolved = await resolveVideoSource(video);
        return SignSearchResult(
          query: query,
          language: language,
          exactMatch: resolved,
          candidates: [resolved],
          isFound: true,
        );
      }
    }

    // 2. Phrase alias match
    for (final video in availableVideos) {
      for (final alias in video.aliases) {
        if (_normalizeText(alias) == cleanQuery) {
          final resolved = await resolveVideoSource(video);
          return SignSearchResult(
            query: query,
            language: language,
            exactMatch: resolved,
            candidates: [resolved],
            isFound: true,
          );
        }
      }
    }

    // 3. Word-by-word tokenized matching jika query berupa kalimat
    final tokens = cleanQuery.split(' ').where((t) => t.isNotEmpty).toList();
    final List<SignVideoEntry> candidates = [];

    for (final token in tokens) {
      for (final video in availableVideos) {
        final normLabel = _normalizeText(video.label);
        final hasAlias = video.aliases.any((a) => _normalizeText(a) == token);
        if (normLabel == token || hasAlias) {
          final resolved = await resolveVideoSource(video);
          if (!candidates.any((c) => c.id == resolved.id)) {
            candidates.add(resolved);
          }
        }
      }
    }

    if (candidates.isNotEmpty) {
      return SignSearchResult(
        query: query,
        language: language,
        exactMatch: candidates.first,
        candidates: candidates,
        isFound: true,
      );
    }

    return SignSearchResult.notFound(query: query, language: language);
  }

  /// Normalisasi teks: lowercase, trim, hapus tanda baca, satukan spasi.
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ---------------------------------------------------------------------------
  // 4. REMOTE DOWNLOAD FLOW WITH DIO (Atomic & Persistent)
  // ---------------------------------------------------------------------------

  /// Mengunduh file video remote ke persistent local storage:
  /// `ApplicationSupportDirectory/sign_language/videos/${language}/${id}_v${version}.mp4`
  Future<SignVideoEntry> downloadVideo(
    SignVideoEntry entry, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (entry.source == SignVideoSource.asset) {
      return entry; // Bundled asset tidak perlu didownload
    }

    // Cek apakah sudah pernah diunduh
    final isAlreadyCached = await _cacheService.isVideoCached(entry);
    if (isAlreadyCached) {
      final file = await _cacheService.getCachedVideoFile(entry);
      return entry.copyWith(
        source: SignVideoSource.localCached,
        cachedFilePath: file?.path,
      );
    }

    final targetFile = await _cacheService.getTargetVideoFile(entry);
    final tempFile = File('${targetFile.path}.tmp');

    final downloadUrl = SignLanguageConfig.resolveVideoUrl(entry.path);
    debugPrint('[SignRepo] Downloading: $downloadUrl -> ${targetFile.path}');

    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await _dio.download(
        downloadUrl,
        tempFile.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            final progress = (received / total).clamp(0.0, 1.0);
            onProgress(progress);
          }
        },
      );

      // Verifikasi integritas download
      if (!await tempFile.exists() || await tempFile.length() < 1024) {
        throw Exception('File video yang diunduh korup atau tidak lengkap.');
      }

      // Atomic rename dari .tmp ke nama file target
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);

      debugPrint('[SignRepo] Download complete: ${targetFile.path}');

      return entry.copyWith(
        source: SignVideoSource.localCached,
        cachedFilePath: targetFile.path,
      );
    } catch (e) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      debugPrint('[SignRepo] Download error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. PACKAGE DOWNLOAD BY CATEGORY
  // ---------------------------------------------------------------------------

  /// Mengunduh seluruh video dalam satu kategori untuk bahasa tertentu.
  /// Contoh kategori: 'health', 'hajj', 'emergency', 'alphabet'.
  Future<void> downloadCategory({
    required String category,
    required String language,
    void Function(int completed, int total, double progress)? onProgress,
  }) async {
    final cleanCategory = category.toLowerCase().trim();
    final allVideos = await getAvailableVideos(
      language: language,
      forceRefresh: true,
    );
    final categoryVideos = allVideos
        .where(
          (v) =>
              v.category == cleanCategory && v.source == SignVideoSource.remote,
        )
        .toList();

    final total = categoryVideos.length;
    if (total == 0) {
      onProgress?.call(0, 0, 1.0);
      return;
    }

    int completed = 0;
    for (final video in categoryVideos) {
      try {
        await downloadVideo(
          video,
          onProgress: (videoProgress) {
            final overallProgress = (completed + videoProgress) / total;
            onProgress?.call(completed, total, overallProgress);
          },
        );
        completed++;
      } catch (e) {
        debugPrint('[SignRepo] Failed to download video ${video.id}: $e');
        // Lanjutkan download video lain dalam kategori meski satu video gagal
      }
    }

    onProgress?.call(completed, total, 1.0);
  }

  // ---------------------------------------------------------------------------
  // 6. CACHE MANAGEMENT
  // ---------------------------------------------------------------------------

  Future<bool> deleteDownloadedVideo(SignVideoEntry entry) async {
    return await _cacheService.deleteCachedVideo(entry);
  }

  Future<int> clearDownloadedVideos() async {
    return await _cacheService.clearAllDownloadedVideos();
  }

  Future<int> getTotalCachedSizeBytes() async {
    return await _cacheService.getTotalCachedSizeBytes();
  }
}
