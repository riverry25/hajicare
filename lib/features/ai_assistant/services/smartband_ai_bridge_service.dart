import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../../core/state/hajicare_controller.dart';
import '../../smartband/controllers/smartband_ldr_controller.dart';
import '../../smartband/services/smartband_ble_service.dart';
import '../models/oled_display_state.dart';
import '../models/sensor_context.dart';
import 'oled_text_formatter.dart';

/// Service jembatan antara fitur **HajiCare AI Assistant** dengan
/// `SmartbandBleService` / `SmartbandLdrController` dan `HajiCareController`.
///
/// Menyediakan:
/// 1. Pembacaan telemetri terbaru gelang (BPM, Suhu °C, Status Jatuh, GPS,
///    Jarak ke Pendamping, Batas Safe Radius) lengkap dengan fallback simulasi
///    realistis apabila BLE sedang tidak terhubung.
/// 2. Pengiriman payload `"AI:<teks>"` (maks. 55 karakter ASCII tanpa emoji/newline)
///    ke BLE RX Characteristic (`6e400002-b5a3-f393-e0a9-e50e24dcca9e`).
class SmartbandAiBridgeService {
  SmartbandAiBridgeService({
    SmartbandLdrController? smartbandController,
    SmartbandBleService? bleService,
    HajiCareController? hajiCareController,
  }) : _explicitSmartbandCtrl = smartbandController,
       _explicitBleService = bleService,
       _explicitHajiCareCtrl = hajiCareController;

  final SmartbandLdrController? _explicitSmartbandCtrl;
  final SmartbandBleService? _explicitBleService;
  final HajiCareController? _explicitHajiCareCtrl;

  // Koordinat default realistis: Pelataran Masjidil Haram, Makkah
  static const double defaultLatitude = 21.422487;
  static const double defaultLongitude = 39.826206;
  static const int defaultHeartRateBpm = 78;
  static const double defaultTemperatureC = 36.6;
  static const double defaultDistanceMeters = 12.0;
  static const double defaultSafeRadiusMeters = 200.0;

  bool _localSimulationMode = true;
  double _simPhase = 0.0;
  int _simHeartRate = defaultHeartRateBpm;
  double _simTemperature = defaultTemperatureC;
  double _simDistance = defaultDistanceMeters;
  bool _simFallDetected = false;

  SmartbandLdrController? get _ldrCtrl {
    if (_explicitSmartbandCtrl != null) return _explicitSmartbandCtrl;
    if (Get.isRegistered<SmartbandLdrController>()) {
      return Get.find<SmartbandLdrController>();
    }
    return null;
  }

  SmartbandBleService? get _bleService {
    if (_explicitBleService != null) return _explicitBleService;
    final ldr = _ldrCtrl;
    if (ldr != null) return ldr.bleService;
    if (Get.isRegistered<SmartbandBleService>()) {
      return Get.find<SmartbandBleService>();
    }
    return null;
  }

  HajiCareController? get _hajiCtrl {
    if (_explicitHajiCareCtrl != null) return _explicitHajiCareCtrl;
    if (Get.isRegistered<HajiCareController>()) {
      return Get.find<HajiCareController>();
    }
    return null;
  }

  /// Status koneksi BLE perangkat fisik gelang (murni hardware, di luar simulasi).
  SmartbandLinkStatus get bleLinkStatus {
    final ble = _bleService;
    if (ble == null) return SmartbandLinkStatus.disconnected;
    return switch (ble.currentStatus) {
      SmartbandBleStatus.connected => SmartbandLinkStatus.connected,
      SmartbandBleStatus.scanning => SmartbandLinkStatus.scanning,
      SmartbandBleStatus.connecting => SmartbandLinkStatus.connecting,
      SmartbandBleStatus.disconnected => SmartbandLinkStatus.disconnected,
    };
  }

  bool get isBleHardwareConnected =>
      bleLinkStatus == SmartbandLinkStatus.connected;

  bool get isSimulationEnabled =>
      _localSimulationMode || (_ldrCtrl?.isSimulationMode.value ?? false);

