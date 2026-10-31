import 'dart:convert';
import 'dart:isolate';

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

/// Loads real places around a coordinate from OpenStreetMap's Overpass API.
/// This service deliberately has no built-in POI list. An empty provider
/// response therefore stays empty instead of being replaced with demo pins.
class PoiService {
  static const _cacheLifetime = Duration(minutes: 5);
  static const _endpoints = <String>[
    'https://overpass.openstreetmap.fr/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.osm.ch/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
  ];

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

    final query = _buildQuery(center, safeRadius);
    for (final endpoint in _endpoints) {
      try {
        final response = await _client
            .post(
              Uri.parse(endpoint),
              headers: const {
                'Content-Type':
                    'application/x-www-form-urlencoded; charset=UTF-8',
                'Accept': 'application/json',
                'User-Agent': 'HajiCare/0.1 (Flutter map client)',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 7));

        if (response.statusCode != 200) {
          continue;
        }

        final limited = await Isolate.run(() {
          return _parseAndSortPois(
            responseBody: response.body,
            center: center,
            safeLimit: safeLimit,
          );
        });
        _cache[cacheKey] = _PoiCacheEntry(DateTime.now(), limited);
        return limited;
      } catch (_) {}
    }

    // Stale data is only reused for the exact same spatial cache cell.
    if (cached != null) return List.unmodifiable(cached.pois);
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

  static List<MapPoi> _parseAndSortPois({
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
      final poi = _mapOsmElementToPoi(Map<String, dynamic>.from(raw));
      if (poi != null) unique[poi.id] = poi;
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
        ]) ??
        category.label;
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
          name.toLowerCase().contains('masjid') ||
          name.toLowerCase().contains('mushola') ||
          name.toLowerCase().contains('surau')) ...[
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
        name.toLowerCase().contains('masjid') ||
        name.toLowerCase().contains('mushola') ||
        name.toLowerCase().contains('surau');
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

  static String _buildQuery(LatLng center, int radius) {
    final around = '$radius,${center.latitude},${center.longitude}';
    return '''
[out:json][timeout:10];
(
  node(around:$around)[amenity~"^(toilets|drinking_water|water_point|place_of_worship|hospital|clinic|doctors|pharmacy|fuel|police|restaurant|fast_food|food_court|cafe|atm|bank|bus_station|parking)\$"];
  way(around:$around)[amenity~"^(toilets|drinking_water|water_point|place_of_worship|hospital|clinic|doctors|pharmacy|fuel|police|restaurant|fast_food|food_court|cafe|atm|bank|bus_station|parking)\$"];
  node(around:$around)[shop~"^(supermarket|convenience|mall|department_store|chemist)\$"];
  way(around:$around)[shop~"^(supermarket|convenience|mall|department_store|chemist)\$"];
  node(around:$around)[tourism~"^(hotel|hostel|guest_house|motel|apartment|camp_site|attraction|museum|viewpoint)\$"];
  way(around:$around)[tourism~"^(hotel|hostel|guest_house|motel|apartment|camp_site|attraction|museum|viewpoint)\$"];
  node(around:$around)[healthcare~"^(hospital|clinic|doctor|pharmacy|first_aid)\$"];
  way(around:$around)[healthcare~"^(hospital|clinic|doctor|pharmacy|first_aid)\$"];
  node(around:$around)[toilets=yes];
  way(around:$around)[toilets=yes];
  node(around:$around)[wudhu=yes];
  way(around:$around)[wudhu=yes];
);
out center 200;
''';
  }

  static PoiCategory? _categoryFor(Map<String, String> tags) {
    final tourism = tags['tourism'];
    final amenity = tags['amenity'];
    final healthcare = tags['healthcare'];
    final shop = tags['shop'];
    final aeroway = tags['aeroway'];
    final railway = tags['railway'];
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
        {'clinic', 'doctor'}.contains(healthcare)) {
      return PoiCategory.clinic;
    }
    if (amenity == 'hospital' || healthcare == 'hospital') {
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
    if (amenity == 'police') return PoiCategory.posPantau;

    // 5. Worship / Mosque
    if (amenity == 'place_of_worship' ||
        name.contains('masjid') ||
        name.contains('mushola') ||
        name.contains('mushalla') ||
        name.contains('mosque') ||
        name.contains('surau') ||
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
}
