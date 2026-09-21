import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../services/ble_service.dart';

enum SmartbandConnectionState { disconnected, scanning, connecting, connected }

class SmartbandLdrController extends GetxController {
  final BleService _bleService = BleService();

  // Observable state - LDR
  final ldrValue = 0.obs;
  final rawDataString = '-'.obs;
  final connectionState = SmartbandConnectionState.disconnected.obs;
  final receivingData = false.obs;
  final lastUpdated = Rxn<DateTime>();
  final statusMessage = 'Gelang belum terhubung'.obs;
  final serviceDiscovered = false.obs;
  final characteristicDiscovered = false.obs;
  final deviceName = 'HajiCare Watch'.obs;

  // Observable state - Flame Sensor
  final flameDetected = false.obs;
  final flameRawData = ''.obs;
  final flameReceivingData = false.obs;
  final flameLastUpdated = Rxn<DateTime>();

  // Flag untuk mendeteksi transisi perubahan status SAFE -> FIRE
  bool _previousFlameAlertTriggered = false;
  int _connectionGeneration = 0;

  // Relative time updater tickers
  Timer? _tickerTimer;
  final relativeTimeStr = ''.obs;
  final flameRelativeTimeStr = ''.obs;

  // Convenient getters
  bool get isConnected =>
      connectionState.value == SmartbandConnectionState.connected;
  bool get isScanning =>
      connectionState.value == SmartbandConnectionState.scanning;
  bool get isConnecting =>
      connectionState.value == SmartbandConnectionState.connecting;
  bool get isBusy => isScanning || isConnecting;

  /// Status cahaya prototype:
  /// 0 - 999    : Gelap
  /// 1000 - 2499: Redup
  /// 2500+      : Terang
  String get lightStatus {
    if (!isConnected || (!receivingData.value && ldrValue.value == 0)) {
      return '-';
    }

    final val = ldrValue.value;

    if (val >= 3000) {
      return 'Gelap';
    } else if (val >= 1000) {
      return 'Redup';
    } else {
      return 'Terang';
    }
  }

