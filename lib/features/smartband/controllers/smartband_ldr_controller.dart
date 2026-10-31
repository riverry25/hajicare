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

/// Controller GetX untuk Smartband HajiCare ESP32-S3 Pro v2.0
/// Mengelola telemetri dinamis murni dari sensor:
/// 1. MAX30102: Detak Jantung (BPM) & Sensor Sentuhan Kulit (fingerDetected)
/// 2. DFRobot MCP9808: Suhu Sensor Presisi Tinggi (\u00B0C)
/// 3. MPU6050: Motion totalG, Kemiringan (Roll/Pitch), & Deteksi Jatuh (fallStatus)
/// 4. GPS ATGM336H: Satelit, Status Fix, & Koordinat (latitude, longitude)
/// 5. Action Button: Manual SOS (3 Detik) & Batal Alarm
/// 6. Dynamic Safe Radius: Jarak (m), Batas Radius (m), Peringatan Radius (radiusAlert)
class SmartbandLdrController extends GetxController {
  final SmartbandBleService bleService;

  SmartbandLdrController({SmartbandBleService? bleService})
    : bleService =
          bleService ??
          (Get.isRegistered<SmartbandBleService>()
              ? Get.find<SmartbandBleService>()
              : SmartbandBleService());

  /// Service penyimpanan data ke local storage
  final SmartbandStorageService _storage = SmartbandStorageService.instance;

  /// Flag bahwa data riwayat pernah dimuat dari storage
  final RxBool hasRestoredData = false.obs;

  // Observable State - Smartband BLE (ESP32-S3)
  final Rx<SmartbandBleStatus> bleStatus = SmartbandBleStatus.disconnected.obs;
  final RxString braceletId = 'HCG-001'.obs;
  final Rxn<DateTime> lastDataReceivedAt = Rxn<DateTime>();
  final RxString relativeTimeText = 'Belum menerima data'.obs;
  final RxString heartRateStatus = 'Sensor belum tersedia'.obs;
  final RxString errorMessage = ''.obs;

  // 1. MAX30102: Detak Jantung BPM & Kontak Kulit
  final Rxn<int> heartRate = Rxn<int>();
  final RxBool fingerDetected = false.obs;
  final Rxn<int> spo2 = Rxn<int>();

  // 2. DFRobot MCP9808: Suhu Sensor (\u00B0C)
  final Rxn<double> mcpTemperature = Rxn<double>();

  // 3. MPU6050: Akselerometer totalG & Deteksi Jatuh
  final Rxn<double> accelG = Rxn<double>();
  final RxDouble gyroRoll = 0.0.obs;
  final RxDouble gyroPitch = 0.0.obs;
  final RxString fallStatus = 'UNAVAILABLE'.obs;
  final RxBool isFallDetected = false.obs;
  final RxInt fallCountdownSeconds = 15.obs;
  final Rxn<int> stabilityScore = Rxn<int>();
  final RxString postureKey = 'smartband.postureUpright'.obs;

  // 4. GPS ATGM336H: Satelit & Koordinat
  final Rxn<int> gpsSatellites = Rxn<int>();
  final RxBool isGpsFix = false.obs;
  final Rxn<double> latitude = Rxn<double>();
  final Rxn<double> longitude = Rxn<double>();
  final Rxn<double> lastKnownLatitude = Rxn<double>();
  final Rxn<double> lastKnownLongitude = Rxn<double>();

  // 5. Dynamic Safe Radius
  final RxDouble safeRadiusMeters = 50.0.obs;
  final RxDouble activeSafeRadius = 200.0.obs;
  final Rxn<double> currentDistanceM = Rxn<double>();
  final RxDouble currentDistanceToPosko = 0.0.obs;
  final RxBool isOutsideSafeRadius = false.obs;
  final RxString safeRadiusStatusLabel = 'Di Dalam Radius Aman'.obs;
  final RxBool radiusAlertActive = false.obs;

  /// Panjang rata-rata per langkah jamaah dewasa: 0.70 meter (70 cm)
  static const double strideLengthMeters = 0.70;

  /// Jumlah langkah sesi aktif (dihitung sejak gelang tersambung / reset)
  final RxInt sessionSteps = 0.obs;

