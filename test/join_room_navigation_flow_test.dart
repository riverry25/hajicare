import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/features/room/controllers/join_room_controller.dart';
import 'package:hajicare/features/room/bindings/join_room_binding.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  group('JoinRoomController Navigation & Guard Tests', () {
    test('Default mode is 1 (Gabung Room) when user is not pendamping', () {
      final controller = Get.put(JoinRoomController());
      expect(controller.selectedMode.value, equals(1));
      expect(controller.isPendamping, isFalse);
    });

    test(
      'Validation rejects invalid room code format without navigating',
      () async {
        final controller = Get.put(JoinRoomController());
        controller.roomCodeController.text = '--INVALID--';

        await controller.joinRoom();

        expect(controller.errorMessage.value, isNotNull);
        expect(
          controller.errorMessage.value,
          contains('Format kode rombongan tidak valid'),
        );
        expect(controller.isLoading.value, isFalse);
      },
    );

    test('Empty room code triggers validation error', () async {
      final controller = Get.put(JoinRoomController());
      controller.roomCodeController.text = '';

      await controller.joinRoom();

      expect(controller.errorMessage.value, equals('Masukkan kode rombongan.'));
      expect(controller.isLoading.value, isFalse);
    });

    test('JoinRoomBinding registers JoinRoomController with fenix', () {
      JoinRoomBinding().dependencies();
      expect(Get.isRegistered<JoinRoomController>(), isTrue);
      final c1 = Get.find<JoinRoomController>();
      expect(c1, isNotNull);
    });

    test('isSyncing and syncStatus have correct initial state', () {
      final controller = Get.put(JoinRoomController());
      expect(controller.isSyncing.value, isFalse);
      expect(controller.syncStatus.value, isEmpty);
    });

    test('MapController.to evicts closed controller and returns active instance', () {
      final c1 = Get.put(MapController());
      c1.onClose();
      expect(c1.isClosedSafe, isTrue);

      final c2 = MapController.to;
      expect(c2.isClosedSafe, isFalse);
      expect(identical(c1, c2), isFalse);
    });

    test('ensureFreshMapController provides active MapController even after dispose', () {
      final mapCtrl = Get.put(MapController());
      mapCtrl.flutterMapController.dispose();

      final fresh = mapCtrl.ensureFreshMapController();
      expect(fresh, isNotNull);
      expect(identical(fresh, mapCtrl.flutterMapController), isTrue);
    });
  });
}