  /// Color corresponding to the light intensity
  Color get lightStatusColor {
    final status = lightStatus;
    switch (status) {
      case 'Gelap':
        return const Color(0xFF6B7280); // Slate gray
      case 'Redup':
        return const Color(0xFFE68A2E); // Warm amber
      case 'Terang':
        return const Color(0xFFD4A857); // Glowing Mecca gold
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData get lightStatusIcon {
    final status = lightStatus;
    switch (status) {
      case 'Gelap':
        return Icons.nightlight_round;
      case 'Redup':
        return Icons.wb_twilight_rounded;
      case 'Terang':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.light_mode_outlined;
    }
  }

  /// Persentase kecerahan berdasarkan ADC 12-bit ESP32 (0 - 4095)
  /// ADC 4095 (sangat gelap) -> 0%
  /// ADC 0 (sangat terang) -> 100%
  double get brightnessPercentage {
    final value = ((4095 - ldrValue.value) / 4095.0) * 100.0;
    return value.clamp(0.0, 100.0);
  }

  /// Format persentase kecerahan untuk UI (contoh: "88%")
  String get formattedBrightnessPercentage {
    if (!isConnected && ldrValue.value == 0) {
      return '-';
    }
    return '${brightnessPercentage.round()}%';
  }

  /// Number format with Indonesian thousands separator (e.g. 2847 -> 2.847, 712 -> 712)
  String get formattedLdrValue {
    if (!isConnected && ldrValue.value == 0) {
      return '-';
    }
    return ldrValue.value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  void onInit() {
    super.onInit();
    _setupBleCallbacks();
    _startRelativeTimeTicker();
  }

  void _setupBleCallbacks() {
    _bleService.onDataReceived = (val, rawStr) {
      ldrValue.value = val;
      rawDataString.value = rawStr;
      receivingData.value = true;
      lastUpdated.value = DateTime.now();
      _updateRelativeTime();
    };

    _bleService.onFlameDataReceived = (isFire, rawStr) {
      flameDetected.value = isFire;
      flameRawData.value = rawStr;
      flameReceivingData.value = true;
      flameLastUpdated.value = DateTime.now();
      _updateFlameRelativeTime();

      // Trigger alert dialog HANYA ketika transisi dari SAFE -> FIRE
      if (isFire && !_previousFlameAlertTriggered) {
        _previousFlameAlertTriggered = true;
        AppAlert.warning(
          Get.context,
          title: 'Peringatan Api',
          message:
              'Sensor mendeteksi indikasi api di sekitar Anda! Harap waspada dan segera periksa kondisi sekitar.',
          okText: 'Mengerti',
        );
      } else if (!isFire && _previousFlameAlertTriggered) {
        // Reset trigger flag saat status kembali normal (SAFE)
        _previousFlameAlertTriggered = false;
      }
    };

    _bleService.onConnectionChanged = (connected) {
      if (connected) {
        connectionState.value = SmartbandConnectionState.connected;
        statusMessage.value = 'Gelang terhubung';
        serviceDiscovered.value = true;
        characteristicDiscovered.value = true;
      } else {
        connectionState.value = SmartbandConnectionState.disconnected;
        statusMessage.value = 'Gelang belum terhubung';
        receivingData.value = false;
        flameReceivingData.value = false;
        _previousFlameAlertTriggered = false;
        serviceDiscovered.value = false;
        characteristicDiscovered.value = false;
      }
    };

    _bleService.onStatusLog = (msg) {
      statusMessage.value = msg;
    };
  }

  void _startRelativeTimeTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRelativeTime();
      _updateFlameRelativeTime();
    });
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

  void _updateFlameRelativeTime() {
    final updated = flameLastUpdated.value;
    if (updated == null) {
      flameRelativeTimeStr.value = 'Menunggu data sensor...';
      return;
    }

    final diff = DateTime.now().difference(updated);
    if (diff.inSeconds <= 1) {
      flameRelativeTimeStr.value = 'Diperbarui baru saja';
    } else if (diff.inSeconds < 60) {
      flameRelativeTimeStr.value = 'Diperbarui ${diff.inSeconds} detik lalu';
    } else {
      final minutes = diff.inMinutes;
      flameRelativeTimeStr.value = 'Diperbarui $minutes menit lalu';
    }
  }

  /// Start BLE Scanning and Connection flow
  Future<void> connectSmartband() async {
    if (isBusy) return;
    final generation = ++_connectionGeneration;

    // 1. Check if Bluetooth is enabled
    final isEnabled = await _bleService.isBluetoothEnabled();
    if (isClosed || generation != _connectionGeneration) return;
    if (!isEnabled) {
      AppAlert.warning(
        Get.context,
        title: 'Bluetooth Tidak Aktif',
        message:
            'Silakan aktifkan Bluetooth pada perangkat Anda untuk menghubungkan gelang.',
      );
      return;
    }

    try {
      // 2. Update state to Scanning
      connectionState.value = SmartbandConnectionState.scanning;
      statusMessage.value = 'Mencari gelang HajiCare...';
      receivingData.value = false;
      flameReceivingData.value = false;

      // 3. Scan for target device
      final device = await _bleService.scanForDevice(
        timeout: const Duration(seconds: 15),
      );
      if (isClosed || generation != _connectionGeneration) return;

      // 4. Update state to Connecting
      connectionState.value = SmartbandConnectionState.connecting;
      statusMessage.value = 'Menghubungkan...';
      deviceName.value = device.platformName.isNotEmpty
          ? device.platformName
          : BleService.targetDeviceName;

      // 5. Connect, discover service & characteristic, subscribe
      await _bleService.connectToDevice(device);
    } catch (e) {
      if (isClosed || generation != _connectionGeneration) return;
      connectionState.value = SmartbandConnectionState.disconnected;
      statusMessage.value = 'Gelang belum terhubung';
      receivingData.value = false;
      flameReceivingData.value = false;

      AppAlert.error(
        Get.context,
        title: 'Gelang Belum Terhubung',
        message: UserFeedbackMessage.from(
          e,
          fallback:
              'Pastikan gelang menyala dan berada dekat dengan ponsel, lalu coba lagi.',
        ),
        okText: 'Coba Lagi',
      );
    }
  }

  /// Disconnect smartband cleanly
  Future<void> disconnectSmartband() async {
    await _bleService.disconnect();
    connectionState.value = SmartbandConnectionState.disconnected;
    statusMessage.value = 'Gelang terputus';
    receivingData.value = false;
    flameReceivingData.value = false;
    _previousFlameAlertTriggered = false;
  }

  @override
  void onClose() {
    _connectionGeneration++;
    _tickerTimer?.cancel();
    unawaited(_bleService.dispose());
    super.onClose();
  }
}
