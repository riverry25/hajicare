import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/smartband_data.dart';

/// Enum representasi status koneksi BLE Smartband
enum SmartbandBleStatus { disconnected, scanning, connecting, connected }

/// Service komunikasi Bluetooth Low Energy (BLE) untuk Smartband HajiCare ESP32-S3
class SmartbandBleService {
  // Identitas BLE Perangkat
  static const String targetDeviceName = 'HajiCare-Gelang-001';
  static const String targetBraceletId = 'HCG-001';
  static const String serviceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String dataCharacteristicUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  // Perangkat aktif & characteristic
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? _foundDevice;
  BluetoothCharacteristic? _dataCharacteristic;

  // Stream Controllers
  final _connectionStatusController =
      StreamController<SmartbandBleStatus>.broadcast();
  final _smartbandDataController = StreamController<SmartbandData>.broadcast();
  final _foundDeviceController = StreamController<BluetoothDevice?>.broadcast();
  final _statusMessageController = StreamController<String>.broadcast();

  // Subscriptions
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  Timer? _scanTimeoutTimer;

  // State internal
  SmartbandBleStatus _currentStatus = SmartbandBleStatus.disconnected;
  SmartbandData? _lastData;
  bool _isDisposed = false;

  // Getters publik
  SmartbandBleStatus get currentStatus => _currentStatus;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothDevice? get foundDevice => _foundDevice;
  SmartbandData? get lastData => _lastData;
  bool get isConnected => _currentStatus == SmartbandBleStatus.connected;

  // Streams publik
  Stream<SmartbandBleStatus> get connectionStateStream =>
      _connectionStatusController.stream;
  Stream<SmartbandData> get receivedSmartbandData =>
      _smartbandDataController.stream;
  Stream<BluetoothDevice?> get foundDeviceStream =>
      _foundDeviceController.stream;
  Stream<String> get statusMessageStream => _statusMessageController.stream;

  SmartbandBleService() {
    _emitStatus(SmartbandBleStatus.disconnected);
  }

