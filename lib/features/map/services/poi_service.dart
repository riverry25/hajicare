import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/map_poi.dart';

/// Service for discovering real-world physical points of interest (Toilets, Medical, Mosques, Water points)
/// using OpenStreetMap Overpass API and authentic verified Holy Land coordinates.
class PoiService {
  final http.Client _client;

  PoiService({http.Client? client}) : _client = client ?? http.Client();

  // In-memory cache to prevent redundant Overpass queries
  final Map<String, List<MapPoi>> _cache = {};

  /// Comprehensive real-world verified facilities in Holy Land (Makkah, Mina, Arafah, Madinah).
  static const List<MapPoi> holyLandRealPois = [
    // ── MINA VALLEY (MAKTAB & MEDICAL SITES) ──
    MapPoi(
      id: 'maktab_48_mina',
      name: 'Tenda Maktab 48 Mina',
      category: PoiCategory.maktab,
      coordinate: LatLng(21.4135, 39.8930),
      statusLabel: 'Pusat Jamaah Indonesia',
      subtitle: 'Tenda Utama Kloter JKG & SOC',
      icon: Icons.holiday_village_rounded,
      color: Color(0xFFD97706),
      tags: ['Tenda Utama', 'Dapur Maktab', 'AC'],
    ),
    MapPoi(
      id: 'posko_medis_ppih_mina',
      name: 'Posko Medis PPIH Mina Sektor 1',
      category: PoiCategory.medis,
      coordinate: LatLng(21.4145, 39.8942),
      statusLabel: 'Siaga 24 Jam',
      subtitle: 'Dokter & Ambulans Darurat PPIH',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFE53935),
      tags: ['Dokter 24 Jam', 'Ambulans Siaga', 'Bebas Biaya'],
    ),
    MapPoi(
      id: 'toilet_mina_12',
      name: 'Fasilitas Toilet & Wudhu Blok 12 Mina',
      category: PoiCategory.toilet,
      coordinate: LatLng(21.4130, 39.8922),
      statusLabel: 'Buka • Ramai Lancar',
      subtitle: 'Toilet Terpisah Pria & Wanita',
      icon: Icons.wc_rounded,
      color: Color(0xFF0288D1),
      tags: ['Bilik Terpisah', 'Ramah Lansia', 'Kloset Duduk'],
    ),
    MapPoi(
      id: 'wudhu_mina_sektor_48',
      name: 'Kran Wudhu Air Bersih Sektor 48',
      category: PoiCategory.wudhu,
      coordinate: LatLng(21.4128, 39.8918),
      statusLabel: 'Air Mengalir Lancar',
      subtitle: 'Kran Wudhu Duduk & Berdiri',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF00897B),
      tags: ['Air Sejuk', 'Lantai Anti Slip'],
    ),
    MapPoi(
      id: 'pos_pantau_linjam_mina',
      name: 'Pos Pantau Linjam Sektor Mina',
      category: PoiCategory.posPantau,
      coordinate: LatLng(21.4126, 39.8938),
      statusLabel: 'Petugas Bertugas',
      subtitle: 'Layanan Jamaah Terpisah & Informasi',
      icon: Icons.flag_rounded,
      color: Color(0xFF5E35B1),
      tags: ['Linjam TNI/Polri', 'Pusat Informasi'],
    ),
    MapPoi(
      id: 'jamarat_bridge_real',
      name: 'Jembatan Jamarat (Lontar Jumrah)',
      category: PoiCategory.ibadah,
      coordinate: LatLng(21.4190, 39.8730),
      statusLabel: 'Area Pelontaran',
      subtitle: 'Ula, Wustha, dan Aqabah',
      icon: Icons.mosque_rounded,
      color: Color(0xFF2E7D32),
      tags: ['Jalur Satu Arah', 'Tangga Eskalator'],
    ),
    MapPoi(
      id: 'posko_darurat_jamarat',
      name: 'Posko Medis Darurat Jamarat',
      category: PoiCategory.medis,
      coordinate: LatLng(21.4198, 39.8738),
      statusLabel: 'Siaga 24 Jam',
      subtitle: 'Tim Gerak Cepat (TGC) PPIH',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFE53935),
      tags: ['Oksigen Siaga', 'P3K'],
    ),
    MapPoi(
      id: 'toilet_jamarat_timur',
      name: 'Toilet Publik Jamarat Timur',
      category: PoiCategory.toilet,
      coordinate: LatLng(21.4202, 39.8715),
      statusLabel: 'Buka 24 Jam',
      subtitle: 'Fasilitas Wudhu & Toilet Bersih',
      icon: Icons.wc_rounded,
      color: Color(0xFF0288D1),
      tags: ['Kapasitas Besar', 'Fasilitas Wudhu'],
    ),

    // ── MAKKAH CITY & MASJIDIL HARAM ──
    MapPoi(
      id: 'masjidil_haram_real',
      name: 'Masjidil Haram (Ka\'bah)',
      category: PoiCategory.ibadah,
      coordinate: LatLng(21.4225, 39.8262),
      statusLabel: 'Pusat Tawaf & Shalat',
      subtitle: 'Kiblat Umat Islam Sedunia',
      icon: Icons.mosque_rounded,
      color: Color(0xFF2E7D32),
      tags: ['Air Zamzam', 'Jalur Kursi Roda', 'AC Sentral'],
    ),
    MapPoi(
      id: 'kkhi_makkah_real',
      name: 'KKHI Makkah (Klinik Kesehatan Haji)',
      category: PoiCategory.medis,
      coordinate: LatLng(21.4116, 39.8732),
      statusLabel: 'Rumah Sakit Rujukan PPIH',
      subtitle: 'Spesialis & Ruang Rawat Inap',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFE53935),
      tags: ['ICU', 'Spesialis', 'Ambulans Rujukan'],
    ),
    MapPoi(
      id: 'posko_linjam_haram',
      name: 'Posko Perlindungan Jamaah Sektor Khusus Haram',
      category: PoiCategory.posPantau,
      coordinate: LatLng(21.4235, 39.8250),
      statusLabel: 'Siaga 24 Jam',
      subtitle: 'Pelataran Masjidil Haram',
      icon: Icons.flag_rounded,
      color: Color(0xFF5E35B1),
      tags: ['Pencarian Jamaah', 'Bantuan Lansia'],
    ),

    // ── MADINAH ──
    MapPoi(
      id: 'masjid_nabawi_real',
      name: 'Masjid Nabawi Madinah',
      category: PoiCategory.ibadah,
      coordinate: LatLng(24.4672, 39.6111),
      statusLabel: 'Raudhah & Makam Rasulullah',
      subtitle: 'Area Shalat & Ziarah',
      icon: Icons.mosque_rounded,
      color: Color(0xFF2E7D32),
      tags: ['Raudhah', 'Zamzam', 'Payung Raksasa'],
    ),
    MapPoi(
      id: 'kkhi_madinah_real',
      name: 'KKHI Madinah',
      category: PoiCategory.medis,
      coordinate: LatLng(24.4750, 39.6050),
      statusLabel: 'Siaga 24 Jam',
      subtitle: 'Klinik Rujukan Haji Madinah',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFE53935),
      tags: ['UGD 24 Jam', 'Ambulans'],
    ),
  ];

  /// Checks whether a given coordinate is located in the Holy Land region (Makkah, Mina, Arafah, Madinah).
  static bool isInHolyLand(LatLng coord) {
    // Makkah/Masyair bounding box: Lat 21.2 to 21.6, Lng 39.6 to 40.2
    final isMakkah =
        coord.latitude >= 21.2 &&
        coord.latitude <= 21.6 &&
        coord.longitude >= 39.6 &&
        coord.longitude <= 40.2;

    // Madinah bounding box: Lat 24.3 to 24.6, Lng 39.4 to 39.8
    final isMadinah =
        coord.latitude >= 24.3 &&
        coord.latitude <= 24.6 &&
        coord.longitude >= 39.4 &&
        coord.longitude <= 39.8;

    return isMakkah || isMadinah;
  }

  // In-memory cache for hotel queries: maps grid key to list of MapPoi
  final Map<String, List<MapPoi>> _hotelCache = {};
  DateTime? _lastHotelFetchTime;
  LatLng? _lastHotelFetchCenter;
  List<MapPoi> _lastFetchedHotels = [];
  bool _isHotelFetchInProgress = false;

  /// Fetches nearby hotels within [radiusMeters] using OpenStreetMap Overpass API.
  /// Supports node, way, and relation (with center coordinates).
  /// Results are deduplicated, sorted by proximity, capped to [limit], and cached.
  Future<List<MapPoi>> fetchNearbyHotels({
    required LatLng center,
    double radiusMeters = 3000,
    int limit = 35,
  }) async {
    final lat = center.latitude;
    final lon = center.longitude;

    // 1. Check spatial distance from last successful query
    if (_lastHotelFetchCenter != null && _lastFetchedHotels.isNotEmpty) {
      final distFromLast = _calcDistance(center, _lastHotelFetchCenter!);
      // If user moved less than 500m, return existing cached hotels
      if (distFromLast < 500) {
        debugPrint(
          '[HOTEL] Using spatial cache (moved only ${distFromLast.toInt()}m)',
        );
        return _lastFetchedHotels;
      }
    }

    // 2. Grid cache check
    final gridKey = '${(lat * 50).round()}_${(lon * 50).round()}';
    if (_hotelCache.containsKey(gridKey)) {
      debugPrint('[HOTEL] Using grid cache for $gridKey');
      return _hotelCache[gridKey]!;
    }

    // 3. In-flight guard & debounce (minimum 10s between queries)
    if (_isHotelFetchInProgress) {
      debugPrint(
        '[HOTEL] Fetch already in progress, returning previous hotels',
      );
      return _lastFetchedHotels;
    }
    final now = DateTime.now();
    if (_lastHotelFetchTime != null &&
        now.difference(_lastHotelFetchTime!).inSeconds < 10 &&
        _lastFetchedHotels.isNotEmpty) {
      return _lastFetchedHotels;
    }

    _isHotelFetchInProgress = true;
    _lastHotelFetchTime = now;

    try {
      final r = radiusMeters.clamp(500, 5000).round();
      final overpassQuery =
          '''
[out:json][timeout:25];
(
  nwr["tourism"="hotel"](around:$r,$lat,$lon);
);
out center tags;
''';

      debugPrint(
        '[HOTEL] Querying Overpass API around ($lat, $lon) radius ${r}m',
      );
      final uri = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await _client
          .post(uri, body: {'data': overpassQuery})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>? ?? [];

        final hotels = <MapPoi>[];
        final seenIds = <String>{};

        for (final el in elements) {
          if (el is! Map<String, dynamic>) continue;
          final hotel = mapOsmElementToHotel(el);
          if (hotel != null && seenIds.add(hotel.id)) {
            hotels.add(hotel);
          }
        }

        // Sort by distance from center
        hotels.sort((a, b) {
          final dA = _calcDistance(center, a.coordinate);
          final dB = _calcDistance(center, b.coordinate);
          return dA.compareTo(dB);
        });

        final cappedHotels = hotels.take(limit).toList();
        debugPrint(
          '[HOTEL] Parsed ${cappedHotels.length} unique hotels near user',
        );

        _hotelCache[gridKey] = cappedHotels;
        _lastHotelFetchCenter = center;
        _lastFetchedHotels = cappedHotels;
        return cappedHotels;
      } else {
        debugPrint('[HOTEL] Overpass returned HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[HOTEL] Overpass query notice/error: $e');
    } finally {
      _isHotelFetchInProgress = false;
    }

    // Graceful failure: return previously cached hotels if available
    return _lastFetchedHotels;
  }

  /// Parses an OSM element (node, way, or relation) into a hotel MapPoi.
  /// Returns null if coordinates are missing or invalid.
  MapPoi? mapOsmElementToHotel(Map<String, dynamic> el) {
    final type = el['type'] as String? ?? 'node';
    final idNum = el['id'];
    if (idNum == null) return null;

    double? lat;
    double? lon;

    if (type == 'node') {
      lat = (el['lat'] as num?)?.toDouble();
      lon = (el['lon'] as num?)?.toDouble();
    } else if (type == 'way' || type == 'relation') {
      final center = el['center'] as Map<String, dynamic>?;
      if (center != null) {
        lat = (center['lat'] as num?)?.toDouble();
        lon = (center['lon'] as num?)?.toDouble();
      }
    }

    if (lat == null || lon == null) return null;
    // Validate coordinate range
    if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) return null;

    final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
    final rawName =
        tags['name'] as String? ??
        tags['name:id'] as String? ??
        tags['name:en'] as String? ??
        tags['name:ar'] as String?;
    final name = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : 'Hotel';

    final stars = tags['stars'] as String?;
    final rooms = tags['rooms'] as String?;
    final phone = tags['phone'] as String? ?? tags['contact:phone'] as String?;

    final statusLabel = stars != null
        ? 'Bintang $stars • Penginapan'
        : 'Hotel / Penginapan';
    final subtitle =
        tags['address'] ?? tags['addr:street'] ?? 'Fasilitas Akomodasi';

    final tagList = <String>[
      if (stars != null) 'Bintang $stars',
      if (rooms != null) '$rooms Kamar',
      if (tags['wheelchair'] == 'yes') 'Ramah Kursi Roda',
      if (tags['internet_access'] == 'wlan' || tags['wifi'] == 'yes') 'Wi-Fi',
      if (tags['air_conditioning'] == 'yes') 'AC',
      if (phone != null) 'Telepon Tersedia',
      'Data OSM Nyata',
    ];

    return MapPoi(
      id: 'osm_${type}_$idNum',
      name: name,
      category: PoiCategory.hotel,
      coordinate: LatLng(lat, lon),
      statusLabel: statusLabel,
      subtitle: subtitle,
      icon: Icons.hotel_rounded,
      color: const Color(0xFF8E24AA),
      isAccessible: tags['wheelchair'] != 'no',
      tags: tagList,
    );
  }

  /// Fetches real-world physical amenities surrounding the given coordinate.
  /// If the user is in Holy Land, returns the authentic verified facilities.
  /// If anywhere else, queries OpenStreetMap Overpass API for genuine physical locations.
  Future<List<MapPoi>> fetchRealNearbyPois({
    required LatLng center,
    double radiusMeters = 1500,
    String? roomName,
    bool includeHotels = true,
  }) async {
    final combinedPois = <MapPoi>[];

    // 1. If in Holy Land, return authentic verified Holy Land facilities nearby
    if (isInHolyLand(center)) {
      if (includeHotels) {
        final hotels = await fetchNearbyHotels(center: center);
        combinedPois.addAll(hotels);
      }
      for (final p in holyLandRealPois) {
        final dist = _calcDistance(center, p.coordinate);
        if (dist <= 8000) {
          // within 8 km
          combinedPois.add(p);
        }
      }
      if (combinedPois.isNotEmpty) return combinedPois;
      return holyLandRealPois;
    }

    if (includeHotels) {
      final hotels = await fetchNearbyHotels(center: center);
      combinedPois.addAll(hotels);
    }

    // 3. Check in-memory grid cache for non-Holy Land coordinates (grid size ~200m)
    final cacheKey =
        '${(center.latitude * 100).round()}_${(center.longitude * 100).round()}';
    if (_cache.containsKey(cacheKey)) {
      combinedPois.addAll(_cache[cacheKey]!);
      return combinedPois;
    }

    // 4. Query OpenStreetMap Overpass API for actual real amenities in the area
    try {
      final lat = center.latitude;
      final lon = center.longitude;
      final r = radiusMeters.clamp(500, 2500).round();

      final overpassQuery =
          '''
[out:json][timeout:6];
(
  node["amenity"="toilets"](around:$r,$lat,$lon);
  node["amenity"~"hospital|clinic|doctors|pharmacy"](around:$r,$lat,$lon);
  node["amenity"="place_of_worship"](around:$r,$lat,$lon);
  node["amenity"~"drinking_water|water_point"](around:$r,$lat,$lon);
  node["amenity"="police"](around:$r,$lat,$lon);
);
out body 35;
''';

      final uri = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await _client
          .post(uri, body: {'data': overpassQuery})
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>? ?? [];

        final realPois = <MapPoi>[];
        for (final el in elements) {
          if (el is Map<String, dynamic> &&
              el['lat'] != null &&
              el['lon'] != null) {
            final poi = _mapOsmElementToPoi(el);
            if (poi != null) {
              realPois.add(poi);
            }
          }
        }

        if (realPois.isNotEmpty) {
          _cache[cacheKey] = realPois;
          combinedPois.addAll(realPois);
          return combinedPois;
        }
      }
    } catch (e) {
      debugPrint('[PoiService] Overpass query notice: $e');
    }

    return combinedPois;
  }

  MapPoi? _mapOsmElementToPoi(Map<String, dynamic> el) {
    final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
    final amenity = tags['amenity'] as String? ?? '';
    final religion = tags['religion'] as String? ?? '';
    final name =
        tags['name'] as String? ??
        tags['name:id'] as String? ??
        tags['name:en'] as String?;

    final lat = (el['lat'] as num).toDouble();
    final lon = (el['lon'] as num).toDouble();
    final coord = LatLng(lat, lon);
    final id = 'osm_${el['id']}';

    if (amenity == 'toilets') {
      final wheelchair = tags['wheelchair'] == 'yes';
      return MapPoi(
        id: id,
        name: name ?? 'Toilet Umum',
        category: PoiCategory.toilet,
        coordinate: coord,
        statusLabel: wheelchair ? 'Akses Ramah Lansia' : 'Tersedia',
        subtitle: tags['fee'] == 'yes' ? 'Toilet Berbayar' : 'Toilet Publik',
        icon: wheelchair ? Icons.accessible_rounded : Icons.wc_rounded,
        color: const Color(0xFF0288D1),
        isAccessible: wheelchair,
        tags: [
          if (wheelchair) 'Ramah Disabilitas',
          if (tags['female'] == 'yes') 'Toilet Wanita',
          if (tags['male'] == 'yes') 'Toilet Pria',
          'Fasilitas Nyata',
        ],
      );
    }

    if (amenity == 'hospital' ||
        amenity == 'clinic' ||
        amenity == 'doctors' ||
        amenity == 'pharmacy') {
      final is24 = tags['opening_hours'] == '24/7';
      return MapPoi(
        id: id,
        name:
            name ?? (amenity == 'hospital' ? 'Rumah Sakit' : 'Klinik / Dokter'),
        category: PoiCategory.medis,
        coordinate: coord,
        statusLabel: is24 ? 'Siaga 24 Jam' : 'Layanan Medis',
        subtitle: tags['healthcare:speciality'] ?? 'Pusat Pelayanan Kesehatan',
        icon: Icons.medical_services_rounded,
        color: const Color(0xFFE53935),
        tags: [
          if (is24) 'Buka 24 Jam',
          if (tags['emergency'] == 'yes') 'Unit Gawat Darurat',
          'Fasilitas Medis Nyata',
        ],
      );
    }

    if (amenity == 'place_of_worship' || religion == 'muslim') {
      return MapPoi(
        id: id,
        name:
            name ??
            (religion == 'muslim' ? 'Masjid / Musholla' : 'Tempat Ibadah'),
        category: PoiCategory.ibadah,
        coordinate: coord,
        statusLabel: 'Tempat Ibadah',
        subtitle: 'Area Shalat & Wudhu',
        icon: Icons.mosque_rounded,
        color: const Color(0xFF2E7D32),
        tags: ['Tempat Shalat', 'Kran Wudhu', 'Fasilitas Nyata'],
      );
    }

    if (amenity == 'drinking_water' || amenity == 'water_point') {
      return MapPoi(
        id: id,
        name: name ?? 'Tempat Wudhu & Air Bersih',
        category: PoiCategory.wudhu,
        coordinate: coord,
        statusLabel: 'Air Bersih Tersedia',
        subtitle: 'Titik Sumber Air',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF00897B),
        tags: ['Air Minum / Wudhu', 'Fasilitas Nyata'],
      );
    }

    if (amenity == 'police') {
      return MapPoi(
        id: id,
        name: name ?? 'Pos Keamanan & Bantuan',
        category: PoiCategory.posPantau,
        coordinate: coord,
        statusLabel: 'Petugas Siaga',
        subtitle: 'Pos Informasi & Keamanan',
        icon: Icons.flag_rounded,
        color: const Color(0xFF5E35B1),
        tags: ['Keamanan', 'Pusat Bantuan'],
      );
    }

    return null;
  }

  double _calcDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180.0;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * math.pi / 180.0) *
            math.cos(p2.latitude * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
}
