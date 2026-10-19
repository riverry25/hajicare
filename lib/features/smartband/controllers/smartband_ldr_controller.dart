import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../map/controllers/map_controller.dart';
import '../models/smartband_data.dart';
import '../services/smartband_ble_service.dart';
import '../services/smartband_storage_service.dart';

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

  /// Service penyimpanan data ke local storage
  final SmartbandStorageService _storage = SmartbandStorageService.instance;

  /// Flag bahwa data sudah dimuat dari storage
  final RxBool hasRestoredData = false.obs;

  // ── Observable State - Smartband BLE (ESP32-S3) ───────────────────────────
  final Rx<SmartbandBleStatus> bleStatus = SmartbandBleStatus.disconnected.obs;
  final RxString braceletId = 'HCG-001'.obs;
  final Rxn<int> heartRate = Rxn<int>();
  final Rxn<double> latitude = Rxn<double>();
  final Rxn<double> longitude = Rxn<double>();
  final RxBool isGpsFix = false.obs;
  final Rxn<double> lastKnownLatitude = Rxn<double>();
  final Rxn<double> lastKnownLongitude = Rxn<double>();
  final Rxn<DateTime> lastDataReceivedAt = Rxn<DateTime>();
  final RxString relativeTimeText = 'Belum menerima data'.obs;
  final RxString heartRateStatus = 'Sensor belum tersedia'.obs;
  final RxString errorMessage = ''.obs;

  // ── 5 Modul Hardware Spesifik Telemetri ─────────────────────────────────────
  // 1. MAX30102 (Detak Jantung BPM & Kadar Oksigen SpO2)
  final Rxn<int> maxHeartRate = Rxn<int>();
  final Rxn<int> spo2 = Rxn<int>();

  // 2. MCP9808 (Suhu Tubuh Presisi Tinggi °C)
  final Rxn<double> mcpTemperature = Rxn<double>();

  // 3. MPU6050 (Akselerometer & Giroskop: Langkah & Deteksi Jatuh)
  final RxInt stepCount = 0.obs;
  final RxBool isFallDetected = false.obs;
  final RxInt fallCountdownSeconds = 15.obs;
  final RxDouble gyroRoll = 0.0.obs; // Derajat kemiringan roll (-90 s/d +90)
  final RxDouble gyroPitch = 0.0.obs; // Derajat kemiringan pitch (-90 s/d +90)
  final RxDouble accelG = 1.0.obs; // G-force (1.0 = gravitasi normal)
  final RxInt stabilityScore = 98.obs; // Skor stabilitas tubuh (0 - 100%)
  final RxString postureKey = 'smartband.postureUpright'.obs;

  // 4. GPS NEO-6M (Satelit & Koordinat Presisi)
  final RxInt gpsSatellites = 0.obs;

  // 5. LCD 16x2 + I2C Backpack (Layar Pergelangan Tangan)
  final RxString lcdLine1 = 'HR:--   SpO2:--%'.obs;
  final RxString lcdLine2 = 'STATUS: NORMAL  '.obs;
  final RxString emergencyMessage = ''.obs;

  // 6. Baterai LiPo 3.7V
  final RxInt batteryPercent = 88.obs;
  final RxDouble batteryVoltage = 3.96.obs;
  final RxBool isCharging = false.obs;

  // ── Tombol SOS Fisik Smartband (Interrupt Button) ─────────────────────────
  final RxBool isSosButtonPressed = false.obs;
  final RxBool isSosTransmitted = false.obs;
  DateTime? _lastSosTriggerTime;
  Timer? _sosCountdownTimer;

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
  int get currentSpo2 => spo2.value ?? (isSimulationMode.value ? 98 : 0);
  double get currentTemperature =>
      mcpTemperature.value ?? (isSimulationMode.value ? 36.6 : 36.5);
  int get currentSteps => stepCount.value;
  int get currentBattery => batteryPercent.value;
  String get currentLcdLine1 => lcdLine1.value.isNotEmpty
      ? lcdLine1.value
      : 'HR:${currentHeartRate > 0 ? currentHeartRate.toString().padLeft(3) : " --"} SpO2:${currentSpo2 > 0 ? "$currentSpo2%" : "--%"}';
  String get currentLcdLine2 => lcdLine2.value.isNotEmpty
      ? lcdLine2.value
      : 'T:${currentTemperature.toStringAsFixed(1)}C ST:NORMAL';

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
    _initStorage();
    _subscribeToBleService();
    _startRelativeTimeTicker();
  }

  /// Inisialisasi storage dan muat data tersimpan
  Future<void> _initStorage() async {
    await _storage.init();
    _restoreStoredData();
  }

  /// Muat data terakhir dari local storage ke observable state.
  /// Data ini ditampilkan saat smartband tidak terhubung.
  void _restoreStoredData() {
    final snapshot = _storage.loadStoredData();
    if (!snapshot.hasAnyData) return;

    // Restore vital signs
    if (snapshot.heartRate != null && snapshot.heartRate! > 0) {
      heartRate.value = snapshot.heartRate;
    }
    if (snapshot.spo2 != null && snapshot.spo2! > 0) {
      spo2.value = snapshot.spo2;
    }
    if (snapshot.temperature != null && snapshot.temperature! > 0) {
      mcpTemperature.value = snapshot.temperature;
      temperature.value = snapshot.temperature;
      isSensorAvailable.value = true;
    }

    // Restore steps - data akumulatif tidak boleh hilang
    if (snapshot.stepCount != null && snapshot.stepCount! > 0) {
      stepCount.value = snapshot.stepCount!;
    }

    // Restore GPS last known position
    if (snapshot.lastKnownLatitude != null) {
      lastKnownLatitude.value = snapshot.lastKnownLatitude;
    }
    if (snapshot.lastKnownLongitude != null) {
      lastKnownLongitude.value = snapshot.lastKnownLongitude;
    }

    // Restore battery
    if (snapshot.batteryPercent != null) {
      batteryPercent.value = snapshot.batteryPercent!;
    }
    if (snapshot.batteryVoltage != null) {
      batteryVoltage.value = snapshot.batteryVoltage!;
    }

    // Restore LCD & metadata
    if (snapshot.lcdLine1 != null && snapshot.lcdLine1!.isNotEmpty) {
      lcdLine1.value = snapshot.lcdLine1!;
    }
    if (snapshot.lcdLine2 != null && snapshot.lcdLine2!.isNotEmpty) {
      lcdLine2.value = snapshot.lcdLine2!;
    }
    if (snapshot.braceletId != null && snapshot.braceletId!.isNotEmpty) {
      braceletId.value = snapshot.braceletId!;
    }
    if (snapshot.lastDataReceivedAt != null) {
      lastDataReceivedAt.value = snapshot.lastDataReceivedAt;
      lastUpdated.value = snapshot.lastDataReceivedAt;
    }
    if (snapshot.gpsSatellites != null) {
      gpsSatellites.value = snapshot.gpsSatellites!;
    }
    if (snapshot.gyroRoll != null) gyroRoll.value = snapshot.gyroRoll!;
    if (snapshot.gyroPitch != null) gyroPitch.value = snapshot.gyroPitch!;
    if (snapshot.accelG != null) accelG.value = snapshot.accelG!;
    if (snapshot.stabilityScore != null) {
      stabilityScore.value = snapshot.stabilityScore!;
    }

    hasRestoredData.value = true;
    _updateRelativeTime();
    AppLogger.debug(
      '[SmartbandStorage] Data dipulihkan: HR=${snapshot.heartRate}, '
      'Steps=${snapshot.stepCount}, SpO2=${snapshot.spo2}, '
      'Temp=${snapshot.temperature}',
      tag: 'SmartbandLdr',
    );
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
        // Koordinat dan status GPS tidak di-hardcode ke koordinat statis;
        // status dan koordinat diperoleh secara murni dan dinamis dari paket BLE Smartband
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

    if (data.spo2 != null) {
      spo2.value = data.spo2;
    }
    if (data.temperature != null) {
      mcpTemperature.value = data.temperature;
      temperature.value = data.temperature;
      isSensorAvailable.value = true;
    }
    // 3. MPU6050: Langkah, Orientasi (Roll & Pitch), & G-Force Dinamis
    if (data.stepCount != null) {
      stepCount.value = data.stepCount!;
    }
    if (data.roll != null) gyroRoll.value = data.roll!;
    if (data.pitch != null) gyroPitch.value = data.pitch!;
    if (data.accelG != null) accelG.value = data.accelG!;

    // Hitung skor stabilitas tubuh dan postur dinamis dari orientasi MPU
    final r = (data.roll ?? gyroRoll.value).abs();
    final p = (data.pitch ?? gyroPitch.value).abs();
    final g = (data.accelG ?? accelG.value);
    if (data.fallDetected || r > 55 || p > 55 || g > 2.2) {
      stabilityScore.value = (35 - (r + p) * 0.2).clamp(10, 45).round();
      postureKey.value = 'smartband.postureUnstable';
    } else if (r > 20 || p > 20 || g > 1.35) {
      stabilityScore.value = (80 - (r + p) * 0.4).clamp(50, 84).round();
      postureKey.value = 'smartband.postureTilting';
    } else {
      stabilityScore.value = (100 - (r + p) * 0.45).clamp(86, 100).round();
      postureKey.value = 'smartband.postureUpright';
    }

    // 4. Baterai LiPo 3.7V Dinamis
    if (data.batteryLevel != null) {
      batteryPercent.value = data.batteryLevel!;
    }
    if (data.batteryVoltage != null) {
      batteryVoltage.value = data.batteryVoltage!;
    }
    isCharging.value = data.isCharging;
    if (data.satellites != null) gpsSatellites.value = data.satellites!;

    // GPS NEO-6M Dinamis: Menggunakan koordinat riil satelit dari payload BLE
    if (data.isValidLocation &&
        data.latitude != null &&
        data.longitude != null) {
      latitude.value = data.latitude;
      longitude.value = data.longitude;
      lastKnownLatitude.value = data.latitude;
      lastKnownLongitude.value = data.longitude;
      isGpsFix.value = true;
    } else {
      latitude.value = data.latitude;
      longitude.value = data.longitude;
      isGpsFix.value = data.isValidLocation;
    }

    // LCD 16x2 + I2C Backpack Dinamis
    lcdLine1.value = data.displayLcdLine1;
    lcdLine2.value = data.displayLcdLine2;
    if (data.emergencyMessage != null && data.emergencyMessage!.isNotEmpty) {
      emergencyMessage.value = data.emergencyMessage!;
    }

    if (data.isSos) {
      triggerSosButtonAlert();
    } else if (data.fallDetected) {
      triggerFallAlert();
    }

    lastDataReceivedAt.value = data.timestamp;
    lastUpdated.value = data.timestamp;
    receivingData.value = true;
    rawDataString.value = data.rawJson;
    _updateRelativeTime();

    // Persist data ke local storage agar tidak hilang saat smartband mati
    _storage.saveSmartbandData(data);
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
    // Inisialisasi awal telemetri dinamis 5 modul
    heartRate.value = 76;
    spo2.value = 98;
    mcpTemperature.value = 36.6;
    stepCount.value = 3420;
    gyroRoll.value = 2.4;
    gyroPitch.value = -1.8;
    accelG.value = 1.02;
    stabilityScore.value = 98;
    postureKey.value = 'smartband.postureUpright';
    gpsSatellites.value = 9;
    latitude.value = 21.422487;
    longitude.value = 39.826206;
    lastKnownLatitude.value = 21.422487;
    lastKnownLongitude.value = 39.826206;
    isGpsFix.value = true;
    batteryPercent.value = 88;
    batteryVoltage.value = 3.96;
    isCharging.value = false;
    lcdLine1.value = 'HR: 76  SpO2:98%';
    lcdLine2.value = 'T:36.6C ST:NORMAL';
    lastDataReceivedAt.value = DateTime.now();
    heartRateStatus.value = 'Sensor aktif (Simulasi)';
    _updateTrendDataForPeriod(trendPeriod.value);

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _simPhase += 0.2;

      // 1. MAX30102: Fluktuasi ritmik denyut nadi alami 74 - 82 BPM & SpO2 97% - 99%
      final simHr = (78 + 4 * sin(_simPhase) + (Random().nextInt(3) - 1))
          .round();
      heartRate.value = simHr;
      spo2.value = 97 + Random().nextInt(3);

      // 2. MCP9808: Fluktuasi suhu tubuh presisi 36.5 - 36.7 °C
      final simTemp = 36.6 + 0.1 * sin(_simPhase * 0.5);
      mcpTemperature.value = double.parse(simTemp.toStringAsFixed(1));

      // 3. MPU6050: Ayunan postural saat berjalan & langkah bertambah dinamis
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
        if (Random().nextDouble() > 0.35) {
          stepCount.value += 1;
          // Persist step count secara berkala ke storage
          _storage.saveStepCount(stepCount.value);
        }
      }

      // 4. GPS NEO-6M: Koordinat satelit bergeser alami mengikuti langkah jemaah
      final simLat = 21.422487 + 0.000030 * sin(_simPhase * 0.15);
      final simLng = 39.826206 + 0.000030 * cos(_simPhase * 0.15);
      latitude.value = double.parse(simLat.toStringAsFixed(6));
      longitude.value = double.parse(simLng.toStringAsFixed(6));
      lastKnownLatitude.value = latitude.value;
      lastKnownLongitude.value = longitude.value;
      isGpsFix.value = true;
      gpsSatellites.value = 9 + (sin(_simPhase).abs() > 0.7 ? 1 : 0);

      // 5. LCD 16x2 + I2C Backpack: Sinkronisasi realtime baris 1 & baris 2
      final hrFormatted = simHr.toString().padLeft(3);
      final oxFormatted = '${spo2.value ?? 98}%';
      lcdLine1.value = 'HR:$hrFormatted SpO2:$oxFormatted'
          .padRight(16)
          .substring(0, 16);

      if (isFallDetected.value) {
        lcdLine2.value = '!JATUH DETEKSI !';
      } else if (emergencyMessage.value.isNotEmpty) {
        lcdLine2.value = emergencyMessage.value.padRight(16).substring(0, 16);
      } else {
        final tempFormatted =
            '${(mcpTemperature.value ?? 36.6).toStringAsFixed(1)}C';
        lcdLine2.value = 'T:$tempFormatted ST:NORMAL';
      }

      lastDataReceivedAt.value = DateTime.now();
      _updateRelativeTime();
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    if (bleStatus.value != SmartbandBleStatus.connected) {
      final snapshot = _storage.loadStoredData();
      if (snapshot.hasAnyData) {
        heartRate.value = snapshot.heartRate;
        spo2.value = snapshot.spo2;
        mcpTemperature.value = snapshot.temperature;
        stepCount.value = snapshot.stepCount ?? stepCount.value;
      } else {
        heartRate.value = null;
        spo2.value = null;
        mcpTemperature.value = null;
      }
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
    lcdLine2.value = '!JATUH DETEKSI !';

    _fallCountdownTimer?.cancel();
    _fallCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (fallCountdownSeconds.value > 1) {
        fallCountdownSeconds.value--;
      } else {
        timer.cancel();
        // Trigger auto SOS action ke HP Pendamping & Posko
        dispatchSosToCompanion(reason: 'Deteksi Jatuh (Fall Detection)');
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
    final tempStr = mcpTemperature.value != null
        ? '${mcpTemperature.value!.toStringAsFixed(1)}C'
        : '36.6C';
    lcdLine2.value = 'T:$tempStr ST:NORMAL';
  }

  // ── Tombol SOS Fisik Smartband (Physical SOS Button Interrupt) ─────────────
  /// Dipicu saat tombol SOS pada hardware gelang ditekan
  void triggerSosButtonAlert({bool immediate = false}) {
    final now = DateTime.now();
    if (_lastSosTriggerTime != null &&
        now.difference(_lastSosTriggerTime!).inSeconds < 8 &&
        isSosButtonPressed.value) {
      // Debounce sinyal berulang cepat dari paket BLE notifikasi
      return;
    }
    _lastSosTriggerTime = now;
    isSosButtonPressed.value = true;
    emergencyMessage.value = 'TOMBOL SOS SMARTBAND AKTIF';
    lcdLine2.value = '!TOMBOL SOS!    ';

    // Berikan respons taktil pada smartphone & kirim perintah BUZZ ke gelang
    HapticFeedback.heavyImpact();
    bleService.sendCommand('BUZZ');

    // Meneruskan pesan SOS ke ponsel pendamping
    dispatchSosToCompanion(reason: 'Tombol SOS Smartband Ditekan');
  }

  /// Simulasi penekanan tombol SOS fisik smartband (untuk pengujian & demo)
  void triggerSosSimulation() {
    triggerSosButtonAlert(immediate: true);
  }

  /// Batalkan status darurat tombol SOS smartband
  void cancelSosButtonAlert() {
    _sosCountdownTimer?.cancel();
    _sosCountdownTimer = null;
    isSosButtonPressed.value = false;
    isSosTransmitted.value = false;
    emergencyMessage.value = '';
    final tempStr = mcpTemperature.value != null
        ? '${mcpTemperature.value!.toStringAsFixed(1)}C'
        : '36.6C';
    lcdLine2.value = 'T:$tempStr ST:NORMAL';
  }

  /// Meneruskan pesan darurat SOS ke HP Pendamping via HajiCareController / Firestore
  Future<bool> dispatchSosToCompanion({required String reason}) async {
    AppLogger.info(
      'Memproses transmisi SOS ke HP Pendamping: $reason',
      tag: 'SmartbandLdr',
    );
    isSosTransmitted.value = false;

    if (Get.isRegistered<HajiCareController>()) {
      final hajiCtrl = Get.find<HajiCareController>();

      // Update koordinat GPS jemaah jika tersedia dari satelit NEO-6M
      final lat = latitude.value;
      final lng = longitude.value;
      if (lat != null &&
          lng != null &&
          (lat.abs() > 0.0001 || lng.abs() > 0.0001)) {
        hajiCtrl.myCurrentPosition.value = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      final success = await hajiCtrl.triggerSos();
      if (success) {
        isSosTransmitted.value = true;
        sendEmergencyMessage('SOS TERKIRIM');
        if (Get.context != null) {
          Get.snackbar(
            '🚨 SOS TERKIRIM KE HP PENDAMPING',
            '$reason: Sinyal darurat beserta koordinat lokasi berhasil diteruskan ke ponsel pendamping & posko haji!',
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
        return true;
      } else {
        // Kasus: User belum masuk rombongan pemantauan atau offline
        if (Get.context != null) {
          Get.snackbar(
            '⚠️ Peringatan Darurat Lokal Aktif',
            '$reason terdeteksi! Pastikan telah bergabung ke rombongan agar pendamping menerima notifikasi cloud secara langsung.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.shade800,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.all(16),
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 28,
            ),
          );
        }
        return false;
      }
    } else {
      if (Get.context != null) {
        Get.snackbar(
          '🚨 SOS DARURAT TERDETEKSI',
          '$reason: Sistem darurat lokal aktif.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.statusDanger,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
        );
      }
      return false;
    }
  }

  /// Kirim / perbarui pesan darurat ke layar LCD 16x2 Smartband
  void sendEmergencyMessage(String message) {
    emergencyMessage.value = message;
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      final tempStr = mcpTemperature.value != null
          ? '${mcpTemperature.value!.toStringAsFixed(1)}C'
          : '36.6C';
      lcdLine2.value = 'T:$tempStr ST:NORMAL';
    } else {
      lcdLine2.value = trimmed.padRight(16).substring(0, 16);
    }
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
    _sosCountdownTimer?.cancel();
    _tickerTimer?.cancel();
    _bleStatusSub?.cancel();
    _bleDataSub?.cancel();
    _bleMessageSub?.cancel();
    super.onClose();
  }

  /// Hapus semua data tersimpan di local storage (misal: logout/reset gelang)
  Future<void> clearStoredData() async {
    await _storage.clearAll();
    hasRestoredData.value = false;
    AppLogger.debug(
      '[SmartbandStorage] Semua data tersimpan dihapus.',
      tag: 'SmartbandLdr',
    );
  }
}
