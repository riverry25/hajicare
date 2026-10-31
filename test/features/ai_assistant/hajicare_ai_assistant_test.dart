import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/ai_assistant/controllers/hajicare_ai_controller.dart';
import 'package:hajicare/features/ai_assistant/models/ai_server_config.dart';
import 'package:hajicare/features/ai_assistant/models/ai_server_status.dart';
import 'package:hajicare/features/ai_assistant/models/oled_display_state.dart';
import 'package:hajicare/features/ai_assistant/repositories/ai_assistant_repository.dart';
import 'package:hajicare/features/ai_assistant/services/ai_voice_service.dart';
import 'package:hajicare/features/ai_assistant/services/hermes_ai_service.dart';
import 'package:hajicare/features/ai_assistant/services/hermes_response_parser.dart';
import 'package:hajicare/features/ai_assistant/services/oled_text_formatter.dart';
import 'package:hajicare/features/ai_assistant/services/smartband_ai_bridge_service.dart';
import 'package:hajicare/features/ai_assistant/widgets/hajicare_ai_widget.dart';
import 'package:hajicare/features/smartband/services/smartband_ble_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSmartbandBleService extends SmartbandBleService {
  bool mockConnected = false;
  final List<String> writtenPayloads = <String>[];

  @override
  SmartbandBleStatus get currentStatus => mockConnected
      ? SmartbandBleStatus.connected
      : SmartbandBleStatus.disconnected;

  @override
  bool get isConnected => mockConnected;

  @override
  bool get canWriteCommand => mockConnected;

  @override
  Future<bool> sendAiOledPayload(String payload) async {
    writtenPayloads.add(payload);
    return mockConnected;
  }
}

class _NoopVoiceService extends AiVoiceService {
  final List<String> spokenTexts = <String>[];

  @override
  Future<void> initTts() async {}

  @override
  Future<void> speak(String text) async {
    spokenTexts.add(text);
    onSpeakingChanged?.call(true);
  }

  @override
  Future<void> stopSpeaking() async {
    onSpeakingChanged?.call(false);
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('OledTextFormatter', () {
    test('membersihkan emoji, simbol derajat, newline, dan membatasi <= 55 char ASCII', () {
      const raw =
          '✅ Kondisi Bapak stabil 😊!\nDetak jantung 78 BPM, suhu 36.6°C, tetap minum air zamzam yang cukup.';
      final sanitized = OledTextFormatter.sanitize(raw);

      expect(sanitized.length, lessThanOrEqualTo(55));
      expect(sanitized.contains('\n'), isFalse);
      expect(RegExp(r'^[\x20-\x7E]+$').hasMatch(sanitized), isTrue);

      final payload = OledTextFormatter.buildPayload(raw);
      expect(payload, startsWith('AI:'));
      expect(payload.substring(3).length, lessThanOrEqualTo(55));
    });
  });

  group('HermesResponseParser (Defensive JSON Parser)', () {
    test('mem-parse amplop standar OpenAI /v1/chat/completions dengan JSON murni', () {
      final rawEnvelope = jsonEncode({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': jsonEncode({
                'speech': 'Alhamdulillah kondisi kesehatan Anda sangat stabil.',
                'oled': 'Kondisi sehat HR:78 T:36.6C',
              }),
            },
          },
        ],
      });

