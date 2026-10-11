import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HajiCareController controller;

  // Base coordinate for Jamaah (Makkah reference point: 21.42250, 39.82620)
  const jamaahLat = 21.42250;
  const jamaahLng = 39.82620;

  Position createPosition(double lat, double lng) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      accuracy: 5.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  // Helper to offset latitude by approximately `meters`
  double offsetLat(double meters) => jamaahLat + (meters / 111320.0);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    controller = Get.put(HajiCareController(), permanent: true);
    controller.setRole(UserRole.jamaah);
    controller.activeRoomId.value = 'room_123';
    controller.activeRoom.value = RoomModel(
      id: 'room_123',
      name: 'Rombongan Uji',
      code: 'TEST01',
      createdBy: 'fadli_uid', // Fadli is Owner Utama
      coOwnerId: 'apiw_uid', // Apiw is Owner Kedua
      pendampingIds: const ['fadli_uid', 'apiw_uid'],
    );
    controller.myCurrentPosition.value = createPosition(jamaahLat, jamaahLng);
  });

  tearDown(() {
    Get.reset();
  });

  group('Nearest Companion Distance Tests (Bagian B)', () {
    test(
      'Test A: Pemilik bukan yang terdekat -> Apiw (100m) dipilih daripada Fadli (600m)',
      () {
        final now = DateTime.now();
        final fadliOwner = RoomMemberModel(
          uid: 'fadli_uid',
          name: 'Fadli (Owner)',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(600), jamaahLng),
          locationUpdatedAt: now,
        );
        final apiwCompanion = RoomMemberModel(
          uid: 'apiw_uid',
          name: 'Apiw (Pendamping)',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(100), jamaahLng),
          locationUpdatedAt: now,
        );

        controller.activeRoomMembers.value = [fadliOwner, apiwCompanion];
        controller.recalculateRealDistance();

        expect(controller.nearestPendamping.value, isNotNull);
        expect(controller.nearestPendamping.value!.uid, equals('apiw_uid'));
        expect(controller.pendampingName.value, equals('Apiw (Pendamping)'));
        expect(controller.calculatedDistance.value, closeTo(100, 5));
      },
    );

    test(
      'Test B: Pendamping ketiga lebih dekat -> Pendamping lain (80m) dipilih daripada Apiw (250m) dan Fadli (600m)',
      () {
        final now = DateTime.now();
        final fadliOwner = RoomMemberModel(
          uid: 'fadli_uid',
          name: 'Fadli',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(600), jamaahLng),
          locationUpdatedAt: now,
        );
        final apiwCompanion = RoomMemberModel(
          uid: 'apiw_uid',
          name: 'Apiw',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(250), jamaahLng),
          locationUpdatedAt: now,
        );
        final otherCompanion = RoomMemberModel(
          uid: 'other_uid',
          name: 'Pendamping Lain',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(80), jamaahLng),
          locationUpdatedAt: now,
        );

        controller.activeRoomMembers.value = [
          fadliOwner,
          apiwCompanion,
          otherCompanion,
        ];
        controller.recalculateRealDistance();

        expect(controller.nearestPendamping.value!.uid, equals('other_uid'));
        expect(controller.pendampingName.value, equals('Pendamping Lain'));
        expect(controller.calculatedDistance.value, closeTo(80, 5));
      },
    );

    test(
      'Test C: Owner paling dekat -> Fadli (50m) dipilih daripada Apiw (100m) tanpa perlakuan bias',
      () {
        final now = DateTime.now();
        final fadliOwner = RoomMemberModel(
          uid: 'fadli_uid',
          name: 'Fadli',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(50), jamaahLng),
          locationUpdatedAt: now,
        );
        final apiwCompanion = RoomMemberModel(
          uid: 'apiw_uid',
          name: 'Apiw',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(100), jamaahLng),
          locationUpdatedAt: now,
        );

        controller.activeRoomMembers.value = [fadliOwner, apiwCompanion];
        controller.recalculateRealDistance();

        expect(controller.nearestPendamping.value!.uid, equals('fadli_uid'));
        expect(controller.pendampingName.value, equals('Fadli'));
        expect(controller.calculatedDistance.value, closeTo(50, 5));
      },
    );

    test(
      'Test D: Lokasi Owner tidak tersedia -> Apiw (150m) tetap dihitung dan dipilih',
      () {
        final now = DateTime.now();
        final fadliOwner = RoomMemberModel(
          uid: 'fadli_uid',
          name: 'Fadli',
          role: 'pendamping',
          currentLocation: null, // No GPS coordinate
          locationUpdatedAt: null,
        );
        final apiwCompanion = RoomMemberModel(
          uid: 'apiw_uid',
          name: 'Apiw',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(150), jamaahLng),
          locationUpdatedAt: now,
        );

        controller.activeRoomMembers.value = [fadliOwner, apiwCompanion];
        controller.recalculateRealDistance();

        expect(controller.nearestPendamping.value!.uid, equals('apiw_uid'));
        expect(controller.calculatedDistance.value, closeTo(150, 5));
      },
    );

    test(
      'Test E: Anggota keluar room -> Apiw keluar, perhitungan beralih ke Fadli (600m)',
      () {
        final now = DateTime.now();
        final fadliOwner = RoomMemberModel(
          uid: 'fadli_uid',
          name: 'Fadli',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(600), jamaahLng),
          locationUpdatedAt: now,
        );
        final apiwCompanion = RoomMemberModel(
          uid: 'apiw_uid',
          name: 'Apiw',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(100), jamaahLng),
          locationUpdatedAt: now,
        );

        // Initially both are present -> Apiw is chosen
        controller.activeRoomMembers.value = [fadliOwner, apiwCompanion];
        controller.recalculateRealDistance();
        expect(controller.nearestPendamping.value!.uid, equals('apiw_uid'));

        // Apiw leaves the room -> activeRoomMembers only contains Fadli
        controller.activeRoomMembers.value = [fadliOwner];
        controller.recalculateRealDistance();

        expect(controller.nearestPendamping.value!.uid, equals('fadli_uid'));
        expect(controller.calculatedDistance.value, closeTo(600, 10));
      },
    );

    test(
      'Test F: Lokasi tidak tersedia -> calculatedDistance & nearestPendamping null',
      () {
        final fadliOwner = RoomMemberModel(
          uid: 'fadli_uid',
          name: 'Fadli',
          role: 'pendamping',
          currentLocation: null,
        );
        final apiwCompanion = RoomMemberModel(
          uid: 'apiw_uid',
          name: 'Apiw',
          role: 'pendamping',
          currentLocation: null,
        );

        controller.activeRoomMembers.value = [fadliOwner, apiwCompanion];
        controller.recalculateRealDistance();

        expect(controller.nearestPendamping.value, isNull);
        expect(controller.calculatedDistance.value, isNull);
      },
    );

    test(
      'Test G: Perubahan lokasi real-time -> Apiw menjauh ke 800m, Fadli (600m) otomatis menjadi terdekat',
      () {
        final now = DateTime.now();
        final fadliOwner = RoomMemberModel(
          uid: 'fadli_uid',
          name: 'Fadli',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(600), jamaahLng),
          locationUpdatedAt: now,
        );
        var apiwCompanion = RoomMemberModel(
          uid: 'apiw_uid',
          name: 'Apiw',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(100), jamaahLng),
          locationUpdatedAt: now,
        );

        controller.activeRoomMembers.value = [fadliOwner, apiwCompanion];
        controller.recalculateRealDistance();
        expect(controller.nearestPendamping.value!.uid, equals('apiw_uid'));

        // Apiw moves further away to 800m
        apiwCompanion = apiwCompanion.copyWith(
          currentLocation: GeoPoint(offsetLat(800), jamaahLng),
          locationUpdatedAt: DateTime.now(),
        );

        controller.activeRoomMembers.value = [fadliOwner, apiwCompanion];
        controller.recalculateRealDistance();

        expect(controller.nearestPendamping.value!.uid, equals('fadli_uid'));
        expect(controller.calculatedDistance.value, closeTo(600, 10));
      },
    );

    test(
      'Test H: Evaluasi kesegaran (freshness) -> Mengutamakan lokasi segar (<30 mnt) daripada lokasi lama (>30 mnt)',
      () {
        final now = DateTime.now();
        // Fadli has stale location from 45 minutes ago at 40m
        final fadliStale = RoomMemberModel(
          uid: 'fadli_uid',
          name: 'Fadli (Stale)',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(40), jamaahLng),
          locationUpdatedAt: now.subtract(const Duration(minutes: 45)),
        );
        // Apiw has fresh location from 2 minutes ago at 120m
        final apiwFresh = RoomMemberModel(
          uid: 'apiw_uid',
          name: 'Apiw (Fresh)',
          role: 'pendamping',
          currentLocation: GeoPoint(offsetLat(120), jamaahLng),
          locationUpdatedAt: now.subtract(const Duration(minutes: 2)),
        );

        controller.activeRoomMembers.value = [fadliStale, apiwFresh];
        controller.recalculateRealDistance();

        // Fresh candidate Apiw is prioritized over stale candidate Fadli
        expect(controller.nearestPendamping.value!.uid, equals('apiw_uid'));
        expect(controller.calculatedDistance.value, closeTo(120, 5));
      },
    );
  });
}