  /// Aktifkan/nonaktifkan Mode Simulasi Sensor.
  void setSimulationEnabled(bool enabled) {
    _localSimulationMode = enabled;
    final ldr = _ldrCtrl;
    if (ldr != null && ldr.isSimulationMode.value != enabled) {
      ldr.toggleSimulation(enabled);
    }
    if (!enabled) {
      _simFallDetected = false;
    }
  }

  /// Simulasikan perubahan kondisi jatuh (untuk demo cepat).
  void setSimulatedFallDetected(bool fallDetected) {
    _simFallDetected = fallDetected;
    final ldr = _ldrCtrl;
    if (ldr != null) {
      if (fallDetected) {
        ldr.isFallDetected.value = true;
      } else {
        ldr.cancelFallAlert();
      }
    }
  }

  /// Majukan fase simulasi sedikit agar angka BPM/suhu/jarak tampak hidup.
  void stepSimulationTick() {
    _simPhase += 0.35;
    _simHeartRate = (78 + (4 * sin(_simPhase)).round()).clamp(72, 86);
    _simTemperature = double.parse(
      (36.6 + 0.12 * cos(_simPhase * 0.6)).toStringAsFixed(1),
    );
    _simDistance = double.parse(
      (12.0 + 3.0 * sin(_simPhase * 0.4)).clamp(5.0, 25.0).toStringAsFixed(0),
    );
  }

  /// Ambil snapshot konteks sensor terbaru dari gelang atau fallback simulasi.
  SensorContext readCurrentSensorContext() {
    final ldr = _ldrCtrl;
    final haji = _hajiCtrl;
    final liveConnected = isBleHardwareConnected;

    final safeRadius =
        haji?.safeRadiusMeters.value ??
        ldr?.activeSafeRadius.value ??
        defaultSafeRadiusMeters;

    final liveDistance =
        haji?.calculatedDistance.value ??
        ((ldr != null && ldr.currentDistanceToPosko.value > 0)
            ? ldr.currentDistanceToPosko.value
            : null);

    // 1. Jika BLE hardware terhubung, utamakan data riil dari gelang
    if (liveConnected && ldr != null) {
      final hr = (ldr.heartRate.value != null && ldr.heartRate.value! > 0)
          ? ldr.heartRate.value!
          : defaultHeartRateBpm;
      final temp =
          (ldr.mcpTemperature.value != null && ldr.mcpTemperature.value! > 0)
          ? ldr.mcpTemperature.value!
          : defaultTemperatureC;
      final lat =
          ldr.latitude.value ??
          ldr.lastKnownLatitude.value ??
          haji?.myCurrentPosition.value?.latitude ??
          defaultLatitude;
      final lng =
          ldr.longitude.value ??
          ldr.lastKnownLongitude.value ??
          haji?.myCurrentPosition.value?.longitude ??
          defaultLongitude;

      return SensorContext(
        heartRateBpm: hr,
        temperatureC: temp,
        isFallDetected: ldr.isFallDetected.value,
        latitude: lat,
        longitude: lng,
        distanceToCompanionMeters: liveDistance ?? defaultDistanceMeters,
        safeRadiusMeters: safeRadius,
        source: SensorDataSource.live,
        capturedAt: DateTime.now(),
      );
    }

    // 2. Jika Mode Simulasi Sensor aktif
    if (isSimulationEnabled) {
      final hr =
          (ldr != null &&
              ldr.isSimulationMode.value &&
              (ldr.heartRate.value ?? 0) > 0)
          ? ldr.heartRate.value!
          : _simHeartRate;
      final temp =
          (ldr != null &&
              ldr.isSimulationMode.value &&
              (ldr.mcpTemperature.value ?? 0) > 0)
          ? ldr.mcpTemperature.value!
          : _simTemperature;
      final fall = (ldr?.isFallDetected.value ?? false) || _simFallDetected;
      final lat = ldr?.latitude.value ?? defaultLatitude;
      final lng = ldr?.longitude.value ?? defaultLongitude;

      return SensorContext(
        heartRateBpm: hr,
        temperatureC: temp,
        isFallDetected: fall,
        latitude: lat,
        longitude: lng,
        distanceToCompanionMeters: liveDistance ?? _simDistance,
        safeRadiusMeters: safeRadius,
        source: SensorDataSource.simulation,
        capturedAt: DateTime.now(),
      );
    }

    // 3. Jika ada data terakhir yang tersimpan di SmartbandLdrController
    if (ldr != null && ldr.hasRestoredData.value) {
      return SensorContext(
        heartRateBpm: (ldr.heartRate.value != null && ldr.heartRate.value! > 0)
            ? ldr.heartRate.value!
            : defaultHeartRateBpm,
        temperatureC:
            (ldr.mcpTemperature.value != null && ldr.mcpTemperature.value! > 0)
            ? ldr.mcpTemperature.value!
            : defaultTemperatureC,
        isFallDetected: ldr.isFallDetected.value,
        latitude:
            ldr.lastKnownLatitude.value ??
            haji?.myCurrentPosition.value?.latitude ??
            defaultLatitude,
        longitude:
            ldr.lastKnownLongitude.value ??
            haji?.myCurrentPosition.value?.longitude ??
            defaultLongitude,
        distanceToCompanionMeters: liveDistance ?? defaultDistanceMeters,
        safeRadiusMeters: safeRadius,
        source: SensorDataSource.lastKnown,
        capturedAt: ldr.lastDataReceivedAt.value ?? DateTime.now(),
      );
    }

    // 4. Fallback nilai demo realistis agar kapan saja siap didemokan
    return SensorContext(
      heartRateBpm: defaultHeartRateBpm,
      temperatureC: defaultTemperatureC,
      isFallDetected: false,
      latitude: haji?.myCurrentPosition.value?.latitude ?? defaultLatitude,
      longitude: haji?.myCurrentPosition.value?.longitude ?? defaultLongitude,
      distanceToCompanionMeters: liveDistance ?? defaultDistanceMeters,
      safeRadiusMeters: safeRadius,
      source: SensorDataSource.demo,
      capturedAt: DateTime.now(),
    );
  }

