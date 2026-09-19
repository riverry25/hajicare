/// Centralized utility for consistent distance formatting across the HajiCare app.
class DistanceFormatter {
  DistanceFormatter._();

  /// Formats distance in meters into human-readable strings:
  /// - `< 1000m` -> `X m` (e.g. `250 m`)
  /// - `1000m` to `99.9km` -> `X.X km` (e.g. `2.4 km`)
  /// - `>= 100km` -> `X km` rounded (e.g. `14040 km`)
  static String format(double? meters) {
    if (meters == null || meters.isNaN || meters.isInfinite || meters < 0) {
      return '-';
    }
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000.0;
    if (km < 100) {
      // Remove trailing zero decimal if whole number (e.g. 2.0 km -> 2 km)
      final str = km.toStringAsFixed(1);
      return str.endsWith('.0') ? '${km.toInt()} km' : '$str km';
    }
    return '${km.round()} km';
  }
}
