import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../../core/services/app_alert_service.dart';
import '../services/ble_service.dart';

enum SmartbandConnectionState { disconnected, scanning, connecting, connected }

class SmartbandLdrController extends GetxController {
  final BleService _bleService = BleService();

  // Observable state - Connection
  final isWatchConnected = false.obs;
  final connectionState = SmartbandConnectionState.disconnected.obs;
  final statusMessage = 'HajiCare Watch belum terhubung'.obs;
  final deviceName = 'HajiCare Watch'.obs;
  final receivingData = false.obs;
  final lastUpdated = Rxn<DateTime>();
  final rawDataString = '-'.obs;
  final relativeTimeStr = ''.obs;

  // Observable state - DHT11 Environmental Sensor (Specification Requirement 5)
  final temperature = Rxn<double>();
  final humidity = Rxn<double>();
  final heatIndex = Rxn<double>();
  final isSensorAvailable = false.obs;
  final sensorError = Rxn<String>();
  final environmentStatus = 'Menunggu Sensor'.obs;

  int _connectionGeneration = 0;
  Timer? _tickerTimer;

  // Convenient getters
  bool get isConnected => isWatchConnected.value;
  bool get isScanning =>
      connectionState.value == SmartbandConnectionState.scanning;
  bool get isConnecting =>
      connectionState.value == SmartbandConnectionState.connecting;
  bool get isBusy => isScanning || isConnecting;

  /// Calculates Heat Index (°C) based on ambient temperature (°C) and relative humidity (%)
  /// using NOAA's Rothfusz regression equation as fallback if ESP32 does not provide it.
  static double calculateHeatIndex(double tempC, double hum) {
    final rh = hum.clamp(0.0, 100.0);

    if (tempC < 26.7) {
      return double.parse(tempC.toStringAsFixed(1));
    }

    final tf = tempC * 1.8 + 32.0;
    double hi = 0.5 * (tf + 61.0 + ((tf - 68.0) * 1.2) + (rh * 0.094));

    if ((hi + tf) / 2.0 >= 80.0) {
      hi =
          -42.379 +
          2.04901523 * tf +
          10.14333127 * rh -
          0.22475541 * tf * rh -
          0.00683783 * tf * tf -
          0.05481717 * rh * rh +
          0.00122874 * tf * tf * rh +
          0.00085282 * tf * rh * rh -
          0.00000199 * tf * tf * rh * rh;

      if (rh < 13.0 && tf >= 80.0 && tf <= 112.0) {
        final adj =
            ((13.0 - rh) / 4.0) *
            sqrt(
              ((17.0 - (tf - 95.0).abs()) / 17.0).clamp(0.0, double.infinity),
            );
        hi -= adj;
      } else if (rh > 85.0 && tf >= 80.0 && tf <= 87.0) {
        final adj = ((rh - 85.0) / 10.0) * ((87.0 - tf) / 5.0);
        hi += adj;
      }
    }

    final hiC = (hi - 32.0) / 1.8;
    return double.parse(hiC.toStringAsFixed(1));
  }

  /// Dedicated function to determine environmental condition (Requirement 10):
  /// - 'Dingin'  : Temp < 20.0 °C
  /// - 'Panas'   : Temp >= 32.0 °C OR Heat Index >= 35.0 °C
  /// - 'Normal'  : 20.0 °C <= Temp < 32.0 °C and Heat Index < 35.0 °C
  static String determineEnvironmentStatus({
    required double temperature,
    required double heatIndex,
  }) {
    if (temperature < 20.0) {
      return 'Dingin';
    } else if (temperature >= 32.0 || heatIndex >= 35.0) {
      return 'Panas';
    } else {
      return 'Normal';
    }
  }

  /// Formatted string for Suhu Lingkungan, e.g. "31.0 °C" (Requirement 8 & 9)
  String get formattedTemperature {
    if (!isWatchConnected.value ||
        !isSensorAvailable.value ||
        temperature.value == null) {
      return '-';
    }
    return '${temperature.value!.toStringAsFixed(1)} °C';
  }

  /// Formatted string for Kelembapan, e.g. "68 %" (Requirement 8)
  String get formattedHumidity {
    if (!isWatchConnected.value ||
        !isSensorAvailable.value ||
        humidity.value == null) {
      return '-';
    }
    return '${humidity.value!.round()} %';
  }

