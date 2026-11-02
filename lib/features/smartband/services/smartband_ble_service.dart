import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/smartband_data.dart';
import 'smartband_foreground_service.dart';

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
  static const String txCharacteristicUuid = dataCharacteristicUuid;
  static const String rxCharacteristicUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const String audioCharacteristicUuid =
      '6e400004-b5a3-f393-e0a9-e50e24dcca9e';

  // Perangkat aktif & characteristic
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? _foundDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _audioCharacteristic;

  // Stream Controllers
  final _connectionStatusController =
      StreamController<SmartbandBleStatus>.broadcast();
  final _smartbandDataController = StreamController<SmartbandData>.broadcast();
  final _foundDeviceController = StreamController<BluetoothDevice?>.broadcast();
  final _statusMessageController = StreamController<String>.broadcast();
  final _audioStreamController = StreamController<Uint8List>.broadcast();
  final _smartbandAiListeningController =
      StreamController<bool>.broadcast();
  final _completePcmRecordingController =
      StreamController<Uint8List>.broadcast();

  // Buffer akumulator audio PCM 16-bit 8000Hz dari INMP441
  final BytesBuilder _pcmAudioBuffer = BytesBuilder(copy: false);
  bool _isSmartbandRecordingVoice = false;
  Timer? _audioSilenceTimer;

  // Subscriptions
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<List<int>>? _audioNotificationSubscription;
  Timer? _scanTimeoutTimer;

  // State internal
  SmartbandBleStatus _currentStatus = SmartbandBleStatus.disconnected;
  SmartbandData? _lastData;
  bool _isDisposed = false;
  bool _isManualDisconnect = false;
  BluetoothDevice? _lastKnownDevice;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;

  // Buffer untuk reassembly fragment (~%02X%02X%02X:)
  int? _lastSeq;
  final Map<int, String> _fragmentParts = {};
  int _expectedTotal = 0;

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
  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  Stream<bool> get smartbandAiListeningStream =>
      _smartbandAiListeningController.stream;
  Stream<Uint8List> get completePcmAudioRecordingStream =>
      _completePcmRecordingController.stream;
  bool get isSmartbandRecordingVoice => _isSmartbandRecordingVoice;

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
    _lastKnownDevice = device;
    _isManualDisconnect = false;
    _reconnectTimer?.cancel();
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

      // Negosiasi MTU 512 dan prioritas koneksi tinggi (untuk stream audio INMP441 & paket telemetri utuh)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          _log('REQUEST MTU 512');
          final mtu = await device.requestMtu(512);
          _log('MTU NEGOTIATED: $mtu');
        } catch (e) {
          _log('Peringatan: Gagal negosiasi MTU: $e');
        }
        try {
          await device.requestConnectionPriority(
            connectionPriorityRequest: ConnectionPriority.high,
          );
          _log('BLE CONNECTION PRIORITY: HIGH (11.25-15ms interval)');
        } catch (e) {
          _log('Peringatan: Gagal negosiasi connection priority: $e');
        }
      }

      // 3. Discover Services
      await discoverServices(device);

      _emitStatus(SmartbandBleStatus.connected);
      unawaited(
        SmartbandForegroundService.startService(
          title: 'HajiCare Smartband Terhubung',
          message: '❤️ Monitor Sensor & AI Siaga 24/7',
        ),
      );
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

    // 4. Discover Characteristic (TX Notify 6e400003 & RX Write 6e400002)
    final targetCharUuidNormalized = dataCharacteristicUuid
        .toLowerCase()
        .replaceAll('-', '');
    final targetRxUuidNormalized = rxCharacteristicUuid
        .toLowerCase()
        .replaceAll('-', '');
    final targetAudioUuidNormalized = audioCharacteristicUuid
        .toLowerCase()
        .replaceAll('-', '');
    BluetoothCharacteristic? targetChar;
    BluetoothCharacteristic? exactRxChar;
    BluetoothCharacteristic? fallbackWriteChar;
    BluetoothCharacteristic? audioChar;
    for (final char in targetService.characteristics) {
      final cUuid = char.uuid.toString().toLowerCase().replaceAll('-', '');
      final p = char.properties;

      _log('CHARACTERISTIC FOUND: ${char.uuid}');
      _log(
        'properties: read=${p.read}, write=${p.write}, notify=${p.notify}, indicate=${p.indicate}',
      );

      if (cUuid == targetCharUuidNormalized) {
        targetChar = char;
      }
      if (cUuid == targetAudioUuidNormalized) {
        audioChar = char;
      }
      if (cUuid == targetRxUuidNormalized &&
          (p.write || p.writeWithoutResponse)) {
        exactRxChar = char;
      } else if (p.write || p.writeWithoutResponse) {
        fallbackWriteChar = char;
      }
    }
    _writeCharacteristic = exactRxChar ?? fallbackWriteChar;

    if (targetChar == null) {
      _log('CHARACTERISTIC NOT FOUND\nexpected:\n$dataCharacteristicUuid');
      throw Exception(
        'Characteristic UUID $dataCharacteristicUuid tidak ditemukan',
      );
    }

    _dataCharacteristic = targetChar;
    _audioCharacteristic = audioChar;

    // 5. Subscribe ke BLE Notification (Data Telemetri)
    await subscribeToDataNotification(targetChar);

    // 6. Subscribe ke Karakteristik Audio (INMP441 PCM 8kHz) jika ada
    if (audioChar != null) {
      await subscribeToAudioNotification(audioChar);
    }
  }

  /// Indikator apakah characteristic penulisan perintah BLE tersedia
  bool get canWriteCommand => _writeCharacteristic != null;

  /// Kirim perintah teks (misal: "PING", "CANCEL", "PAGE:1", "RADIUS:50", atau `"AI:<teks>"`) ke ESP32
  Future<bool> sendCommand(String cmd) async {
    final char = _writeCharacteristic;
    if (char == null) {
      _log('Characteristic penulisan BLE tidak tersedia');
      return false;
    }
    try {
      _log('SEND COMMAND: $cmd');
      await char.write(
        utf8.encode('$cmd\n'),
        withoutResponse:
            char.properties.writeWithoutResponse && !char.properties.write,
      );
      _log('COMMAND SENT: $cmd');
      return true;
    } catch (e) {
      _log('COMMAND FAILED: $e');
      return false;
    }
  }

  /// Ubah batas Safe Radius pada gelang (meter)
  Future<bool> setSafeRadius(double radiusMeters) async {
    return sendCommand('RADIUS:${radiusMeters.round()}');
  }

  /// Kirim lokasi GPS pendamping ke ESP32 agar gelang dapat menghitung jarak mandiri
  Future<bool> sendCompanionGps(
    double lat,
    double lon, [
    double accuracyM = 10.0,
  ]) async {
    return sendCommand(
      'COMP_GPS:${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)},${accuracyM.toStringAsFixed(1)}',
    );
  }

  /// Kirim jarak jemaah ke pendamping (meter)
  Future<bool> sendDistance(double distanceM, [double? safeRadius]) async {
    if (safeRadius != null) {
      return sendCommand(
        'DIST:${distanceM.toStringAsFixed(1)},${safeRadius.round()}',
      );
    }
    return sendCommand('DIST:${distanceM.toStringAsFixed(1)}');
  }

  /// Pindah halaman OLED pada gelang (0:HR, 1:GPS, 2:Temp, 3:Motion, 4:Safe Radius)
  Future<bool> setOledPage(int page) async {
    return sendCommand('PAGE:$page');
  }

  /// Batalkan alarm/getaran lokal pada gelang
  Future<bool> cancelAlarm() async {
    return sendCommand('CANCEL');
  }

  /// Ping perangkat untuk meminta paket telemetri segera
  Future<bool> ping() async {
    return sendCommand('PING');
  }

  /// Aktifkan mode perekaman suara mikrofon INMP441 dari aplikasi
  Future<bool> startSmartbandAiListening() async {
    return sendCommand('AI_LISTEN:1');
  }

  /// Selesaikan/hentikan rekaman suara mikrofon INMP441 dari aplikasi
  Future<bool> stopSmartbandAiListening() async {
    return sendCommand('AI_LISTEN:0');
  }

  /// Reset hitungan langkah pada smartband MPU6050
  Future<bool> resetSteps() async {
    return sendCommand('RESET_STEPS');
  }

  /// Picu getaran peringatan radius atau buzzer pada gelang ("RADIUS_ALERT:1" / "RADIUS_ALERT:0")
  Future<bool> triggerRadiusAlert(bool active) async {
    return sendCommand(active ? 'RADIUS_ALERT:1' : 'RADIUS_ALERT:0');
  }

  /// Tampilkan pesan teks atau balasan pada layar OLED gelang via perintah `"AI:<teks>"`
  Future<bool> showAiReplyOnOled(String message) async {
    return sendAiOledPayload('AI:$message');
  }

  /// Reset watchdog keheningan audio (jika paket audio berhenti selama 1.2 detik, finalisasi rekaman)
  void _resetAudioSilenceWatchdog() {
    _audioSilenceTimer?.cancel();
    _audioSilenceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (_isSmartbandRecordingVoice || _pcmAudioBuffer.length > 0) {
        _log('AUDIO SILENCE WATCHDOG: Aliran paket audio berhenti, menyelesaikan rekaman...');
        _finalizePcmAudioRecording();
      }
    });
  }

  /// Finalisasi dan kirim seluruh byte rekaman audio PCM ke listener
  void _finalizePcmAudioRecording() {
    _audioSilenceTimer?.cancel();
    _audioSilenceTimer = null;

    if (!_isSmartbandRecordingVoice && _pcmAudioBuffer.length == 0) return;

    _isSmartbandRecordingVoice = false;
    if (!_smartbandAiListeningController.isClosed) {
      _smartbandAiListeningController.add(false);
    }

    final completePcm = _pcmAudioBuffer.toBytes();
    _pcmAudioBuffer.clear();

    _log('REKAMAN AUDIO SELESAI: ${completePcm.length} bytes PCM siap ditranskripsi');
    if (completePcm.isNotEmpty && !_completePcmRecordingController.isClosed) {
      _completePcmRecordingController.add(completePcm);
    }
  }

  /// Subscribe ke notifikasi karakteristik audio (6e400004)
  Future<void> subscribeToAudioNotification([
    BluetoothCharacteristic? characteristic,
  ]) async {
    final char = characteristic ?? _audioCharacteristic;
    if (char == null) return;

    final dev = _connectedDevice;
    if (dev == null) return;

    _log('AUDIO NOTIFICATION START');
    try {
      await _audioNotificationSubscription?.cancel();
      _audioNotificationSubscription = char.onValueReceived.listen(
        (bytes) {
          if (bytes.isNotEmpty) {
            final uint8 = Uint8List.fromList(bytes);

            // Auto-deteksi: jika data audio mulai mengalir dari mic, otomatis aktifkan buffer perekaman
            if (!_isSmartbandRecordingVoice) {
              _isSmartbandRecordingVoice = true;
              _pcmAudioBuffer.clear();
              if (!_smartbandAiListeningController.isClosed) {
                _smartbandAiListeningController.add(true);
              }
              _log('AUDIO STREAM DETECTED: Auto-mulai merekam suara INMP441');
            }

            _pcmAudioBuffer.add(uint8);
            _resetAudioSilenceWatchdog();

            if (!_audioStreamController.isClosed) {
              _audioStreamController.add(uint8);
            }
          }
        },
        onError: (e) {
          _log('Error audio notification stream: $e');
        },
      );

      dev.cancelWhenDisconnected(_audioNotificationSubscription!);
      await char.setNotifyValue(true);
      _log('AUDIO NOTIFICATION ENABLED (6e400004)');
    } catch (e) {
      _log('AUDIO NOTIFICATION FAILED: $e');
    }
  }

  /// Kirim payload AI OLED (`"AI:<teks>"`) maksimal 55 karakter ASCII tanpa newline
  /// ke BLE RX Characteristic (6e400002-b5a3-f393-e0a9-e50e24dcca9e).
  Future<bool> sendAiOledPayload(String payload) async {
    final char = _writeCharacteristic;
    if (char == null) {
      _log('BLE RX Characteristic ($rxCharacteristicUuid) belum terhubung');
      return false;
    }
    try {
      _log('SEND AI OLED PAYLOAD: $payload');
      await char.write(
        utf8.encode(payload),
        withoutResponse:
            char.properties.writeWithoutResponse && !char.properties.write,
      );
      _log('AI OLED PAYLOAD SENT: $payload');
      return true;
    } catch (e) {
      if (char.properties.writeWithoutResponse) {
        try {
          await char.write(utf8.encode(payload), withoutResponse: true);
          _log('AI OLED PAYLOAD SENT (fallback withoutResponse): $payload');
          return true;
        } catch (_) {}
      }
      _log('AI OLED PAYLOAD FAILED: $e');
      return false;
    }
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
      final rawString = utf8.decode(bytes, allowMalformed: true);
      final trimmed = rawString.trim();
      if (trimmed.isEmpty) return;

      // Cek apakah paket adalah event kontrol suara AI (AI_START / AI_END)
      if (trimmed.contains('AI_START')) {
        _isSmartbandRecordingVoice = true;
        _pcmAudioBuffer.clear();
        _resetAudioSilenceWatchdog();
        if (!_smartbandAiListeningController.isClosed) {
          _smartbandAiListeningController.add(true);
        }
        _log('EVENT AI_START: Smartband mic INMP441 mulai merekam');
        return;
      } else if (trimmed.contains('AI_END')) {
        _log('EVENT AI_END: Smartband mic selesai dari hardware');
        _finalizePcmAudioRecording();
        return;
      }

      String jsonToParse = trimmed;

      // Cek apakah paket adalah fragment (~%02X%02X%02X:payload)
      if (rawString.startsWith('~') &&
          rawString.length >= 8 &&
          rawString[7] == ':') {
        final seq = int.tryParse(rawString.substring(1, 3), radix: 16) ?? -1;
        final idx = int.tryParse(rawString.substring(3, 5), radix: 16) ?? -1;
        final tot = int.tryParse(rawString.substring(5, 7), radix: 16) ?? -1;
        final payload = rawString.substring(8);

        if (seq != _lastSeq) {
          _lastSeq = seq;
          _fragmentParts.clear();
          _expectedTotal = tot;
        }

        _fragmentParts[idx] = payload;
        if (_fragmentParts.length < _expectedTotal) {
          return;
        }

        final sb = StringBuffer();
        for (int i = 0; i < _expectedTotal; i++) {
          sb.write(_fragmentParts[i] ?? '');
        }
        jsonToParse = sb.toString().trim();
        _fragmentParts.clear();
      }

      _log('RAW BLE DATA:\n$jsonToParse');

      final parsedData = SmartbandData.fromRawJson(jsonToParse);
      _lastData = parsedData;
      if (!_smartbandDataController.isClosed) {
        _smartbandDataController.add(parsedData);
      }

      final bpmStr = parsedData.heartRate > 0 ? '${parsedData.heartRate} BPM' : 'Aktif';
      final alertStr = parsedData.fallDetected ? ' • ⚠️ JATUH TERDETEKSI' : '';
      unawaited(
        SmartbandForegroundService.updateNotification(
          title: 'HajiCare Smartband Terhubung',
          message: '❤️ $bpmStr • AI Siaga$alertStr',
        ),
      );

      _log('PARSED BLE DATA');
      _log('braceletId: ${parsedData.braceletId}');
      _log('heartRate: ${parsedData.heartRate}');
      _log('contact: ${parsedData.fingerDetected}');
      _log('temp: ${parsedData.temperature}');
      _log('motionG: ${parsedData.accelG}');
      _log('fallStatus: ${parsedData.fallStatus}');
      _log('gps: ${parsedData.latitude}, ${parsedData.longitude}');
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
    unawaited(
      SmartbandForegroundService.updateNotification(
        title: 'HajiCare Smartband',
        message: 'Menyambungkan kembali ke gelang...',
      ),
    );

    if (!_isManualDisconnect && _lastKnownDevice != null && !_isDisposed) {
      _scheduleAutoReconnect();
    }
  }

  void _scheduleAutoReconnect() {
    if (_isManualDisconnect || _isDisposed || _lastKnownDevice == null) return;
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _log('Batas percobaan auto-reconnect tercapai ($_reconnectAttempts kali).');
      return;
    }
    _reconnectAttempts++;
    final delaySeconds = _reconnectAttempts * 2;
    _log(
      'Menjadwalkan auto-reconnect ke ${_lastKnownDevice?.remoteId.str} dalam $delaySeconds detik (percobaan $_reconnectAttempts/$maxReconnectAttempts)...',
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_isManualDisconnect || _isDisposed || _lastKnownDevice == null) return;
      if (_currentStatus == SmartbandBleStatus.connected ||
          _currentStatus == SmartbandBleStatus.connecting) {
        return;
      }
      try {
        _log('Menjalankan auto-reconnect...');
        await connectToSmartband(_lastKnownDevice!);
        _log('Auto-reconnect berhasil!');
      } catch (e) {
        _log('Percobaan auto-reconnect ke-$_reconnectAttempts gagal: $e');
        _scheduleAutoReconnect();
      }
    });
  }

  /// Bersihkan state internal koneksi
  void _cleanUpDeviceState() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;

    _scanSubscription?.cancel();
    _scanSubscription = null;

    _notificationSubscription?.cancel();
    _notificationSubscription = null;

    _audioNotificationSubscription?.cancel();
    _audioNotificationSubscription = null;

    _deviceConnectionSubscription?.cancel();
    _deviceConnectionSubscription = null;

    _audioSilenceTimer?.cancel();
    _audioSilenceTimer = null;
    _dataCharacteristic = null;
    _writeCharacteristic = null;
    _audioCharacteristic = null;
    _isSmartbandRecordingVoice = false;
    _pcmAudioBuffer.clear();
    _connectedDevice = null;
    _lastData = null;
    _fragmentParts.clear();
  }

  /// 7. Putuskan koneksi Smartband secara manual dan aman
  Future<void> disconnectSmartband() async {
    _log('Memutuskan koneksi Smartband secara aman...');
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _audioSilenceTimer?.cancel();
    _reconnectAttempts = 0;
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
      unawaited(SmartbandForegroundService.stopService());
      _log('Koneksi Smartband telah terputus.');
    }
  }

  /// Bersihkan semua stream dan listener saat service ditutup
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _audioSilenceTimer?.cancel();

    disconnectSmartband();

    _connectionStatusController.close();
    _smartbandDataController.close();
    _foundDeviceController.close();
    _statusMessageController.close();
    _audioStreamController.close();
    _smartbandAiListeningController.close();
    _completePcmRecordingController.close();
  }
}
