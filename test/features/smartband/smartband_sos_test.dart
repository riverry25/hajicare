import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/features/smartband/controllers/smartband_ldr_controller.dart';
import 'package:hajicare/features/smartband/models/smartband_data.dart';
import 'package:hajicare/features/smartband/services/smartband_ble_service.dart';

class MockSmartbandBleService extends SmartbandBleService {
  final _dataController = StreamController<SmartbandData>.broadcast();
  final _statusController = StreamController<SmartbandBleStatus>.broadcast();

  @override
  Stream<SmartbandData> get receivedSmartbandData => _dataController.stream;

  @override
  Stream<SmartbandBleStatus> get connectionStateStream =>
      _statusController.stream;

  @override
  SmartbandBleStatus get currentStatus => SmartbandBleStatus.connected;

  void emitData(SmartbandData data) {
    _dataController.add(data);
  }

  final List<String> sentCommands = [];

  @override
  Future<bool> sendCommand(String cmd) async {
    sentCommands.add(cmd);
    return true;
  }

  @override
  void dispose() {
    _dataController.close();
    _statusController.close();
    super.dispose();
  }
}

class FakeHajiCareController extends HajiCareController {
  int triggerSosCount = 0;
  int dismissSosCount = 0;
  String? lastDismissedUid;

  @override
  String? get currentUid => 'jamaah_test_123';

  @override
  Future<bool> triggerSos() async {
    triggerSosCount++;
    return true;
  }

  @override
  Future<bool> dismissSos(String id, {String? eventId}) async {
    dismissSosCount++;
    lastDismissedUid = id;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartbandLdrController SOS State Transitions & Firebase Sync', () {
    late MockSmartbandBleService mockBle;
    late SmartbandLdrController controller;
    late FakeHajiCareController fakeHajiCtrl;

    setUp(() {
      Get.reset();
      fakeHajiCtrl = FakeHajiCareController();
      Get.put<HajiCareController>(fakeHajiCtrl);

      mockBle = MockSmartbandBleService();
      controller = SmartbandLdrController(bleService: mockBle);
      Get.put<SmartbandLdrController>(controller);
    });

    tearDown(() {
      mockBle.dispose();
      Get.reset();
    });

    test('SOS button pressed in BLE packet turns on SOS and dispatches to Firebase', () async {
      expect(controller.isSosButtonPressed.value, isFalse);
      expect(fakeHajiCtrl.triggerSosCount, 0);

      final dataWithSos = SmartbandData(
        braceletId: 'HCG-001',
        heartRate: 75,
        isSos: true,
      );

      mockBle.emitData(dataWithSos);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.isSosButtonPressed.value, isTrue);
      expect(controller.emergencyMessage.value.isNotEmpty, isTrue);
      expect(fakeHajiCtrl.triggerSosCount, 1);
    });

