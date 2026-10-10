import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/locales/app_localizations.dart';

/// Categories derived from OpenStreetMap tags. No category implies that a
/// place exists unless it was returned by the data provider.
enum PoiCategory {
  maktab,
  medis,
  clinic,
  pharmacy,
  emergency,
  toilet,
  wudhu,
  posPantau,
  police,
  ibadah,
  hotel,
  restaurant,
  cafe,
  shopping,
  supermarket,
  mall,
  atm,
  bank,
  fuel,
  parking,
  bus,
  train,
  airport,
  touristAttraction,
  place;

  String get label => switch (this) {
    PoiCategory.maktab => 'Perkemahan / Maktab',
    PoiCategory.medis => 'Rumah Sakit / Medis',
    PoiCategory.clinic => 'Klinik / Dokter',
    PoiCategory.pharmacy => 'Apotek / Farmasi',
    PoiCategory.emergency => 'Titik Darurat Medis',
    PoiCategory.toilet => 'Toilet',
    PoiCategory.wudhu => 'Air & Wudhu',
    PoiCategory.posPantau => 'Pos Keamanan / Pantau',
    PoiCategory.police => 'Kantor Polisi',
    PoiCategory.ibadah => 'Masjid / Tempat Ibadah',
    PoiCategory.hotel => 'Hotel / Penginapan',
    PoiCategory.restaurant => 'Restoran / Rumah Makan',
    PoiCategory.cafe => 'Kafe / Kedai',
    PoiCategory.shopping => 'Pusat Belanja',
    PoiCategory.supermarket => 'Supermarket / Swalayan',
    PoiCategory.mall => 'Mall / Plaza',
    PoiCategory.atm => 'ATM',
    PoiCategory.bank => 'Bank',
    PoiCategory.fuel => 'SPBU / Bensin',
    PoiCategory.parking => 'Area Parkir',
    PoiCategory.bus => 'Terminal / Halte Bus',
    PoiCategory.train => 'Stasiun Kereta',
    PoiCategory.airport => 'Bandara / Airport',
    PoiCategory.touristAttraction => 'Objek Wisata & Bersejarah',
    PoiCategory.place => 'Lokasi Umum',
  };

  String localizedLabel(BuildContext context) => switch (this) {
    PoiCategory.maktab => context.tr('maps.poi.maktab'),
    PoiCategory.medis => context.tr('maps.poi.medis'),
    PoiCategory.clinic => context.tr('maps.poi.clinic'),
    PoiCategory.pharmacy => context.tr('maps.poi.pharmacy'),
    PoiCategory.emergency => context.tr('maps.poi.emergency'),
    PoiCategory.toilet => context.tr('maps.poi.toilet'),
    PoiCategory.wudhu => context.tr('maps.poi.wudhu'),
    PoiCategory.posPantau => context.tr('maps.poi.posPantau'),
    PoiCategory.police => context.tr('maps.poi.police'),
    PoiCategory.ibadah => context.tr('maps.poi.ibadah'),
    PoiCategory.hotel => context.tr('maps.poi.hotel'),
    PoiCategory.restaurant => context.tr('maps.poi.restaurant'),
    PoiCategory.cafe => context.tr('maps.poi.cafe'),
    PoiCategory.shopping => context.tr('maps.poi.shopping'),
    PoiCategory.supermarket => context.tr('maps.poi.supermarket'),
    PoiCategory.mall => context.tr('maps.poi.mall'),
    PoiCategory.atm => context.tr('maps.poi.atm'),
    PoiCategory.bank => context.tr('maps.poi.bank'),
    PoiCategory.fuel => context.tr('maps.poi.fuel'),
    PoiCategory.parking => context.tr('maps.poi.parking'),
    PoiCategory.bus => context.tr('maps.poi.bus'),
    PoiCategory.train => context.tr('maps.poi.train'),
    PoiCategory.airport => context.tr('maps.poi.airport'),
    PoiCategory.touristAttraction => context.tr('maps.poi.touristAttraction'),
    PoiCategory.place => context.tr('maps.poi.place'),
  };