  /// Formatted string for Heat Index, e.g. "33.8 °C" (Requirement 8)
  String get formattedHeatIndex {
    if (!isWatchConnected.value ||
        !isSensorAvailable.value ||
        heatIndex.value == null) {
      return '-';
    }
    return '${heatIndex.value!.toStringAsFixed(1)} °C';
  }

  /// Status label for Kondisi Lingkungan (Requirement 8 & 10)
  String get environmentStatusLabel {
    if (!isWatchConnected.value) {
      return '-';
    }
    if (!isSensorAvailable.value) {
      return 'Sensor tidak tersedia';
    }
    return environmentStatus.value;
  }

  /// Theme color representing the environmental condition
  Color get environmentStatusColor {
    if (!isWatchConnected.value || !isSensorAvailable.value) {
      return AppColors.textMuted;
    }
    switch (environmentStatus.value) {
      case 'Dingin':
        return const Color(0xFF0284C7); // Sky blue
      case 'Normal':
        return AppColors.statusSafe; // Emerald Islamic green
      case 'Panas':
        return const Color(0xFFEA580C); // Warning amber / heat
      default:
        return AppColors.textMuted;
    }
  }

  /// Icon representing the environmental condition
  IconData get environmentStatusIcon {
    if (!isWatchConnected.value || !isSensorAvailable.value) {
      return Icons.sensors_off_rounded;
    }
    switch (environmentStatus.value) {
      case 'Dingin':
        return Icons.ac_unit_rounded;
      case 'Normal':
        return Icons.wb_cloudy_rounded;
      case 'Panas':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.device_thermostat_rounded;
    }
  }

  @override
  void onInit() {
    super.onInit();
    ever<SmartbandConnectionState>(connectionState, (state) {
      isWatchConnected.value = (state == SmartbandConnectionState.connected);
    });
    _setupBleCallbacks();
    _startRelativeTimeTicker();
  }

  void _setupBleCallbacks() {
    // 1. Temperature characteristic received (initial read & notification)
    _bleService.onTemperatureReceived = (val, rawStr) {
      temperature.value = val;
      rawDataString.value = 'Temp: $rawStr';
      receivingData.value = true;
      lastUpdated.value = DateTime.now();
      _evaluateSensorState();
      _updateRelativeTime();
    };

    // 2. Humidity characteristic received (initial read & notification)
    _bleService.onHumidityReceived = (val, rawStr) {
      humidity.value = val;
      rawDataString.value = 'Hum: $rawStr';
      receivingData.value = true;
      lastUpdated.value = DateTime.now();
      _evaluateSensorState();
      _updateRelativeTime();
    };

    // 3. Heat Index characteristic received (initial read & notification)
    _bleService.onHeatIndexReceived = (val, rawStr) {
      heatIndex.value = val;
      rawDataString.value = 'HI: $rawStr';
      receivingData.value = true;
      lastUpdated.value = DateTime.now();
      _evaluateSensorState();
      _updateRelativeTime();
    };

    // 4. Sensor parsing error / corrupted stream
    _bleService.onSensorError = (err) {
      sensorError.value = err;
      debugPrint('[HajiCare Watch] $err');
      _evaluateSensorState();
    };

    // 5. Connection state changes
    _bleService.onConnectionChanged = (connected) {
      isWatchConnected.value = connected;
      if (connected) {
        connectionState.value = SmartbandConnectionState.connected;
        statusMessage.value = 'HajiCare Watch terhubung';
        sensorError.value = null;
      } else {
        // Requirement 7: When ESP32 disconnects
        connectionState.value = SmartbandConnectionState.disconnected;
        statusMessage.value = 'HajiCare Watch terputus';
        receivingData.value = false;
        isSensorAvailable.value = false;
        environmentStatus.value = 'Sensor tidak tersedia';
      }
    };

    _bleService.onStatusLog = (msg) {
      statusMessage.value = msg;
    };
  }

  /// Evaluates reactive sensor availability and condition status
  void _evaluateSensorState() {
    final t = temperature.value;
    final h = humidity.value;

    if (t == null || h == null) {
      // DHT11 data is incomplete or unavailable
      isSensorAvailable.value = false;
      environmentStatus.value = 'Sensor tidak tersedia';
      return;
    }

    // Both temperature and humidity are available
    isSensorAvailable.value = true;
    sensorError.value = null;

    // Use reported Heat Index or calculate fallback
    final hi = heatIndex.value ?? calculateHeatIndex(t, h);
    if (heatIndex.value == null) {
      heatIndex.value = hi;
    }

    environmentStatus.value = determineEnvironmentStatus(
      temperature: t,
      heatIndex: hi,
    );
  }

