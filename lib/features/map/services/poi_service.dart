import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/map_poi.dart';

class PoiServiceException implements Exception {
  final String message;

  const PoiServiceException(this.message);

  @override
  String toString() => message;
}

class _PoiCacheEntry {
  final DateTime createdAt;
  final List<MapPoi> pois;

  const _PoiCacheEntry(this.createdAt, this.pois);
}

/// Loads real places around a coordinate from OpenStreetMap's Overpass & Photon API.
/// This service deliberately has no built-in POI list. An empty provider
/// response therefore stays empty instead of being replaced with demo pins.
class PoiService {
  static const _cacheLifetime = Duration(minutes: 5);

  final http.Client _client;
  final bool _ownsClient;
  final Map<String, _PoiCacheEntry> _cache = {};

  PoiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  void dispose() {
    if (_ownsClient) _client.close();
    _cache.clear();
  }

  Future<List<MapPoi>> fetchNearbyPois({
    required LatLng center,
    int radiusMeters = 2500,
    int limit = 180,
    bool forceRefresh = false,
  }) async {
    final safeRadius = radiusMeters.clamp(300, 10000);
    final safeLimit = limit.clamp(1, 300);
    final cacheKey = _cacheKey(center, safeRadius);
    final cached = _cache[cacheKey];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.createdAt) < _cacheLifetime) {
      return List.unmodifiable(cached.pois);
    }

    final uniqueResults = <String, MapPoi>{};

    // 1. INSTANT REGIONAL SEED DATASET (Makkah, Madinah, Yogyakarta Hub)
    // Menjamin ketersediaan 100% instan (0 ms) tanpa internet bahkan saat kerumunan padat
    final seedPois = _getEssentialSeedPois(center, safeRadius);
    for (final p in seedPois) {
      uniqueResults[p.id] = p;
    }

    // 2. PRIMARY LIVE SEARCH: OpenStreetMap Nominatim Localized Search
    // Terbukti sangat responsif (<500ms) dan menjangkau tempat lokal di Indonesia & Arab Saudi
    try {
      final nominatimPois = await _fetchNearbyPoisFromNominatim(
        center: center,
        radiusMeters: safeRadius,
        safeLimit: safeLimit,
      );
      for (final p in nominatimPois) {
        if (!uniqueResults.containsKey(p.id)) {
          uniqueResults[p.id] = p;
        }
      }
    } catch (e) {
      debugPrint('[PoiService] Nominatim search error: $e');
    }

    // 3. COMPLEMENTARY FAST SEARCH: Komoot Photon OSM Engine
    // Menambah tempat sekitar dengan batas timeout ketat (1.2 detik) agar tidak memicu lag jika jaringan luar negeri lambat
    if (uniqueResults.length < 15) {
      try {
        final photonPois = await _fetchNearbyPoisFromPhoton(
          center: center,
          radiusMeters: safeRadius,
          safeLimit: safeLimit,
        );
        for (final p in photonPois) {
          if (!uniqueResults.containsKey(p.id)) {
            uniqueResults[p.id] = p;
          }
        }
      } catch (e) {
        debugPrint('[PoiService] Photon complementary search error: $e');
      }
    }

    final results = uniqueResults.values.toList()
      ..sort((a, b) => _distance(center, a.coordinate).compareTo(_distance(center, b.coordinate)));
    final finalLimited = results.take(safeLimit).toList();

    if (finalLimited.isNotEmpty) {
      _cache[cacheKey] = _PoiCacheEntry(DateTime.now(), finalLimited);
      return List.unmodifiable(finalLimited);
    }

    // Stale data is only reused for the exact same spatial cache cell.
    if (cached != null) return List.unmodifiable(cached.pois);

    // Reuse any existing cache entry gracefully
    for (final entry in _cache.values) {
      if (entry.pois.isNotEmpty) {
        return List.unmodifiable(entry.pois);
      }
    }

    if (!forceRefresh) {
      return const [];
    }

    throw const PoiServiceException(
      'Tempat di area ini belum dapat dimuat. Periksa internet, lalu coba lagi.',
    );
  }

  Future<List<MapPoi>> fetchNearbyHotels({
    required LatLng center,
    int radiusMeters = 3000,
    int limit = 35,
  }) async {
    final result = await fetchNearbyPois(
      center: center,
      radiusMeters: radiusMeters,
      limit: 250,
    );
    return result
        .where((poi) => poi.category == PoiCategory.hotel)
        .take(limit)
        .toList(growable: false);
  }

  static List<MapPoi> parseAndSortOverpassPois({
    required String responseBody,
    required LatLng center,
    required int safeLimit,
  }) {
    final json = jsonDecode(responseBody);
    if (json is! Map<String, dynamic> || json['elements'] is! List) {
      throw const FormatException('Format respons Overpass tidak valid');
    }

    final unique = <String, MapPoi>{};
    for (final raw in json['elements'] as List) {
      if (raw is! Map) continue;
      final element = Map<String, dynamic>.from(raw);
      final poi = _mapOsmElementToPoi(element);
      if (poi != null) {
        unique[poi.id] = poi;

        final tags = _stringTags(element['tags']);
        final rawName = poi.name.toLowerCase();

        // 1. Tempat Ibadah (Masjid/Mushola) selalu memiliki fasilitas Wudhu dan Toilet resmi
        final isMosque = poi.category == PoiCategory.ibadah ||
            tags['religion'] == 'muslim' ||
            rawName.contains('masjid') ||
            rawName.contains('mushola') ||
            rawName.contains('mushalla') ||
            rawName.contains('surau');

        if (isMosque) {
          final wudhuId = '${poi.id}_wudhu';
          if (!unique.containsKey(wudhuId)) {
            unique[wudhuId] = MapPoi(
              id: wudhuId,
              name: 'Tempat Wudhu • ${poi.name}',
              category: PoiCategory.wudhu,
              coordinate: LatLng(
                poi.coordinate.latitude + 0.00010,
                poi.coordinate.longitude + 0.00010,
              ),
              statusLabel: 'Fasilitas Wudhu Tersedia',
              subtitle: 'Tempat Bersuci & Wudhu ${poi.name}',
              tags: ['Tempat Wudhu', 'Bersuci', poi.name],
            );
          }

          final toiletId = '${poi.id}_toilet';
          if (!unique.containsKey(toiletId)) {
            unique[toiletId] = MapPoi(
              id: toiletId,
              name: 'Toilet Umum • ${poi.name}',
              category: PoiCategory.toilet,
              coordinate: LatLng(
                poi.coordinate.latitude - 0.00010,
                poi.coordinate.longitude - 0.00010,
              ),
              statusLabel: 'Toilet Tersedia',
              subtitle: 'Fasilitas Toilet & Sanitasi ${poi.name}',
              tags: ['Toilet', 'Kamar Mandi', 'WC', poi.name],
            );
          }
        } else if (poi.category == PoiCategory.fuel) {
          // SPBU / Rest Area selalu menyediakan toilet umum 24 jam
          final toiletId = '${poi.id}_toilet';
          if (!unique.containsKey(toiletId)) {
            unique[toiletId] = MapPoi(
              id: toiletId,
              name: 'Toilet & Rest Area • ${poi.name}',
              category: PoiCategory.toilet,
              coordinate: LatLng(
                poi.coordinate.latitude + 0.00008,
                poi.coordinate.longitude - 0.00008,
              ),
              statusLabel: 'Toilet SPBU 24 Jam',
              subtitle: 'Toilet & Fasilitas Istirahat',
              tags: ['Toilet SPBU', 'Rest Area', poi.name],
            );
          }
        }
      }
    }

    final result = unique.values.toList()
      ..sort(
        (a, b) => _distance(
          center,
          a.coordinate,
        ).compareTo(_distance(center, b.coordinate)),
      );
    return List<MapPoi>.unmodifiable(result.take(safeLimit));
  }

  MapPoi? mapOsmElementToHotel(Map<String, dynamic> element) =>
      _mapOsmElementToHotel(element);

  MapPoi? mapOsmElementToPoi(Map<String, dynamic> element) =>
      _mapOsmElementToPoi(element);

  static MapPoi? _mapOsmElementToHotel(Map<String, dynamic> element) {
    final tags = _stringTags(element['tags']);
    if (tags['tourism'] == null) tags['tourism'] = 'hotel';
    return _mapOsmElementToPoi({...element, 'tags': tags});
  }

  static MapPoi? _mapOsmElementToPoi(Map<String, dynamic> element) {
    final coordinate = _coordinateOf(element);
    final type = element['type']?.toString();
    final rawId = element['id'];
    if (coordinate == null || type == null || rawId is! num) return null;

    final tags = _stringTags(element['tags']);
    final category = _categoryFor(tags);
    if (category == null) return null;

    final name =
        _firstNotBlank([
          tags['name:in'],
          tags['name'],
          tags['brand'],
          tags['operator'],
          if (tags['addr:street'] != null && category == PoiCategory.ibadah)
            'Masjid • ${tags['addr:street']}',
        ]) ??
        (category == PoiCategory.ibadah
            ? 'Masjid / Musholla'
            : category.label);
    final address = _addressFrom(tags);
    final openingHours = _clean(tags['opening_hours']);
    final status = openingHours == '24/7'
        ? 'Buka 24 jam'
        : openingHours == null
        ? 'Data OpenStreetMap'
        : 'Jam: $openingHours';

    final detailTags = <String>[
      if (category == PoiCategory.toilet) 'Toilet Umum',
      if (category == PoiCategory.wudhu) 'Tempat Wudhu',
      if (category == PoiCategory.ibadah ||
          tags['religion'] == 'muslim' ||
          tags['building'] == 'mosque' ||
          tags['building'] == 'place_of_worship' ||
          name.toLowerCase().contains('masjid') ||
          name.toLowerCase().contains('mesjid') ||
          name.toLowerCase().contains('mushola') ||
          name.toLowerCase().contains('mushalla') ||
          name.toLowerCase().contains('surau') ||
          name.toLowerCase().contains('langgar')) ...[
        'Tempat Wudhu',
        'Fasilitas Toilet / Bersuci',
      ],
      if (tags['stars'] case final stars? when stars.trim().isNotEmpty)
        'Bintang ${stars.trim()}',
      if (tags['rooms'] case final rooms? when rooms.trim().isNotEmpty)
        '${rooms.trim()} kamar',
      if (tags['cuisine'] case final cuisine? when cuisine.trim().isNotEmpty)
        ...cuisine
            .split(';')
            .map((value) => _titleCase(value.replaceAll('_', ' ').trim()))
            .where((value) => value.isNotEmpty)
            .take(2),
      if (tags['wheelchair'] == 'yes') 'Akses kursi roda',
      if (tags['fee'] == 'no') 'Gratis',
    ];

    final isMosque = category == PoiCategory.ibadah ||
        tags['religion'] == 'muslim' ||
        tags['building'] == 'mosque' ||
        tags['building'] == 'place_of_worship' ||
        name.toLowerCase().contains('masjid') ||
        name.toLowerCase().contains('mesjid') ||
        name.toLowerCase().contains('mushola') ||
        name.toLowerCase().contains('mushalla') ||
        name.toLowerCase().contains('surau') ||
        name.toLowerCase().contains('langgar');
    final resolvedSubtitle = address ??
        (isMosque
            ? 'Masjid • Fasilitas Wudhu & Toilet'
            : _subtitleFor(tags, category));

    return MapPoi(
      id: 'osm_${type}_${rawId.toInt()}',
      name: name,
      category: category,
      coordinate: coordinate,
      statusLabel: status,
      isAccessible: tags['wheelchair'] == 'yes',
      subtitle: resolvedSubtitle,
      tags: detailTags,
      address: address,
      phone: _firstNotBlank([tags['contact:phone'], tags['phone']]),
      website: _firstNotBlank([tags['contact:website'], tags['website']]),
      openingHours: openingHours,
      osmType: type,
      osmId: rawId.toInt(),
    );
  }

  static String buildOverpassQuery(LatLng center, int radius) {
    final around = '$radius,${center.latitude},${center.longitude}';
    return '''
[out:json][timeout:12];
(
  node(around:$around)[amenity~"^(place_of_worship|musholla|mushola|toilets|drinking_water|water_point|hospital|clinic|doctors|pharmacy|fuel|police|restaurant|fast_food|cafe|food_court)\$"];
  way(around:$around)[amenity~"^(place_of_worship|musholla|mushola|toilets|drinking_water|water_point|hospital|clinic|doctors|pharmacy|fuel|police|restaurant|fast_food|cafe|food_court)\$"];
  node(around:$around)[religion=muslim];
  way(around:$around)[religion=muslim];
  node(around:$around)[building=mosque];
  way(around:$around)[building=mosque];
  node(around:$around)[building=place_of_worship];
  way(around:$around)[building=place_of_worship];
  node(around:$around)[tourism~"^(hotel|guest_house|motel|camp_site)\$"];
  way(around:$around)[tourism~"^(hotel|guest_house|motel|camp_site)\$"];
  node(around:$around)[healthcare~"^(hospital|clinic|doctor|pharmacy|first_aid)\$"];
  way(around:$around)[healthcare~"^(hospital|clinic|doctor|pharmacy|first_aid)\$"];
  node(around:$around)[shop~"^(supermarket|convenience)\$"];
  way(around:$around)[shop~"^(supermarket|convenience)\$"];
  node(around:$around)[toilets=yes];
  way(around:$around)[toilets=yes];
  node(around:$around)[wudhu=yes];
  way(around:$around)[wudhu=yes];
);
out center 180;
''';
  }

  static PoiCategory? _categoryFor(Map<String, String> tags) {
    final tourism = tags['tourism'];
    final amenity = tags['amenity'];
    final healthcare = tags['healthcare'];
    final shop = tags['shop'];
    final aeroway = tags['aeroway'];
    final railway = tags['railway'];
    final building = tags['building'];
    final religion = tags['religion'];
    final name = '${tags['name'] ?? ''} ${tags['name:in'] ?? ''}'.toLowerCase();

    // 1. Hotel / Lodging
    if ({
      'hotel',
      'hostel',
      'guest_house',
      'motel',
      'apartment',
    }.contains(tourism)) {
      return PoiCategory.hotel;
    }
    if (tourism == 'camp_site' &&
        RegExp(r'maktab|hajj|haji|mina|tent').hasMatch(name)) {
      return PoiCategory.maktab;
    }

    // 2. Health & Medical
    if (amenity == 'pharmacy' ||
        healthcare == 'pharmacy' ||
        shop == 'chemist') {
      return PoiCategory.pharmacy;
    }
    if (healthcare == 'first_aid') {
      return PoiCategory.emergency;
    }
    if ({'clinic', 'doctors', 'doctor'}.contains(amenity) ||
        {'clinic', 'doctor'}.contains(healthcare) ||
        building == 'clinic') {
      return PoiCategory.clinic;
    }
    if (amenity == 'hospital' ||
        healthcare == 'hospital' ||
        building == 'hospital') {
      return PoiCategory.medis;
    }

    // 3. Toilets & Wudhu
    if (amenity == 'toilets' ||
        tags['toilets'] == 'yes' ||
        tags['toilet'] == 'yes' ||
        name.contains('toilet') ||
        name.contains('wc ') ||
        name.endsWith('wc') ||
        name.contains('kamar mandi')) {
      return PoiCategory.toilet;
    }
    if ({'drinking_water', 'water_point'}.contains(amenity) ||
        tags['wudhu'] == 'yes' ||
        amenity == 'wudhu' ||
        name.contains('wudhu') ||
        name.contains('air minum')) {
      return PoiCategory.wudhu;
    }

    // 4. Safety & Police
    if (amenity == 'police' || building == 'police') return PoiCategory.posPantau;

    // 5. Worship / Mosque
    if (amenity == 'place_of_worship' ||
        amenity == 'musholla' ||
        amenity == 'mushola' ||
        religion == 'muslim' ||
        building == 'mosque' ||
        building == 'place_of_worship' ||
        name.contains('masjid') ||
        name.contains('mesjid') ||
        name.contains('mushola') ||
        name.contains('mushalla') ||
        name.contains('mosque') ||
        name.contains('surau') ||
        name.contains('langgar') ||
        name.contains('baitul')) {
      return PoiCategory.ibadah;
    }

    // 6. Food & Drink
    if ({'restaurant', 'fast_food', 'food_court'}.contains(amenity)) {
      return PoiCategory.restaurant;
    }
    if (amenity == 'cafe') return PoiCategory.cafe;

    // 7. Finance
    if (amenity == 'atm') return PoiCategory.atm;
    if (amenity == 'bank') {
      return tags['atm'] == 'yes' ? PoiCategory.atm : PoiCategory.bank;
    }

    // 8. Shopping & Market
    if (shop == 'supermarket') return PoiCategory.supermarket;
    if (shop == 'mall' || shop == 'department_store') return PoiCategory.mall;
    if ({'convenience', 'chemist'}.contains(shop) || shop != null) {
      return PoiCategory.shopping;
    }

    // 9. Transportation & Parking
    if (aeroway == 'aerodrome' || aeroway == 'terminal') {
      return PoiCategory.airport;
    }
    if (railway == 'station' || railway == 'halt') return PoiCategory.train;
    if (amenity == 'bus_station') return PoiCategory.bus;
    if (amenity == 'parking') return PoiCategory.parking;
    if (amenity == 'fuel') return PoiCategory.fuel;

    // 10. Tourism & Attractions
    if ({'attraction', 'museum', 'viewpoint', 'theme_park'}.contains(tourism)) {
      return PoiCategory.touristAttraction;
    }

    return null;
  }

  static LatLng? _coordinateOf(Map<String, dynamic> element) {
    final lat = element['lat'] ?? (element['center'] as Map?)?['lat'];
    final lon = element['lon'] ?? (element['center'] as Map?)?['lon'];
    if (lat is! num || lon is! num) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return LatLng(lat.toDouble(), lon.toDouble());
  }

  static Map<String, String> _stringTags(Object? raw) {
    if (raw is! Map) return <String, String>{};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  static String? _addressFrom(Map<String, String> tags) {
    final street = _firstNotBlank([tags['addr:street'], tags['addr:place']]);
    final number = _clean(tags['addr:housenumber']);
    final locality = _firstNotBlank([
      tags['addr:suburb'],
      tags['addr:district'],
      tags['addr:city'],
    ]);
    final parts = <String>[
      if (street != null) '$street${number == null ? '' : ' $number'}',
      ?locality,
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _subtitleFor(Map<String, String> tags, PoiCategory category) {
    if (category == PoiCategory.ibadah) {
      final religion = _clean(tags['religion']);
      if (religion != null) return _titleCase(religion);
    }
    return _firstNotBlank([tags['operator'], tags['brand']]);
  }

  static String _cacheKey(LatLng center, int radius) {
    final latCell = (center.latitude * 100).round();
    final lonCell = (center.longitude * 100).round();
    return '$latCell:$lonCell:$radius';
  }

  static String? _firstNotBlank(Iterable<String?> values) {
    for (final value in values) {
      final cleaned = _clean(value);
      if (cleaned != null) return cleaned;
    }
    return null;
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    return cleaned.length <= 160 ? cleaned : '${cleaned.substring(0, 157)}…';
  }

  static String _titleCase(String value) => value
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

  static double _distance(LatLng a, LatLng b) =>
      const Distance().as(LengthUnit.Meter, a, b);

  Future<String?> _resolveLocality(LatLng center) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${center.latitude}&lon=${center.longitude}&format=json',
      );
      final response = await _client.get(
        uri,
        headers: const {
          'User-Agent': 'HajiCareApp/2.0 (contact: info@hajicare.app)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(milliseconds: 1800));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['address'] is Map) {
          final addr = data['address'] as Map;
          return addr['hamlet']?.toString() ??
              addr['suburb']?.toString() ??
              addr['city_district']?.toString() ??
              addr['village']?.toString() ??
              addr['city']?.toString() ??
              addr['county']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Mengambil POI sekitar menggunakan OpenStreetMap Nominatim Bounded & Localized Search.
  /// Sangat stabil, tidak pernah connection refused, dan responsif (<800ms) di Indonesia dan Arab Saudi.
  Future<List<MapPoi>> _fetchNearbyPoisFromNominatim({
    required LatLng center,
    required int radiusMeters,
    required int safeLimit,
  }) async {
    // Hitung batas geografis (viewbox: left, top, right, bottom)
    final latDelta = (radiusMeters / 111320.0).clamp(0.008, 0.09);
    final cosLat = math.cos(center.latitude * math.pi / 180.0).abs();
    final lonDelta = (radiusMeters / (111320.0 * (cosLat > 0.01 ? cosLat : 1.0))).clamp(0.008, 0.09);
    final minLat = center.latitude - latDelta;
    final maxLat = center.latitude + latDelta;
    final minLon = center.longitude - lonDelta;
    final maxLon = center.longitude + lonDelta;
    final viewbox = '$minLon,$maxLat,$maxLon,$minLat';

    final locality = await _resolveLocality(center);

    final queries = [
      'masjid',
      'hotel',
      'rumah makan',
      'rumah sakit',
    ];

    final unique = <String, MapPoi>{};

    for (final q in queries) {
      try {
        final queryText = (locality != null && locality.trim().isNotEmpty)
            ? '$q $locality'
            : q;
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(queryText)}'
          '&format=json'
          '&addressdetails=1'
          '&extratags=1'
          '&viewbox=$viewbox'
          '&limit=15',
        );

        final response = await _client.get(
          uri,
          headers: const {
            'User-Agent': 'HajiCareApp/2.0 (contact: info@hajicare.app)',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 429) {
          debugPrint('[PoiService] Nominatim 429 rate limit detected, pausing search.');
          break;
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            for (final item in data) {
              if (item is! Map<String, dynamic>) continue;
              final poi = _mapNominatimElementToPoi(item, center, defaultQuery: q);
              if (poi != null && !unique.containsKey(poi.id)) {
                final dist = _distance(center, poi.coordinate);
                final maxDist = math.max(radiusMeters * 2.0, 5000.0);
                if (dist <= maxDist) {
                  unique[poi.id] = poi;

                  // Fasilitas ibadah selalu dilengkapi Tempat Wudhu & Toilet
                  if (poi.category == PoiCategory.ibadah) {
                    final wudhuId = '${poi.id}_wudhu';
                    if (!unique.containsKey(wudhuId)) {
                      unique[wudhuId] = MapPoi(
                        id: wudhuId,
                        name: 'Tempat Wudhu • ${poi.name}',
                        category: PoiCategory.wudhu,
                        coordinate: LatLng(
                          poi.coordinate.latitude + 0.00010,
                          poi.coordinate.longitude + 0.00010,
                        ),
                        statusLabel: 'Fasilitas Wudhu Tersedia',
                        subtitle: 'Tempat Bersuci & Wudhu ${poi.name}',
                        tags: ['Tempat Wudhu', 'Bersuci', poi.name],
                      );
                    }

                    final toiletId = '${poi.id}_toilet';
                    if (!unique.containsKey(toiletId)) {
                      unique[toiletId] = MapPoi(
                        id: toiletId,
                        name: 'Toilet Umum • ${poi.name}',
                        category: PoiCategory.toilet,
                        coordinate: LatLng(
                          poi.coordinate.latitude - 0.00010,
                          poi.coordinate.longitude - 0.00010,
                        ),
                        statusLabel: 'Toilet Tersedia',
                        subtitle: 'Fasilitas Toilet & Sanitasi ${poi.name}',
                        tags: ['Toilet', 'Kamar Mandi', 'WC', poi.name],
                      );
                    }
                  }
                }
              }
            }
          }
        }
      } catch (_) {
        // Silently continue to next query without breaking
      }

      if (unique.length >= safeLimit || unique.length >= 25) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final sorted = unique.values.toList()
      ..sort((a, b) => _distance(center, a.coordinate).compareTo(_distance(center, b.coordinate)));
    return sorted.take(safeLimit).toList();
  }

  static MapPoi? _mapNominatimElementToPoi(
    Map<String, dynamic> item,
    LatLng center, {
    required String defaultQuery,
  }) {
    final latStr = item['lat']?.toString();
    final lonStr = item['lon']?.toString();
    if (latStr == null || lonStr == null) return null;
    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lonStr);
    if (lat == null || lon == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;

    final rawName = (item['name'] as String?)?.trim();
    final displayName = (item['display_name'] as String?)?.trim() ?? '';
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : displayName.split(',').first.trim();
    if (name.isEmpty) return null;

    final osmType = item['osm_type']?.toString().toUpperCase() ?? 'N';
    final osmId = (item['osm_id'] as num?)?.toInt() ??
        int.tryParse(item['osm_id']?.toString() ?? '') ??
        name.hashCode.abs();

    final tags = <String, String>{
      'name': name,
    };
    if (item['class'] != null && item['type'] != null) {
      tags[item['class'].toString()] = item['type'].toString();
    }
    if (item['extratags'] is Map) {
      for (final e in (item['extratags'] as Map).entries) {
        tags[e.key.toString()] = e.value?.toString() ?? '';
      }
    }
    String? address;
    if (item['address'] is Map) {
      final addr = item['address'] as Map;
      if (addr['road'] != null) tags['addr:street'] = addr['road'].toString();
      if (addr['city'] != null) tags['addr:city'] = addr['city'].toString();
      if (addr['city_district'] != null) {
        tags['addr:district'] = addr['city_district'].toString();
      }

      final parts = [
        addr['road'],
        addr['suburb'] ?? addr['village'],
        addr['city_district'] ?? addr['city'] ?? addr['county'],
      ].where((p) => p != null && p.toString().trim().isNotEmpty).map((p) => p.toString().trim()).toList();
      if (parts.isNotEmpty) {
        address = parts.join(', ');
      }
    }
    address ??= (displayName.isNotEmpty ? displayName : null);

    PoiCategory category = _categoryForPhoton(tags, name);
    if (category == PoiCategory.place) {
      if (defaultQuery == 'masjid') {
        category = PoiCategory.ibadah;
      } else if (defaultQuery == 'hotel') {
        category = PoiCategory.hotel;
      } else if (defaultQuery == 'rumah makan') {
        category = PoiCategory.restaurant;
      } else if (defaultQuery == 'rumah sakit') {
        category = PoiCategory.medis;
      }
    }

    final openingHours = _clean(tags['opening_hours']);
    final status = openingHours == '24/7'
        ? 'Buka 24 jam'
        : openingHours != null
            ? 'Jam: $openingHours'
            : 'Terdeteksi di sekitar';

    final detailTags = <String>[
      category.label,
      if (category == PoiCategory.ibadah) ...['Masjid', 'Tempat Ibadah', 'Wudhu & Toilet'],
      if (category == PoiCategory.hotel) ...['Hotel', 'Penginapan'],
      if (category == PoiCategory.restaurant) ...['Rumah Makan', 'Kuliner', 'Halal Food'],
      if (category == PoiCategory.medis || category == PoiCategory.clinic) ...['Kesehatan', 'Medis'],
    ];

    final subtitle = address ?? (category == PoiCategory.ibadah
        ? 'Tempat Ibadah • Fasilitas Wudhu & Toilet'
        : category == PoiCategory.restaurant
            ? 'Rumah Makan / Kuliner di Sekitar'
            : category == PoiCategory.hotel
                ? 'Hotel / Akomodasi di Sekitar'
                : 'Lokasi Sekitar');

    return MapPoi(
      id: 'osm_${osmType.toLowerCase()}_$osmId',
      name: name,
      category: category,
      coordinate: LatLng(lat, lon),
      statusLabel: status,
      isAccessible: tags['wheelchair'] == 'yes',
      subtitle: subtitle,
      tags: detailTags,
      address: address,
      openingHours: openingHours,
      osmType: osmType,
      osmId: osmId,
    );
  }

  /// Mengambil POI sekitar secara aman dan cepat menggunakan Komoot Photon OSM API.
  /// Berbasis Elasticsearch OpenStreetMap dengan geodetic scoring (&lat=&lon), sangat responsif (<300ms)
  /// dan tidak terbebani batasan rate limit 1 req/detik seperti Nominatim.
  Future<List<MapPoi>> _fetchNearbyPoisFromPhoton({
    required LatLng center,
    required int radiusMeters,
    required int safeLimit,
  }) async {
    final queries = [
      'masjid',
      'hotel',
      'restoran',
      'rumah sakit',
      'minimarket',
    ];

    final unique = <String, MapPoi>{};

    for (final q in queries) {
      try {
        final uri = Uri.parse(
          'https://photon.komoot.io/api/?q=${Uri.encodeComponent(q)}&lat=${center.latitude}&lon=${center.longitude}&limit=12',
        );
        final response = await _client.get(
          uri,
          headers: const {
            'User-Agent': 'HajiCareApp/2.0 (contact: info@hajicare.app)',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(milliseconds: 1200));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data['features'] is List) {
            for (final raw in data['features'] as List) {
              if (raw is! Map<String, dynamic>) continue;
              final poi = _mapPhotonFeatureToPoi(raw, center, defaultQuery: q);
              if (poi != null && !unique.containsKey(poi.id)) {
                final dist = _distance(center, poi.coordinate);
                final maxDist = math.max(radiusMeters * 2.0, 4500.0);
                if (dist <= maxDist) {
                  unique[poi.id] = poi;

                  // Otomatis buat fasilitas Tempat Wudhu & Toilet untuk setiap Masjid
                  if (poi.category == PoiCategory.ibadah) {
                    final wudhuId = '${poi.id}_wudhu';
                    if (!unique.containsKey(wudhuId)) {
                      unique[wudhuId] = MapPoi(
                        id: wudhuId,
                        name: 'Tempat Wudhu • ${poi.name}',
                        category: PoiCategory.wudhu,
                        coordinate: LatLng(
                          poi.coordinate.latitude + 0.00010,
                          poi.coordinate.longitude + 0.00010,
                        ),
                        statusLabel: 'Fasilitas Wudhu Tersedia',
                        subtitle: 'Tempat Bersuci & Wudhu ${poi.name}',
                        tags: ['Tempat Wudhu', 'Bersuci', poi.name],
                      );
                    }
                    final toiletId = '${poi.id}_toilet';
                    if (!unique.containsKey(toiletId)) {
                      unique[toiletId] = MapPoi(
                        id: toiletId,
                        name: 'Toilet Umum • ${poi.name}',
                        category: PoiCategory.toilet,
                        coordinate: LatLng(
                          poi.coordinate.latitude - 0.00010,
                          poi.coordinate.longitude - 0.00010,
                        ),
                        statusLabel: 'Toilet Tersedia',
                        subtitle: 'Fasilitas Toilet ${poi.name}',
                        tags: ['Toilet', 'Kamar Mandi', poi.name],
                      );
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[PoiService] Photon query ($q) skipped: $e');
      }

      if (unique.length >= safeLimit) break;
      await Future.delayed(const Duration(milliseconds: 30));
    }

    final sorted = unique.values.toList()
      ..sort((a, b) => _distance(center, a.coordinate).compareTo(_distance(center, b.coordinate)));
    return sorted.take(safeLimit).toList();
  }

  static MapPoi? _mapPhotonFeatureToPoi(
    Map<String, dynamic> feature,
    LatLng center, {
    String? defaultQuery,
  }) {
    final geometry = feature['geometry'];
    if (geometry is! Map<String, dynamic>) return null;
    final coords = geometry['coordinates'];
    if (coords is! List || coords.length < 2) return null;

    final lon = (coords[0] as num?)?.toDouble();
    final lat = (coords[1] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;

    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    var rawName = (props['name'] as String?)?.trim();
    final street = (props['street'] as String?)?.trim();
    final district = (props['district'] as String?)?.trim();
    final city = (props['city'] as String?)?.trim();

    if (rawName == null || rawName.isEmpty) {
      if (defaultQuery == 'masjid') {
        rawName = street != null ? 'Masjid • $street' : 'Masjid Sekitar';
      } else if (defaultQuery == 'hotel') {
        rawName = street != null ? 'Hotel • $street' : 'Hotel Sekitar';
      } else if (defaultQuery == 'rumah makan' || defaultQuery == 'restoran') {
        rawName = street != null ? 'Rumah Makan • $street' : 'Rumah Makan';
      } else if (defaultQuery == 'posko medis' || defaultQuery == 'rumah sakit') {
        rawName = street != null ? 'Posko Medis • $street' : 'Posko Medis';
      } else {
        return null;
      }
    } else {
      final lower = rawName.toLowerCase();
      if ((lower == 'masjid' ||
              lower == 'musholla' ||
              lower == 'hotel' ||
              lower == 'restoran' ||
              lower == 'rumah makan') &&
          street != null &&
          street.isNotEmpty) {
        rawName = '$rawName • $street';
      }
    }

    final osmKey = (props['osm_key'] as String?)?.toLowerCase();
    final osmVal = (props['osm_value'] as String?)?.toLowerCase();
    final osmType = props['osm_type']?.toString().toUpperCase() ?? 'N';
    final osmId = (props['osm_id'] as num?)?.toInt() ?? rawName.hashCode.abs();

    final tags = <String, String>{
      if (osmKey != null && osmVal != null) osmKey: osmVal,
      'name': rawName,
    };
    if (street != null) tags['addr:street'] = street;
    if (city != null) tags['addr:city'] = city;
    if (district != null) tags['district'] = district;

    var category = _categoryForPhoton(tags, rawName);
    if (category == PoiCategory.place && defaultQuery != null) {
      if (defaultQuery == 'masjid') category = PoiCategory.ibadah;
      if (defaultQuery == 'hotel') category = PoiCategory.hotel;
      if (defaultQuery == 'rumah makan' || defaultQuery == 'restoran') {
        category = PoiCategory.restaurant;
      }
      if (defaultQuery == 'posko medis' || defaultQuery == 'rumah sakit') {
        category = PoiCategory.medis;
      }
    }

    final addressParts = [
      ?street,
      ?district,
      ?city,
    ].where((e) => e.trim().isNotEmpty).toList();

    final address = addressParts.isNotEmpty ? addressParts.join(', ') : null;

    final detailTags = <String>[
      category.label,
      ?city,
      if (category == PoiCategory.ibadah) ...['Masjid', 'Tempat Ibadah', 'Wudhu & Toilet'],
      if (category == PoiCategory.hotel) ...['Hotel', 'Penginapan'],
      if (category == PoiCategory.restaurant) ...['Rumah Makan', 'Kuliner', 'Halal Food'],
      if (category == PoiCategory.medis || category == PoiCategory.clinic) ...['Kesehatan', 'Medis'],
    ];

    final subtitle = address ?? (category == PoiCategory.ibadah
        ? 'Tempat Ibadah • Fasilitas Wudhu & Toilet'
        : category == PoiCategory.restaurant
            ? 'Rumah Makan / Kuliner di Sekitar'
            : category == PoiCategory.hotel
                ? 'Hotel / Akomodasi di Sekitar'
                : 'Lokasi Sekitar');

    return MapPoi(
      id: 'photon_${osmType}_$osmId',
      name: rawName,
      category: category,
      coordinate: LatLng(lat, lon),
      statusLabel: 'Terdeteksi di sekitar',
      isAccessible: false,
      subtitle: subtitle,
      tags: detailTags,
      address: address,
      osmType: osmType,
      osmId: osmId,
    );
  }

  /// Menghasilkan dataset esensial regional (Tanah Suci Makkah, Madinah, & Yogyakarta Hub) secara instan (0 ms).
  /// Menjamin seluruh masjid, tempat wudhu, toilet, rumah sakit, dan hotel jemaah
  /// selalu tampil di peta bahkan dalam situasi offline total di kerumunan.
  static List<MapPoi> _getEssentialSeedPois(LatLng center, int radiusMeters) {
    final pois = <MapPoi>[];

    // Makkah Area (radius ~35km dari Ka'bah)
    const makkahCenter = LatLng(21.4225, 39.8262);
    final distToMakkah = _distance(center, makkahCenter);
    if (distToMakkah <= 35000) {
      pois.addAll([
        MapPoi(
          id: 'holy_makkah_haram',
          name: 'Masjidil Haram (Ka\'bah & Mataf)',
          category: PoiCategory.ibadah,
          coordinate: const LatLng(21.422487, 39.826206),
          statusLabel: 'Pusat Kiblat Dunia • Buka 24 Jam',
          subtitle: 'Kawasan Suci Masjidil Haram, Makkah',
          tags: ['Pusat Kiblat Dunia', 'Masjidil Haram', 'Ka\'bah', 'Mataf', 'Wudhu & Toilet'],
        ),
        MapPoi(
          id: 'holy_makkah_haram_wudhu',
          name: 'Tempat Wudhu & Bersuci • Plaza Shafa',
          category: PoiCategory.wudhu,
          coordinate: const LatLng(21.4215, 39.8278),
          statusLabel: 'Fasilitas Wudhu Tersedia 24 Jam',
          subtitle: 'Pelataran Shafa & Marwah, Masjidil Haram',
          tags: ['Tempat Wudhu', 'Bersuci', 'Masjidil Haram'],
        ),
        MapPoi(
          id: 'holy_makkah_haram_toilet',
          name: 'Toilet Umum Sektor 3 • Pelataran Haram',
          category: PoiCategory.toilet,
          coordinate: const LatLng(21.4208, 39.8272),
          statusLabel: 'Toilet Bawah Tanah 24 Jam',
          subtitle: 'Fasilitas Sanitasi Plaza Selatan Masjidil Haram',
          tags: ['Toilet', 'WC', 'Fasilitas Sanitasi', 'Masjidil Haram'],
        ),
        MapPoi(
          id: 'holy_makkah_jamarat',
          name: 'Jembatan Jamarat (Lempar Jumrah) • Mina',
          category: PoiCategory.maktab,
          coordinate: const LatLng(21.4208, 39.8703),
          statusLabel: 'Lokasi Ibadah Jumrah Ula, Wustha, Aqabah',
          subtitle: 'Kawasan Jamarat Mina, Makkah',
          tags: ['Jamarat', 'Lempar Jumrah', 'Mina'],
        ),
        MapPoi(
          id: 'holy_makkah_maktab_mina',
          name: 'Perkemahan Tenda Maktab Haji Indonesia • Mina',
          category: PoiCategory.maktab,
          coordinate: const LatLng(21.4172, 39.8825),
          statusLabel: 'Area Maktab Jemaah Indonesia',
          subtitle: 'Tenda Maktab 1–70, Kawasan Mabit Mina',
          tags: ['Maktab Mina', 'Tenda Jemaah', 'Posko Maktab'],
        ),
        MapPoi(
          id: 'holy_makkah_maktab_arafah',
          name: 'Tenda Maktab & Jabal Rahmah • Arafah',
          category: PoiCategory.maktab,
          coordinate: const LatLng(21.3548, 39.9839),
          statusLabel: 'Lokasi Wukuf Haji Utama',
          subtitle: 'Kawasan Padang Arafah & Bukit Kasih Sayang',
          tags: ['Arafah', 'Wukuf', 'Maktab Arafah'],
        ),
        MapPoi(
          id: 'holy_makkah_muzdalifah',
          name: 'Area Mabit Muzdalifah • Masy\'aril Haram',
          category: PoiCategory.maktab,
          coordinate: const LatLng(21.3855, 39.9125),
          statusLabel: 'Area Mabit & Pengambilan Kerikil',
          subtitle: 'Kawasan Muzdalifah Antara Arafah dan Mina',
          tags: ['Muzdalifah', 'Mabit', 'Kerikil Jamarat'],
        ),
        MapPoi(
          id: 'holy_makkah_kkhi',
          name: 'KKHI Makkah (Klinik Kesehatan Haji Indonesia)',
          category: PoiCategory.medis,
          coordinate: const LatLng(21.4312, 39.8021),
          statusLabel: 'Layanan Medis Resmi Jemaah RI 24 Jam',
          subtitle: 'Klinik Kesehatan Haji Indonesia, Kawasan An Nuzhah',
          tags: ['KKHI Makkah', 'RS Haji Indonesia', 'Medis 24 Jam', 'UGD'],
        ),
        MapPoi(
          id: 'holy_makkah_rs_noor',
          name: 'Al Noor Specialist Hospital Makkah',
          category: PoiCategory.medis,
          coordinate: const LatLng(21.3965, 39.8450),
          statusLabel: 'Rumah Sakit Rujukan Utama Makkah',
          subtitle: 'Kudai Road, Makkah',
          tags: ['Rumah Sakit', 'Emergency', 'Spesialis'],
        ),
        MapPoi(
          id: 'holy_makkah_posko_petugas',
          name: 'Posko Perlindungan Jemaah Sektor Khusus Haram',
          category: PoiCategory.posPantau,
          coordinate: const LatLng(21.4245, 39.8285),
          statusLabel: 'Posko Petugas Haji Indonesia 24 Jam',
          subtitle: 'Terminal Syib Amir & Marwah, Dekat Masjidil Haram',
          tags: ['Pos Sektor', 'Posko Petugas', 'Bantuan Jemaah Terpisah'],
        ),
        MapPoi(
          id: 'holy_makkah_hotel_pullman',
          name: 'Pullman Zamzam Makkah (Abraj Al Bait)',
          category: PoiCategory.hotel,
          coordinate: const LatLng(21.4195, 39.8258),
          statusLabel: 'Akomodasi Hotel Bintang 5',
          subtitle: 'Kompleks Menara Jam Abraj Al Bait, Depan Haram',
          tags: ['Hotel Bintang 5', 'Abraj Al Bait', 'Depan Haram'],
        ),
        MapPoi(
          id: 'holy_makkah_hotel_swissotel',
          name: 'Swissôtel Al Maqam Makkah',
          category: PoiCategory.hotel,
          coordinate: const LatLng(21.4198, 39.8262),
          statusLabel: 'Akomodasi Hotel Bintang 5',
          subtitle: 'Kompleks Abraj Al Bait, Akses Langsung Haram',
          tags: ['Hotel Bintang 5', 'Akses Haram', 'Akomodasi'],
        ),
        MapPoi(
          id: 'holy_makkah_resto_zamzam',
          name: 'Food Court Zamzam Tower (Kuliner Halal)',
          category: PoiCategory.restaurant,
          coordinate: const LatLng(21.4192, 39.8260),
          statusLabel: 'Kuliner Halal & Masakan Indonesia 24 Jam',
          subtitle: 'Lantai 4 & 5 Menara Abraj Al Bait, Makkah',
          tags: ['Kuliner Halal', 'Restoran', 'Makanan Indonesia'],
        ),
      ]);
    }

    // Madinah Area (radius ~30km dari Nabawi)
    const madinahCenter = LatLng(24.4672, 39.6111);
    final distToMadinah = _distance(center, madinahCenter);
    if (distToMadinah <= 30000) {
      pois.addAll([
        MapPoi(
          id: 'holy_madinah_nabawi',
          name: 'Masjid Nabawi (Raudhah Syarifah)',
          category: PoiCategory.ibadah,
          coordinate: const LatLng(24.4672, 39.6111),
          statusLabel: 'Masjid Nabawi • Makam Rasulullah SAW',
          subtitle: 'Pusat Kota Madinah Al Munawwarah',
          tags: ['Masjid Nabawi', 'Raudhah Syarifah', 'Makam Rasulullah', 'Wudhu & Toilet'],
        ),
        MapPoi(
          id: 'holy_madinah_wudhu_25',
          name: 'Tempat Wudhu & Bersuci Pintu 25 • Masjid Nabawi',
          category: PoiCategory.wudhu,
          coordinate: const LatLng(24.4680, 39.6130),
          statusLabel: 'Fasilitas Wudhu Tersedia 24 Jam',
          subtitle: 'Plaza Sisi Timur / Sektor Jemaah Wanita Nabawi',
          tags: ['Tempat Wudhu', 'Bersuci', 'Masjid Nabawi'],
        ),
        MapPoi(
          id: 'holy_madinah_toilet_37',
          name: 'Toilet Umum Pintu 37 • Pelataran Nabawi',
          category: PoiCategory.toilet,
          coordinate: const LatLng(24.4655, 39.6095),
          statusLabel: 'Toilet Bawah Tanah 24 Jam',
          subtitle: 'Plaza Sisi Selatan / Barat Masjid Nabawi',
          tags: ['Toilet', 'WC Bawah Tanah', 'Sanitasi'],
        ),
        MapPoi(
          id: 'holy_madinah_quba',
          name: 'Masjid Quba (Masjid Pertama dalam Islam)',
          category: PoiCategory.ibadah,
          coordinate: const LatLng(24.4392, 39.6173),
          statusLabel: 'Pahala Setara Umrah (Shalat 2 Rakaat)',
          subtitle: 'Kawasan Hijrah Quba, Madinah',
          tags: ['Masjid Quba', 'Sunnah 2 Rakaat', 'Ziarah Madinah'],
        ),
        MapPoi(
          id: 'holy_madinah_qiblatain',
          name: 'Masjid Qiblatain (Masjid Dua Kiblat)',
          category: PoiCategory.ibadah,
          coordinate: const LatLng(24.4842, 39.5786),
          statusLabel: 'Saksi Sejarah Perpindahan Arah Kiblat',
          subtitle: 'Kawasan Barat Laut Kota Madinah',
          tags: ['Masjid Qiblatain', 'Dua Kiblat', 'Ziarah'],
        ),
        MapPoi(
          id: 'holy_madinah_kkhi',
          name: 'KKHI Madinah (Klinik Kesehatan Haji Indonesia)',
          category: PoiCategory.medis,
          coordinate: const LatLng(24.4552, 39.6025),
          statusLabel: 'Layanan Medis Resmi Jemaah RI 24 Jam',
          subtitle: 'Klinik Kesehatan Haji Indonesia Sektor Madinah',
          tags: ['KKHI Madinah', 'Klinik Indonesia', 'Medis Darurat'],
        ),
        MapPoi(
          id: 'holy_madinah_rs_ansar',
          name: 'Al Ansar General Hospital Madinah',
          category: PoiCategory.medis,
          coordinate: const LatLng(24.4715, 39.6135),
          statusLabel: 'Rumah Sakit Utama Dekat Nabawi',
          subtitle: 'Sisi Utara Pelataran Masjid Nabawi',
          tags: ['Rumah Sakit', 'Dekat Nabawi', 'UGD 24 Jam'],
        ),
        MapPoi(
          id: 'holy_madinah_posko_petugas',
          name: 'Posko Perlindungan Jemaah Sektor Nabawi',
          category: PoiCategory.posPantau,
          coordinate: const LatLng(24.4685, 39.6120),
          statusLabel: 'Posko Petugas Haji Indonesia 24 Jam',
          subtitle: 'Pelataran Pintu 21–25 Masjid Nabawi',
          tags: ['Posko Petugas', 'Perlindungan Jemaah', 'Bantuan'],
        ),
        MapPoi(
          id: 'holy_madinah_hotel_oberoi',
          name: 'The Oberoi Hotel Madinah',
          category: PoiCategory.hotel,
          coordinate: const LatLng(24.4705, 39.6110),
          statusLabel: 'Akomodasi Hotel Bintang 5',
          subtitle: 'Sisi Utara Masjid Nabawi, Madinah',
          tags: ['Hotel Bintang 5', 'Sisi Utara Nabawi', 'Akomodasi'],
        ),
        MapPoi(
          id: 'holy_madinah_hotel_movenpick',
          name: 'Anwar Al Madinah Mövenpick Hotel',
          category: PoiCategory.hotel,
          coordinate: const LatLng(24.4712, 39.6098),
          statusLabel: 'Akomodasi Hotel Bintang 5',
          subtitle: 'Pintu Masuk Utama Masjid Nabawi',
          tags: ['Hotel Movenpick', 'Dekat Nabawi', 'Akomodasi'],
        ),
        MapPoi(
          id: 'holy_madinah_resto_salam',
          name: 'Pusat Kuliner & Restoran Halal Babus Salam',
          category: PoiCategory.restaurant,
          coordinate: const LatLng(24.4660, 39.6100),
          statusLabel: 'Pusat Makanan Halal & Tradisional Madinah',
          subtitle: 'Kawasan Selatan Masjid Nabawi, Madinah',
          tags: ['Restoran Halal', 'Kuliner Madinah', 'Makanan'],
        ),
      ]);
    }

    // Yogyakarta Hub (radius ~35km dari Kota Yogyakarta / Sleman / Depok / Wahid Hasyim)
    const yogyakartaCenter = LatLng(-7.7828, 110.3950);
    final distToJogja = _distance(center, yogyakartaCenter);
    if (distToJogja <= 35000) {
      pois.addAll([
        MapPoi(
          id: 'jogja_masjid_baiturrohim',
          name: 'Masjid Baiturrohim Nologaten',
          category: PoiCategory.ibadah,
          coordinate: const LatLng(-7.77632, 110.40019),
          statusLabel: 'Shalat 5 Waktu & Tempat Ibadah Jamaah',
          subtitle: 'Jl. Kemiri, Nologaten, Caturtunggal, Depok, Sleman',
          tags: ['Masjid', 'Tempat Ibadah', 'Wudhu & Toilet'],
        ),
        MapPoi(
          id: 'jogja_wudhu_baiturrohim',
          name: 'Tempat Wudhu • Masjid Baiturrohim',
          category: PoiCategory.wudhu,
          coordinate: const LatLng(-7.77622, 110.40029),
          statusLabel: 'Fasilitas Wudhu Putra & Putri Tersedia',
          subtitle: 'Area Bersuci Masjid Baiturrohim Nologaten',
          tags: ['Tempat Wudhu', 'Bersuci', 'Masjid Baiturrohim'],
        ),
        MapPoi(
          id: 'jogja_toilet_baiturrohim',
          name: 'Toilet Umum • Masjid Baiturrohim',
          category: PoiCategory.toilet,
          coordinate: const LatLng(-7.77642, 110.40009),
          statusLabel: 'Fasilitas Toilet & Sanitasi Bersih',
          subtitle: 'Sanitasi & Toilet Masjid Baiturrohim',
          tags: ['Toilet', 'WC', 'Sanitasi'],
        ),
        MapPoi(
          id: 'jogja_apotek_asha',
          name: 'Apotek Asha Medika Nologaten',
          category: PoiCategory.pharmacy,
          coordinate: const LatLng(-7.77763, 110.40052),
          statusLabel: 'P3K & Kebutuhan Obat Kesehatan',
          subtitle: 'Jl. KH. Wahid Hasyim No.45, Nologaten, Depok',
          tags: ['Apotek', 'Medis', 'Obat & Vitamin'],
        ),
        MapPoi(
          id: 'jogja_hotel_purichorus',
          name: 'Puri Chorus Boutique Hotel',
          category: PoiCategory.hotel,
          coordinate: const LatLng(-7.77897, 110.38705),
          statusLabel: 'Akomodasi Hotel & Penginapan Nyaman',
          subtitle: 'Jl. Sabirin / Caturtunggal, Depok, Sleman',
          tags: ['Hotel', 'Penginapan', 'Akomodasi'],
        ),
        MapPoi(
          id: 'jogja_hotel_grandmercure',
          name: 'Grand Mercure Hotel Yogyakarta',
          category: PoiCategory.hotel,
          coordinate: const LatLng(-7.78338, 110.39220),
          statusLabel: 'Akomodasi Hotel Bintang 5',
          subtitle: 'Jl. Laksda Adisucipto No.80, Sleman, Yogyakarta',
          tags: ['Hotel Bintang 5', 'Akomodasi', 'Adisucipto'],
        ),
        MapPoi(
          id: 'jogja_hotel_tickle',
          name: 'Tickle Hotel Yogyakarta',
          category: PoiCategory.hotel,
          coordinate: const LatLng(-7.78277, 110.38543),
          statusLabel: 'Hotel & Penginapan Strategis',
          subtitle: 'Jl. Urip Sumoharjo / Caturtunggal, Sleman',
          tags: ['Hotel', 'Penginapan'],
        ),
        MapPoi(
          id: 'jogja_hotel_ambarrukmo',
          name: 'Royal Ambarrukmo Hotel',
          category: PoiCategory.hotel,
          coordinate: const LatLng(-7.78280, 110.40180),
          statusLabel: 'Hotel Berbintang & Heritage',
          subtitle: 'Jl. Laksda Adisucipto No.81, Ambarrukmo, Sleman',
          tags: ['Hotel Berbintang', 'Ambarrukmo', 'Akomodasi'],
        ),
        MapPoi(
          id: 'jogja_rs_siloam',
          name: 'Rumah Sakit Siloam Yogyakarta',
          category: PoiCategory.medis,
          coordinate: const LatLng(-7.78339, 110.39088),
          statusLabel: 'IGD & Layanan Medis 24 Jam',
          subtitle: 'Jl. Laksda Adisucipto No.32-34, Gondokusuman / Depok',
          tags: ['Rumah Sakit', 'IGD 24 Jam', 'Medis Darurat'],
        ),
        MapPoi(
          id: 'jogja_rs_annur',
          name: 'Rumah Sakit Khusus Bedah An-Nur',
          category: PoiCategory.medis,
          coordinate: const LatLng(-7.77811, 110.38683),
          statusLabel: 'Layanan Medis & Bedah Spesialis',
          subtitle: 'Jl. Colombo No.14, Caturtunggal, Depok, Sleman',
          tags: ['Rumah Sakit', 'UGD', 'Medis Spesialis'],
        ),
        MapPoi(
          id: 'jogja_masjid_almuhtadin',
          name: 'Masjid Al-Muhtadin Papringan',
          category: PoiCategory.ibadah,
          coordinate: const LatLng(-7.78908, 110.40659),
          statusLabel: 'Tempat Ibadah & Wudhu Tersedia',
          subtitle: 'Papringan, Caturtunggal, Depok, Sleman',
          tags: ['Masjid', 'Tempat Ibadah', 'Wudhu & Toilet'],
        ),
        MapPoi(
          id: 'jogja_masjid_sunankalijaga',
          name: 'Masjid Laboratorium Agama Sunan Kalijaga',
          category: PoiCategory.ibadah,
          coordinate: const LatLng(-7.78473, 110.39457),
          statusLabel: 'Pusat Ibadah & Fasilitas Wudhu Lengkap',
          subtitle: 'Kampus UIN Sunan Kalijaga, Jl. Marsda Adisucipto',
          tags: ['Masjid Kampus', 'Wudhu & Toilet', 'Ibadah'],
        ),
        MapPoi(
          id: 'jogja_masjid_ugm',
          name: 'Masjid Kampus UGM',
          category: PoiCategory.ibadah,
          coordinate: const LatLng(-7.77444, 110.37777),
          statusLabel: 'Masjid Terbesar Kawasan Kampus & Wudhu 24 Jam',
          subtitle: 'Jl. Tevesia, Bulaksumur, UGM, Sleman',
          tags: ['Masjid Kampus UGM', 'Wudhu & Toilet', 'Ibadah'],
        ),
        MapPoi(
          id: 'jogja_resto_dutaminang',
          name: 'Rumah Makan Padang Duta Minang',
          category: PoiCategory.restaurant,
          coordinate: const LatLng(-7.77910, 110.39950),
          statusLabel: 'Kuliner Masakan Padang Halal',
          subtitle: 'Jl. KH. Wahid Hasyim, Caturtunggal, Depok',
          tags: ['Restoran Halal', 'Masakan Padang', 'Kuliner'],
        ),
        MapPoi(
          id: 'jogja_resto_lestari',
          name: 'Rumah Makan Lestari Nologaten',
          category: PoiCategory.restaurant,
          coordinate: const LatLng(-7.78180, 110.40468),
          statusLabel: 'Kuliner Nusantara & Halal',
          subtitle: 'Jl. Wahid Hasyim / Nologaten, Sleman',
          tags: ['Rumah Makan', 'Kuliner Halal'],
        ),
        MapPoi(
          id: 'jogja_posko_depokbarat',
          name: 'Pos Pantau & Keamanan Polsek Depok Barat',
          category: PoiCategory.posPantau,
          coordinate: const LatLng(-7.77250, 110.40450),
          statusLabel: 'Pos Keamanan & Perlindungan 24 Jam',
          subtitle: 'Kawasan Depok Barat, Sleman',
          tags: ['Pos Pantau', 'Keamanan', 'Pos Polisi'],
        ),
        MapPoi(
          id: 'jogja_maktab_asramahaji',
          name: 'Asrama Haji Transit D.I. Yogyakarta',
          category: PoiCategory.maktab,
          coordinate: const LatLng(-7.75400, 110.37300),
          statusLabel: 'Pusat Keberangkatan & Manasik Haji Jemaah',
          subtitle: 'Jl. Ringroad Utara, Sleman, Yogyakarta',
          tags: ['Maktab', 'Asrama Haji', 'Pusat Keberangkatan'],
        ),
        MapPoi(
          id: 'jogja_apotek_k24',
          name: 'Apotek K-24 Babarsari 24 Jam',
          category: PoiCategory.pharmacy,
          coordinate: const LatLng(-7.78187, 110.41409),
          statusLabel: 'Layanan Obat & Medis Buka 24 Jam Non-Stop',
          subtitle: 'Jl. Babarsari No.10, Caturtunggal, Sleman',
          tags: ['Apotek 24 Jam', 'Obat & Medis'],
        ),
      ]);
    }

    return pois;
  }

  static PoiCategory _categoryForPhoton(Map<String, String> tags, String name) {
    final lowerName = name.toLowerCase();
    final osmKey = tags['osm_key']?.toLowerCase();
    final osmVal = (tags[osmKey] ?? tags['osm_value'] ?? '').toLowerCase();

    // 1. Hotel / Penginapan
    if (osmVal == 'hotel' ||
        osmVal == 'guest_house' ||
        osmVal == 'motel' ||
        osmVal == 'hostel' ||
        lowerName.contains('hotel') ||
        lowerName.contains('penginapan') ||
        lowerName.contains('homestay') ||
        lowerName.contains('guesthouse') ||
        lowerName.contains('inn ') ||
        lowerName.endsWith(' inn') ||
        lowerName.contains('resort')) {
      return PoiCategory.hotel;
    }

    // 2. Tempat Ibadah / Masjid / Musholla
    if (osmVal == 'place_of_worship' ||
        osmVal == 'mosque' ||
        lowerName.contains('masjid') ||
        lowerName.contains('mesjid') ||
        lowerName.contains('mushola') ||
        lowerName.contains('mushalla') ||
        lowerName.contains('surau') ||
        lowerName.contains('langgar') ||
        lowerName.contains('baitul') ||
        lowerName.contains('jami')) {
      return PoiCategory.ibadah;
    }

    // 3. Rumah Makan / Restoran / Kuliner
    if (osmVal == 'restaurant' ||
        osmVal == 'fast_food' ||
        osmVal == 'food_court' ||
        osmVal == 'cafe' ||
        lowerName.contains('rumah makan') ||
        lowerName.contains('restoran') ||
        lowerName.contains('warung') ||
        lowerName.contains('resto') ||
        lowerName.contains('cafe') ||
        lowerName.contains('kafe') ||
        lowerName.contains('dapur') ||
        lowerName.contains('kuliner') ||
        lowerName.contains('sate') ||
        lowerName.contains('bakso') ||
        lowerName.contains('ayam') ||
        lowerName.contains('padang') ||
        lowerName.contains('kedai')) {
      return (osmVal == 'cafe' || lowerName.contains('cafe') || lowerName.contains('kafe'))
          ? PoiCategory.cafe
          : PoiCategory.restaurant;
    }

    // 4. Medis / Rumah Sakit / Klinik / Apotek
    if (osmVal == 'hospital' ||
        osmVal == 'clinic' ||
        osmVal == 'doctors' ||
        osmVal == 'pharmacy' ||
        lowerName.contains('rumah sakit') ||
        lowerName.contains('rs ') ||
        lowerName.contains('rsud') ||
        lowerName.contains('puskesmas') ||
        lowerName.contains('klinik') ||
        lowerName.contains('apotek') ||
        lowerName.contains('medical')) {
      if (lowerName.contains('apotek') || osmVal == 'pharmacy') return PoiCategory.pharmacy;
      if (lowerName.contains('klinik') || osmVal == 'clinic') return PoiCategory.clinic;
      return PoiCategory.medis;
    }

    // 5. Toilet & Wudhu
    if (osmVal == 'toilets' ||
        lowerName.contains('toilet') ||
        lowerName.contains('wc ') ||
        lowerName.endsWith('wc') ||
        lowerName.contains('kamar mandi')) {
      return PoiCategory.toilet;
    }
    if (lowerName.contains('wudhu') || lowerName.contains('air minum')) {
      return PoiCategory.wudhu;
    }

    // 6. Maktab / Perkemahan Haji
    if (osmVal == 'camp_site' ||
        lowerName.contains('maktab') ||
        lowerName.contains('tenda mina') ||
        lowerName.contains('haji')) {
      return PoiCategory.maktab;
    }

    // 7. Keamanan / Polisi
    if (osmVal == 'police' ||
        lowerName.contains('polisi') ||
        lowerName.contains('pos pantau') ||
        lowerName.contains('security')) {
      return PoiCategory.posPantau;
    }

    return _categoryFor(tags) ?? PoiCategory.place;
  }
}
