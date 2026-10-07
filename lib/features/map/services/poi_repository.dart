import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/geocoding_service.dart';
import '../models/map_poi.dart';
import '../models/map_search_result.dart';
import 'poi_service.dart';

/// Abstraction for POI retrieval and location searching.
/// Allows swapping underlying providers (Overpass, Photon, Nominatim, backend)
/// without modifying UI or MapController.
abstract class PoiRepository {
  Future<List<MapPoi>> fetchNearbyPois({
    required LatLng center,
    int radiusMeters = 2500,
    int limit = 180,
    bool forceRefresh = false,
  });

  Future<List<MapSearchResult>> searchPlaces({
    required String query,
    LatLng? userLocation,
    LatLng? viewportCenter,
    List<MapPoi> currentPois = const [],
    int limit = 15,
  });

  void dispose();
}

/// Default implementation using [PoiService] (Overpass OSM) and [GeocodingService] (Photon/OSM).
class DefaultPoiRepository implements PoiRepository {
  final PoiService _poiService;
  final GeocodingService _geocodingService;

  DefaultPoiRepository({
    PoiService? poiService,
    GeocodingService? geocodingService,
  }) : _poiService = poiService ?? PoiService(),
       _geocodingService = geocodingService ?? GeocodingService();

  @override
  Future<List<MapPoi>> fetchNearbyPois({
    required LatLng center,
    int radiusMeters = 2500,
    int limit = 180,
    bool forceRefresh = false,
  }) {
    return _poiService.fetchNearbyPois(
      center: center,
      radiusMeters: radiusMeters,
      limit: limit,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<List<MapSearchResult>> searchPlaces({
    required String query,
    LatLng? userLocation,
    LatLng? viewportCenter,
    List<MapPoi> currentPois = const [],
    int limit = 15,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || cleanQuery.length < 2) {
      return const [];
    }

    // Anchor location priority: 1. user GPS, 2. map viewport center
    final anchor = userLocation ?? viewportCenter;

    // 1. Fetch remote geocoding results (Photon / Nominatim)
    List<MapSearchResult> remoteResults = const [];
    dynamic remoteError;
    try {
      remoteResults = await _geocodingService.searchLocations(
        cleanQuery,
        latitude: anchor?.latitude,
        longitude: anchor?.longitude,
        limit: limit,
      );
    } catch (e) {
      debugPrint('[DefaultPoiRepository] remote search error: $e');
      remoteError = e;
    }

    // 2. Rank and combine local map POIs and remote search results
    final ranked = MapSearchRanker.rankResults(
      query: cleanQuery,
      remoteResults: remoteResults,
      currentPois: currentPois,
      anchorLocation: anchor,
      limit: limit,
    );

    if (ranked.isEmpty && remoteError != null) {
      throw remoteError;
    }

    return ranked;
  }

  @override
  void dispose() {
    _poiService.dispose();
  }
}

/// Deterministic, nearest-first ranking engine for map search suggestions.
class MapSearchRanker {
  static const Distance _distanceCalc = Distance();

  /// Maps generic keywords in Indonesian and English to canonical POI category tags.
  static final Map<String, List<String>> _categoryKeywords = {
    'hotel': [
      'hotel',
      'penginapan',
      'lodging',
      'hostel',
      'motel',
      'inn',
      'resort',
    ],
    'restaurant': [
      'restaurant',
      'restoran',
      'rumah makan',
      'makan',
      'food',
      'kuliner',
      'warung',
      'dine',
    ],
    'cafe': ['cafe', 'kafe', 'kopi', 'coffee', 'warkop'],
    'pharmacy': [
      'pharmacy',
      'apotek',
      'apotik',
      'farmasi',
      'obat',
      'chemist',
      'drugstore',
    ],
    'medis': [
      'hospital',
      'rumah sakit',
      'rs',
      'medis',
      'medical',
      'kesehatan',
      'igd',
    ],
    'clinic': ['clinic', 'klinik', 'dokter', 'doctor', 'puskesmas'],
    'ibadah': [
      'mosque',
      'masjid',
      'musholla',
      'mushola',
      'ibadah',
      'sholat',
      'salat',
      'surau',
    ],
    'toilet': ['toilet', 'wc', 'kamar mandi', 'restroom', 'lavatory'],
    'wudhu': ['wudhu', 'wudu', 'tempat wudhu', 'air wudhu', 'ablution'],
    'shopping': [
      'shopping',
      'supermarket',
      'mall',
      'toko',
      'pasar',
      'swalayan',
      'minimarket',
      'plaza',
    ],
    'atm': ['atm', 'bank', 'tarik tunai'],
    'fuel': ['spbu', 'bensin', 'pertamina', 'fuel', 'gas station'],
    'parking': ['parkir', 'parking', 'tempat parkir'],
    'police': [
      'polisi',
      'police',
      'pos polisi',
      'kantor polisi',
      'pos pantau',
      'keamanan',
    ],
    'maktab': ['maktab', 'tenda', 'mina', 'perkemahan', 'kemah'],
    'bus': ['bus', 'terminal', 'halte', 'bus station', 'bis'],
    'train': ['kereta', 'stasiun', 'train', 'station', 'railway'],
    'airport': ['bandara', 'airport', 'lapangan terbang'],
    'touristAttraction': [
      'wisata',
      'tourist',
      'attraction',
      'museum',
      'monumen',
    ],
  };

  /// Returns canonical category key if [query] represents a generic category search.
  static String? detectCategoryIntent(String query) {
    final lower = query.trim().toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower == keyword ||
            lower == '${keyword}s' ||
            lower.startsWith('$keyword ') ||
            lower.endsWith(' $keyword')) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// Deterministically ranks combined candidates using category matching, textual relevance,
  /// and proximity distance.
  static List<MapSearchResult> rankResults({
    required String query,
    required List<MapSearchResult> remoteResults,
    required List<MapPoi> currentPois,
    LatLng? anchorLocation,
    int limit = 15,
  }) {
    final lowerQuery = query.trim().toLowerCase();
    final categoryIntent = detectCategoryIntent(lowerQuery);
    final candidates = <MapSearchResult>[];

    // Convert local in-memory POIs to search results
    for (final poi in currentPois) {
      candidates.add(
        MapSearchResult(
          id: poi.id,
          name: poi.name,
          address: poi.address ?? poi.subtitle ?? poi.category.label,
          latitude: poi.coordinate.latitude,
          longitude: poi.coordinate.longitude,
          category: poi.category.name,
          type: poi.category.label,
        ),
      );
    }

    // Add remote geocoding search results
    candidates.addAll(remoteResults);

    // Deduplicate candidates by coordinate proximity (within 45m) and normalized name
    final deduplicated = <MapSearchResult>[];
    for (final candidate in candidates) {
      final isDup = deduplicated.any((existing) {
        final dist = _distanceCalc.as(
          LengthUnit.Meter,
          existing.coordinate,
          candidate.coordinate,
        );
        final nameSim = _isNameSimilar(existing.name, candidate.name);
        return dist < 45.0 && nameSim;
      });
      if (!isDup) {
        deduplicated.add(candidate);
      }
    }

    // Compute deterministic score for each candidate
    final scoredList = <_ScoredResult>[];
    for (final item in deduplicated) {
      final double score = _calculateScore(
        item: item,
        query: lowerQuery,
        categoryIntent: categoryIntent,
        anchor: anchorLocation,
      );
      scoredList.add(_ScoredResult(item, score));
    }

    // Sort descending by score
    scoredList.sort((a, b) => b.score.compareTo(a.score));

    // Return top N results
    return scoredList.map((e) => e.result).take(limit).toList();
  }

  static double _calculateScore({
    required MapSearchResult item,
    required String query,
    required String? categoryIntent,
    required LatLng? anchor,
  }) {
    final itemName = item.name.toLowerCase();
    final itemCategory = (item.category ?? '').toLowerCase();
    final itemType = (item.type ?? '').toLowerCase();
    final itemAddress = item.address.toLowerCase();

    double score = 0.0;
    double? distanceMeters;

    if (anchor != null) {
      distanceMeters = _distanceCalc.as(
        LengthUnit.Meter,
        anchor,
        item.coordinate,
      );
    }

    final bool isCategoryCandidate =
        categoryIntent != null &&
        (_matchesCategory(categoryIntent, itemCategory) ||
            _matchesCategory(categoryIntent, itemType) ||
            _matchesCategory(categoryIntent, itemName));

    if (categoryIntent != null) {
      // ── GENERIC CATEGORY QUERY (e.g. "hotel", "restaurant", "pharmacy") ──
      // Proximity is the strongest factor!
      if (isCategoryCandidate) {
        score += 20000.0; // Huge base boost for category membership
      } else if (itemName.contains(query) || itemCategory.contains(query)) {
        score += 5000.0;
      }

      if (distanceMeters != null) {
        // Distance penalty: 1 pt per meter. Nearest items always rank higher!
        score -= distanceMeters;
      }
    } else {
      // ── SPECIFIC PLACE NAME QUERY (e.g. "Shashi Hotel", "Makkah Clock Tower") ──
      // Textual relevance is the primary factor, distance breaks ties.
      if (itemName == query) {
        score += 30000.0; // Exact full match
      } else if (itemName.startsWith(query)) {
        score += 20000.0; // Prefix match
      } else if (itemName.contains(query)) {
        score += 12000.0; // Substring match
      } else {
        // Check word-by-word matching
        final queryWords = query
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty);
        int matchedWords = 0;
        for (final word in queryWords) {
          if (itemName.contains(word)) matchedWords++;
        }
        if (matchedWords > 0) {
          score += 4000.0 * matchedWords;
        } else if (itemAddress.contains(query)) {
          score += 2000.0; // Found in address
        }
      }

      if (distanceMeters != null) {
        // Subtle distance factor: penalty of 0.2 pt per meter so same-name nearby place wins
        score -= (distanceMeters * 0.2);
      }
    }

    return score;
  }

  static bool _matchesCategory(String intent, String candidateTag) {
    if (candidateTag.isEmpty) return false;
    final keywords = _categoryKeywords[intent] ?? [intent];
    for (final kw in keywords) {
      if (candidateTag.contains(kw)) return true;
    }
    return false;
  }

  static bool _isNameSimilar(String a, String b) {
    final normA = a.trim().toLowerCase();
    final normB = b.trim().toLowerCase();
    if (normA == normB) return true;
    if (normA.contains(normB) || normB.contains(normA)) return true;
    return false;
  }
}

class _ScoredResult {
  final MapSearchResult result;
  final double score;

  const _ScoredResult(this.result, this.score);
}