    test('Turning off SOS in BLE packet automatically cancels SOS and syncs dismiss to Firebase', () async {
      // 1. SOS turned ON
      final dataWithSos = SmartbandData(
        braceletId: 'HCG-001',
        heartRate: 75,
        isSos: true,
      );
      mockBle.emitData(dataWithSos);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.isSosButtonPressed.value, isTrue);
      expect(fakeHajiCtrl.triggerSosCount, 1);
      expect(fakeHajiCtrl.dismissSosCount, 0);

      // 2. SOS turned OFF on the smartband
      final dataWithoutSos = SmartbandData(
        braceletId: 'HCG-001',
        heartRate: 75,
        isSos: false,
      );
      mockBle.emitData(dataWithoutSos);
      await Future.delayed(const Duration(milliseconds: 50));

      // Must be cancelled automatically and dismiss called on Firebase controller
      expect(controller.isSosButtonPressed.value, isFalse);
      expect(controller.emergencyMessage.value, isEmpty);
      expect(fakeHajiCtrl.dismissSosCount, 1);
      expect(fakeHajiCtrl.lastDismissedUid, 'jamaah_test_123');
    });

    test('Spamming consecutive SOS: true packets does not create multiple SOS triggers', () async {
      final dataWithSos = SmartbandData(
        braceletId: 'HCG-001',
        heartRate: 75,
        isSos: true,
      );

      // Emit multiple packets rapidly
      mockBle.emitData(dataWithSos);
      mockBle.emitData(dataWithSos);
      mockBle.emitData(dataWithSos);
      mockBle.emitData(dataWithSos);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.isSosButtonPressed.value, isTrue);
      // Even with 4 packets, triggerSos should only have been called once!
      expect(fakeHajiCtrl.triggerSosCount, 1);
    });

    test('Full cycle: Press SOS -> Turn off -> Press SOS again works cleanly', () async {
      final dataOn = SmartbandData(
        braceletId: 'HCG-001',
        heartRate: 75,
        isSos: true,
      );
      final dataOff = SmartbandData(
        braceletId: 'HCG-001',
        heartRate: 75,
        isSos: false,
      );

      // Cycle 1: ON
      mockBle.emitData(dataOn);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.isSosButtonPressed.value, isTrue);
      expect(fakeHajiCtrl.triggerSosCount, 1);

      // Cycle 1: OFF -> Cancelled
      mockBle.emitData(dataOff);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.isSosButtonPressed.value, isFalse);
      expect(fakeHajiCtrl.dismissSosCount, 1);

      // Cycle 2: ON again
      mockBle.emitData(dataOn);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.isSosButtonPressed.value, isTrue);
      expect(fakeHajiCtrl.triggerSosCount, 2);

      // Cycle 2: OFF again -> Cancelled
      mockBle.emitData(dataOff);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.isSosButtonPressed.value, isFalse);
      expect(fakeHajiCtrl.dismissSosCount, 2);
    });
  });

  group('Smartband Safe Radius & Mobile Vibration Motor Alerts', () {
    late MockSmartbandBleService mockBle;
    late SmartbandLdrController controller;
    late FakeHajiCareController fakeHajiCtrl;

    setUp(() {
      Get.reset();
      fakeHajiCtrl = FakeHajiCareController();
      fakeHajiCtrl.safeRadiusMeters.value = 200.0;
      Get.put<HajiCareController>(fakeHajiCtrl);

      mockBle = MockSmartbandBleService();
      controller = SmartbandLdrController(bleService: mockBle);
      Get.put<SmartbandLdrController>(controller);
    });

    tearDown(() {
      mockBle.dispose();
      Get.reset();
    });

    test('Breaching safe radius automatically activates outside status and triggers vibration commands', () async {
      expect(controller.isOutsideSafeRadius.value, isFalse);

      // Simulate jamaah walking outside the 200m safe radius
      fakeHajiCtrl.calculatedDistance.value = 320.0;
      // Wait for safe radius watcher timer tick
      await Future.delayed(const Duration(milliseconds: 1200));

      expect(controller.isOutsideSafeRadius.value, isTrue);
      expect(controller.currentDistanceToPosko.value, 320.0);
      expect(mockBle.sentCommands.contains('VIBRATE'), isTrue);
      expect(mockBle.sentCommands.contains('BUZZ'), isTrue);
      expect(controller.lcdLine2.value, '!LUAR RADIUS !');
    });

    test('Returning inside safe radius automatically stops vibration and restores normal status', () async {
      // 1. Move outside
      fakeHajiCtrl.calculatedDistance.value = 320.0;
      await Future.delayed(const Duration(milliseconds: 1200));
      expect(controller.isOutsideSafeRadius.value, isTrue);

      // 2. Return inside
      fakeHajiCtrl.calculatedDistance.value = 120.0;
      await Future.delayed(const Duration(milliseconds: 1200));

      expect(controller.isOutsideSafeRadius.value, isFalse);
      expect(mockBle.sentCommands.contains('STOP_BUZZ'), isTrue);
      expect(controller.lcdLine2.value.contains('NORMAL'), isTrue);
    });
  });

  group('Dynamic Sensor Trends & OLED 0.96 inch Telemetry Buffering', () {
    late MockSmartbandBleService mockBle;
    late SmartbandLdrController controller;

    setUp(() {
      Get.reset();
      mockBle = MockSmartbandBleService();
      controller = SmartbandLdrController(bleService: mockBle);
      Get.put<SmartbandLdrController>(controller);
    });

    tearDown(() {
      mockBle.dispose();
      Get.reset();
    });

    test('Incoming BLE packets dynamically update trend buffers and chart data', () async {
      final initialHrCount = controller.heartRateHistory.length;

      mockBle.emitData(SmartbandData(
        braceletId: 'HCG-001',
        heartRate: 88,
        temperature: 37.1,
        spo2: 97,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.heartRateHistory.length, initialHrCount + 1);
      expect(controller.heartRateHistory.last, 88.0);
      expect(controller.temperatureHistory.last, 37.1);
      expect(controller.trendData.last, 88.0);

      // Switching sensor dynamically updates unit and formatted values
      controller.selectSensor(1); // Suhu
      expect(controller.trendUnit, '°C');
      expect(controller.formatTrendValue(36.7), '36.7');

      controller.selectSensor(0); // Jantung
      expect(controller.trendUnit, 'BPM');
    });

    test('OLED 0.96 inch getters and elderly advice generate clear, friendly messages', () {
      final data = SmartbandData(
        braceletId: 'HCG-001',
        heartRate: 76,
        temperature: 36.6,
        spo2: 98,
      );

      expect(data.displayOledLine1.contains('HR: 76'), isTrue);
      expect(data.displayOledLine2.contains('36.6C'), isTrue);
      expect(controller.currentOledLine1.isNotEmpty, isTrue);
      expect(controller.currentOledLine2.isNotEmpty, isTrue);

      controller.heartRate.value = 76;
      controller.mcpTemperature.value = 36.6;
      controller.spo2.value = 98;

      // Elderly advice is accessible and polite
      expect(controller.elderlyOverallSummary.contains('Alhamdulillah'), isTrue);
      expect(controller.elderlyHeartRateAdvice.contains('BPM'), isTrue);
      expect(controller.elderlyTemperatureAdvice.contains('°C'), isTrue);
    });
  });
}
