import 'package:latlong2/latlong.dart';

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
