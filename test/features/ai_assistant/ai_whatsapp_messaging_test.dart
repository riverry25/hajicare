import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/ai_assistant/models/ai_messaging_config.dart';
import 'package:hajicare/features/ai_assistant/models/ai_reply.dart';
import 'package:hajicare/features/ai_assistant/models/sensor_context.dart';
import 'package:hajicare/features/ai_assistant/services/ai_external_messaging_service.dart';
import 'package:hajicare/features/ai_assistant/services/hermes_response_parser.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Integrasi WhatsApp AI & Smartband Tests', () {
    test('Normalisasi nomor telepon Indonesia 08xx / +628xx ke 628xx', () {
      expect(
        AiMessagingConfig.normalizePhoneNumber('0812-3456-7890'),
        '6281234567890',
      );
      expect(
        AiMessagingConfig.normalizePhoneNumber('+62 813 9988 7766'),
        '6281399887766',
      );
      expect(
        AiMessagingConfig.normalizePhoneNumber('85211223344'),
        '6285211223344',
      );
    });

    test('HermesResponseParser mengekstrak field notify: whatsapp dari JSON LLM', () {
      const rawJson = '''
      {
        "speech": "Baik Bapak, laporan kondisi dan lokasi GPS Anda sedang dikirim ke WhatsApp Pendamping.",
        "oled": "Kirim laporan & lokasi ke WA Pendamping",
        "notify": "whatsapp",
        "notifyMessage": "Jamaah merasa pusing di dekat pintu Marwah"
      }
      ''';
      final reply = HermesResponseParser.parseModelContent(rawJson);
      expect(reply.isStructured, isTrue);
      expect(reply.notifyChannel, 'whatsapp');
      expect(
        reply.notifyMessage,
        'Jamaah merasa pusing di dekat pintu Marwah',
      );
    });

    test('Deteksi intent perintah suara / chat untuk kirim ke WhatsApp', () {
      const normalReply = AiReply(
        speech: 'Detak jantung Anda 82 BPM.',
        oled: 'HR: 82 BPM',
      );
      const waJsonReply = AiReply(
        speech: 'Mengirim ke WhatsApp.',
        oled: 'Kirim WA',
        notifyChannel: 'whatsapp',
      );

      expect(
        AiExternalMessagingService.shouldSendToWhatsApp(
          userQuestion: 'Bagaimana kondisi kesehatan saya?',
          reply: normalReply,
        ),
        isFalse,
      );

      expect(
        AiExternalMessagingService.shouldSendToWhatsApp(
          userQuestion: 'Tolong kirim kondisi dan lokasi saya ke WA pendamping',
          reply: normalReply,
        ),
        isTrue,
      );

      expect(
        AiExternalMessagingService.shouldSendToWhatsApp(
          userQuestion: 'Kabari pendamping kalau saya pusing',
          reply: normalReply,
        ),
        isTrue,
      );

      expect(
        AiExternalMessagingService.shouldSendToWhatsApp(
          userQuestion: 'Apa saja',
          reply: waJsonReply,
        ),
        isTrue,
      );
    });

    test(
      'Format laporan WhatsApp memuat Identitas, Telemetri Gelang (tanpa SpO2), dan Link Google Maps',
      () {
        final sensor = SensorContext(
          isSmartbandConnected: true,
          braceletId: 'HCG-001',
          heartRateBpm: 88,
          temperatureC: 36.7,
          isFallDetected: false,
          spo2Percent: 98, // Harus diabaikan / tidak ditampilkan di laporan WA
          stepCount: 1420,
          smartbandLatitude: 21.422510,
          smartbandLongitude: 39.826168,
          isSmartbandGpsFix: true,
          latitude: 21.422510,
          longitude: 39.826168,
          locationCityName: 'Masjidil Haram, Makkah',
          userName: 'H. Ahmad',
          userRole: 'jamaah',
          hasActiveRoom: true,
          roomName: 'Rombongan Al-Hidayah',
          kloter: 'SUB-12',
          maktab: '44',
          companionName: 'Ustadz Yusuf',
          distanceToCompanionMeters: 42.0,
          safeRadiusMeters: 200.0,
          source: SensorDataSource.live,
          capturedAt: DateTime(2026, 11, 3),
        );

        final report = AiExternalMessagingService.formatWhatsAppReport(
          aiOrAlertMessage: 'Mohon jemput saya di dekat bukit Marwah.',
          sensor: sensor,
        );

        expect(report, contains('H. Ahmad'));
        expect(report, contains('Kloter SUB-12'));
        expect(report, contains('Maktab 44'));
        expect(report, contains('88 BPM'));
        expect(report, contains('36.7 °C'));
        expect(report, contains('1420 langkah'));
        expect(report, contains('42 meter'));
        expect(
          report,
          contains('https://maps.google.com/?q=21.422510,39.826168'),
        );
        // Pastikan SpO2 TIDAK disertakan sesuai permintaan user
        expect(report.toLowerCase(), isNot(contains('spo2')));
        expect(report.toLowerCase(), isNot(contains('oksigen')));
      },
    );

    test(
      'Pengiriman otomatis di background via Fonnte WhatsApp API berhasil tanpa buka aplikasi',
      () async {
        String? capturedTarget;
        String? capturedAuthHeader;
        String? capturedMessage;

        final mockClient = MockClient((http.Request request) async {
          capturedAuthHeader = request.headers['Authorization'];
          final bodyFields = request.bodyFields;
          capturedTarget = bodyFields['target'];
          capturedMessage = bodyFields['message'];
          return http.Response(jsonEncode({'status': true}), 200);
        });

        final service = AiExternalMessagingService(httpClient: mockClient);
        final sensor = SensorContext(
          isSmartbandConnected: true,
          braceletId: 'HCG-001',
          heartRateBpm: 92,
          temperatureC: 36.8,
          isFallDetected: false,
          source: SensorDataSource.live,
          capturedAt: DateTime(2026, 11, 3),
        );

        const cfg = AiMessagingConfig(
          whatsAppPhone: '081234567890',
          whatsAppApiToken: 'fonnte_secret_token_123',
        );

        final res = await service.sendWhatsAppReport(
          aiOrAlertMessage: 'Tes kirim otomatis background',
          sensor: sensor,
          overrideConfig: cfg,
          allowDeepLinkFallback: false,
        );

        expect(res.success, isTrue);
        expect(res.isBackgroundApi, isTrue);
        expect(capturedAuthHeader, 'fonnte_secret_token_123');
        expect(capturedTarget, '6281234567890');
        expect(capturedMessage, contains('92 BPM'));
      },
    );
  });
}

