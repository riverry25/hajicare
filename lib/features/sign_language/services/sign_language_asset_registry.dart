import '../models/sign_video_entry.dart';

/// Registry statis untuk bundled offline assets di dalam aplikasi.
/// Memastikan video offline selalu tersedia sejak install tanpa perlu akses filesystem dinamis.
class SignLanguageAssetRegistry {
  SignLanguageAssetRegistry._();

  static const List<SignVideoEntry> bundledAssets = [
    // ── BISINDO BUNDLED ASSETS ──────────────────────────────────────────────
    SignVideoEntry(
      id: 'bisindo_alphabet_j',
      language: 'bisindo',
      type: 'alphabet',
      label: 'J',
      aliases: ['j'],
      category: 'alphabet',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/alfabet/J.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_alphabet_l',
      language: 'bisindo',
      type: 'alphabet',
      label: 'L',
      aliases: ['l'],
      category: 'alphabet',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/alfabet/L.mp4',
      source: SignVideoSource.asset,
    ),

    // ── SIBI BUNDLED ASSETS ────────────────────────────────────────────────
    SignVideoEntry(
      id: 'sibi_sentence_masjid',
      language: 'sibi',
      type: 'phrase',
      label: 'Masjid',
      aliases: ['masjid', 'ke masjid', 'masjidil haram'],
      category: 'hajj',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/masjid.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_sentence_bantu',
      language: 'sibi',
      type: 'phrase',
      label: 'Bantu',
      aliases: ['bantu', 'tolong bantu', 'tolong', 'minta tolong'],
      category: 'emergency',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/bantu.mp4',
      source: SignVideoSource.asset,
    ),
  ];

  /// Mengambil semua bundled assets yang difilter berdasarkan bahasa ('sibi' atau 'bisindo').
  static List<SignVideoEntry> getByLanguage(String language) {
    final clean = language.toLowerCase().trim();
    return bundledAssets.where((e) => e.language == clean).toList();
  }

  /// Mencari bundled asset berdasarkan id.
  static SignVideoEntry? findById(String id) {
    try {
      return bundledAssets.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Mengecek apakah suatu label atau alias cocok dengan bundled asset di bahasa tertentu.
  static SignVideoEntry? matchAsset(String query, String language) {
    final cleanQuery = query.toLowerCase().trim();
    final langAssets = getByLanguage(language);

    // 1. Exact label match
    for (final asset in langAssets) {
      if (asset.label.toLowerCase() == cleanQuery) {
        return asset;
      }
    }

    // 2. Alias match
    for (final asset in langAssets) {
      if (asset.aliases.contains(cleanQuery)) {
        return asset;
      }
    }

    return null;
  }
}
