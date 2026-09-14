import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

enum PoiCategory {
  maktab,
  medis,
  toilet,
  posPantau,
  ibadah,
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
      icon: Icons.holiday_village,
      color: AppColors.tanMedium,
    ),
    MapPoi(
      id: 'posko_medis_ppih',
      name: 'Posko Medis PPIH Mina',
      category: PoiCategory.medis,
      coordinate: LatLng(21.4145, 39.8942),
      statusLabel: 'Siaga 24 Jam',
      subtitle: 'Dokter & Ambulans Darurat',
      icon: Icons.medical_services,
      color: AppColors.sosEmergency,
    ),
    MapPoi(
      id: 'toilet_wudhu_12',
      name: 'Toilet & Fasilitas Wudhu 12',
      category: PoiCategory.toilet,
      coordinate: LatLng(21.4130, 39.8922),
      statusLabel: 'Tersedia • Ramai Lancar',
      subtitle: 'Akses Khusus Lansia & Disabilitas',
      icon: Icons.wc,
      color: AppColors.accentGoldStar,
    ),
    MapPoi(
      id: 'pos_pantau_sektor',
      name: 'Pos Pantau Sektor 48',
      category: PoiCategory.posPantau,
      coordinate: LatLng(21.4126, 39.8938),
      statusLabel: 'Petugas Bertugas',
      subtitle: 'Layanan Jamaah Terpisah & Informasi',
      icon: Icons.flag,
      color: AppColors.espressoDark,
    ),
    MapPoi(
      id: 'jamarat_bridge',
      name: 'Jembatan Jamarat (Lontar Jumrah)',
      category: PoiCategory.ibadah,
      coordinate: LatLng(21.4190, 39.8730),
      statusLabel: 'Jadwal Reguler',
      subtitle: 'Area Pelontaran Ula, Wustha, Aqabah',
      icon: Icons.mosque,
      color: AppColors.statusSafe,
    ),
  ];
}