  DateTime _lastStepAt = DateTime.now();
  bool _stepPeak = false;

  // 6. Action Button / SOS & Haptic
  final RxBool isSosButtonPressed = false.obs;
  final RxBool isSosTransmitted = false.obs;
  final RxString emergencyMessage = ''.obs;
  DateTime? _lastSosTriggerTime;
  Timer? _fallCountdownTimer;
  Timer? _sosCountdownTimer;
  Timer? _safeRadiusWatcherTimer;

  // 7. Status Tampilan OLED (Halaman Aktif 0-4)
  // 0:HR, 1:GPS, 2:Temp, 3:Motion, 4:Safe Radius
  final RxInt oledPage = 0.obs;
  final RxString lcdLine1 = 'HR:--   SpO2:--%'.obs;
  final RxString lcdLine2 = 'STATUS: NORMAL  '.obs;
  RxString get oledLine1 => lcdLine1;
  RxString get oledLine2 => lcdLine2;
  String get currentLcdLine1 => lcdLine1.value;
  String get currentLcdLine2 => lcdLine2.value;
  String get currentOledLine1 => currentLcdLine1;
  String get currentOledLine2 => currentLcdLine2;

  // 8. Baterai & Langkah (Jika tersedia pada paket)
  final RxInt stepCount = 0.obs;
  final Rxn<int> batteryPercent = Rxn<int>();
  final Rxn<double> batteryVoltage = Rxn<double>();
  final RxBool isCharging = false.obs;

  // 9. Riwayat Telemetri Dinamis untuk Grafik Tren
  final RxList<double> hrHistory = <double>[].obs;
  final RxList<double> tempHistory = <double>[].obs;
  final RxList<double> motionHistory = <double>[].obs;
  final RxList<double> spo2History = <double>[].obs;
  final RxList<double> stabilityHistory = <double>[].obs;
  final RxList<double> stepHistory = <double>[].obs;
  final RxList<double> batteryHistory = <double>[].obs;
  final RxInt selectedSensorIndex = 0.obs;
  final RxString trendPeriod = 'today'.obs;

  /// Metode kompatibilitas simulasi (diabaikan karena mode dinamis hardware penuh aktif)
  void toggleSimulation([bool? enable]) {
    AppLogger.debug('toggleSimulation ignored - hardware full dynamic mode active');
  }

  RxList<double> get heartRateHistory => hrHistory;
  RxList<double> get temperatureHistory => tempHistory;
  RxList<double> get trendData {
    switch (selectedSensorIndex.value) {
      case 1:
        return tempHistory;
      case 2:
        return motionHistory;
      case 3:
        return spo2History;
      default:
        return hrHistory;
    }
  }

  String get trendUnit {
    switch (selectedSensorIndex.value) {
      case 1:
        return '\u00B0C';
      case 2:
        return 'G';
      case 3:
        return '%';
      default:
        return 'BPM';
    }
  }

  String formatTrendValue(double val) {
    if (selectedSensorIndex.value == 1) {
      return val.toStringAsFixed(1);
    }
    return val.toStringAsFixed(0);
  }

  // Observable State - Legacy / Generic Connection
  final isWatchConnected = false.obs;
  final connectionState = SmartbandConnectionState.disconnected.obs;
  final statusMessage = 'Gelang Belum Terhubung'.obs;
  final deviceName = 'HajiCare-Gelang-001'.obs;
  final receivingData = false.obs;
  final lastUpdated = Rxn<DateTime>();
  final rawDataString = '-'.obs;
  final relativeTimeStr = ''.obs;

  // Backward compatibility
  final temperature = Rxn<double>();
  final humidity = Rxn<double>();
  final heatIndex = Rxn<double>();
  final isSensorAvailable = false.obs;
  final environmentStatus = 'Menunggu Sensor'.obs;
  final RxBool isSimulationMode = false.obs;

  Timer? _tickerTimer;
  StreamSubscription<SmartbandBleStatus>? _bleStatusSub;
  StreamSubscription<SmartbandData>? _bleDataSub;
  StreamSubscription<String>? _bleMessageSub;