      final reply = HermesResponseParser.parseHttpBody(rawEnvelope);
      expect(reply.isStructured, isTrue);
      expect(
        reply.speech,
        equals('Alhamdulillah kondisi kesehatan Anda sangat stabil.'),
      );
      expect(reply.oled, equals('Kondisi sehat HR:78 T:36.6C'));
    });

    test('mengekstrak JSON meskipun dibungkus markdown ```json ... ``` dan tag <think>', () {
      const messyContent = '''
<think>Menganalisis sensor detak jantung 78 BPM</think>
Berikut hasil analisis untuk jamaah:
```json
{
  "speech": "Silakan menepi ke tempat teduh dan minum air zamzam.",
  "oled": "Menepi & minum air zamzam 🌟",
}
```
Semoga membantu!
''';

      final reply = HermesResponseParser.parseModelContent(messyContent);
      expect(reply.isStructured, isTrue);
      expect(
        reply.speech,
        equals('Silakan menepi ke tempat teduh dan minum air zamzam.'),
      );
      expect(reply.oled, equals('Menepi & minum air zamzam'));
      expect(reply.oled.length, lessThanOrEqualTo(55));
    });

    test('tidak pernah crash jika LLM membalas teks biasa (bukan JSON)', () {
      const plainText =
          'Bapak berada 12 meter dari pendamping, masih sangat aman di dalam radius rombongan.';

      final reply = HermesResponseParser.parseModelContent(plainText);
      expect(reply.isStructured, isFalse);
      expect(reply.speech, equals(plainText));
      expect(reply.oled.length, lessThanOrEqualTo(55));
      expect(reply.oled, startsWith('Bapak berada 12 meter'));
    });
  });

  group('HermesAiService & AiAssistantRepository', () {
    test('menyertakan critical headers, system prompt sensor, dan mengirim payload AI:<oled> ke BLE RX', () async {
      late http.Request capturedRequest;
      final mockHttp = MockClient((request) async {
        capturedRequest = request;
        if (request.url.path == '/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content':
                        '{"speech": "Detak jantung Anda 80 BPM dan suhu 36.7 derajat, kondisi aman.", "oled": "Aman HR:80 BPM T:36.7C ✅"}',
                  },
                },
              ],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final fakeBle = _FakeSmartbandBleService()..mockConnected = true;
      final hermesService = HermesAiService(httpClient: mockHttp);
      final bridge = SmartbandAiBridgeService(bleService: fakeBle);
      final repo = AiAssistantRepository(
        hermesService: hermesService,
        smartbandBridge: bridge,
      );

      // Simpan URL dinamis ke SharedPreferences
      final savedConfig = await repo.saveServerConfig(
        const AiServerConfig(
          baseUrl: 'https://hajicare-demo.ngrok-free.app',
          apiKey: 'rahasia_hajicare_2026',
          model: 'hermes',
        ),
      );
      expect(savedConfig.baseUrl, equals('https://hajicare-demo.ngrok-free.app'));

      final health = await repo.checkServerHealth();
      expect(health.health, equals(AiServerHealth.online));
      expect(
        capturedRequest.headers['ngrok-skip-browser-warning'],
        equals('true'),
      );
      expect(
        capturedRequest.headers['Authorization'],
        equals('Bearer rahasia_hajicare_2026'),
      );

      final outcome = await repo.askQuestion(
        question: 'Bagaimana kondisi kesehatan saya sekarang?',
        allowOfflineFallback: false,
      );

      // Verifikasi endpoint & headers
      expect(capturedRequest.url.path, equals('/v1/chat/completions'));
      expect(
        capturedRequest.headers['Content-Type'],
        contains('application/json'),
      );
      expect(
        capturedRequest.headers['Authorization'],
        equals('Bearer rahasia_hajicare_2026'),
      );
      expect(
        capturedRequest.headers['ngrok-skip-browser-warning'],
        equals('true'),
      );

      // Verifikasi body & system prompt
      final sentJson = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(sentJson['model'], equals('hermes'));
      final messages = sentJson['messages'] as List<dynamic>;
      final sysPrompt = (messages.first as Map)['content'] as String;
      expect(sysPrompt, contains('Detak Jantung='));
      expect(sysPrompt, contains('Suhu='));
      expect(sysPrompt, contains('Status Jatuh='));
      expect(sysPrompt, contains('Jarak ke Pendamping='));

      // Verifikasi BLE RX payload ("AI:<teks>" <= 55 char ASCII tanpa emoji)
      expect(outcome.oledState.status, equals(OledDeliveryStatus.deliveredBle));
      expect(fakeBle.writtenPayloads, hasLength(1));
      expect(fakeBle.writtenPayloads.first, equals('AI:Aman HR:80 BPM T:36.7C'));
    });
  });

  group('HajiCareAiAssistantPage Widget Test', () {
    testWidgets('merender halaman AI, kartu sensor, preview OLED 128x64, quick prompts, dan merespons pertanyaan tanpa overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeBle = _FakeSmartbandBleService()..mockConnected = false;
      final fakeVoice = _NoopVoiceService();
      final repo = AiAssistantRepository(
        hermesService: HermesAiService(
          httpClient: MockClient((_) async => http.Response('offline', 502)),
        ),
        smartbandBridge: SmartbandAiBridgeService(bleService: fakeBle),
      );

      final controller = Get.put(
        HajiCareAiController(
          repository: repo,
          voiceService: fakeVoice,
          autoInitPlatformServices: false,
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const HajiCareAiAssistantPage(),
        ),
      );
      await tester.pump();

      expect(find.text('HajiCare AI Assistant'), findsOneWidget);
      expect(find.textContaining('Layar Gelang OLED 0.96"'), findsOneWidget);
      expect(find.text('Konteks Sensor Gelang'), findsOneWidget);
      expect(
        find.text('Bagaimana kondisi kesehatan saya sekarang?'),
        findsOneWidget,
      );

      // Ketuk Quick Prompt pertama yang langsung tampil di layar
      await tester.tap(
        find.text('Bagaimana kondisi kesehatan saya sekarang?'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.messages.length, greaterThanOrEqualTo(3));
      expect(controller.oledState.value.payload, startsWith('AI:'));
      expect(controller.isOledLedActive.value, isTrue);
      expect(fakeVoice.spokenTexts, isNotEmpty);

      // Pastikan tombol Stop TTS muncul saat AI sedang berbicara
      expect(find.byKey(const Key('stop_tts_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('stop_tts_button')));
      await tester.pump();
      expect(controller.isSpeaking.value, isFalse);

      // Selesaikan timer indikator LED hijau (6 detik)
      await tester.pump(const Duration(seconds: 6));
      expect(controller.isOledLedActive.value, isFalse);
    });
  });
}

