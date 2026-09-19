import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/utils/distance_formatter.dart';

void main() {
  group('DistanceFormatter Tests', () {
    test('formats meters correctly when distance < 1000m', () {
      expect(DistanceFormatter.format(0), '0 m');
      expect(DistanceFormatter.format(50), '50 m');
      expect(DistanceFormatter.format(249.6), '250 m');
      expect(DistanceFormatter.format(999), '999 m');
    });

    test(
      'formats kilometers correctly when distance is between 1000m and 100km',
      () {
        expect(DistanceFormatter.format(1000), '1 km');
        expect(DistanceFormatter.format(1200), '1.2 km');
        expect(DistanceFormatter.format(2450), '2.5 km');
        expect(DistanceFormatter.format(15400), '15.4 km');
        expect(DistanceFormatter.format(99900), '99.9 km');
      },
    );

    test('formats rounded kilometers when distance >= 100km', () {
      expect(DistanceFormatter.format(100000), '100 km');
      expect(DistanceFormatter.format(14040000), '14040 km');
    });

    test('handles null, negative, and invalid values gracefully', () {
      expect(DistanceFormatter.format(null), '-');
      expect(DistanceFormatter.format(-10), '-');
      expect(DistanceFormatter.format(double.nan), '-');
      expect(DistanceFormatter.format(double.infinity), '-');
    });
  });
}
