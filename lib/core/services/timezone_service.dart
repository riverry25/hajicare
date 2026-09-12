import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tz_lookup;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneInfo {
  final String timezoneId;
  final String abbreviation;
  final Duration offset;

  const TimezoneInfo({
    required this.timezoneId,
    required this.abbreviation,
    required this.offset,
  });
}

class TimezoneService {
  static bool _isInitialized = false;

  TimezoneService() {
    _initTimezoneDatabase();
  }

  static void _initTimezoneDatabase() {
    if (!_isInitialized) {
      try {
        tz.initializeTimeZones();
        _isInitialized = true;
      } catch (_) {}
    }
  }

  /// Resolves the IANA timezone ID for a given coordinate
  String getTimezoneId(double latitude, double longitude) {
    _initTimezoneDatabase();
    try {
      final tzId = tz_lookup.latLngToTimezoneString(latitude, longitude);
      if (tzId.isNotEmpty) {
        return tzId;
      }
    } catch (_) {}

    // Fallback based on longitude approximation if lookup fails
    return _approximateTimezoneId(longitude);
  }

  /// Resolves detailed timezone information including abbreviation and offset
  TimezoneInfo getTimezoneInfo(
    double latitude,
    double longitude, {
    DateTime? dateTime,
  }) {
    _initTimezoneDatabase();
    final targetDate = dateTime ?? DateTime.now();
    final tzId = getTimezoneId(latitude, longitude);

    try {
      final location = tz.getLocation(tzId);
      final tzDateTime = tz.TZDateTime.from(targetDate, location);
      final rawAbbr = tzDateTime.timeZoneName;
      final offset = tzDateTime.timeZoneOffset;

      final formattedAbbr = _resolveAbbreviation(tzId, rawAbbr, offset);

      return TimezoneInfo(
        timezoneId: tzId,
        abbreviation: formattedAbbr,
        offset: offset,
      );
    } catch (_) {
      // Fallback
      final offsetHours = (longitude / 15.0).round();
      final sign = offsetHours >= 0 ? '+' : '-';
      final gmtText = 'GMT$sign${offsetHours.abs()}';

      return TimezoneInfo(
        timezoneId: tzId,
        abbreviation: gmtText,
        offset: Duration(hours: offsetHours),
      );
    }
  }

  /// Resolves standard human-readable abbreviations with priority for known cultural standards
  String _resolveAbbreviation(String tzId, String rawAbbr, Duration offset) {
    // Saudi Arabia / Gulf Standard Time
    if (tzId == 'Asia/Riyadh' || tzId.contains('Riyadh')) {
      return 'AST';
    }

    // Indonesian Time Zones
    if (tzId == 'Asia/Jakarta' || tzId == 'Asia/Pontianak') {
      return 'WIB';
    }
    if (tzId == 'Asia/Makassar' || tzId == 'Asia/Ujung_Pandang') {
      return 'WITA';
    }
    if (tzId == 'Asia/Jayapura') {
      return 'WIT';
    }

    // Japan Standard Time
    if (tzId == 'Asia/Tokyo') {
      return 'JST';
    }

    // If raw abbreviation is already a well-known alphabetic acronym (e.g. BST, GMT, EST, EDT, CST, CDT, PST, PDT)
    if (rawAbbr.isNotEmpty && RegExp(r'^[A-Z]{2,5}$').hasMatch(rawAbbr)) {
      return rawAbbr;
    }

    // If raw abbreviation is offset-like (+03, -0400, etc.), convert to GMT fallback
    final totalMinutes = offset.inMinutes;
    final hours = (totalMinutes / 60).truncate();
    final minutes = (totalMinutes % 60).abs();
    final sign = totalMinutes >= 0 ? '+' : '-';

    if (minutes == 0) {
      return 'GMT$sign${hours.abs()}';
    } else {
      final minStr = minutes.toString().padLeft(2, '0');
      return 'GMT$sign${hours.abs()}:$minStr';
    }
  }

  /// Formats a DateTime into a string like "12:45 WIB" or "08:21 AST"
  String formatTime(
    DateTime dt, {
    String? timezoneId,
    bool includeTimeZone = false,
  }) {
    _initTimezoneDatabase();
    int hour = dt.hour;
    int minute = dt.minute;
    String abbr = '';

    if (timezoneId != null && timezoneId.isNotEmpty) {
      try {
        final location = tz.getLocation(timezoneId);
        final tzDt = tz.TZDateTime.from(dt, location);
        hour = tzDt.hour;
        minute = tzDt.minute;
        abbr = _resolveAbbreviation(
          timezoneId,
          tzDt.timeZoneName,
          tzDt.timeZoneOffset,
        );
      } catch (_) {
        final localDt = dt.toLocal();
        hour = localDt.hour;
        minute = localDt.minute;
      }
    } else {
      final localDt = dt.toLocal();
      hour = localDt.hour;
      minute = localDt.minute;
    }

    final hStr = hour.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');

    if (includeTimeZone && abbr.isNotEmpty) {
      return '$hStr:$mStr $abbr';
    }
    return '$hStr:$mStr';
  }

  String _approximateTimezoneId(double longitude) {
    if (longitude >= 95 && longitude <= 141) {
      if (longitude <= 114) return 'Asia/Jakarta';
      if (longitude <= 125) return 'Asia/Makassar';
      return 'Asia/Jayapura';
    }
    if (longitude >= 34 && longitude <= 55) {
      return 'Asia/Riyadh';
    }
    if (longitude >= 129 && longitude <= 146) {
      return 'Asia/Tokyo';
    }
    return 'UTC';
  }
}