  /// Kirim ringkasan OLED ke gelang pintar melalui BLE RX Characteristic
  /// (`6e400002-b5a3-f393-e0a9-e50e24dcca9e`) dengan format `"AI:<teks>"`
  /// (dipotong aman maksimal 55 karakter ASCII, bersih dari newline & emoji).
  ///
  /// Jika BLE belum terhubung, mengembalikan [OledDeliveryStatus.previewOnly]
  /// agar pratinjau OLED 128x64 di aplikasi tetap menampilkan pesan tersebut.
  Future<OledDisplayState> sendOledToSmartband(String rawOledText) async {
    final sanitizedText = OledTextFormatter.sanitize(rawOledText);
    final effectiveText = sanitizedText.isNotEmpty
        ? sanitizedText
        : 'Kondisi Anda terpantau stabil';
    final payload = OledTextFormatter.buildPayload(effectiveText);

    // Sinkronkan juga ke state layar OLED pada SmartbandLdrController bila terdaftar
    final ldr = _ldrCtrl;
    if (ldr != null) {
      final wrapped = OledTextFormatter.wrap(effectiveText, width: 16);
      if (wrapped.isNotEmpty) {
        ldr.lcdLine1.value = wrapped.first.padRight(16).substring(0, 16);
      }
      if (wrapped.length > 1) {
        ldr.lcdLine2.value = wrapped[1].padRight(16).substring(0, 16);
      }
    }

    final ble = _bleService;
    if (ble != null && ble.isConnected && ble.canWriteCommand) {
      final ok = await ble.sendAiOledPayload(payload);
      return OledDisplayState(
        text: effectiveText,
        payload: payload,
        status: ok
            ? OledDeliveryStatus.deliveredBle
            : OledDeliveryStatus.failed,
        updatedAt: DateTime.now(),
      );
    }

    return OledDisplayState(
      text: effectiveText,
      payload: payload,
      status: OledDeliveryStatus.previewOnly,
      updatedAt: DateTime.now(),
    );
  }

  /// Pindai & hubungkan gelang BLE.
  Future<void> connectSmartband() async {
    final ldr = _ldrCtrl;
    if (ldr != null) {
      await ldr.connectSmartband();
      return;
    }
    final ble = _bleService;
    if (ble != null) {
      await ble.scanSmartband(autoConnect: true);
    }
  }
}

