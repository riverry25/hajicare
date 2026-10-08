import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'map_poi.dart';

/// Represents a single geocoded location search result.
class MapSearchResult {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? type;
  final String? category;

  const MapSearchResult({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.type,
    this.category,
  });

  LatLng get coordinate => LatLng(latitude, longitude);

  /// Resolves matching [PoiCategory] from category/type string or name keywords.
  PoiCategory get resolvedCategory {
    final cat = (category ?? '').toLowerCase();
    final typ = (type ?? '').toLowerCase();
    final combined = '$cat $typ ${name.toLowerCase()}';

    if (combined.contains('hotel') ||
        combined.contains('lodging') ||
        combined.contains('hostel')) {
      return PoiCategory.hotel;
    }
    if (combined.contains('pharmacy') ||
        combined.contains('apotek') ||
        combined.contains('apotik') ||
        combined.contains('obat')) {
      return PoiCategory.pharmacy;
    }
    if (combined.contains('hospital') ||
        combined.contains('rumah sakit') ||
        combined.contains('medis')) {
      return PoiCategory.medis;
    }
    if (combined.contains('clinic') ||
        combined.contains('klinik') ||
        combined.contains('doctor')) {
      return PoiCategory.clinic;
    }
    if (combined.contains('mosque') ||
        combined.contains('masjid') ||
        combined.contains('musholla') ||
        combined.contains('worship')) {
      return PoiCategory.ibadah;
    }
    if (combined.contains('restaurant') ||
        combined.contains('restoran') ||
        combined.contains('food') ||
        combined.contains('makan')) {
      return PoiCategory.restaurant;
    }
    if (combined.contains('cafe') ||
        combined.contains('kafe') ||
        combined.contains('coffee')) {
      return PoiCategory.cafe;
    }
    if (combined.contains('toilet') || combined.contains('wc')) {
      return PoiCategory.toilet;
    }
    if (combined.contains('wudhu') ||
        combined.contains('wudu') ||
        combined.contains('water')) {
      return PoiCategory.wudhu;
    }
    if (combined.contains('supermarket') || combined.contains('swalayan')) {
      return PoiCategory.supermarket;
    }
    if (combined.contains('mall') || combined.contains('plaza')) {
      return PoiCategory.mall;
    }
    if (combined.contains('shopping') ||
        combined.contains('toko') ||
        combined.contains('market')) {
      return PoiCategory.shopping;
    }
    if (combined.contains('atm')) {
      return PoiCategory.atm;
    }
    if (combined.contains('bank')) {
      return PoiCategory.bank;
    }
    if (combined.contains('airport') || combined.contains('bandara')) {
      return PoiCategory.airport;
    }
    if (combined.contains('bus') ||
        combined.contains('terminal') ||
        combined.contains('halte')) {
      return PoiCategory.bus;
    }
    if (combined.contains('train') ||
        combined.contains('stasiun') ||
        combined.contains('kereta')) {
      return PoiCategory.train;
    }
    if (combined.contains('police') || combined.contains('polisi')) {
      return PoiCategory.police;
    }
    if (combined.contains('parkir') || combined.contains('parking')) {
      return PoiCategory.parking;
    }
    if (combined.contains('fuel') ||
        combined.contains('spbu') ||
        combined.contains('bensin')) {
      return PoiCategory.fuel;
    }
    if (combined.contains('maktab') || combined.contains('mina')) {
      return PoiCategory.maktab;
    }
    if (combined.contains('wisata') ||
        combined.contains('attraction') ||
        combined.contains('museum')) {
      return PoiCategory.touristAttraction;
    }

    return PoiCategory.place;
  }

  IconData get icon => resolvedCategory.defaultIcon;
  Color get color => resolvedCategory.defaultColor;
  String get categoryLabel => resolvedCategory.label;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    if (type != null) 'type': type,
    if (category != null) 'category': category,
  };

  factory MapSearchResult.fromJson(Map<String, dynamic> json) {
    return MapSearchResult(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String?,
      category: json['category'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapSearchResult &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MapSearchResult(name: $name, lat: $latitude, lon: $longitude)';
}
