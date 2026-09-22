import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Exception thrown for specific BLE workflow errors
class BleException implements Exception {
  final String message;
  final String? code;

  const BleException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Service handling BLE scanning, connection, service/characteristic discovery,
/// initial characteristic read, and realtime notification listening for HajiCare Watch
/// using the DHT11 Environmental Sensor.
class BleService {
  static const String targetDeviceName = 'HajiCare Watch';
  static const String serviceUuid = '12345678-1234-1234-1234-1234567890ab';

  // 3 Distinct Characteristics for DHT11 on ESP32
  static const String temperatureCharacteristicUuid =
      '12345678-1234-1234-1234-1234567890ac';
  static const String humidityCharacteristicUuid =
      '12345678-1234-1234-1234-1234567890ad';
  static const String heatIndexCharacteristicUuid =
      '12345678-1234-1234-1234-1234567890ae';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _tempCharacteristic;
  BluetoothCharacteristic? _humCharacteristic;
  BluetoothCharacteristic? _hiCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _tempSubscription;
  StreamSubscription<List<int>>? _humSubscription;
  StreamSubscription<List<int>>? _hiSubscription;

  Timer? _scanTimeoutTimer;
  Completer<BluetoothDevice>? _scanCompleter;
  bool _isDisposed = false;
  int _generation = 0;

  // Callbacks for notifying controller of sensor updates
  void Function(double? temperature, String rawString)? onTemperatureReceived;
  void Function(double? humidity, String rawString)? onHumidityReceived;
  void Function(double? heatIndex, String rawString)? onHeatIndexReceived;
  void Function(String error)? onSensorError;
  void Function(bool isConnected)? onConnectionChanged;
  void Function(String message)? onStatusLog;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;

