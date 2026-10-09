import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../map/controllers/map_controller.dart';
import '../models/smartband_data.dart';
import '../services/smartband_ble_service.dart';

enum SmartbandConnectionState { disconnected, scanning, connecting, connected }

class SmartbandLdrController extends GetxController {
  final SmartbandBleService bleService;

  SmartbandLdrController({SmartbandBleService? bleService})
    : bleService =
          bleService ??
          (Get.isRegistered<SmartbandBleService>()
              ? Get.find<SmartbandBleService>()
              : SmartbandBleService());

  /// Koordinat GPS statis Smartband (Pelataran Masjidil Haram, Makkah)
  static const double staticGpsLatitude = 21.422487;
  static const double staticGpsLongitude = 39.826206;

  // ── Observable State - Smartband BLE (ESP32-S3) ───────────────────────────
  final Rx<SmartbandBleStatus> bleStatus = SmartbandBleStatus.disconnected.obs;
  final RxString braceletId = 'HCG-001'.obs;
  final Rxn<int> heartRate = Rxn<int>();
  final Rxn<double> latitude = Rxn<double>(staticGpsLatitude);
  final Rxn<double> longitude = Rxn<double>(staticGpsLongitude);
  final RxBool isGpsFix = true.obs;
  final Rxn<double> lastKnownLatitude = Rxn<double>(staticGpsLatitude);
  final Rxn<double> lastKnownLongitude = Rxn<double>(staticGpsLongitude);
  final Rxn<DateTime> lastDataReceivedAt = Rxn<DateTime>();
  final RxString relativeTimeText = 'Belum menerima data'.obs;
  final RxString heartRateStatus = 'Sensor belum tersedia'.obs;
  final RxString errorMessage = ''.obs;

  // ── Observable State - Legacy / Generic Connection ────────────────────────
  final isWatchConnected = false.obs;
  final connectionState = SmartbandConnectionState.disconnected.obs;
  final statusMessage = 'Gelang Belum Terhubung'.obs;
  final deviceName = 'HajiCare-Gelang-001'.obs;
  final receivingData = false.obs;
  final lastUpdated = Rxn<DateTime>();
  final rawDataString = '-'.obs;
  final relativeTimeStr = ''.obs;

  // ── Observable State - DHT11 (Preserved for backwards compatibility) ───────
  final temperature = Rxn<double>();
  final humidity = Rxn<double>();
  final heatIndex = Rxn<double>();
  final isSensorAvailable = false.obs;
  final sensorError = Rxn<String>();
  final environmentStatus = 'Menunggu Sensor'.obs;

  Timer? _tickerTimer;
  StreamSubscription<SmartbandBleStatus>? _bleStatusSub;
  StreamSubscription<SmartbandData>? _bleDataSub;
  StreamSubscription<String>? _bleMessageSub;

  // Getters
  bool get isConnected => bleStatus.value == SmartbandBleStatus.connected;
  bool get isScanning => bleStatus.value == SmartbandBleStatus.scanning;
  bool get isConnecting => bleStatus.value == SmartbandBleStatus.connecting;
  bool get isBusy => isScanning || isConnecting;

  /// Calculates Heat Index (°C) - Preserved for tests
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

  /// Determines environmental condition - Preserved for tests
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

  String get formattedTemperature {
    if (!isWatchConnected.value ||
        !isSensorAvailable.value ||
        temperature.value == null) {
      return '-';
    }
    return '${temperature.value!.toStringAsFixed(1)} °C';
  }

  String get formattedHumidity {
    if (!isWatchConnected.value ||
        !isSensorAvailable.value ||
        humidity.value == null) {
      return '-';
    }
    return '${humidity.value!.round()} %';
  }

  String get formattedHeatIndex {
    if (!isWatchConnected.value ||
        !isSensorAvailable.value ||
        heatIndex.value == null) {
      return '-';
    }
    return '${heatIndex.value!.toStringAsFixed(1)} °C';
  }

  String get environmentStatusLabel {
    if (!isWatchConnected.value) {
      return '-';
    }
    if (!isSensorAvailable.value) {
      return 'Sensor tidak tersedia';
    }
    return environmentStatus.value;
  }