  /// Update status koneksi dan kirim ke broadcast stream
  void _emitStatus(SmartbandBleStatus status) {
    _currentStatus = status;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(status);
    }
  }

  /// Kirim pesan status/log ke UI dan debug console
  void _log(String message) {
    debugPrint(message);
    if (!_statusMessageController.isClosed) {
      _statusMessageController.add(message);
    }
  }

  /// Periksa ketersediaan dan status aktif adapter Bluetooth dengan log lengkap
  Future<bool> isBluetoothAvailable() async {
    _log('BLE START');
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      _log('BLE supported: ${isSupported ? "YES" : "NO"}');
      if (!isSupported) {
        _log('Bluetooth Low Energy tidak didukung pada perangkat ini.');
        return false;
      }

      // Tunggu hingga adapter state bernilai definitif (bukan unknown)
      BluetoothAdapterState state = FlutterBluePlus.adapterStateNow;
      if (state == BluetoothAdapterState.unknown) {
        state = await FlutterBluePlus.adapterState
            .where((s) => s != BluetoothAdapterState.unknown)
            .first
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () => FlutterBluePlus.adapterStateNow,
            );
      }

      final isPermissionGranted = state != BluetoothAdapterState.unauthorized;
      _log(
        'Bluetooth permission: ${isPermissionGranted ? "GRANTED" : "DENIED"}',
      );
      _log(
        'Bluetooth adapter: ${state == BluetoothAdapterState.on ? "ON" : "OFF"} ($state)',
      );

      if (state == BluetoothAdapterState.unauthorized) {
        _log('Izin Bluetooth belum diberikan di pengaturan aplikasi.');
        return false;
      }

      if (state == BluetoothAdapterState.off) {
        _log('Bluetooth dalam keadaan OFF.');
        try {
          _log('Mencoba menyalakan Bluetooth adapter...');
          await FlutterBluePlus.turnOn();
          final nextState = await FlutterBluePlus.adapterState
              .where((s) => s != BluetoothAdapterState.off)
              .first
              .timeout(
                const Duration(seconds: 4),
                onTimeout: () => FlutterBluePlus.adapterStateNow,
              );
          _log('Bluetooth adapter setelah turnOn: $nextState');
          return nextState == BluetoothAdapterState.on;
        } catch (e) {
          _log('Tidak dapat menyalakan Bluetooth otomatis: $e');
          return false;
        }
      }

      return state == BluetoothAdapterState.on;
    } catch (e) {
      _log('Gagal memeriksa status Bluetooth: $e');
      return false;
    }
  }

  /// 1. Pindai (Scan) Smartband BLE
  /// Mencari perangkat dengan nama "HajiCare-Gelang-001" atau Service UUID target
  Future<void> scanSmartband({
    Duration timeout = const Duration(seconds: 15),
    bool autoConnect = false,
  }) async {
    if (_isDisposed) return;

    final isReady = await isBluetoothAvailable();
    if (!isReady) {
      _log(
        'Bluetooth belum aktif atau izin belum diberikan. Aktifkan Bluetooth & beri izin Nearby Devices di HP.',
      );
      throw Exception('Bluetooth tidak aktif atau izin ditolak');
    }

    if (_currentStatus == SmartbandBleStatus.connected) {
      _log(
        'Perangkat sudah terhubung. Disconnect terlebih dahulu untuk scan ulang.',
      );
      return;
    }

    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }

      _emitStatus(SmartbandBleStatus.scanning);
      _foundDevice = null;
      _foundDeviceController.add(null);
      _log('SCAN START');

      final targetUuidNormalized = serviceUuid.toLowerCase().replaceAll(
        '-',
        '',
      );

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (final result in results) {
            final pName = result.device.platformName.trim();
            final advName = result.advertisementData.advName.trim();
            final effectiveName = pName.isNotEmpty ? pName : advName;
            final remoteId = result.device.remoteId.str;
            final rssi = result.rssi;
            final serviceUuids = result.advertisementData.serviceUuids
                .map((u) => u.toString())
                .toList();

            _log('SCAN RESULT');
            _log(
              'name: ${effectiveName.isNotEmpty ? effectiveName : "(kosong)"}',
            );
            _log('platformName: $pName');
            _log('advertisement name: $advName');
            _log('remoteId: $remoteId');
            _log(
              'service UUID: ${serviceUuids.isNotEmpty ? serviceUuids.join(", ") : "(none)"}',
            );
            _log('rssi: $rssi');

            // Cek pencocokan target via Nama ATAU via Service UUID
            final matchesName =
                effectiveName.toLowerCase() == targetDeviceName.toLowerCase() ||
                effectiveName.toLowerCase().startsWith('hajicare-gelang') ||
                effectiveName.toLowerCase().contains('hcg-001');

            final matchesService = result.advertisementData.serviceUuids.any(
              (u) =>
                  u.toString().toLowerCase().replaceAll('-', '') ==
                  targetUuidNormalized,
            );

            if (matchesName || matchesService) {
              _log('DEVICE FOUND');
              _log('Name: $effectiveName');
              _log('ID: $remoteId');
              _log('RSSI: $rssi');

              _foundDevice = result.device;
              _foundDeviceController.add(result.device);
              _stopScanInternal();
              if (autoConnect) {
                unawaited(connectToSmartband(result.device));
              }
              break;
            }
          }
        },
        onError: (e) {
          _log('Error saat memindai BLE: $e');
          _stopScanInternal();
        },
      );

      await FlutterBluePlus.startScan(timeout: timeout);

      _scanTimeoutTimer?.cancel();
      _scanTimeoutTimer = Timer(timeout, () {
        if (_currentStatus == SmartbandBleStatus.scanning) {
          _log(
            'SCAN TIMEOUT: Device target "$targetDeviceName" tidak ditemukan dalam rentang waktu.',
          );
          _stopScanInternal();
        }
      });
    } catch (e) {
      _log('Gagal memulai scan BLE: $e');
      _stopScanInternal();
      rethrow;
    }
  }

  void _stopScanInternal() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;

    if (FlutterBluePlus.isScanningNow) {
      FlutterBluePlus.stopScan().catchError((_) {});
    }

    if (_currentStatus == SmartbandBleStatus.scanning) {
      _emitStatus(
        _connectedDevice != null
            ? SmartbandBleStatus.connected
            : SmartbandBleStatus.disconnected,
      );
    }
  }

  /// Hentikan pemindaian secara manual
  Future<void> stopScan() async {
    _stopScanInternal();
    _log('Pemindaian BLE dihentikan');
  }

  /// 2. Hubungkan ke Smartband
  Future<void> connectToSmartband([BluetoothDevice? target]) async {
    if (_isDisposed) return;

    final device = target ?? _foundDevice;
    if (device == null) {
      _log('Target perangkat belum ditemukan untuk dihubungkan.');
      throw Exception('Target perangkat belum ditemukan');
    }

    await stopScan();

    _emitStatus(SmartbandBleStatus.connecting);
    final devId = device.remoteId.str;
    _log('CONNECT START');
    _log('deviceId: $devId');

    try {
      await _deviceConnectionSubscription?.cancel();
      _deviceConnectionSubscription = device.connectionState.listen(
        (connectionState) {
          _log('CONNECTION STATE: $connectionState');
          if (connectionState == BluetoothConnectionState.disconnected) {
            _handleSafeDisconnection(
              'BLE DISCONNECTED: Terputus dari perangkat.',
            );
          }
        },
        onError: (e) {
          _log('Error status koneksi hardware: $e');
        },
      );

      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _connectedDevice = device;
      _log('CONNECT SUCCESS');
      _log('CONNECTION STATE:\nCONNECTED');

      // 3. Discover Services
      await discoverServices(device);

      _emitStatus(SmartbandBleStatus.connected);
    } catch (e) {
      _log('CONNECT FAILED');
      _log('error: $e');
      await disconnectSmartband();
      rethrow;
    }
  }

  /// 3. Discover BLE Services dan cari Service UUID Smartband
  Future<void> discoverServices([BluetoothDevice? device]) async {
    final dev = device ?? _connectedDevice;
    if (dev == null) {
      throw Exception('Perangkat belum terhubung');
    }

    _log('DISCOVER SERVICES');
    final services = await dev.discoverServices();
    for (final service in services) {
      _log('SERVICE FOUND:\n${service.uuid}');
    }

    final targetUuidNormalized = serviceUuid.toLowerCase().replaceAll('-', '');
    BluetoothService? targetService;
    for (final service in services) {
      final sUuid = service.uuid.toString().toLowerCase().replaceAll('-', '');
      if (sUuid == targetUuidNormalized) {
        targetService = service;
        break;
      }
    }

    if (targetService == null) {
      _log('SERVICE NOT FOUND\nexpected:\n$serviceUuid');
      throw Exception(
        'Service UUID $serviceUuid tidak ditemukan pada Smartband',
      );
    }

    _log('TARGET SERVICE MATCHED: ${targetService.uuid}');

    // 4. Discover Characteristic
    final targetCharUuidNormalized = dataCharacteristicUuid
        .toLowerCase()
        .replaceAll('-', '');
    BluetoothCharacteristic? targetChar;
    for (final char in targetService.characteristics) {
      final cUuid = char.uuid.toString().toLowerCase().replaceAll('-', '');
      final p = char.properties;

      _log('CHARACTERISTIC FOUND');
      _log('UUID: ${char.uuid}');
      _log(
        'properties: read=${p.read}, write=${p.write}, notify=${p.notify}, indicate=${p.indicate}',
      );
      _log('canRead: ${p.read}');
      _log('canNotify: ${p.notify || p.indicate}');

      if (cUuid == targetCharUuidNormalized) {
        targetChar = char;
      }
    }

    if (targetChar == null) {
      _log('CHARACTERISTIC NOT FOUND\nexpected:\n$dataCharacteristicUuid');
      throw Exception(
        'Characteristic UUID $dataCharacteristicUuid tidak ditemukan',
      );
    }

    _dataCharacteristic = targetChar;

    // 5. Subscribe ke BLE Notification
    await subscribeToDataNotification(targetChar);
  }

  /// 4. Subscribe ke BLE Notification data karakteristik
  Future<void> subscribeToDataNotification([
    BluetoothCharacteristic? characteristic,
  ]) async {
    final char = characteristic ?? _dataCharacteristic;
    if (char == null) {
      throw Exception('Data Characteristic belum siap');
    }

    final dev = _connectedDevice;
    if (dev == null) {
      throw Exception('Perangkat tidak terhubung');
    }

    _log('NOTIFICATION START');

    try {
      await _notificationSubscription?.cancel();
      _notificationSubscription = char.onValueReceived.listen(
        (bytes) {
          _handleIncomingBytes(bytes);
        },
        onError: (e) {
          _log('Error notification stream: $e');
        },
      );

      dev.cancelWhenDisconnected(_notificationSubscription!);
      await char.setNotifyValue(true);
      _log('NOTIFICATION ENABLED');
    } catch (e) {
      _log('NOTIFICATION FAILED\nerror: $e');
      rethrow;
    }
  }

  /// 5. Penanganan paket data byte yang diterima dari ESP32
  void _handleIncomingBytes(List<int> bytes) {
    if (_isDisposed || bytes.isEmpty) return;

    try {
      // 1. Decode UTF-8
      final rawString = utf8.decode(bytes, allowMalformed: true).trim();
      if (rawString.isEmpty) return;

      _log('RAW BLE DATA:\n$rawString');

      // 2. Parse JSON
      final parsedData = SmartbandData.fromRawJson(rawString);

      // 3. Simpan dan pancarkan ke Stream
      _lastData = parsedData;
      if (!_smartbandDataController.isClosed) {
        _smartbandDataController.add(parsedData);
      }

      _log('PARSED BLE DATA');
      _log('braceletId: ${parsedData.braceletId}');
      _log('latitude: ${parsedData.latitude ?? "-"}');
      _log('longitude: ${parsedData.longitude ?? "-"}');
      _log('heartRate: ${parsedData.heartRate}');
    } catch (e) {
      final raw = utf8.decode(bytes, allowMalformed: true);
      _log('JSON PARSE ERROR\nraw data: $raw\nerror: $e');
    }
  }

  /// 6. Tangani koneksi terputus dengan aman (Safe Disconnection)
  void _handleSafeDisconnection(String reason) {
    if (_currentStatus == SmartbandBleStatus.disconnected) return;

    _log('DISCONNECTED: $reason');
    _cleanUpDeviceState();
    _emitStatus(SmartbandBleStatus.disconnected);
  }

  /// Bersihkan state internal koneksi
  void _cleanUpDeviceState() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;

    _scanSubscription?.cancel();
    _scanSubscription = null;

    _notificationSubscription?.cancel();
    _notificationSubscription = null;

    _deviceConnectionSubscription?.cancel();
    _deviceConnectionSubscription = null;

    _dataCharacteristic = null;
    _connectedDevice = null;
  }

  /// 7. Putuskan koneksi Smartband secara manual dan aman
  Future<void> disconnectSmartband() async {
    _log('Memutuskan koneksi Smartband secara aman...');
    try {
      if (_dataCharacteristic != null) {
        try {
          await _dataCharacteristic?.setNotifyValue(false);
        } catch (_) {}
      }

      if (_connectedDevice != null) {
        await _connectedDevice?.disconnect();
      }
    } catch (e) {
      _log('Catatan saat disconnect: $e');
    } finally {
      _cleanUpDeviceState();
      _emitStatus(SmartbandBleStatus.disconnected);
      _log('Koneksi Smartband telah terputus.');
    }
  }

  /// Bersihkan semua stream dan listener saat service ditutup
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    disconnectSmartband();

    _connectionStatusController.close();
    _smartbandDataController.close();
    _foundDeviceController.close();
    _statusMessageController.close();
  }
}