  /// Check if Bluetooth is available and turned on.
  Future<bool> isBluetoothEnabled() async {
    if (_isDisposed) return false;
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) return false;

      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('Error checking Bluetooth state: $e');
      return false;
    }
  }

  /// Request to turn on Bluetooth (Android only, no-op on iOS)
  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      debugPrint('Error turning on Bluetooth: $e');
    }
  }

  /// Start scanning for the target device "HajiCare Watch".
  /// Returns the found [BluetoothDevice] or throws a [BleException].
  Future<BluetoothDevice> scanForDevice({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_isDisposed) {
      throw const BleException('Layanan gelang sudah ditutup.', code: 'CLOSED');
    }
    final generation = _generation;
    final enabled = await isBluetoothEnabled();
    _ensureActive(generation);
    if (!enabled) {
      throw const BleException(
        'Bluetooth tidak aktif. Silakan aktifkan Bluetooth pada perangkat.',
        code: 'BLUETOOTH_OFF',
      );
    }

    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    final completer = Completer<BluetoothDevice>();
    _scanCompleter = completer;

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (_isDisposed || generation != _generation) return;
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.advertisementData.advName;

        if (name.trim() == targetDeviceName) {
          onStatusLog?.call('Gelang ditemukan: $name');
          _scanTimeoutTimer?.cancel();
          _scanSubscription?.cancel();
          _scanSubscription = null;
          FlutterBluePlus.stopScan();
          if (!completer.isCompleted) {
            completer.complete(result.device);
          }
          break;
        }
      }
    });

    _scanTimeoutTimer = Timer(timeout, () async {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      await FlutterBluePlus.stopScan();
      if (!completer.isCompleted) {
        completer.completeError(
          const BleException(
            'Gelang tidak ditemukan. Pastikan ESP32 HajiCare Watch menyala dan berada di dekat perangkat.',
            code: 'DEVICE_NOT_FOUND',
          ),
        );
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      _scanTimeoutTimer?.cancel();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      if (!completer.isCompleted) {
        completer.completeError(
          BleException('Gagal memulai scan BLE: $e', code: 'SCAN_FAILED'),
        );
      }
    }

    try {
      return await completer.future;
    } finally {
      if (identical(_scanCompleter, completer)) {
        _scanCompleter = null;
        _scanTimeoutTimer = null;
      }
    }
  }

  /// Connect to the specified device, discover services, find the 3 characteristics,
  /// read initial values, and subscribe to notifications.
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isDisposed) {
      throw const BleException('Layanan gelang sudah ditutup.', code: 'CLOSED');
    }
    final generation = _generation;
    try {
      onStatusLog?.call('Menghubungkan ke HajiCare Watch...');

      await device.connect(
        license: License.nonprofit,
        autoConnect: false,
        timeout: const Duration(seconds: 15),
      );
      if (_isDisposed || generation != _generation) {
        await device.disconnect();
        _ensureActive(generation);
      }

      _connectedDevice = device;

      // ==========================================
      // 1. CONNECTION STATE LISTENER
      // ==========================================

      await _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (_isDisposed || generation != _generation) return;
        if (state == BluetoothConnectionState.disconnected) {
          onStatusLog?.call('HajiCare Watch terputus');
          _handleDisconnection();
        } else if (state == BluetoothConnectionState.connected) {
          onConnectionChanged?.call(true);
        }
      });

      // ==========================================
      // 2. DISCOVER BLE SERVICES
      // ==========================================

      onStatusLog?.call('Mencari service sensor...');

      final services = await device.discoverServices();
      _ensureActive(generation);

      BluetoothService? targetService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() ==
            serviceUuid.toLowerCase()) {
          targetService = service;
          break;
        }
      }

      if (targetService == null) {
        await disconnect();
        throw const BleException(
          'BLE Service sensor tidak ditemukan pada ESP32.',
          code: 'SERVICE_NOT_FOUND',
        );
      }

      // ==========================================
      // 3. DISCOVER 3 SENSOR CHARACTERISTICS
      // ==========================================

      BluetoothCharacteristic? tempChar;
      BluetoothCharacteristic? humChar;
      BluetoothCharacteristic? hiChar;

      for (final characteristic in targetService.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();
        if (uuid == temperatureCharacteristicUuid.toLowerCase()) {
          tempChar = characteristic;
        } else if (uuid == humidityCharacteristicUuid.toLowerCase()) {
          humChar = characteristic;
        } else if (uuid == heatIndexCharacteristicUuid.toLowerCase()) {
          hiChar = characteristic;
        }
      }

      if (tempChar == null || humChar == null || hiChar == null) {
        await disconnect();
        final missing = <String>[];
        if (tempChar == null) missing.add('Temperature');
        if (humChar == null) missing.add('Humidity');
        if (hiChar == null) missing.add('Heat Index');
        throw BleException(
          'Karakteristik sensor tidak ditemukan: ${missing.join(', ')}.',
          code: 'CHARACTERISTIC_NOT_FOUND',
        );
      }

      _tempCharacteristic = tempChar;
      _humCharacteristic = humChar;
      _hiCharacteristic = hiChar;

      // ==========================================
      // 4. READ INITIAL VALUES (PROPERTY_READ)
      // ==========================================

      onStatusLog?.call('Membaca data awal sensor...');

      try {
        final tempBytes = await tempChar.read();
        _processTemperatureData(tempBytes);
      } catch (e) {
        debugPrint('Error reading initial temperature: $e');
      }

      try {
        final humBytes = await humChar.read();
        _processHumidityData(humBytes);
      } catch (e) {
        debugPrint('Error reading initial humidity: $e');
      }

      try {
        final hiBytes = await hiChar.read();
        _processHeatIndexData(hiBytes);
      } catch (e) {
        debugPrint('Error reading initial heat index: $e');
      }

      // ==========================================
      // 5. SUBSCRIBE NOTIFICATIONS (PROPERTY_NOTIFY)
      // ==========================================

      onStatusLog?.call('Mengaktifkan notifikasi realtime...');

      // 5a. Temperature notification
      await _tempSubscription?.cancel();
      _tempSubscription = tempChar.onValueReceived.listen((bytes) {
        _processTemperatureData(bytes);
      });
      device.cancelWhenDisconnected(_tempSubscription!);
      await tempChar.setNotifyValue(true);
      _ensureActive(generation);

      // 5b. Humidity notification
      await _humSubscription?.cancel();
      _humSubscription = humChar.onValueReceived.listen((bytes) {
        _processHumidityData(bytes);
      });
      device.cancelWhenDisconnected(_humSubscription!);
      await humChar.setNotifyValue(true);
      _ensureActive(generation);

      // 5c. Heat Index notification
      await _hiSubscription?.cancel();
      _hiSubscription = hiChar.onValueReceived.listen((bytes) {
        _processHeatIndexData(bytes);
      });
      device.cancelWhenDisconnected(_hiSubscription!);
      await hiChar.setNotifyValue(true);
      _ensureActive(generation);

      // ==========================================
      // 6. SUCCESS
      // ==========================================

      onConnectionChanged?.call(true);
      onStatusLog?.call('HajiCare Watch terhubung');
    } catch (e) {
      if (e is BleException) {
        rethrow;
      }

      throw BleException(
        'Gagal terhubung: Tidak dapat menghubungkan ke HajiCare Watch ($e)',
        code: 'CONNECTION_FAILED',
      );
    }
  }

  /// Process incoming byte stream for Temperature from ESP32.
  /// Converts String representation (e.g. "31.00") to double.
  void _processTemperatureData(List<int> bytes) {
    if (_isDisposed) return;
    if (bytes.isEmpty) return;

    try {
      final rawString = utf8.decode(bytes).trim();
      if (rawString.isEmpty) return;

      final parsed = double.tryParse(rawString);
      if (parsed != null &&
          !parsed.isNaN &&
          parsed >= -20.0 &&
          parsed <= 80.0) {
        onTemperatureReceived?.call(parsed, rawString);
      } else {
        onSensorError?.call('Format suhu tidak valid: "$rawString"');
      }
    } catch (e) {
      debugPrint('Error decoding temperature: $e');
      onSensorError?.call('Gagal memproses data suhu: $e');
    }
  }

  /// Process incoming byte stream for Humidity from ESP32.
  /// Converts String representation (e.g. "68.00") to double.
  void _processHumidityData(List<int> bytes) {
    if (_isDisposed) return;
    if (bytes.isEmpty) return;

    try {
      final rawString = utf8.decode(bytes).trim();
      if (rawString.isEmpty) return;

      final parsed = double.tryParse(rawString);
      if (parsed != null && !parsed.isNaN && parsed >= 0.0 && parsed <= 100.0) {
        onHumidityReceived?.call(parsed, rawString);
      } else {
        onSensorError?.call('Format kelembapan tidak valid: "$rawString"');
      }
    } catch (e) {
      debugPrint('Error decoding humidity: $e');
      onSensorError?.call('Gagal memproses data kelembapan: $e');
    }
  }

  /// Process incoming byte stream for Heat Index from ESP32.
  /// Converts String representation (e.g. "33.80") to double.
  void _processHeatIndexData(List<int> bytes) {
    if (_isDisposed) return;
    if (bytes.isEmpty) return;

    try {
      final rawString = utf8.decode(bytes).trim();
      if (rawString.isEmpty) return;

      final parsed = double.tryParse(rawString);
      if (parsed != null &&
          !parsed.isNaN &&
          parsed >= -20.0 &&
          parsed <= 100.0) {
        onHeatIndexReceived?.call(parsed, rawString);
      } else {
        onSensorError?.call('Format Heat Index tidak valid: "$rawString"');
      }
    } catch (e) {
      debugPrint('Error decoding heat index: $e');
      onSensorError?.call('Gagal memproses data Heat Index: $e');
    }
  }

  /// Disconnect cleanly from the currently connected device and stop notifications.
  Future<void> disconnect() async {
    try {
      await _tempSubscription?.cancel();
      _tempSubscription = null;

      await _humSubscription?.cancel();
      _humSubscription = null;

      await _hiSubscription?.cancel();
      _hiSubscription = null;

      if (_tempCharacteristic != null) {
        try {
          await _tempCharacteristic?.setNotifyValue(false);
        } catch (_) {}
        _tempCharacteristic = null;
      }

      if (_humCharacteristic != null) {
        try {
          await _humCharacteristic?.setNotifyValue(false);
        } catch (_) {}
        _humCharacteristic = null;
      }

      if (_hiCharacteristic != null) {
        try {
          await _hiCharacteristic?.setNotifyValue(false);
        } catch (_) {}
        _hiCharacteristic = null;
      }

      if (_connectedDevice != null) {
        await _connectedDevice?.disconnect();
        _connectedDevice = null;
      }
    } catch (e) {
      debugPrint('Error during disconnect: $e');
    } finally {
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _connectedDevice = null;
    _tempCharacteristic = null;
    _humCharacteristic = null;
    _hiCharacteristic = null;

    _tempSubscription?.cancel();
    _tempSubscription = null;

    _humSubscription?.cancel();
    _humSubscription = null;

    _hiSubscription?.cancel();
    _hiSubscription = null;

    _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (!_isDisposed) onConnectionChanged?.call(false);
  }

  void _ensureActive(int generation) {
    if (_isDisposed || generation != _generation) {
      throw const BleException('Operasi gelang dibatalkan.', code: 'CLOSED');
    }
  }

  /// Cancel all active subscriptions and dispose resources.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _generation++;
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    final pendingScan = _scanCompleter;
    _scanCompleter = null;
    if (pendingScan != null && !pendingScan.isCompleted) {
      pendingScan.completeError(
        const BleException('Operasi gelang dibatalkan.', code: 'CLOSED'),
      );
    }
    onTemperatureReceived = null;
    onHumidityReceived = null;
    onHeatIndexReceived = null;
    onSensorError = null;
    onConnectionChanged = null;
    onStatusLog = null;
    await disconnect();
  }
}
