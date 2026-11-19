import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/services/cams_canonical_frames.dart';
import 'package:hajicare/services/cams_location_resolver.dart';

void main() {
  group('CamsLocationResolver Coordinate Mapping', () {
    test('maps Masjidil Haram Tawaf coordinates to areaTawafMasjidilHaram', () {
      const resolver = CamsLocationResolver();
      final loc = resolver.resolveFromCoordinates(21.4225, 39.8262);
      expect(loc, equals(CamsLocation.areaTawafMasjidilHaram));
    });

    test('maps Masjid Nabawi Madinah coordinates to pelataranMasjidNabawiMadinah', () {
      const resolver = CamsLocationResolver();
      final loc = resolver.resolveFromCoordinates(24.4672, 39.6111);
      expect(loc, equals(CamsLocation.pelataranMasjidNabawiMadinah));
    });

    test('maps Mina Clinic coordinates to klinikSektorMina', () {
      const resolver = CamsLocationResolver();
      final loc = resolver.resolveFromCoordinates(21.4133, 39.8933);
      expect(loc, equals(CamsLocation.klinikSektorMina));
    });

    test('returns CamsLocation.unknown when coordinates are outside Hajj sites (e.g. Jakarta)', () {
      const resolver = CamsLocationResolver();
      final loc = resolver.resolveFromCoordinates(-6.2088, 106.8456);
      expect(loc, equals(CamsLocation.unknown));
    });
  });
}
