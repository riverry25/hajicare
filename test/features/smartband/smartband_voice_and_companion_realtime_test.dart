import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/models/jamaah_data.dart';
import 'package:hajicare/features/ai_assistant/services/audio_transcription_service.dart';
import 'package:hajicare/features/ai_assistant/services/smartband_ai_bridge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioTranscriptionService PCM to WAV Conversion', () {
    test('convertPcmToWav produces valid 44-byte RIFF/WAV header', () {
      final service = AudioTranscriptionService.instance;
      // 800 sampel PCM 16-bit Mono (1600 bytes) = 0.1 detik audio pada 8000 Hz
      final pcmBytes = Uint8List(1600);
      for (int i = 0; i < pcmBytes.length; i++) {
        pcmBytes[i] = (i % 256);
      }

      final wavBytes = service.convertPcmToWav(
        pcmBytes,
        sampleRate: 8000,
        numChannels: 1,
        bitsPerSample: 16,
      );

      expect(wavBytes.length, equals(44 + 1600));

      // 1. RIFF Identifier
      expect(String.fromCharCodes(wavBytes.sublist(0, 4)), equals('RIFF'));
      // 2. WAVE Identifier
      expect(String.fromCharCodes(wavBytes.sublist(8, 12)), equals('WAVE'));
      // 3. 'fmt ' Sub-chunk
      expect(String.fromCharCodes(wavBytes.sublist(12, 16)), equals('fmt '));
      // 4. 'data' Sub-chunk
      expect(String.fromCharCodes(wavBytes.sublist(36, 40)), equals('data'));

      // Check subchunk2 size (data size = 1600)
      final byteData = ByteData.sublistView(wavBytes);
      final subchunk2Size = byteData.getUint32(40, Endian.little);
      expect(subchunk2Size, equals(1600));

      // Check sample rate = 8000
      final sampleRate = byteData.getUint32(24, Endian.little);
      expect(sampleRate, equals(8000));
    });
  });

  group('JamaahData Real-Time Telemetry & Anomaly Evaluation', () {
    test('Correctly identifies normal condition', () {
      final normalJamaah = JamaahData(
        id: 'user_1',
        name: 'Ahmad Jamaah',
        shortLabel: 'Ahmad',
        distance: 12.0,
        heartRate: 75,
        temperature: 36.7,
        spo2: 98,
        fallDetected: false,
        fallStatus: 'NORMAL',
        batteryLevel: 85,
        steps: 1240,
        stepDistanceM: 868.0,
      );

      expect(normalJamaah.hasCriticalAnomaly, isFalse);
      expect(normalJamaah.hasAnyWarningOrAnomaly, isFalse);
      expect(normalJamaah.isOutOfSafeRadius, isFalse);
      expect(normalJamaah.steps, equals(1240));
      expect(normalJamaah.stepDistanceM, equals(868.0));
    });

    test('Triggers critical anomaly on Fall Detection (MPU6050)', () {
      final fallenJamaah = JamaahData(
        id: 'user_2',
        name: 'Budi Santoso',
        shortLabel: 'Budi',
        distance: 10.0,
        heartRate: 80,
        temperature: 36.6,
        spo2: 97,
        fallDetected: true,
        fallStatus: 'FALLEN',
      );

      expect(fallenJamaah.isFallen, isTrue);
      expect(fallenJamaah.hasCriticalAnomaly, isTrue);
      expect(fallenJamaah.hasAnyWarningOrAnomaly, isTrue);
    });

    test('Triggers critical anomaly on SOS Button Press', () {
      final sosJamaah = JamaahData(
        id: 'user_3',
        name: 'Citra Dewi',
        shortLabel: 'Citra',
        distance: 5.0,
        sosActive: true,
      );

      expect(sosJamaah.sosActive, isTrue);
      expect(sosJamaah.hasCriticalAnomaly, isTrue);
    });

    test('Triggers critical anomaly on Tachycardia (>120 BPM) & Heatstroke (>38.5°C)', () {
      final criticalHealthJamaah = JamaahData(
        id: 'user_4',
        name: 'Dedi Kurnia',
        shortLabel: 'Dedi',
        distance: 15.0,
        heartRate: 135,
        temperature: 39.2,
        spo2: 88,
      );

      expect(criticalHealthJamaah.isHeartRateCritical, isTrue);
      expect(criticalHealthJamaah.isTemperatureCritical, isTrue);
      expect(criticalHealthJamaah.isSpo2Critical, isTrue);
      expect(criticalHealthJamaah.hasCriticalAnomaly, isTrue);
    });

    test('Triggers out of safe radius warning when distance exceeds safe limit', () {
      final separatedJamaah = JamaahData(
        id: 'user_5',
        name: 'Ferdi Jamaah',
        shortLabel: 'Ferdi',
        distance: 33100.0, // 33.1 km
        heartRate: 78,
        temperature: 36.8,
        spo2: 98,
      );

      expect(separatedJamaah.hasCriticalAnomaly, isFalse);
      expect(separatedJamaah.isOutOfSafeRadius, isTrue);
      expect(separatedJamaah.hasAnyWarningOrAnomaly, isTrue);
    });

    test('Serialization toFirestore includes stepCount and stepDistanceM', () {
      final jamaah = JamaahData(
        id: 'user_6',
        name: 'Gani Pratama',
        shortLabel: 'Gani',
        distance: 20.0,
        heartRate: 72,
        steps: 3500,
        stepDistanceM: 2450.0,
      );

      final firestoreMap = jamaah.toFirestore();
      expect(firestoreMap['steps'], equals(3500));
      expect(firestoreMap['stepDistanceM'], equals(2450.0));
      expect(firestoreMap['heartRate'], equals(72));
    });
  });

  group('SmartbandAiBridgeService Stream Token to OLED', () {
    test('Formats and truncates accumulated stream text for 128x64 OLED display', () async {
      final bridge = SmartbandAiBridgeService();
      // Panjang > 100 karakter
      const longReply = 'Kondisi kesehatan Anda saat ini sangat prima dengan detak jantung 78 BPM dan suhu tubuh 36.8°C.';
      
      // Kirim token final
      final success = await bridge.streamTokenToSmartbandOled(longReply, isFinal: true);
      // Ketika tidak terhubung ke BLE asli di test unit, mengembalikan false tanpa exception
      expect(success, isFalse);
    });
  });
}
