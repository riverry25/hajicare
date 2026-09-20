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
/// and realtime notification listening for HajiCare Watch.
class BleService {
  static const String targetDeviceName = 'HajiCare Watch';
  static const String serviceUuid = '12345678-1234-1234-1234-1234567890ab';
  static const String ldrCharacteristicUuid =
      '12345678-1234-1234-1234-1234567890ac';
  static const String flameCharacteristicUuid =
      '12345678-1234-1234-1234-1234567890ad';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _ldrCharacteristic;
  BluetoothCharacteristic? _flameCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription<List<int>>? _flameSubscription;
  Timer? _scanTimeoutTimer;
  Completer<BluetoothDevice>? _scanCompleter;
  bool _isDisposed = false;
  int _generation = 0;

  // Callbacks for notifying controller of events
  void Function(int ldrValue, String rawString)? onDataReceived;
  void Function(bool flameDetected, String rawString)? onFlameDataReceived;
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

  /// Connect to the specified device and discover services & characteristics.
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isDisposed) {
      throw const BleException('Layanan gelang sudah ditutup.', code: 'CLOSED');
    }
    final generation = _generation;
    try {
      onStatusLog?.call('Menghubungkan gelang...');

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
      // CONNECTION STATE
      // ==========================================

      await _connectionSubscription?.cancel();

      _connectionSubscription = device.connectionState.listen((state) {
        if (_isDisposed || generation != _generation) return;
        if (state == BluetoothConnectionState.disconnected) {
          onStatusLog?.call('Perangkat terputus.');
          _handleDisconnection();
        } else if (state == BluetoothConnectionState.connected) {
          onConnectionChanged?.call(true);
        }
      });

      // ==========================================
      // DISCOVER SERVICES
      // ==========================================

      onStatusLog?.call('Menyiapkan gelang...');

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
          'BLE Service tidak ditemukan pada perangkat.',
          code: 'SERVICE_NOT_FOUND',
        );
      }

      // ==========================================
      // FIND LDR + FLAME CHARACTERISTIC
      // ==========================================

      BluetoothCharacteristic? ldrChar;
      BluetoothCharacteristic? flameChar;

      for (final characteristic in targetService.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();

        if (uuid == ldrCharacteristicUuid.toLowerCase()) {
          ldrChar = characteristic;
        }

        if (uuid == flameCharacteristicUuid.toLowerCase()) {
          flameChar = characteristic;
        }
      }

      // ==========================================
      // VALIDATE LDR
      // ==========================================

      if (ldrChar == null) {
        await disconnect();

        throw const BleException(
          'LDR sensor characteristic tidak ditemukan.',
          code: 'LDR_CHARACTERISTIC_NOT_FOUND',
        );
      }

      // ==========================================
      // VALIDATE FLAME
      // ==========================================

      if (flameChar == null) {
        await disconnect();

        throw const BleException(
          'Flame sensor characteristic tidak ditemukan.',
          code: 'FLAME_CHARACTERISTIC_NOT_FOUND',
        );
      }

      _ldrCharacteristic = ldrChar;
      _flameCharacteristic = flameChar;

      // ==========================================
      // LDR NOTIFICATION
      // ==========================================

      onStatusLog?.call('Menyiapkan sensor cahaya...');

      await _valueSubscription?.cancel();

      _valueSubscription = ldrChar.onValueReceived.listen((bytes) {
        _processReceivedData(bytes);
      });

      device.cancelWhenDisconnected(_valueSubscription!);

      await ldrChar.setNotifyValue(true);
      _ensureActive(generation);

      // ==========================================
      // FLAME NOTIFICATION
      // ==========================================

      onStatusLog?.call('Menyiapkan sensor api...');

      await _flameSubscription?.cancel();

      _flameSubscription = flameChar.onValueReceived.listen((bytes) {
        _processFlameData(bytes);
      });

      device.cancelWhenDisconnected(_flameSubscription!);

      await flameChar.setNotifyValue(true);
      _ensureActive(generation);

      // ==========================================
      // SUCCESS
      // ==========================================

      onConnectionChanged?.call(true);

      onStatusLog?.call('Gelang terhubung');
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

  /// Process incoming byte stream from ESP32 notification.
  void _processReceivedData(List<int> bytes) {
    if (_isDisposed) return;
    if (bytes.isEmpty) return;
    try {
      final rawString = utf8.decode(bytes).trim();
      final parsed = int.tryParse(rawString);
      if (parsed != null) {
        onDataReceived?.call(parsed, rawString);
      }
    } catch (e) {
      debugPrint('Error decoding LDR BLE data: $e');
    }
  }

  void _processFlameData(List<int> bytes) {
    if (_isDisposed) return;
    if (bytes.isEmpty) return;

    try {
      final rawString = utf8.decode(bytes).trim();

      final flameDetected = rawString.toUpperCase() == 'FIRE';

      debugPrint('FLAME BLE: $rawString');

      onFlameDataReceived?.call(flameDetected, rawString);
    } catch (e) {
      debugPrint('Error decoding Flame BLE data: $e');
    }
  }

  /// Disconnect cleanly from the currently connected device.
  Future<void> disconnect() async {
    try {
      await _valueSubscription?.cancel();
      _valueSubscription = null;

      await _flameSubscription?.cancel();
      _flameSubscription = null;

      if (_ldrCharacteristic != null) {
        try {
          await _ldrCharacteristic?.setNotifyValue(false);
        } catch (_) {}
        _ldrCharacteristic = null;
      }
      if (_flameCharacteristic != null) {
        try {
          await _flameCharacteristic?.setNotifyValue(false);
        } catch (_) {}

        _flameCharacteristic = null;
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

    _ldrCharacteristic = null;
    _flameCharacteristic = null;

    _valueSubscription?.cancel();
    _valueSubscription = null;

    _flameSubscription?.cancel();
    _flameSubscription = null;

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
    onDataReceived = null;
    onFlameDataReceived = null;
    onConnectionChanged = null;
    onStatusLog = null;
    await disconnect();
  }
}