  void _startRelativeTimeTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRelativeTime();
      _checkSensorTimeout();
    });
  }

  void _checkSensorTimeout() {
    if (!isWatchConnected.value) return;
    final updated = lastUpdated.value;
    if (updated != null &&
        DateTime.now().difference(updated) > const Duration(seconds: 45)) {
      if (isSensorAvailable.value) {
        isSensorAvailable.value = false;
        environmentStatus.value = 'Sensor tidak tersedia';
        sensorError.value = 'Sensor tidak merespon (timeout)';
      }
    }
  }

  void _updateRelativeTime() {
    final updated = lastUpdated.value;
    if (updated == null) {
      relativeTimeStr.value = 'Menunggu data sensor...';
      return;
    }

    final diff = DateTime.now().difference(updated);
    if (diff.inSeconds <= 1) {
      relativeTimeStr.value = 'Diperbarui baru saja';
    } else if (diff.inSeconds < 60) {
      relativeTimeStr.value = 'Diperbarui ${diff.inSeconds} detik lalu';
    } else {
      final minutes = diff.inMinutes;
      relativeTimeStr.value = 'Diperbarui $minutes menit lalu';
    }
  }

  /// Start BLE Scanning and Connection flow (No uncontrolled reconnect loop)
  Future<void> connectSmartband() async {
    if (isBusy) return;
    final generation = ++_connectionGeneration;

    // 1. Check if Bluetooth is enabled
    final isEnabled = await _bleService.isBluetoothEnabled();
    if (isClosed || generation != _connectionGeneration) return;
    if (!isEnabled) {
      AppAlert.warning(
        Get.context,
        title: AppTranslations.tr('smartband.bluetoothInactive'),
        message:
            'Silakan aktifkan Bluetooth pada perangkat Anda untuk menghubungkan HajiCare Watch.',
      );
      return;
    }

    try {
      // 2. Update state to Scanning
      connectionState.value = SmartbandConnectionState.scanning;
      statusMessage.value = 'Mencari HajiCare Watch...';
      receivingData.value = false;
      isSensorAvailable.value = false;

      // 3. Scan for target device
      final device = await _bleService.scanForDevice(
        timeout: const Duration(seconds: 15),
      );
      if (isClosed || generation != _connectionGeneration) return;

      // 4. Update state to Connecting
      connectionState.value = SmartbandConnectionState.connecting;
      statusMessage.value =
          'Menghubungkan ke ${device.platformName.isNotEmpty ? device.platformName : BleService.targetDeviceName}...';
      deviceName.value = device.platformName.isNotEmpty
          ? device.platformName
          : BleService.targetDeviceName;

      // 5. Connect, discover 3 characteristics, read initial values, subscribe notifications
      await _bleService.connectToDevice(device);
    } catch (e) {
      if (isClosed || generation != _connectionGeneration) return;
      isWatchConnected.value = false;
      connectionState.value = SmartbandConnectionState.disconnected;
      statusMessage.value = 'HajiCare Watch belum terhubung';
      receivingData.value = false;
      isSensorAvailable.value = false;
      environmentStatus.value = 'Sensor tidak tersedia';
      sensorError.value = UserFeedbackMessage.from(e);

      AppAlert.error(
        Get.context,
        title: AppTranslations.tr('smartband.bandNotConnected'),
        message: UserFeedbackMessage.from(
          e,
          fallback:
              'Pastikan ESP32 HajiCare Watch menyala dan berada dekat dengan ponsel, lalu coba lagi.',
        ),
        okText: 'Coba Lagi',
      );
    }
  }

  /// Disconnect cleanly from HajiCare Watch without reconnect loop
  Future<void> disconnectSmartband() async {
    await _bleService.disconnect();
    isWatchConnected.value = false;
    connectionState.value = SmartbandConnectionState.disconnected;
    statusMessage.value = 'HajiCare Watch terputus';
    receivingData.value = false;
    isSensorAvailable.value = false;
    environmentStatus.value = 'Menunggu Sensor';
    temperature.value = null;
    humidity.value = null;
    heatIndex.value = null;
    sensorError.value = null;
  }

  @override
  void onClose() {
    _connectionGeneration++;
    _tickerTimer?.cancel();
    unawaited(_bleService.dispose());
    super.onClose();
  }
}
