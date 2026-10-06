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
    final Set<String> registeredLabels = {};

    // Prioritas 1: Bundled assets untuk bahasa ini selalu didaftarkan
    final bundled = SignLanguageAssetRegistry.getByLanguage(cleanLang);
    for (final item in bundled) {
      merged.add(item);
      registeredIds.add(item.id);
      registeredLabels.add(item.label.toLowerCase().trim());
    }

    // Prioritas 2: Remote/Cached catalog items untuk bahasa ini
    if (catalog != null) {
      for (final rawRemote in catalog.videos) {
        if (rawRemote.language != cleanLang) continue;

        // Cek apakah sudah ada bundled asset dengan ID atau label yang sama
        if (registeredIds.contains(rawRemote.id) ||
            registeredLabels.contains(rawRemote.label.toLowerCase().trim())) {
          // Bundled asset diprioritaskan
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
        registeredLabels.add(rawRemote.label.toLowerCase().trim());
      }
    }

    return merged;
  }

  /// Memuat katalog dari memory, network, persistent disk cache, atau fallback statis.
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

    // 4. Fallback: Gunakan static catalog bawaan v1.1.0 jika network & disk kosong
    _cachedCatalogInMemory = _fallbackCatalog;
    return _cachedCatalogInMemory;
  }

  /// Katalog statis default v1.1.0 sebagai jaminan ketersediaan metadata saat offline/initial launch
  static final SignLanguageCatalog _fallbackCatalog = SignLanguageCatalog(
    schemaVersion: 1,
    catalogVersion: '1.1.0',
    updatedAt: '2026-10-06',
    videos: [
      const SignVideoEntry(
        id: 'bisindo_baik',
        language: 'bisindo',
        type: 'word',
        label: 'Baik',
        aliases: ['baik'],
        category: 'general',
        version: 1,
        path: 'videos/bisindo/baik_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_berapa',
        language: 'bisindo',
        type: 'word',
        label: 'Berapa',
        aliases: ['berapa'],
        category: 'question',
        version: 1,
        path: 'videos/bisindo/berapa_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_berdiri',
        language: 'bisindo',
        type: 'word',
        label: 'Berdiri',
        aliases: ['berdiri'],
        category: 'movement',
        version: 1,
        path: 'videos/bisindo/berdiri_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_dia',
        language: 'bisindo',
        type: 'word',
        label: 'Dia',
        aliases: ['dia'],
        category: 'pronoun',
        version: 1,
        path: 'videos/bisindo/dia_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_duduk',
        language: 'bisindo',
        type: 'word',
        label: 'Duduk',
        aliases: ['duduk'],
        category: 'movement',
        version: 1,
        path: 'videos/bisindo/duduk_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_f',
        language: 'bisindo',
        type: 'letter',
        label: 'F',
        aliases: ['f'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/f_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_g',
        language: 'bisindo',
        type: 'letter',
        label: 'G',
        aliases: ['g'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/g_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_h',
        language: 'bisindo',
        type: 'letter',
        label: 'H',
        aliases: ['h'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/h_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_i',
        language: 'bisindo',
        type: 'letter',
        label: 'I',
        aliases: ['i'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/i_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_j',
        language: 'bisindo',
        type: 'letter',
        label: 'J',
        aliases: ['j'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/j_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_k',
        language: 'bisindo',
        type: 'letter',
        label: 'K',
        aliases: ['k'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/k_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_kalian',
        language: 'bisindo',
        type: 'word',
        label: 'Kalian',
        aliases: ['kalian'],
        category: 'pronoun',
        version: 1,
        path: 'videos/bisindo/kalian_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_kami',
        language: 'bisindo',
        type: 'word',
        label: 'Kami',
        aliases: ['kami'],
        category: 'pronoun',
        version: 1,
        path: 'videos/bisindo/kami_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_kamu',
        language: 'bisindo',
        type: 'word',
        label: 'Kamu',
        aliases: ['kamu'],
        category: 'pronoun',
        version: 1,
        path: 'videos/bisindo/kamu_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_kapan',
        language: 'bisindo',
        type: 'word',
        label: 'Kapan',
        aliases: ['kapan'],
        category: 'question',
        version: 1,
        path: 'videos/bisindo/kapan_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_kemana',
        language: 'bisindo',
        type: 'word',
        label: 'Kemana',
        aliases: ['kemana'],
        category: 'question',
        version: 1,
        path: 'videos/bisindo/kemana_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_kita',
        language: 'bisindo',
        type: 'word',
        label: 'Kita',
        aliases: ['kita'],
        category: 'pronoun',
        version: 1,
        path: 'videos/bisindo/kita_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_l',
        language: 'bisindo',
        type: 'letter',
        label: 'L',
        aliases: ['l'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/l_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_m',
        language: 'bisindo',
        type: 'letter',
        label: 'M',
        aliases: ['m'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/m_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_mandi',
        language: 'bisindo',
        type: 'word',
        label: 'Mandi',
        aliases: ['mandi'],
        category: 'activity',
        version: 1,
        path: 'videos/bisindo/mandi_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_n',
        language: 'bisindo',
        type: 'letter',
        label: 'N',
        aliases: ['n'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/n_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_o',
        language: 'bisindo',
        type: 'letter',
        label: 'O',
        aliases: ['o'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/o_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_p',
        language: 'bisindo',
        type: 'letter',
        label: 'P',
        aliases: ['p'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/p_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_q',
        language: 'bisindo',
        type: 'letter',
        label: 'Q',
        aliases: ['q'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/q_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_r',
        language: 'bisindo',
        type: 'letter',
        label: 'R',
        aliases: ['r'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/r_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_s',
        language: 'bisindo',
        type: 'letter',
        label: 'S',
        aliases: ['s'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/s_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_siapa',
        language: 'bisindo',
        type: 'word',
        label: 'Siapa',
        aliases: ['siapa'],
        category: 'question',
        version: 1,
        path: 'videos/bisindo/siapa_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_t',
        language: 'bisindo',
        type: 'letter',
        label: 'T',
        aliases: ['t'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/t_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_u',
        language: 'bisindo',
        type: 'letter',
        label: 'U',
        aliases: ['u'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/u_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_v',
        language: 'bisindo',
        type: 'letter',
        label: 'V',
        aliases: ['v'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/v_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_w',
        language: 'bisindo',
        type: 'letter',
        label: 'W',
        aliases: ['w'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/w_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_x',
        language: 'bisindo',
        type: 'letter',
        label: 'X',
        aliases: ['x'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/x_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_y',
        language: 'bisindo',
        type: 'letter',
        label: 'Y',
        aliases: ['y'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/y_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'bisindo_z',
        language: 'bisindo',
        type: 'letter',
        label: 'Z',
        aliases: ['z'],
        category: 'alphabet',
        version: 1,
        path: 'videos/bisindo/z_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'sibi_beli',
        language: 'sibi',
        type: 'word',
        label: 'Beli',
        aliases: ['beli'],
        category: 'general',
        version: 1,
        path: 'videos/sibi/beli_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'sibi_dokter',
        language: 'sibi',
        type: 'word',
        label: 'Dokter',
        aliases: ['dokter'],
        category: 'health',
        version: 1,
        path: 'videos/sibi/dokter_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'sibi_hilang',
        language: 'sibi',
        type: 'word',
        label: 'Hilang',
        aliases: ['hilang'],
        category: 'general',
        version: 1,
        path: 'videos/sibi/hilang_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'sibi_mana',
        language: 'sibi',
        type: 'word',
        label: 'Mana',
        aliases: ['mana'],
        category: 'question',
        version: 1,
        path: 'videos/sibi/mana_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'sibi_obat',
        language: 'sibi',
        type: 'word',
        label: 'Obat',
        aliases: ['obat'],
        category: 'health',
        version: 1,
        path: 'videos/sibi/obat_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'sibi_segera',
        language: 'sibi',
        type: 'word',
        label: 'Segera',
        aliases: ['segera'],
        category: 'general',
        version: 1,
        path: 'videos/sibi/segera_v1.mp4',
        source: SignVideoSource.remote,
      ),
      const SignVideoEntry(
        id: 'sibi_sesat',
        language: 'sibi',
        type: 'word',
        label: 'Sesat',
        aliases: ['sesat'],
        category: 'general',
        version: 1,
        path: 'videos/sibi/sesat_v1.mp4',
        source: SignVideoSource.remote,
      ),
    ],
  );

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
    CancelToken? cancelToken,
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
      if (cancelToken?.isCancelled ?? false) {
        debugPrint('[SignRepo] Category download cancelled by user: $category');
        break;
      }
      try {
        await downloadVideo(
          video,
          cancelToken: cancelToken,
          onProgress: (videoProgress) {
            final overallProgress = (completed + videoProgress) / total;
            onProgress?.call(completed, total, overallProgress);
          },
        );
        completed++;
      } catch (e) {
        if (cancelToken?.isCancelled ?? false) {
          debugPrint('[SignRepo] Cancelled during video ${video.id}');
          rethrow;
        }
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
