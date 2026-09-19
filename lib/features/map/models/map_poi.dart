import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Categories derived from OpenStreetMap tags. No category implies that a
/// place exists unless it was returned by the data provider.
enum PoiCategory {
  maktab,
  medis,
  toilet,
  wudhu,
  posPantau,
  ibadah,
  hotel,
  restaurant,
  cafe,
  atm,
  fuel,
  place;

  String get label => switch (this) {
    PoiCategory.maktab => 'Perkemahan / Maktab',
    PoiCategory.medis => 'Fasilitas Medis',
    PoiCategory.toilet => 'Toilet',
    PoiCategory.wudhu => 'Air & Wudhu',
    PoiCategory.posPantau => 'Pos Keamanan',
    PoiCategory.ibadah => 'Tempat Ibadah',
    PoiCategory.hotel => 'Hotel / Penginapan',
    PoiCategory.restaurant => 'Restoran',
    PoiCategory.cafe => 'Kafe',
    PoiCategory.atm => 'ATM',
    PoiCategory.fuel => 'SPBU',
    PoiCategory.place => 'Lokasi',
  };

  IconData get defaultIcon => switch (this) {
    PoiCategory.maktab => Icons.holiday_village_rounded,
    PoiCategory.medis => Icons.medical_services_rounded,
    PoiCategory.toilet => Icons.wc_rounded,
    PoiCategory.wudhu => Icons.water_drop_rounded,
    PoiCategory.posPantau => Icons.local_police_rounded,
    PoiCategory.ibadah => Icons.mosque_rounded,
    PoiCategory.hotel => Icons.hotel_rounded,
    PoiCategory.restaurant => Icons.restaurant_rounded,
    PoiCategory.cafe => Icons.local_cafe_rounded,
    PoiCategory.atm => Icons.local_atm_rounded,
    PoiCategory.fuel => Icons.local_gas_station_rounded,
    PoiCategory.place => Icons.place_rounded,
  };

  Color get defaultColor => switch (this) {
    PoiCategory.maktab => const Color(0xFFD97706),
    PoiCategory.medis => const Color(0xFFE53935),
    PoiCategory.toilet => const Color(0xFF0288D1),
    PoiCategory.wudhu => const Color(0xFF00897B),
    PoiCategory.posPantau => const Color(0xFF5E35B1),
    PoiCategory.ibadah => const Color(0xFF2E7D32),
    PoiCategory.hotel => const Color(0xFF8E24AA),
    PoiCategory.restaurant => const Color(0xFFE64A35),
    PoiCategory.cafe => const Color(0xFF795548),
    PoiCategory.atm => const Color(0xFF1565C0),
    PoiCategory.fuel => const Color(0xFF00838F),
    PoiCategory.place => const Color(0xFF1E60CC),
  };
}

/// A real POI returned by OpenStreetMap/Overpass.
class MapPoi {
  final String id;
  final String name;
  final PoiCategory category;
  final LatLng coordinate;
  final String statusLabel;
  final bool isAccessible;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final List<String> tags;
  final String? address;
  final String? phone;
  final String? website;
  final String? openingHours;
  final String? osmType;
  final int? osmId;

  MapPoi({
    required this.id,
    required this.name,
    required this.category,
    required this.coordinate,
    this.statusLabel = 'Data OpenStreetMap',
    this.isAccessible = false,
    this.subtitle,
    IconData? icon,
    Color? color,
    this.tags = const [],
    this.address,
    this.phone,
    this.website,
    this.openingHours,
    this.osmType,
    this.osmId,
  }) : icon = icon ?? category.defaultIcon,
       color = color ?? category.defaultColor;

  Uri? get openStreetMapUri {
    if (osmType == null || osmId == null) return null;
    return Uri.https('www.openstreetmap.org', '/$osmType/$osmId');
  }
}
