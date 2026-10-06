import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../models/smartband_data.dart';
import '../services/smartband_ble_service.dart';

/// Controller GetX untuk Halaman Uji Coba BLE Smartband ESP32-S3
class SmartbandBleTestController extends GetxController {
  final SmartbandBleService bleService;

  SmartbandBleTestController({SmartbandBleService? service})
    : bleService = service ?? SmartbandBleService();

  // Observable States
  final Rx<SmartbandBleStatus> connectionStatus =
      SmartbandBleStatus.disconnected.obs;
  final Rx<BluetoothDevice?> foundDevice = Rx<BluetoothDevice?>(null);
  final Rx<SmartbandData?> currentData = Rx<SmartbandData?>(null);
  final RxList<String> logs = <String>[].obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription<SmartbandBleStatus>? _statusSub;
  StreamSubscription<SmartbandData>? _dataSub;
  StreamSubscription<BluetoothDevice?>? _deviceSub;
  StreamSubscription<String>? _logSub;

  @override
  void onInit() {
    super.onInit();
    _subscribeToService();
  }

  void _subscribeToService() {
    connectionStatus.value = bleService.currentStatus;
    foundDevice.value = bleService.foundDevice;
    currentData.value = bleService.lastData?.copyWith(
      latitude: SmartbandData.staticDefaultLatitude,
      longitude: SmartbandData.staticDefaultLongitude,
      isValidLocation: true,
    );

    _statusSub = bleService.connectionStateStream.listen((status) {
      connectionStatus.value = status;
      if (status == SmartbandBleStatus.disconnected) {
        if (errorMessage.isEmpty && currentData.value != null) {
          errorMessage.value = 'Koneksi ke Smartband terputus.';
        }
      } else if (status == SmartbandBleStatus.connected) {
        errorMessage.value = '';
      }
    });

    _dataSub = bleService.receivedSmartbandData.listen((data) {
      // Data GPS dibuat statis, data lainnya (heartRate, braceletId) tetap dinamis mengikuti BLE
      currentData.value = data.copyWith(
        latitude: SmartbandData.staticDefaultLatitude,
        longitude: SmartbandData.staticDefaultLongitude,
        isValidLocation: true,
      );
    });

    _deviceSub = bleService.foundDeviceStream.listen((dev) {
      foundDevice.value = dev;
    });

    _logSub = bleService.statusMessageStream.listen((msg) {
      logs.insert(
        0,
        '[${DateTime.now().toIso8601String().substring(11, 19)}] $msg',
      );
      if (logs.length > 50) {
        logs.removeLast();
      }
    });
  }

  /// Mulai pemindaian BLE
  Future<void> startScan() async {
    errorMessage.value = '';
    try {
      await bleService.scanSmartband();
    } catch (e) {
      errorMessage.value = 'Gagal memindai: $e';
    }
  }

  /// Hubungkan ke perangkat yang ditemukan
  Future<void> connect() async {
    errorMessage.value = '';
    try {
      await bleService.connectToSmartband();
    } catch (e) {
      errorMessage.value = 'Gagal menghubungkan: $e';
    }
  }

  /// Putuskan koneksi
  Future<void> disconnect() async {
    try {
      await bleService.disconnectSmartband();
    } catch (e) {
      errorMessage.value = 'Gagal disconnect: $e';
    }
  }

  /// Bersihkan log riwayat
  void clearLogs() {
    logs.clear();
  }

  @override
  void onClose() {
    _statusSub?.cancel();
    _dataSub?.cancel();
    _deviceSub?.cancel();
    _logSub?.cancel();
    bleService.dispose();
    super.onClose();
  }
}
