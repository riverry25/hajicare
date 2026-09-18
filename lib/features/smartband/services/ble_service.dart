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
  static const String ldrCharacteristicUuid = '12345678-1234-1234-1234-1234567890ac';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _ldrCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _valueSubscription;

  // Callbacks for notifying controller of events
  void Function(int ldrValue, String rawString)? onDataReceived;
  void Function(bool isConnected)? onConnectionChanged;
  void Function(String message)? onStatusLog;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;

  /// Check if Bluetooth is available and turned on.
  Future<bool> isBluetoothEnabled() async {
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
    final enabled = await isBluetoothEnabled();
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
    Timer? timeoutTimer;

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.advertisementData.advName;

        if (name.trim() == targetDeviceName) {
          onStatusLog?.call('Ditemukan perangkat: $name');
          timeoutTimer?.cancel();
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

    timeoutTimer = Timer(timeout, () async {
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
      timeoutTimer.cancel();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      if (!completer.isCompleted) {
        completer.completeError(
          BleException('Gagal memulai scan BLE: $e', code: 'SCAN_FAILED'),
        );
      }
    }

    return completer.future;
  }

  /// Connect to the specified device and discover services & characteristics.
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      onStatusLog?.call('Menghubungkan ke ${device.platformName}...');

      await device.connect(
        license: License.free,
        autoConnect: false,
        timeout: const Duration(seconds: 15),
      );

      _connectedDevice = device;

      // Listen for connection state changes (e.g. unexpected disconnection)
      await _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          onStatusLog?.call('Perangkat terputus.');
          _handleDisconnection();
        } else if (state == BluetoothConnectionState.connected) {
          onConnectionChanged?.call(true);
        }
      });

      onStatusLog?.call('Mencari BLE Service...');
      final services = await device.discoverServices();

      // Look for the target service UUID
      BluetoothService? targetService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
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

      onStatusLog?.call('Mencari Characteristic LDR...');
      BluetoothCharacteristic? ldrChar;
      for (final characteristic in targetService.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() ==
            ldrCharacteristicUuid.toLowerCase()) {
          ldrChar = characteristic;
          break;
        }
      }

      if (ldrChar == null) {
        await disconnect();
        throw const BleException(
          'LDR sensor characteristic tidak ditemukan.',
          code: 'CHARACTERISTIC_NOT_FOUND',
        );
      }

      _ldrCharacteristic = ldrChar;

      // Enable notifications and listen to incoming LDR stream
      onStatusLog?.call('Mengaktifkan notifikasi data sensor...');
      await ldrChar.setNotifyValue(true);

      await _valueSubscription?.cancel();
      _valueSubscription = ldrChar.onValueReceived.listen((bytes) {
        _processReceivedData(bytes);
      });

      onConnectionChanged?.call(true);
      onStatusLog?.call('Terhubung & Sync BLE Aktif');
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

  /// Disconnect cleanly from the currently connected device.
  Future<void> disconnect() async {
    try {
      await _valueSubscription?.cancel();
      _valueSubscription = null;

      if (_ldrCharacteristic != null) {
        try {
          await _ldrCharacteristic?.setNotifyValue(false);
        } catch (_) {}
        _ldrCharacteristic = null;
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
    _valueSubscription?.cancel();
    _valueSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    onConnectionChanged?.call(false);
  }

  /// Cancel all active subscriptions and dispose resources.
  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    await disconnect();
  }
}
