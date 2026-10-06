import '../models/sign_video_entry.dart';

/// Registry statis untuk bundled offline assets di dalam aplikasi.
/// Memastikan video offline selalu tersedia sejak install tanpa perlu akses filesystem dinamis.
class SignLanguageAssetRegistry {
  SignLanguageAssetRegistry._();

  static const List<SignVideoEntry> bundledAssets = [
    // ── BISINDO BUNDLED ASSETS (ALFABET & KOSAKATA OFFLINE) ─────────────────
    SignVideoEntry(
      id: 'bisindo_a',
      language: 'bisindo',
      type: 'letter',
      label: 'A',
      aliases: ['a'],
      category: 'alphabet',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/alfabet/A.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_b',
      language: 'bisindo',
      type: 'letter',
      label: 'B',
      aliases: ['b'],
      category: 'alphabet',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/alfabet/B.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_c',
      language: 'bisindo',
      type: 'letter',
      label: 'C',
      aliases: ['c'],
      category: 'alphabet',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/alfabet/C.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_d',
      language: 'bisindo',
      type: 'letter',
      label: 'D',
      aliases: ['d'],
      category: 'alphabet',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/alfabet/D.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_dia',
      language: 'bisindo',
      type: 'word',
      label: 'Dia',
      aliases: ['dia', 'ia', 'beliau'],
      category: 'pronoun',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/alfabet/Dia.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_e',
      language: 'bisindo',
      type: 'letter',
      label: 'E',
      aliases: ['e'],
      category: 'alphabet',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/alfabet/E.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_air',
      language: 'bisindo',
      type: 'word',
      label: 'Air',
      aliases: ['air', 'air putih', 'minum air'],
      category: 'general',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/kalimat/Air.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_apa',
      language: 'bisindo',
      type: 'word',
      label: 'Apa',
      aliases: ['apa', 'apakah'],
      category: 'question',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/kalimat/Apa.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_apa_kabar',
      language: 'bisindo',
      type: 'phrase',
      label: 'Apa Kabar',
      aliases: ['apa kabar', 'kabar', 'bagaimana kabar'],
      category: 'greeting',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/kalimat/Apa_Kabar.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_dimana',
      language: 'bisindo',
      type: 'word',
      label: 'Dimana',
      aliases: ['dimana', 'di mana', 'ke mana', 'lokasi'],
      category: 'question',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/kalimat/Dimana.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_halo',
      language: 'bisindo',
      type: 'word',
      label: 'Halo',
      aliases: ['halo', 'hai', 'assalamualaikum', 'salam'],
      category: 'greeting',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/kalimat/Halo.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_mandi',
      language: 'bisindo',
      type: 'word',
      label: 'Mandi',
      aliases: ['mandi', 'kamar mandi', 'toilet', 'wc'],
      category: 'activity',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/kalimat/Mandi.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_minum',
      language: 'bisindo',
      type: 'word',
      label: 'Minum',
      aliases: ['minum', 'butuh minum'],
      category: 'activity',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/kalimat/Minum.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_terima_kasih',
      language: 'bisindo',
      type: 'phrase',
      label: 'Terima Kasih',
      aliases: ['terima kasih', 'makasih', 'syukran', 'terimakasih', 'thanks'],
      category: 'greeting',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/kalimat/Terima_Kasih.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'bisindo_tuli',
      language: 'bisindo',
      type: 'word',
      label: 'Tuli',
      aliases: ['tuli', 'tunarungu', 'gangguan pendengaran', 'teman tuli'],
      category: 'general',
      version: 1,
      path: 'assets/sign_language/offline/bisindo/kalimat/Tuli.mp4',
      source: SignVideoSource.asset,
    ),

    // ── SIBI BUNDLED ASSETS (KOSAKATA OFFLINE) ──────────────────────────────
    SignVideoEntry(
      id: 'sibi_aku',
      language: 'sibi',
      type: 'word',
      label: 'Aku',
      aliases: ['aku', 'saya', 'diri saya'],
      category: 'pronoun',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/Aku.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_sentence_bantu',
      language: 'sibi',
      type: 'phrase',
      label: 'Bantu',
      aliases: [
        'bantu',
        'tolong',
        'tolong bantu',
        'minta tolong',
        'tolong bantu saya',
        'bantuan',
      ],
      category: 'emergency',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/bantu.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_dia',
      language: 'sibi',
      type: 'word',
      label: 'Dia',
      aliases: ['dia', 'ia', 'beliau'],
      category: 'pronoun',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/Dia.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_haus',
      language: 'sibi',
      type: 'word',
      label: 'Haus',
      aliases: ['haus', 'dahaga', 'butuh air', 'kehausan'],
      category: 'health',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/Haus.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_kami',
      language: 'sibi',
      type: 'word',
      label: 'Kami',
      aliases: ['kami'],
      category: 'pronoun',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/Kami.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_kamu',
      language: 'sibi',
      type: 'word',
      label: 'Kamu',
      aliases: ['kamu', 'anda', 'antum'],
      category: 'pronoun',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/Kamu.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_lapar',
      language: 'sibi',
      type: 'word',
      label: 'Lapar',
      aliases: ['lapar', 'butuh makan', 'kelaparan'],
      category: 'health',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/Lapar.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_lelah',
      language: 'sibi',
      type: 'word',
      label: 'Lelah',
      aliases: ['lelah', 'capek', 'letih', 'istirahat'],
      category: 'health',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/Lelah.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_makan',
      language: 'sibi',
      type: 'word',
      label: 'Makan',
      aliases: ['makan', 'makanan', 'sarapan'],
      category: 'activity',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/Makan.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_sentence_masjid',
      language: 'sibi',
      type: 'phrase',
      label: 'Masjid',
      aliases: [
        'masjid',
        'ke masjid',
        'masjidil haram',
        'masjid nabawi',
        'musholla',
      ],
      category: 'hajj',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/masjid.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_minum',
      language: 'sibi',
      type: 'word',
      label: 'Minum',
      aliases: ['minum', 'minuman'],
      category: 'activity',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/Minum.mp4',
      source: SignVideoSource.asset,
    ),
    SignVideoEntry(
      id: 'sibi_sakit',
      language: 'sibi',
      type: 'word',
      label: 'Sakit',
      aliases: [
        'sakit',
        'merasa sakit',
        'tidak enak badan',
        'nyeri',
        'demam',
        'pusing',
      ],
      category: 'health',
      version: 1,
      path: 'assets/sign_language/offline/sibi/kalimat/Sakit.mp4',
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