  // Getters murni dinamis
  bool get isConnected => bleStatus.value == SmartbandBleStatus.connected;
  bool get isScanning => bleStatus.value == SmartbandBleStatus.scanning;
  bool get isConnecting => bleStatus.value == SmartbandBleStatus.connecting;
  bool get isBusy => isScanning || isConnecting;

  int get currentHeartRate => heartRate.value ?? 0;
  int get currentSpo2 => spo2.value ?? 0;
  double get currentTemperature => mcpTemperature.value ?? 0.0;
  int get currentSteps => stepCount.value;
  int get currentBattery => batteryPercent.value ?? 0;

  List<double> get activeTrendData => trendData;

  double get trendAverage {
    final list = activeTrendData;
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  double get trendMax {
    final list = activeTrendData;
    if (list.isEmpty) return 0;
    return list.reduce(max);
  }

  double get trendMin {
    final list = activeTrendData;
    if (list.isEmpty) return 0;
    return list.reduce(min);
  }

  // Elderly Advice Getters
  String get elderlyOverallSummary {
    final hr = heartRate.value ?? 0;
    final t = mcpTemperature.value ?? temperature.value ?? 0.0;
    if (hr == 0 && t == 0.0) {
      return 'Menunggu data smartband terhubung...';
    }
    return 'Alhamdulillah kondisi kesehatan terpantau stabil dan aman.';
  }

  String get elderlyHeartRateAdvice {
    final hr = heartRate.value ?? 0;
    if (hr == 0) return 'Sensor detak jantung belum aktif.';
    return 'Detak jantung  BPM berada dalam rentang normal istirahat.';
  }

  String get elderlyTemperatureAdvice {
    final t = mcpTemperature.value ?? temperature.value ?? 0.0;
    if (t == 0.0) return 'Sensor suhu belum aktif.';
    return 'Suhu tubuh \u00B0C nyaman dan normal.';
  }

  String get elderlySpo2Advice {
    final s = spo2.value ?? 0;
    if (s == 0) return 'Kadar oksigen belum terdeteksi.';
    return 'Saturasi oksigen % sangat baik.';
  }

  String get elderlyMobilityAdvice {
    return 'Kestabilan gerak baik, tetap jaga keseimbangan saat melangkah.';
  }

  @override
  void onInit() {
    super.onInit();
    _initStorage();
    _subscribeToBleService();
    _startRelativeTimeTicker();
    _startSafeRadiusWatcher();
  }

  /// Inisialisasi storage
  Future<void> _initStorage() async {
    await _storage.init();
    // Bersihkan cache koordinat lama agar tidak menampilkan lokasi statis sebelum GPS FIX
    await _storage.clearGpsCache();
    final snapshot = _storage.loadStoredData();
    if (snapshot.hasAnyData) {
      if (snapshot.stepCount != null) {
        stepCount.value = snapshot.stepCount!;
      }
      hasRestoredData.value = true;
    }
  }

  void _startSafeRadiusWatcher() {
    _safeRadiusWatcherTimer?.cancel();
    _safeRadiusWatcherTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (Get.isRegistered<HajiCareController>()) {
        final hajiCtrl = Get.find<HajiCareController>();
        final radius = hajiCtrl.safeRadiusMeters.value;
        activeSafeRadius.value = radius;
        final dist = hajiCtrl.calculatedDistance.value ?? 0.0;
        currentDistanceToPosko.value = dist;

        if (dist > radius && radius > 0) {
          if (!isOutsideSafeRadius.value) {
            isOutsideSafeRadius.value = true;
            safeRadiusStatusLabel.value = 'Di Luar Radius Aman';
            lcdLine2.value = '!LUAR RADIUS !';
            bleService.sendCommand('VIBRATE');
            bleService.sendCommand('BUZZ');
          }
        } else {
          if (isOutsideSafeRadius.value) {
            isOutsideSafeRadius.value = false;
            safeRadiusStatusLabel.value = 'Di Dalam Radius Aman';
            lcdLine2.value = 'STATUS: NORMAL  ';
            bleService.sendCommand('STOP_BUZZ');
          }
        }
      }
    });
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
      } else if (status == SmartbandBleStatus.disconnected) {
        statusMessage.value = 'Gelang Belum Terhubung';
        // Reset nilai telemetri langsung saat terputus
        heartRate.value = null;
        fingerDetected.value = false;
        mcpTemperature.value = null;
        temperature.value = null;
        accelG.value = null;
        latitude.value = null;
        longitude.value = null;
        lastKnownLatitude.value = null;
        lastKnownLongitude.value = null;
        isGpsFix.value = false;
        gpsSatellites.value = null;
        fallStatus.value = 'UNAVAILABLE';
        isFallDetected.value = false;
        currentDistanceM.value = null;
        radiusAlertActive.value = false;
        heartRateStatus.value = 'Sensor belum tersedia';
        emergencyMessage.value = '';
        lcdLine1.value = 'HR:--   SpO2:--%';
        lcdLine2.value = 'STATUS: NORMAL  ';
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

  /// Memproses data telemetri yang murni dikirimkan oleh ESP32
  void _processSmartbandData(SmartbandData data) {
    braceletId.value = data.braceletId;
    fingerDetected.value = data.fingerDetected;

    // 1. MAX30102: Detak Jantung BPM
    if (data.heartRate > 0) {
      heartRate.value = data.heartRate;
      heartRateStatus.value = 'Detak Jantung Aktif';
      hrHistory.add(data.heartRate.toDouble());
      if (hrHistory.length > 25) hrHistory.removeAt(0);
    } else if (data.fingerDetected) {
      heartRate.value = 0;
      heartRateStatus.value = 'Mendeteksi denyut nadi...';
    } else {
      heartRate.value = null;
      heartRateStatus.value = 'Tempelkan Kulit / Jari';
    }

    if (data.spo2 != null) {
      spo2.value = data.spo2;
      spo2History.add(data.spo2!.toDouble());
      if (spo2History.length > 25) spo2History.removeAt(0);
    }

    // 2. DFRobot MCP9808: Suhu Sensor
    if (data.temperature != null) {
      mcpTemperature.value = data.temperature;
      temperature.value = data.temperature;
      isSensorAvailable.value = true;
      tempHistory.add(data.temperature!);
      if (tempHistory.length > 25) tempHistory.removeAt(0);
    }

    // 3. MPU6050: Motion G & Fall Status
    if (data.accelG != null) {
      accelG.value = data.accelG;
      motionHistory.add(data.accelG!);
      if (motionHistory.length > 25) motionHistory.removeAt(0);
      _detectStepFromAccel(data.accelG!);
    } else if (accelG.value == null && isConnected && data.fallStatus != 'UNAVAILABLE') {
      // Inisialisasi baseline 1.00g (gravitasi bumi) saat MPU aktif
      accelG.value = 1.0;
      motionHistory.add(1.0);
    }
    fallStatus.value = data.fallStatus;
    if (data.roll != null) gyroRoll.value = data.roll!;
    if (data.pitch != null) gyroPitch.value = data.pitch!;

    final r = gyroRoll.value.abs();
    final p = gyroPitch.value.abs();
    final g = accelG.value ?? 1.0;
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

    // 4. GPS ATGM336H: Satelit & Koordinat
    gpsSatellites.value = data.satellites;
    isGpsFix.value = data.isValidLocation;
    if (data.isValidLocation &&
        data.latitude != null &&
        data.longitude != null) {
      latitude.value = data.latitude;
      longitude.value = data.longitude;
      lastKnownLatitude.value = data.latitude;
      lastKnownLongitude.value = data.longitude;
    } else {
      latitude.value = null;
      longitude.value = null;
    }

    // 5. Dynamic Safe Radius & Jarak Per Langkah
    safeRadiusMeters.value = data.safeRadius;
    if (data.distanceM != null && data.distanceM! > 0) {
      currentDistanceM.value = data.distanceM;
      _evaluateRadiusAlert(data.distanceM!);
    } else {
      _recalculateDistance();
    }

    // 6. Action Button / SOS & Fall Alerts
    if (data.isSos) {
      triggerSosButtonAlert();
    } else if (isSosButtonPressed.value) {
      cancelSosButtonAlert();
    } else if (data.fallDetected) {
      triggerFallAlert();
    }

    // 7. Baterai & Langkah
    if (data.stepCount != null) {
      stepCount.value = data.stepCount!;
      stepHistory.add(data.stepCount!.toDouble());
      if (stepHistory.length > 25) stepHistory.removeAt(0);
    }
    if (data.batteryLevel != null) {
      batteryPercent.value = data.batteryLevel!;
      batteryHistory.add(data.batteryLevel!.toDouble());
      if (batteryHistory.length > 25) batteryHistory.removeAt(0);
    }
    if (data.batteryVoltage != null) {
      batteryVoltage.value = data.batteryVoltage!;
    }
    isCharging.value = data.isCharging;

    // Update Baris OLED
    lcdLine1.value = data.displayOledLine1;
    if (!isOutsideSafeRadius.value && !data.isSos && !data.fallDetected) {
      lcdLine2.value = data.displayOledLine2;
    }

    lastDataReceivedAt.value = data.timestamp;
    lastUpdated.value = data.timestamp;
    receivingData.value = true;
    rawDataString.value = data.rawJson;
    _updateRelativeTime();

    _storage.saveSmartbandData(data);
  }

  /// Pindah halaman OLED gelang dari HP (0:HR, 1:GPS, 2:Temp, 3:Motion, 4:Safe Radius)
  Future<void> setOledPage(int page) async {
    oledPage.value = page;
    await bleService.setOledPage(page);
  }

  /// Ubah batas Safe Radius pada gelang secara dinamis
  Future<void> setSafeRadius(double radiusMeters) async {
    safeRadiusMeters.value = radiusMeters;
    await bleService.setSafeRadius(radiusMeters);
  }

  /// Batalkan alarm/getaran lokal pada gelang
  Future<void> cancelAlarm() async {
    await bleService.cancelAlarm();
    cancelFallAlert();
    cancelSosButtonAlert();
  }

  /// Deteksi Jatuh MPU6050
  void triggerFallAlert() {
    isFallDetected.value = true;
    fallStatus.value = 'FALL_ALERT';
    fallCountdownSeconds.value = 10;

    _fallCountdownTimer?.cancel();
    _fallCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (fallCountdownSeconds.value > 1) {
        fallCountdownSeconds.value--;
      } else {
        timer.cancel();
        dispatchSosToCompanion(reason: 'Deteksi Jatuh MPU6050');
      }
    });
  }

  void cancelFallAlert() {
    _fallCountdownTimer?.cancel();
    _fallCountdownTimer = null;
    isFallDetected.value = false;
    fallStatus.value = 'NORMAL';
  }

  /// Tombol SOS Fisik Smartband (GPIO13 hold 3s)
  void triggerSosButtonAlert({bool immediate = false}) {
    if (isSosButtonPressed.value) return;
    final now = DateTime.now();
    if (_lastSosTriggerTime != null &&
        now.difference(_lastSosTriggerTime!).inSeconds < 5 &&
        isSosButtonPressed.value) {
      return;
    }
    _lastSosTriggerTime = now;
    isSosButtonPressed.value = true;
    emergencyMessage.value = 'TOMBOL SOS SMARTBAND AKTIF';

    HapticFeedback.heavyImpact();
    dispatchSosToCompanion(reason: 'Tombol SOS Smartband Ditekan (3 Detik)');
  }

  void cancelSosButtonAlert() {
    _sosCountdownTimer?.cancel();
    _sosCountdownTimer = null;
    isSosButtonPressed.value = false;
    isSosTransmitted.value = false;
    emergencyMessage.value = '';

    if (Get.isRegistered<HajiCareController>()) {
      final hajiCtrl = Get.find<HajiCareController>();
      final uid = hajiCtrl.currentUid;
      if (uid != null && uid.isNotEmpty) {
        hajiCtrl.dismissSos(uid);
      }
    }
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
        if (Get.context != null) {
          Get.snackbar(
            '?? SOS TERKIRIM KE HP PENDAMPING',
            '$reason: Sinyal darurat beserta koordinat lokasi berhasil diteruskan ke ponsel pendamping!',
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
      }
    }
    return false;
  }

  void selectSensor(int index) {
    selectedSensorIndex.value = index;
  }

  void setTrendPeriod(String period) {
    trendPeriod.value = period;
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
    if (!isConnected || !isGpsFix.value || latitude.value == null || longitude.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi realtime belum tersedia. Menunggu Smartband berhasil mengunci sinyal GPS FIX di area terbuka.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final lat = latitude.value!;
    final lng = longitude.value!;

    if (Get.isRegistered<MapController>()) {
      final mapCtrl = Get.find<MapController>();
      mapCtrl.focusCoordinate(LatLng(lat, lng), destZoom: 17.0);
    }
    Get.toNamed(AppRoutes.interactiveMap);
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
      relativeTimeText.value = ' detik lalu';
    } else if (diff.inMinutes < 60) {
      relativeTimeText.value = ' menit lalu';
    } else {
      relativeTimeText.value = ' jam lalu';
    }
    relativeTimeStr.value = relativeTimeText.value;
  }

  /// Deteksi langkah kaki dinamis dari fluktuasi akselerometer MPU6050
  void _detectStepFromAccel(double g) {
    final now = DateTime.now();
    if (g > 1.25 && !_stepPeak && now.difference(_lastStepAt).inMilliseconds > 300) {
      _stepPeak = true;
      _lastStepAt = now;
      stepCount.value++;
      sessionSteps.value++;
      _recalculateDistance();
    } else if (g < 1.05) {
      _stepPeak = false;
    }
  }

  /// Hitung jarak riil jemaah ke HP (per-langkah jika GPS belum fix)
  void _recalculateDistance() {
    if (!isConnected) {
      currentDistanceM.value = null;
      return;
    }

    // 1. Prioritas GPS jika satelit fix
    if (isGpsFix.value && latitude.value != null && longitude.value != null) {
      if (Get.isRegistered<HajiCareController>()) {
        final hajiCtrl = Get.find<HajiCareController>();
        final dist = hajiCtrl.calculatedDistance.value;
        if (dist != null && dist > 0) {
          currentDistanceM.value = dist;
          _evaluateRadiusAlert(dist);
          return;
        }
      }
    }

    // 2. Jika GPS belum fix (indoor / 0 satelit), hitung jarak per langkah (0.7m/langkah)
    final steps = sessionSteps.value > 0 ? sessionSteps.value : stepCount.value;
    final dist = steps * strideLengthMeters;
    currentDistanceM.value = dist;
    _evaluateRadiusAlert(dist);
  }

  void _evaluateRadiusAlert(double dist) {
    final rad = safeRadiusMeters.value;
    final isOut = rad > 0 && dist > rad;

    if (isOut != radiusAlertActive.value) {
      radiusAlertActive.value = isOut;
      isOutsideSafeRadius.value = isOut;
      safeRadiusStatusLabel.value = isOut ? 'Di Luar Radius Aman' : 'Di Dalam Radius Aman';
      lcdLine2.value = isOut ? '!LUAR RADIUS !' : 'STATUS: NORMAL  ';
      bleService.sendCommand(isOut ? 'RADIUS_ALERT:1' : 'RADIUS_ALERT:0');
      if (isOut) {
        bleService.sendCommand('VIBRATE');
      }
    }
    // Kirim sinkronisasi jarak ke gelang
    bleService.sendDistance(dist, rad);
  }

  /// Tambah langkah (untuk pengetesan cepat jarak per langkah)
  void addStep([int count = 1]) {
    sessionSteps.value += count;
    stepCount.value += count;
    _recalculateDistance();
  }

  /// Reset titik awal jarak (kembali ke 0 meter & 0 langkah)
  void resetStepDistance() {
    sessionSteps.value = 0;
    _recalculateDistance();
  }

  @override
  void onClose() {
    _fallCountdownTimer?.cancel();
    _sosCountdownTimer?.cancel();
    _safeRadiusWatcherTimer?.cancel();
    _tickerTimer?.cancel();
    _bleStatusSub?.cancel();
    _bleDataSub?.cancel();
    _bleMessageSub?.cancel();
    super.onClose();
  }

  /// Hapus semua data tersimpan di local storage
  Future<void> clearStoredData() async {
    await _storage.clearAll();
    hasRestoredData.value = false;
  }
}
