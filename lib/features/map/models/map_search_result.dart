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
