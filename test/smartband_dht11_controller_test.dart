import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/features/smartband/controllers/smartband_ldr_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DHT11 Heat Index & Environment Status Calculations', () {
    test(
      'calculateHeatIndex returns correct values according to NOAA regression',
      () {
        // Test warm & high humidity (32°C, 70% RH -> 40.4°C / 40°C)
        final hi1 = SmartbandLdrController.calculateHeatIndex(32.0, 70.0);
        expect(hi1.round(), equals(40));

        // Test warm & moderate humidity (32°C, 60% RH -> 37.1°C / 37°C)
        final hi2 = SmartbandLdrController.calculateHeatIndex(32.0, 60.0);
        expect(hi2.round(), equals(37));

        // Test hot & moderate humidity: 35°C, 50%
        final hi3 = SmartbandLdrController.calculateHeatIndex(35.0, 50.0);
        expect(hi3, greaterThanOrEqualTo(40.0));

        // Test temperature below 26.7°C returns ambient temperature
        final hiCool = SmartbandLdrController.calculateHeatIndex(22.0, 50.0);
        expect(hiCool, equals(22.0));

        final hiCold = SmartbandLdrController.calculateHeatIndex(16.5, 80.0);
        expect(hiCold, equals(16.5));
      },
    );

    test(
      'determineEnvironmentStatus accurately categorizes Dingin, Normal, and Panas',
      () {
        // 1. Dingin: Temperature < 20°C
        expect(
          SmartbandLdrController.determineEnvironmentStatus(
            temperature: 18.0,
            heatIndex: 18.0,
          ),
          equals('Dingin'),
        );
        expect(
          SmartbandLdrController.determineEnvironmentStatus(
            temperature: 14.5,
            heatIndex: 14.5,
          ),
          equals('Dingin'),
        );

        // 2. Normal: 20°C <= Temp < 32°C and Heat Index < 33°C
        expect(
          SmartbandLdrController.determineEnvironmentStatus(
            temperature: 24.0,
            heatIndex: 24.0,
          ),
          equals('Normal'),
        );
        expect(
          SmartbandLdrController.determineEnvironmentStatus(
            temperature: 28.0,
            heatIndex: 30.0,
          ),
          equals('Normal'),
        );

        // User example explicitly: Temp 31.0°C, Humidity 68%, HI 33.8°C -> Normal
        expect(
          SmartbandLdrController.determineEnvironmentStatus(
            temperature: 31.0,
            heatIndex: 33.8,
          ),
          equals('Normal'),
        );

        // 3. Panas: High temperature or high Heat Index (Temp >= 32°C or HI >= 35°C)
        // User example: 32°C, HI 37°C -> Panas
        expect(
          SmartbandLdrController.determineEnvironmentStatus(
            temperature: 32.0,
            heatIndex: 37.0,
          ),
          equals('Panas'),
        );

        // Warm temp with oppressive humidity causing HI >= 35°C
        expect(
          SmartbandLdrController.determineEnvironmentStatus(
            temperature: 29.0,
            heatIndex: 36.0,
          ),
          equals('Panas'),
        );

        // High temperature (>= 32°C)
        expect(
          SmartbandLdrController.determineEnvironmentStatus(
            temperature: 36.0,
            heatIndex: 42.0,
          ),
          equals('Panas'),
        );
      },
    );
  });

  group('SmartbandLdrController DHT11 State & Resilience', () {
    late SmartbandLdrController controller;

    setUp(() {
      Get.reset();
      controller = Get.put(SmartbandLdrController());
    });

    tearDown(() {
      Get.delete<SmartbandLdrController>();
    });

    test(
      'initial state handles disconnected and empty sensor safely without crash',
      () {
        expect(controller.isConnected, isFalse);
        expect(controller.isSensorAvailable.value, isFalse);
        expect(controller.temperature.value, isNull);
        expect(controller.humidity.value, isNull);
        expect(controller.heatIndex.value, isNull);
        expect(controller.formattedTemperature, equals('-'));
        expect(controller.formattedHumidity, equals('-'));
        expect(controller.formattedHeatIndex, equals('-'));
        expect(controller.environmentStatusLabel, equals('-'));
      },
    );

    test(
      'valid sensor reading updates states and formatted getters correctly (matching user example)',
      () {
        // Simulate connection
        controller.isWatchConnected.value = true;
        controller.connectionState.value = SmartbandConnectionState.connected;

        // Simulate incoming BLE data matching user example:
        // Suhu: 31.0 °C, Kelembapan: 68 %, Heat Index: 33.8 °C, Kondisi: Normal
        controller.temperature.value = 31.0;
        controller.humidity.value = 68.0;
        controller.heatIndex.value = 33.8;
        controller.isSensorAvailable.value = true;
        controller.environmentStatus.value =
            SmartbandLdrController.determineEnvironmentStatus(
              temperature: 31.0,
              heatIndex: 33.8,
            );

        expect(controller.formattedTemperature, equals('31.0 °C'));
        expect(controller.formattedHumidity, equals('68 %'));
        expect(controller.formattedHeatIndex, equals('33.8 °C'));
        expect(controller.environmentStatusLabel, equals('Normal'));
        expect(controller.isSensorAvailable.value, isTrue);
      },
    );

    test(
      'sensor failure / null payload sets status to Sensor tidak tersedia without crash',
      () {
        controller.isWatchConnected.value = true;
        controller.connectionState.value = SmartbandConnectionState.connected;

        // Simulate failure state
        controller.isSensorAvailable.value = false;
        controller.environmentStatus.value = 'Sensor tidak tersedia';
        controller.temperature.value = null;
        controller.humidity.value = null;
        controller.heatIndex.value = null;

        expect(controller.formattedTemperature, equals('-'));
        expect(controller.formattedHumidity, equals('-'));
        expect(controller.formattedHeatIndex, equals('-'));
        expect(
          controller.environmentStatusLabel,
          equals('Sensor tidak tersedia'),
        );
      },
    );
  });
}
