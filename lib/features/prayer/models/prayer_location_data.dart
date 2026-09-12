enum LocationSource { gps, lastKnown, cache, unavailable }

class PrayerLocationData {
  final double latitude;
  final double longitude;
  final String cityName;
  final String countryName;
  final String countryCode;
  final String timezoneName;
  final String timezoneAbbr;
  final DateTime timestamp;
  final LocationSource source;

  const PrayerLocationData({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.countryName,
    required this.countryCode,
    required this.timezoneName,
    required this.timezoneAbbr,
    required this.timestamp,
    this.source = LocationSource.gps,
  });

  /// Maximum age for cached location to be considered valid (7 days)
  static const int maxCacheAgeDays = 7;

  /// Whether this cache data is expired
  bool get isExpired {
    return DateTime.now().difference(timestamp).inDays >= maxCacheAgeDays;
  }

  /// Whether this location data is valid and not expired
  bool get isValid {
    return !isExpired && (latitude != 0.0 || longitude != 0.0);
  }

  String get displayName {
    if (cityName.isNotEmpty && countryName.isNotEmpty) {
      return '$cityName, $countryName';
    } else if (cityName.isNotEmpty) {
      return cityName;
    } else if (countryName.isNotEmpty) {
      return countryName;
    } else if (latitude != 0.0 || longitude != 0.0) {
      return 'Koordinat (${latitude.toStringAsFixed(3)}°, ${longitude.toStringAsFixed(3)}°)';
    }
    return 'Lokasi tidak tersedia';
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'cityName': cityName,
      'countryName': countryName,
      'countryCode': countryCode,
      'timezoneName': timezoneName,
      'timezoneAbbr': timezoneAbbr,
      'timestamp': timestamp.toIso8601String(),
      'source': source.name,
    };
  }

  factory PrayerLocationData.fromJson(Map<String, dynamic> json) {
    LocationSource parsedSource = LocationSource.cache;
    final sourceStr = json['source'] as String?;
    if (sourceStr != null) {
      for (final s in LocationSource.values) {
        if (s.name == sourceStr) {
          parsedSource = s;
          break;
        }
      }
    }

    return PrayerLocationData(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      cityName: json['cityName'] as String? ?? '',
      countryName: json['countryName'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      timezoneName: json['timezoneName'] as String? ?? '',
      timezoneAbbr: json['timezoneAbbr'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      source: parsedSource,
    );
  }
}
