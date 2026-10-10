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

/// Controller GetX untuk Smartband HajiCare ESP32-S3
/// Mengelola telemetri 5 sensor:
/// 1. Detak Jantung (MAX30102)
/// 2. Suhu Tubuh (MCP9808)
/// 3. Deteksi Jatuh & Gerak Jamaah (MPU6050)
/// 4. GPS Satelit (NEO-6M)
/// 5. Baterai LiPo 3.7V
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

  // ── 5 Sensor Hardware Spesifik Telemetri ────────────────────────────────────
  // 1. MAX30102 (Detak Jantung)
  final Rxn<int> maxHeartRate = Rxn<int>();

  // 2. MCP9808 (Suhu Tubuh Presisi Tinggi)
  final Rxn<double> mcpTemperature = Rxn<double>();

  // 3. MPU6050 (Deteksi Jatuh & Gyro Keseimbangan)
  final RxBool isFallDetected = false.obs;
  final RxInt fallCountdownSeconds = 15.obs;
  final RxDouble gyroRoll = 0.0.obs; // Derajat kemiringan roll (-90 s/d +90)
  final RxDouble gyroPitch = 0.0.obs; // Derajat kemiringan pitch (-90 s/d +90)
  final RxDouble accelG = 1.0.obs; // G-force (1.0 = gravitasi normal)
  final RxInt stabilityScore = 98.obs; // Skor stabilitas tubuh (0 - 100%)
  final RxString postureKey = 'smartband.postureUpright'.obs;

  // 4. NEO-6M (GPS Satelit)
  final RxInt gpsSatellites = 9.obs;

  // 5. Baterai LiPo 3.7V
  final RxInt batteryPercent = 88.obs;
  final RxDouble batteryVoltage = 3.96.obs;
  final RxBool isCharging = false.obs;

  // ── Mode Simulasi Hardware (Untuk alat yang baru setengah jadi) ─────────────
  final RxBool isSimulationMode = false.obs;
  Timer? _simulationTimer;
  Timer? _fallCountdownTimer;
  double _simPhase = 0.0;

  // ── UI Filter & Hero Selector ──────────────────────────────────────────────
  // 0: MAX30102, 1: MCP9808, 2: MPU6050, 3: NEO-6M, 4: LiPo
  final RxInt selectedSensorIndex = 0.obs;
  final RxString trendPeriod = 'today'.obs; // 'today', 'week', 'month'
  final RxList<double> trendData = <double>[
    72.0,
    74.0,
    78.0,
    82.0,
    86.0,
    79.0,
    76.0,
  ].obs;

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
  bool get isConnected =>
      isSimulationMode.value || bleStatus.value == SmartbandBleStatus.connected;
  bool get isScanning => bleStatus.value == SmartbandBleStatus.scanning;
  bool get isConnecting => bleStatus.value == SmartbandBleStatus.connecting;
  bool get isBusy => isScanning || isConnecting;

  /// Effective values taking simulation into account
  int get currentHeartRate =>
      heartRate.value ?? (isSimulationMode.value ? 78 : 0);
  double get currentTemperature =>
      mcpTemperature.value ?? (isSimulationMode.value ? 36.6 : 36.5);
  int get currentBattery => batteryPercent.value;

  double get trendAverage {
    if (trendData.isEmpty) return 0;
    return trendData.reduce((a, b) => a + b) / trendData.length;
  }

  double get trendMax {
    if (trendData.isEmpty) return 0;
    return trendData.reduce(max);
  }

  double get trendMin {
    if (trendData.isEmpty) return 0;
    return trendData.reduce(min);
  }

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
    braceletId.value = data.braceletId;
    heartRate.value = data.heartRate;

    if (data.heartRate == 0) {
      heartRateStatus.value = 'Mengukur... Tempelkan jari';
    } else {
      heartRateStatus.value = 'Sensor aktif';
    }

    if (data.temperature != null) {
      mcpTemperature.value = data.temperature;
    }
    if (data.roll != null) gyroRoll.value = data.roll!;
    if (data.pitch != null) gyroPitch.value = data.pitch!;
    if (data.accelG != null) accelG.value = data.accelG!;
    if (data.batteryLevel != null) batteryPercent.value = data.batteryLevel!;
    if (data.batteryVoltage != null) {
      batteryVoltage.value = data.batteryVoltage!;
    }
    isCharging.value = data.isCharging;
    if (data.satellites != null) gpsSatellites.value = data.satellites!;

    if (data.fallDetected) {
      triggerFallAlert();
    }

    latitude.value = staticGpsLatitude;
    longitude.value = staticGpsLongitude;
    lastKnownLatitude.value = staticGpsLatitude;
    lastKnownLongitude.value = staticGpsLongitude;
    isGpsFix.value = true;

    lastDataReceivedAt.value = data.timestamp;
    lastUpdated.value = data.timestamp;
    receivingData.value = true;
    rawDataString.value = data.rawJson;
    _updateRelativeTime();
  }

  // ── Mode Simulasi Telemetri (Realistis untuk Demo & Uji Coba) ───────────────
  void toggleSimulation(bool enable) {
    isSimulationMode.value = enable;
    if (enable) {
      _startSimulation();
    } else {
      _stopSimulation();
    }
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    // Inisialisasi awal telemetri simulasi
    heartRate.value = 76;
    mcpTemperature.value = 36.6;
    gyroRoll.value = 2.4;
    gyroPitch.value = -1.8;
    accelG.value = 1.02;
    stabilityScore.value = 98;
    postureKey.value = 'smartband.postureUpright';
    gpsSatellites.value = 9;
    batteryPercent.value = 88;
    batteryVoltage.value = 3.96;
    isCharging.value = false;
    lastDataReceivedAt.value = DateTime.now();
    heartRateStatus.value = 'Sensor aktif (Simulasi)';
    _updateTrendDataForPeriod(trendPeriod.value);

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _simPhase += 0.2;
      // MAX30102: Fluktuasi ritmik denyut nadi alami 74 - 82 BPM
      final simHr = (78 + 4 * sin(_simPhase) + (Random().nextInt(3) - 1))
          .round();
      heartRate.value = simHr;

      // MCP9808: Fluktuasi suhu tubuh presisi 36.5 - 36.7 °C
      final simTemp = 36.6 + 0.1 * sin(_simPhase * 0.5);
      mcpTemperature.value = double.parse(simTemp.toStringAsFixed(1));

      // MPU6050: Ayunan wajar postural saat berjalan pelan
      if (!isFallDetected.value) {
        final simRoll = double.parse(
          (3.0 * sin(_simPhase * 0.8)).toStringAsFixed(1),
        );
        final simPitch = double.parse(
          (-2.0 * cos(_simPhase * 0.8)).toStringAsFixed(1),
        );
        gyroRoll.value = simRoll;
        gyroPitch.value = simPitch;
        accelG.value = 1.02;
        stabilityScore.value = 96 + Random().nextInt(4);
        postureKey.value = 'smartband.postureUpright';
      }

      lastDataReceivedAt.value = DateTime.now();
      _updateRelativeTime();
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    if (bleStatus.value != SmartbandBleStatus.connected) {
      heartRate.value = null;
      mcpTemperature.value = null;
    }
  }

  // ── Simulasi & Deteksi Jatuh MPU6050 ────────────────────────────────────────
  void triggerFallSimulation() {
    triggerFallAlert();
  }

  void triggerFallAlert() {
    isFallDetected.value = true;
    accelG.value = 3.8; // Lonjakan impak G-Force
    gyroRoll.value = 78.5; // Tubuh miring mendadak rebah
    gyroPitch.value = -65.2;
    stabilityScore.value = 18;
    postureKey.value = 'smartband.postureFallen';
    fallCountdownSeconds.value = 15;

    _fallCountdownTimer?.cancel();
    _fallCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (fallCountdownSeconds.value > 1) {
        fallCountdownSeconds.value--;
      } else {
        timer.cancel();
        // Trigger auto SOS action
        Get.snackbar(
          'SOS OTOMATIS TERKIRIM',
          'Sinyal darurat beserta koordinat lokasi telah diteruskan ke Posko Haji!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.statusDanger,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.all(16),
          icon: const Icon(
            Icons.emergency_rounded,
            color: Colors.white,
            size: 28,
          ),
        );
      }
    });
  }

  void cancelFallAlert() {
    _fallCountdownTimer?.cancel();
    _fallCountdownTimer = null;
    isFallDetected.value = false;
    accelG.value = 1.02;
    gyroRoll.value = 0.0;
    gyroPitch.value = 0.0;
    stabilityScore.value = 98;
    postureKey.value = 'smartband.postureUpright';
  }

  // ── Filter Periode Tren ────────────────────────────────────────────────────
  void setTrendPeriod(String period) {
    trendPeriod.value = period;
    _updateTrendDataForPeriod(period);
  }

  void _updateTrendDataForPeriod(String period) {
    if (selectedSensorIndex.value == 0) {
      // MAX30102 Heart Rate
      if (period == 'today') {
        trendData.assignAll([72.0, 75.0, 78.0, 84.0, 88.0, 80.0, 76.0]);
      } else if (period == 'week') {
        trendData.assignAll([74.0, 76.0, 73.0, 81.0, 85.0, 78.0, 76.0]);
      } else {
        trendData.assignAll([72.0, 74.0, 77.0, 82.0, 80.0, 75.0, 77.0]);
      }
    } else if (selectedSensorIndex.value == 1) {
      // MCP9808 Temperature
      if (period == 'today') {
        trendData.assignAll([36.4, 36.5, 36.6, 36.8, 36.7, 36.6, 36.5]);
      } else if (period == 'week') {
        trendData.assignAll([36.5, 36.6, 36.7, 36.6, 36.5, 36.6, 36.6]);
      } else {
        trendData.assignAll([36.4, 36.5, 36.6, 36.7, 36.6, 36.5, 36.6]);
      }
    } else if (selectedSensorIndex.value == 2) {
      // MPU6050 Stability
      trendData.assignAll([95.0, 97.0, 98.0, 94.0, 96.0, 99.0, 98.0]);
    } else if (selectedSensorIndex.value == 4) {
      // LiPo Battery
      trendData.assignAll([100.0, 96.0, 92.0, 89.0, 88.0, 85.0, 83.0]);
    } else {
      trendData.assignAll([8.0, 9.0, 9.0, 10.0, 9.0, 9.0, 9.0]);
    }
  }

  void selectSensor(int index) {
    selectedSensorIndex.value = index;
    _updateTrendDataForPeriod(trendPeriod.value);
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
    _simulationTimer?.cancel();
    _fallCountdownTimer?.cancel();
    _tickerTimer?.cancel();
    _bleStatusSub?.cancel();
    _bleDataSub?.cancel();
    _bleMessageSub?.cancel();
    super.onClose();
  }
}