  Color get environmentStatusColor {
    if (!isWatchConnected.value || !isSensorAvailable.value) {
      return AppColors.textMuted;
    }
    switch (environmentStatus.value) {
      case 'Dingin':
        return const Color(0xFF0284C7);
      case 'Normal':
        return AppColors.statusSafe;
      case 'Panas':
        return const Color(0xFFEA580C);
      default:
        return AppColors.textMuted;
    }
  }

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
    _subscribeToBleService();
    _startRelativeTimeTicker();
  }

  void _subscribeToBleService() {
    bleStatus.value = bleService.currentStatus;
    _syncLegacyState(bleService.currentStatus);

    _bleStatusSub = bleService.connectionStateStream.listen((status) {
      bleStatus.value = status;
      _syncLegacyState(status);

      if (status == SmartbandBleStatus.connected) {
        errorMessage.value = '';
        statusMessage.value = 'Gelang Terhubung';
        isGpsFix.value = true;
        latitude.value = staticGpsLatitude;
        longitude.value = staticGpsLongitude;
        lastKnownLatitude.value = staticGpsLatitude;
        lastKnownLongitude.value = staticGpsLongitude;
      } else if (status == SmartbandBleStatus.disconnected) {
        statusMessage.value = 'Gelang Belum Terhubung';
        isGpsFix.value = false;
        heartRateStatus.value = 'Sensor belum tersedia';
      } else if (status == SmartbandBleStatus.scanning) {
        statusMessage.value = 'Memindai sinyal gelang...';
      } else if (status == SmartbandBleStatus.connecting) {
        statusMessage.value = 'Menghubungkan ke Smartband...';
      }
    });

    _bleDataSub = bleService.receivedSmartbandData.listen((data) {
      _processSmartbandData(data);
    });

    _bleMessageSub = bleService.statusMessageStream.listen((msg) {
      AppLogger.debug(msg, tag: 'SmartbandLdr');
    });
  }

  void _syncLegacyState(SmartbandBleStatus status) {
    switch (status) {
      case SmartbandBleStatus.connected:
        isWatchConnected.value = true;
        connectionState.value = SmartbandConnectionState.connected;
        break;
      case SmartbandBleStatus.scanning:
        isWatchConnected.value = false;
        connectionState.value = SmartbandConnectionState.scanning;
        break;
      case SmartbandBleStatus.connecting:
        isWatchConnected.value = false;
        connectionState.value = SmartbandConnectionState.connecting;
        break;
      case SmartbandBleStatus.disconnected:
        isWatchConnected.value = false;
        connectionState.value = SmartbandConnectionState.disconnected;
        break;
    }
  }

  void _processSmartbandData(SmartbandData data) {
    // 1. Data Dinamis dari BLE (Heart Rate, Bracelet ID)
    braceletId.value = data.braceletId;
    heartRate.value = data.heartRate;

    // Evaluasi status Heart Rate (MAX30102) secara dinamis
    if (data.heartRate == 0) {
      heartRateStatus.value = 'Mengukur... Tempelkan jari';
    } else {
      heartRateStatus.value = 'Sensor aktif';
    }

    // 2. Data GPS Statis (Hanya GPS yang statis, data lainnya dinamis dari BLE)
    latitude.value = staticGpsLatitude;
    longitude.value = staticGpsLongitude;
    lastKnownLatitude.value = staticGpsLatitude;
    lastKnownLongitude.value = staticGpsLongitude;
    isGpsFix.value = true;

    // 3. Status Waktu & Raw Telemetri Dinamis dari BLE
    lastDataReceivedAt.value = data.timestamp;
    lastUpdated.value = data.timestamp;
    receivingData.value = true;
    rawDataString.value = data.rawJson;
    _updateRelativeTime();
  }

  /// Hubungkan ke Smartband dengan memindai BLE dan auto-connect
  Future<void> connectSmartband() async {
    errorMessage.value = '';
    try {
      await bleService.scanSmartband(autoConnect: true);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = msg;
      if (Get.context != null) {
        Get.snackbar(
          'Koneksi Smartband',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.statusDanger.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(
            Icons.bluetooth_disabled_rounded,
            color: Colors.white,
          ),
        );
      }
    }
  }

  /// Putuskan koneksi dari Smartband secara aman
  Future<void> disconnectSmartband() async {
    errorMessage.value = '';
    try {
      await bleService.disconnectSmartband();
    } catch (e) {
      errorMessage.value = 'Gagal memutuskan: $e';
    }
  }

  /// Buka tampilan Peta dan pusatkan ke lokasi Smartband
  void navigateToMap(BuildContext context) {
    final lat = latitude.value ?? lastKnownLatitude.value;
    final lng = longitude.value ?? lastKnownLongitude.value;

    if (lat != null && lng != null) {
      if (Get.isRegistered<MapController>()) {
        final mapCtrl = Get.find<MapController>();
        mapCtrl.focusCoordinate(LatLng(lat, lng), destZoom: 17.0);
      }
      Get.toNamed(AppRoutes.interactiveMap);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Koordinat GPS Smartband belum tersedia. Menunggu sinyal GPS FIX.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _startRelativeTimeTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRelativeTime();
    });
  }

  void _updateRelativeTime() {
    final timestamp = lastDataReceivedAt.value;
    if (timestamp == null) {
      relativeTimeText.value = 'Belum menerima data';
      relativeTimeStr.value = '';
      return;
    }

    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 5) {
      relativeTimeText.value = 'Baru saja';
    } else if (diff.inSeconds < 60) {
      relativeTimeText.value = '${diff.inSeconds} detik lalu';
    } else if (diff.inMinutes < 60) {
      relativeTimeText.value = '${diff.inMinutes} menit lalu';
    } else {
      relativeTimeText.value = '${diff.inHours} jam lalu';
    }
    relativeTimeStr.value = relativeTimeText.value;
  }

  @override
  void onClose() {
    _tickerTimer?.cancel();
    _bleStatusSub?.cancel();
    _bleDataSub?.cancel();
    _bleMessageSub?.cancel();
    super.onClose();
  }
}
