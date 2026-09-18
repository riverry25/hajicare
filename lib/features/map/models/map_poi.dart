import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum PoiCategory {
  maktab,
  medis,
  toilet,
  wudhu,
  posPantau,
  ibadah;

  String get label {
    switch (this) {
      case PoiCategory.medis:
        return 'Posko Medis';
      case PoiCategory.toilet:
        return 'Toilet';
      case PoiCategory.wudhu:
        return 'Tempat Wudhu';
      case PoiCategory.maktab:
        return 'Tenda Maktab';
      case PoiCategory.posPantau:
        return 'Pos Pantau';
      case PoiCategory.ibadah:
        return 'Tempat Ibadah';
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case PoiCategory.medis:
        return Icons.medical_services_rounded;
      case PoiCategory.toilet:
        return Icons.wc_rounded;
      case PoiCategory.wudhu:
        return Icons.water_drop_rounded;
      case PoiCategory.maktab:
        return Icons.holiday_village_rounded;
      case PoiCategory.posPantau:
        return Icons.flag_rounded;
      case PoiCategory.ibadah:
        return Icons.mosque_rounded;
    }
  }

  Color get defaultColor {
    switch (this) {
      case PoiCategory.medis:
        return const Color(0xFFE53935); // Crimson Red
      case PoiCategory.toilet:
        return const Color(0xFF0288D1); // Ocean Blue
      case PoiCategory.wudhu:
        return const Color(0xFF00897B); // Teal Aqua
      case PoiCategory.maktab:
        return const Color(0xFFD97706); // Golden Amber
      case PoiCategory.posPantau:
        return const Color(0xFF5E35B1); // Deep Indigo
      case PoiCategory.ibadah:
        return const Color(0xFF2E7D32); // Emerald Green
    }
  }
}

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

  const MapPoi({
    required this.id,
    required this.name,
    required this.category,
    required this.coordinate,
    required this.statusLabel,
    this.isAccessible = true,
    this.subtitle,
    required this.icon,
    required this.color,
    this.tags = const [],
  });



  /// Default curated Points of Interest around Mina Tent City (Maktab 48) & Mecca
  static const List<MapPoi> defaultMinaPois = [
    MapPoi(
      id: 'maktab_48',
      name: 'Tenda Maktab 48 Mina',
      category: PoiCategory.maktab,
      coordinate: LatLng(21.4135, 39.8930),
      statusLabel: 'Pusat Jamaah',
      subtitle: 'Tenda Utama Kloter JKG & SOC',
      icon: Icons.holiday_village_rounded,
      color: Color(0xFFD97706),
      tags: ['Tenda Utama', 'Dapur', 'AC'],
    ),
    MapPoi(
      id: 'posko_medis_ppih',
      name: 'Posko Medis PPIH Mina',
      category: PoiCategory.medis,
      coordinate: LatLng(21.4145, 39.8942),
      statusLabel: 'Siaga 24 Jam',
      subtitle: 'Dokter & Ambulans Darurat',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFE53935),
      tags: ['Dokter 24 Jam', 'Ambulans', 'Bebas Biaya'],
    ),
    MapPoi(
      id: 'toilet_wudhu_12',
      name: 'Toilet & Fasilitas Wudhu 12',
      category: PoiCategory.toilet,
      coordinate: LatLng(21.4130, 39.8922),
      statusLabel: 'Tersedia • Ramai Lancar',
      subtitle: 'Akses Khusus Lansia & Disabilitas',
      icon: Icons.wc_rounded,
      color: Color(0xFF0288D1),
      tags: ['Kloset Duduk', 'Wudhu', 'Ramah Lansia'],
    ),
    MapPoi(
      id: 'wudhu_mina_12',
      name: 'Tempat Wudhu Sektor 48',
      category: PoiCategory.wudhu,
      coordinate: LatLng(21.4128, 39.8918),
      statusLabel: 'Air Lancar',
      subtitle: 'Kran Wudhu Air Sejuk Terbuka',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF00897B),
      tags: ['Air Bersih', 'Lantai Anti Slip'],
    ),
    MapPoi(
      id: 'pos_pantau_sektor',
      name: 'Pos Pantau Sektor 48',
      category: PoiCategory.posPantau,
      coordinate: LatLng(21.4126, 39.8938),
      statusLabel: 'Petugas Bertugas',
      subtitle: 'Layanan Jamaah Terpisah & Informasi',
      icon: Icons.flag_rounded,
      color: Color(0xFF5E35B1),
      tags: ['Linjam', 'Pusat Informasi'],
    ),
    MapPoi(
      id: 'jamarat_bridge',
      name: 'Jembatan Jamarat (Lontar Jumrah)',
      category: PoiCategory.ibadah,
      coordinate: LatLng(21.4190, 39.8730),
      statusLabel: 'Jadwal Reguler',
      subtitle: 'Area Pelontaran Ula, Wustha, Aqabah',
      icon: Icons.mosque_rounded,
      color: Color(0xFF2E7D32),
      tags: ['Lontar Jumrah', 'Jalur Satu Arah'],
    ),
  ];
}
