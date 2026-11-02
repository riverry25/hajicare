import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/location_service.dart';
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
  DateTime? _lastCloudSyncTime;
  bool _lastEmergencyState = false;

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
  final RxDouble safeRadiusMeters = 200.0.obs;
  final RxDouble activeSafeRadius = 200.0.obs;
  final Rxn<double> currentDistanceM = Rxn<double>();
  final RxDouble currentDistanceToPosko = 0.0.obs;
  final RxBool isOutsideSafeRadius = false.obs;
  final RxString safeRadiusStatusLabel = 'Di Dalam Radius Aman'.obs;
  final RxBool radiusAlertActive = false.obs;
  DateTime? _lastCompGpsSentAt;
  DateTime? _lastDistanceSentAt;

  /// Panjang rata-rata per langkah sesuai kalibrasi ESP32-S3 (0.65 meter)
  static const double strideLengthMeters = 0.65;

  /// Jumlah langkah sesi aktif (dihitung sejak gelang tersambung / reset)
  final RxInt sessionSteps = 0.obs;
  int _stepBaseline = 0;
  double _lastSentDistance = -1.0;

  /// Hitungan langkah efektif dari sensor MPU6050
  int get effectiveSteps {
    final total = stepCount.value;
    if (_stepBaseline > 0 && total >= _stepBaseline) {
      return (total - _stepBaseline).clamp(0, 999999);
    }
    if (total > 0) return total.clamp(0, 999999);
    return sessionSteps.value.clamp(0, 999999);
  }

  // 6. Action Button / SOS & Haptic
  final RxBool isSosButtonPressed = false.obs;
  final RxBool isSosTransmitted = false.obs;
  final RxString emergencyMessage = ''.obs;
  DateTime? _lastSosTriggerTime;
  Timer? _fallCountdownTimer;
  Timer? _sosCountdownTimer;
  Timer? _safeRadiusWatcherTimer;

  // 7. Status Tampilan OLED (Halaman Aktif 0-6)
  // 0:HR, 1:GPS, 2:Temp, 3:Fall, 4:Steps, 5:Safe Radius, 6:AI Voice
  final RxInt oledPage = 0.obs;
  final RxString aiDisplayText = 'Klik 2x tombol untuk bicara ke AI HajiCare'.obs;
  final RxString lcdLine1 = 'HR:--   T:--.-C'.obs;
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

  // 9. AI Voice Assistant & Step Counter MPU6050 ESP32-S3 v2.8.1
  final RxBool isSmartbandRecordingVoice = false.obs;
  final RxDouble smartbandStepDistanceM = 0.0.obs;
  StreamSubscription<bool>? _aiListeningSub;
  StreamSubscription<DocumentSnapshot>? _commandSub;

  // 10. Riwayat Telemetri Dinamis untuk Grafik Tren
  final RxList<double> hrHistory = <double>[].obs;
  final RxList<double> tempHistory = <double>[].obs;
  final RxList<double> motionHistory = <double>[].obs;
  final RxList<double> spo2History = <double>[].obs;
  final RxList<double> gpsSatellitesHistory = <double>[].obs;
  final RxList<double> distanceHistory = <double>[].obs;
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
        return spo2History.isNotEmpty ? spo2History : gpsSatellitesHistory;
      case 4:
        return distanceHistory;
      case 5:
        return stepHistory;
      default:
        return hrHistory;
    }
  }

  String get trendUnit {
    switch (selectedSensorIndex.value) {
      case 1:
        return '\u00B0C';
      case 2:
        return 'g';
      case 3:
        return spo2History.isNotEmpty ? '%' : 'Sats';
      case 4:
        return 'm';
      case 5:
        return 'lkh';
      default:
        return 'BPM';
    }
  }

  String formatTrendValue(double val) {
    if (selectedSensorIndex.value == 1 || selectedSensorIndex.value == 4) {
      return val.toStringAsFixed(1);
    }
    if (selectedSensorIndex.value == 2) {
      return val.toStringAsFixed(2);
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
    return 'Detak jantung $hr BPM berada dalam rentang normal istirahat.';
  }

  String get elderlyTemperatureAdvice {
    final t = mcpTemperature.value ?? temperature.value ?? 0.0;
    if (t == 0.0) return 'Sensor suhu belum aktif.';
    return 'Suhu tubuh ${t.toStringAsFixed(1)}\u00B0C nyaman dan normal.';
  }

  String get elderlySpo2Advice {
    final s = spo2.value ?? 0;
    if (s == 0) return 'Kadar oksigen belum terdeteksi.';
    return 'Saturasi oksigen $s% sangat baik.';
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
    _listenForCompanionCommands();
  }

  /// Mendengarkan perintah kendali jarak jauh dari Pendamping via Firestore (mis. Buzzer / Getar OLED)
  void _listenForCompanionCommands() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      _commandSub?.cancel();
      _commandSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
            if (!doc.exists) return;
            final data = doc.data();
            if (data == null) return;
            final cmd = data['smartbandCommand'] as Map<String, dynamic>?;
            if (cmd != null && cmd['type'] == 'ALERT_BUZZER') {
              final msg = (cmd['message'] as String?) ?? 'Panggilan Pendamping';
              AppLogger.info('Menerima perintah buzzer/getar dari pendamping: $msg', tag: 'SmartbandLdr');
              bleService.showAiReplyOnOled(msg);
              bleService.triggerRadiusAlert(true);
              FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'smartbandCommand': FieldValue.delete(),
              });
            }
          });
    } catch (e) {
      debugPrint('[SmartbandLdr] Error setting up companion commands listener: $e');
    }
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
    _safeRadiusWatcherTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (!Get.isRegistered<HajiCareController>()) return;
      final hajiCtrl = Get.find<HajiCareController>();
      final radius = hajiCtrl.safeRadiusMeters.value;
      if (activeSafeRadius.value != radius) activeSafeRadius.value = radius;
      if (safeRadiusMeters.value != radius) {
        safeRadiusMeters.value = radius;
        if (bleService.isConnected) {
          bleService.setSafeRadius(radius);
        }
      }

      if (!isConnected) {
        if (currentDistanceM.value != null) currentDistanceM.value = null;
        if (radiusAlertActive.value) radiusAlertActive.value = false;
        if (isOutsideSafeRadius.value) isOutsideSafeRadius.value = false;
        return;
      }

      final dist = hajiCtrl.calculatedDistance.value;
      if (dist != null && !dist.isNaN && !dist.isInfinite && dist >= 0) {
        if (currentDistanceToPosko.value != dist) {
          currentDistanceToPosko.value = dist;
        }
        if (currentDistanceM.value != dist) {
          currentDistanceM.value = dist;
        }
        _evaluateRadiusAlert(dist);
      } else if (bleService.lastData?.distanceM == null) {
        _recalculateDistance();
      }

      // Sinkronkan GPS pendamping (atau GPS HP saat ini sebagai referensi) ke ESP32 setiap 4 detik
      final now = DateTime.now();
      if (_lastCompGpsSentAt == null ||
          now.difference(_lastCompGpsSentAt!).inSeconds >= 4) {
        final compLoc = hajiCtrl.pendampingLocation.value;
        final myPos = hajiCtrl.myCurrentPosition.value;
        if (compLoc != null) {
          _lastCompGpsSentAt = now;
          bleService.sendCompanionGps(compLoc.latitude, compLoc.longitude);
        } else if (myPos != null &&
            (myPos.latitude.abs() > 0.0001 || myPos.longitude.abs() > 0.0001)) {
          _lastCompGpsSentAt = now;
          bleService.sendCompanionGps(
            myPos.latitude,
            myPos.longitude,
            myPos.accuracy > 0 ? myPos.accuracy : 10.0,
          );
        }
      }
    });
  }

  void _subscribeToBleService() {
    bleStatus.value = bleService.currentStatus;
    _syncLegacyState(bleService.currentStatus);

    // Langsung muat data terbaru jika BLE service sudah memiliki telemetri aktif
    if (bleService.lastData != null) {
      _processSmartbandData(bleService.lastData!);
    } else {
      final snapshot = _storage.loadStoredData();
      if (snapshot.hasAnyData && !bleService.isConnected) {
        if (snapshot.heartRate != null && snapshot.heartRate! > 0) {
          heartRate.value = snapshot.heartRate;
        }
        if (snapshot.temperature != null && snapshot.temperature! > 0) {
          mcpTemperature.value = snapshot.temperature;
          temperature.value = snapshot.temperature;
        }
        if (snapshot.stepCount != null) {
          stepCount.value = snapshot.stepCount!;
        }
        hasRestoredData.value = true;
      }
    }

    _bleStatusSub = bleService.connectionStateStream.listen((status) {
      bleStatus.value = status;
      _syncLegacyState(status);

      if (status == SmartbandBleStatus.connected) {
        errorMessage.value = '';
        statusMessage.value = 'Gelang Terhubung';
        if (bleService.lastData != null) {
          _processSmartbandData(bleService.lastData!);
        }
        _lastSentDistance = -1.0;
        if (Get.isRegistered<HajiCareController>()) {
          final rad = Get.find<HajiCareController>().safeRadiusMeters.value;
          bleService.setSafeRadius(rad);
        }
        _recalculateDistance();
      } else if (status == SmartbandBleStatus.disconnected) {
        statusMessage.value = 'Gelang Belum Terhubung';
        _lastSentDistance = -1.0;
        _stepBaseline = 0;
        sessionSteps.value = 0;
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
        isOutsideSafeRadius.value = false;
        isSmartbandRecordingVoice.value = false;
        heartRateStatus.value = 'Sensor belum tersedia';
        emergencyMessage.value = '';
        lcdLine1.value = 'HR:--   T:--.-C';
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

    _aiListeningSub?.cancel();
    _aiListeningSub = bleService.smartbandAiListeningStream.listen((isListening) {
      isSmartbandRecordingVoice.value = isListening;
      if (isListening) {
        oledPage.value = 6;
        statusMessage.value = 'Mendengarkan Suara Jamaah (INMP441)...';
      } else if (isConnected) {
        statusMessage.value = 'Gelang Terhubung';
      }
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
        _notifyDisconnectToCloud();
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
    } else {
      mcpTemperature.value = null;
      temperature.value = null;
    }

    // 3. MPU6050: Motion G & Fall Status
    if (data.accelG != null) {
      accelG.value = data.accelG;
      motionHistory.add(data.accelG!);
      if (motionHistory.length > 25) motionHistory.removeAt(0);
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
    if (data.satellites != null) {
      gpsSatellitesHistory.add(data.satellites!.toDouble());
      if (gpsSatellitesHistory.length > 25) gpsSatellitesHistory.removeAt(0);
    }
    isGpsFix.value = data.isGpsFix;
    if (data.isGpsFix &&
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

    // 5. Langkah (MPU6050) & Baterai
    if (data.stepCount != null) {
      if (data.stepCount! < _stepBaseline) {
        _stepBaseline = 0;
      }
      stepCount.value = data.stepCount!;
      stepHistory.add(data.stepCount!.toDouble());
      if (stepHistory.length > 25) stepHistory.removeAt(0);
    }
    if (data.stepDistanceM != null) {
      smartbandStepDistanceM.value = data.stepDistanceM!;
    } else if (data.stepCount != null) {
      smartbandStepDistanceM.value = data.stepCount! * strideLengthMeters;
    }
    isSmartbandRecordingVoice.value = data.isAiListening;
    if (data.isAiListening) {
      oledPage.value = 6;
    } else if (data.oledPage != null) {
      oledPage.value = data.oledPage!;
    }
    if (data.aiText != null && data.aiText!.isNotEmpty) {
      aiDisplayText.value = data.aiText!;
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

    // 6. Dynamic Safe Radius & Jarak Realtime
    if (data.hasSafeRadiusFromBand) {
      safeRadiusMeters.value = data.safeRadius;
      activeSafeRadius.value = data.safeRadius;
      if (Get.isRegistered<HajiCareController>()) {
        final hajiCtrl = Get.find<HajiCareController>();
        if (hajiCtrl.safeRadiusMeters.value != data.safeRadius) {
          hajiCtrl.safeRadiusMeters.value = data.safeRadius;
        }
      }
    }
    if (data.distanceM != null) {
      currentDistanceM.value = data.distanceM;
      currentDistanceToPosko.value = data.distanceM!;
      distanceHistory.add(data.distanceM!);
      if (distanceHistory.length > 25) distanceHistory.removeAt(0);
      final rad = safeRadiusMeters.value;
      final isOut = data.radiusAlert || (rad > 0 && data.distanceM! > rad);
      radiusAlertActive.value = isOut;
      isOutsideSafeRadius.value = isOut;
      safeRadiusStatusLabel.value =
          isOut ? 'Di Luar Radius Aman' : 'Di Dalam Radius Aman';
    } else {
      _recalculateDistance();
      if (data.radiusAlert && !radiusAlertActive.value) {
        radiusAlertActive.value = true;
        isOutsideSafeRadius.value = true;
        safeRadiusStatusLabel.value = 'Di Luar Radius Aman';
      }
    }

    // 7. Action Button / SOS & Fall Alerts
    if (data.isSos) {
      triggerSosButtonAlert();
    } else if (isSosButtonPressed.value) {
      cancelSosButtonAlert();
    }

    if (data.fallDetected) {
      if (!isFallDetected.value) {
        triggerFallAlert();
      }
    } else if (isFallDetected.value) {
      cancelFallAlert();
    }

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
    _syncTelemetryToCloud(data);
  }

  /// Sinkronisasi telemetri smartband ke Firestore secara hemat daya (5s normal),
  /// namun INSTAN 0-DETIK SEKETIKA saat kondisi darurat (Jatuh, SOS, atau Anomali Kritis).
  Future<void> _syncTelemetryToCloud(SmartbandData data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final isEmergency = data.isSos ||
          data.fallDetected ||
          data.fallStatus.toUpperCase() == 'FALLEN' ||
          (data.heartRate > 0 && (data.heartRate < 45 || data.heartRate > 120)) ||
          (data.temperature != null &&
              (data.temperature! > 38.5 || data.temperature! < 35.0)) ||
          (data.spo2 != null && data.spo2! > 0 && data.spo2! < 90);

      final emergencyStateChanged = isEmergency != _lastEmergencyState;
      _lastEmergencyState = isEmergency;

      final now = DateTime.now();
      // Jika BUKAN darurat dan status tidak berubah, lakukan throttle 5 detik hemat baterai
      if (!isEmergency && !emergencyStateChanged && _lastCloudSyncTime != null) {
        if (now.difference(_lastCloudSyncTime!).inSeconds < 5) {
          return;
        }
      }

      _lastCloudSyncTime = now;

      final smartbandPayload = <String, dynamic>{
        'connected': isConnected,
        'braceletId': data.braceletId,
        'heartRate': data.heartRate,
        if (data.temperature != null) 'temperature': data.temperature,
        if (data.spo2 != null) 'spo2': data.spo2,
        'fallDetected': data.fallDetected,
        'fallStatus': data.fallStatus,
        if (data.accelG != null) 'accelG': data.accelG,
        'isSos': data.isSos,
        if (data.batteryLevel != null) 'batteryLevel': data.batteryLevel,
        'steps': data.steps,
        if (data.stepDistanceM != null) 'stepDistanceM': data.stepDistanceM,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Update ke users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'smartband': smartbandPayload,
        'isSmartbandConnected': isConnected,
        if (data.isSos) 'sosActive': true,
        'fallDetected': data.fallDetected,
      }, SetOptions(merge: true));

      // 2. Update ke rooms/{roomId}/members/{uid} jika aktif di dalam room
      if (Get.isRegistered<HajiCareController>()) {
        final roomId = Get.find<HajiCareController>().activeRoomId.value;
        if (roomId != null && roomId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('rooms')
              .doc(roomId)
              .collection('members')
              .doc(user.uid)
              .set({
            'smartband': smartbandPayload,
            'isSmartbandConnected': isConnected,
            if (data.isSos) 'sosActive': true,
            'fallDetected': data.fallDetected,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('[SmartbandCloudSync] Error syncing to cloud: $e');
    }
  }

  void _notifyDisconnectToCloud() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'smartband': {
          'connected': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'isSmartbandConnected': false,
      }, SetOptions(merge: true)).catchError((_) {});

      if (Get.isRegistered<HajiCareController>()) {
        final roomId = Get.find<HajiCareController>().activeRoomId.value;
        if (roomId != null && roomId.isNotEmpty) {
          FirebaseFirestore.instance
              .collection('rooms')
              .doc(roomId)
              .collection('members')
              .doc(user.uid)
              .set({
            'smartband': {
              'connected': false,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            'isSmartbandConnected': false,
          }, SetOptions(merge: true)).catchError((_) {});
        }
      }
    } catch (_) {}
  }

  /// Pindah halaman OLED gelang dari HP (0:HR, 1:GPS, 2:Temp, 3:Fall, 4:Steps, 5:Safe Radius, 6:AI Voice)
  Future<void> setOledPage(int page) async {
    oledPage.value = page.clamp(0, 6);
    await bleService.setOledPage(oledPage.value);
  }

  /// Ubah batas Safe Radius pada gelang secara dinamis
  Future<void> setSafeRadius(double radiusMeters) async {
    safeRadiusMeters.value = radiusMeters;
    activeSafeRadius.value = radiusMeters;
    if (Get.isRegistered<HajiCareController>()) {
      final hajiCtrl = Get.find<HajiCareController>();
      if (hajiCtrl.safeRadiusMeters.value != radiusMeters) {
        hajiCtrl.safeRadiusMeters.value = radiusMeters;
      }
    }
    if (radiusMeters <= 0) {
      radiusAlertActive.value = false;
      isOutsideSafeRadius.value = false;
      safeRadiusStatusLabel.value = 'Radius Aman Nonaktif (OFF)';
    }
    await bleService.setSafeRadius(radiusMeters);
    _lastSentDistance = -1.0;
    _recalculateDistance();
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
      if (relativeTimeText.value != 'Belum menerima data') relativeTimeText.value = 'Belum menerima data';
      if (relativeTimeStr.value != '') relativeTimeStr.value = '';
      return;
    }

    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 5) {
      if (relativeTimeText.value != 'Baru saja') relativeTimeText.value = 'Baru saja';
    } else if (diff.inSeconds < 60) {
      final s = '${diff.inSeconds} detik lalu';
      if (relativeTimeText.value != s) relativeTimeText.value = s;
    } else if (diff.inMinutes < 60) {
      final m = '${diff.inMinutes} menit lalu';
      if (relativeTimeText.value != m) relativeTimeText.value = m;
    } else {
      final h = '${diff.inHours} jam lalu';
      if (relativeTimeText.value != h) relativeTimeText.value = h;
    }
    if (relativeTimeStr.value != relativeTimeText.value) relativeTimeStr.value = relativeTimeText.value;
  }

  /// Hitung jarak riil jamaah (Smartband + HP) ke lokasi Pendamping
  void _recalculateDistance() {
    if (!isConnected) {
      currentDistanceM.value = null;
      return;
    }

    // 1. Jarak riil dari Smartband jika sudah dihitung oleh ESP32
    final bandDist = bleService.lastData?.distanceM;
    if (bandDist != null && !bandDist.isNaN && !bandDist.isInfinite && bandDist >= 0) {
      currentDistanceM.value = bandDist;
      currentDistanceToPosko.value = bandDist;
      _evaluateRadiusAlert(bandDist, fromBand: true);
      return;
    }

    // 2. Jarak riil GPS Jamaah (HP/Smartband) ke Pendamping via Room
    if (Get.isRegistered<HajiCareController>()) {
      final hajiCtrl = Get.find<HajiCareController>();
      final dist = hajiCtrl.calculatedDistance.value;
      if (dist != null && !dist.isNaN && !dist.isInfinite && dist >= 0) {
        currentDistanceM.value = dist;
        currentDistanceToPosko.value = dist;
        _evaluateRadiusAlert(dist);
        return;
      }

      // 3. Jika GPS Smartband fix & ada lokasi pendamping (atau HP)
      if (isGpsFix.value && latitude.value != null && longitude.value != null) {
        final compLoc = hajiCtrl.pendampingLocation.value;
        final myPos = hajiCtrl.myCurrentPosition.value;
        final refLat = compLoc?.latitude ?? myPos?.latitude;
        final refLon = compLoc?.longitude ?? myPos?.longitude;
        if (refLat != null &&
            refLon != null &&
            (refLat.abs() > 0.0001 || refLon.abs() > 0.0001)) {
          final locService = LocationService();
          final d = locService.calculateDistanceMeters(
            latitude.value!,
            longitude.value!,
            refLat,
            refLon,
          );
          currentDistanceM.value = d;
          currentDistanceToPosko.value = d;
          _evaluateRadiusAlert(d);
          return;
        }
      }
    }

    // 4. Jika belum terhubung ke Room / belum ada GPS referensi
    currentDistanceM.value = null;
  }

  void _evaluateRadiusAlert(double dist, {bool fromBand = false}) {
    if (dist.isNaN || dist.isInfinite || dist < 0) return;
    final rad = safeRadiusMeters.value;
    final isOut = rad > 0 && dist > rad;
    final stateChanged = isOut != radiusAlertActive.value;

    if (stateChanged) {
      radiusAlertActive.value = isOut;
      isOutsideSafeRadius.value = isOut;
      safeRadiusStatusLabel.value = isOut ? 'Di Luar Radius Aman' : 'Di Dalam Radius Aman';
      lcdLine2.value = isOut ? '!LUAR RADIUS !' : 'STATUS: NORMAL  ';
      bleService.sendCommand(isOut ? 'RADIUS_ALERT:1' : 'RADIUS_ALERT:0');
    }

    // Kirim sinkronisasi jarak ke gelang jika berasal dari kalkulasi HP (maks 1x per 3 detik atau saat status berubah)
    if (!fromBand) {
      final now = DateTime.now();
      final elapsedOk = _lastDistanceSentAt == null ||
          now.difference(_lastDistanceSentAt!).inSeconds >= 3;
      if (stateChanged || ((dist - _lastSentDistance).abs() >= 1.0 && elapsedOk)) {
        _lastSentDistance = dist;
        _lastDistanceSentAt = now;
        bleService.sendDistance(dist);
      }
    }
  }

  /// Tambah langkah (kompatibilitas pengujian)
  void addStep([int count = 1]) {
    sessionSteps.value = effectiveSteps + count;
  }

  /// Reset titik awal langkah pedometer pada aplikasi dan memori ESP32-S3
  void resetStepDistance() {
    _stepBaseline = 0;
    stepCount.value = 0;
    sessionSteps.value = 0;
    smartbandStepDistanceM.value = 0.0;
    bleService.resetSteps();
  }

  /// Aktifkan mode perekaman suara mikrofon INMP441 pada gelang
  Future<bool> startSmartbandMic() => bleService.startSmartbandAiListening();

  /// Selesaikan/hentikan perekaman suara mikrofon INMP441 pada gelang
  Future<bool> stopSmartbandMic() => bleService.stopSmartbandAiListening();

  @override
  void onClose() {
    _fallCountdownTimer?.cancel();
    _sosCountdownTimer?.cancel();
    _safeRadiusWatcherTimer?.cancel();
    _tickerTimer?.cancel();
    _bleStatusSub?.cancel();
    _bleDataSub?.cancel();
    _bleMessageSub?.cancel();
    _aiListeningSub?.cancel();
    _commandSub?.cancel();
    super.onClose();
  }

  /// Hapus semua data tersimpan di local storage
  Future<void> clearStoredData() async {
    await _storage.clearAll();
    hasRestoredData.value = false;
  }
}