  IconData get defaultIcon => switch (this) {
    PoiCategory.maktab => Icons.holiday_village_rounded,
    PoiCategory.medis => Icons.local_hospital_rounded,
    PoiCategory.clinic => Icons.medical_services_rounded,
    PoiCategory.pharmacy => Icons.local_pharmacy_rounded,
    PoiCategory.emergency => Icons.emergency_rounded,
    PoiCategory.toilet => Icons.wc_rounded,
    PoiCategory.wudhu => Icons.water_drop_rounded,
    PoiCategory.posPantau => Icons.security_rounded,
    PoiCategory.police => Icons.local_police_rounded,
    PoiCategory.ibadah => Icons.mosque_rounded,
    PoiCategory.hotel => Icons.hotel_rounded,
    PoiCategory.restaurant => Icons.restaurant_rounded,
    PoiCategory.cafe => Icons.local_cafe_rounded,
    PoiCategory.shopping => Icons.shopping_bag_rounded,
    PoiCategory.supermarket => Icons.storefront_rounded,
    PoiCategory.mall => Icons.local_mall_rounded,
    PoiCategory.atm => Icons.local_atm_rounded,
    PoiCategory.bank => Icons.account_balance_rounded,
    PoiCategory.fuel => Icons.local_gas_station_rounded,
    PoiCategory.parking => Icons.local_parking_rounded,
    PoiCategory.bus => Icons.directions_bus_rounded,
    PoiCategory.train => Icons.train_rounded,
    PoiCategory.airport => Icons.flight_takeoff_rounded,
    PoiCategory.touristAttraction => Icons.photo_camera_rounded,
    PoiCategory.place => Icons.place_rounded,
  };

  Color get defaultColor => switch (this) {
    PoiCategory.maktab => const Color(0xFFD97706),
    PoiCategory.medis => const Color(0xFFE53935),
    PoiCategory.clinic => const Color(0xFFEF5350),
    PoiCategory.pharmacy => const Color(0xFF00897B),
    PoiCategory.emergency => const Color(0xFFD32F2F),
    PoiCategory.toilet => const Color(0xFF0288D1),
    PoiCategory.wudhu => const Color(0xFF00ACC1),
    PoiCategory.posPantau => const Color(0xFF5E35B1),
    PoiCategory.police => const Color(0xFF3949AB),
    PoiCategory.ibadah => const Color(0xFF2E7D32),
    PoiCategory.hotel => const Color(0xFF8E24AA),
    PoiCategory.restaurant => const Color(0xFFE64A35),
    PoiCategory.cafe => const Color(0xFF795548),
    PoiCategory.shopping => const Color(0xFFF57C00),
    PoiCategory.supermarket => const Color(0xFFFB8C00),
    PoiCategory.mall => const Color(0xFFFFA000),
    PoiCategory.atm => const Color(0xFF1565C0),
    PoiCategory.bank => const Color(0xFF0D47A1),
    PoiCategory.fuel => const Color(0xFF00838F),
    PoiCategory.parking => const Color(0xFF546E7A),
    PoiCategory.bus => const Color(0xFF5C6BC0),
    PoiCategory.train => const Color(0xFF4527A0),
    PoiCategory.airport => const Color(0xFF0277BD),
    PoiCategory.touristAttraction => const Color(0xFF6A1B9A),
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

  String localizedStatusLabel(BuildContext context) {
    final clean = statusLabel.trim().toLowerCase();
    if (clean == 'buka 24 jam' || clean == 'open 24 hours') {
      return context.tr('maps.open24Hours');
    }
    if (clean == 'data openstreetmap') {
      return context.tr('maps.osmData');
    }
    if (clean.startsWith('jam: ') ||
        clean.startsWith('hours: ') ||
        clean.startsWith('buka ') ||
        clean.startsWith('open ')) {
      final hours = statusLabel
          .replaceFirst(
            RegExp(
              r'^(Jam:\s*|Hours:\s*|Buka\s*|Open\s*)',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      return context.tr('maps.hoursFormat', {'hours': hours});
    }
    return statusLabel;
  }
}
