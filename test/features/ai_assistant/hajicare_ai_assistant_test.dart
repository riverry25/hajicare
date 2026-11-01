import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_translations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/ai_assistant/controllers/hajicare_ai_controller.dart';
import 'package:hajicare/features/ai_assistant/models/ai_chat_message.dart';
import 'package:hajicare/features/ai_assistant/models/ai_server_config.dart';
import 'package:hajicare/features/ai_assistant/models/ai_server_status.dart';
import 'package:hajicare/features/ai_assistant/models/oled_display_state.dart';
import 'package:hajicare/features/ai_assistant/models/sensor_context.dart';
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
    test(
      'membersihkan emoji, simbol derajat, newline, dan membatasi <= 55 char ASCII',
      () {
        const raw =
            '✅ Kondisi Bapak stabil 😊!\nDetak jantung 78 BPM, suhu 36.6°C, tetap minum air zamzam yang cukup.';
        final sanitized = OledTextFormatter.sanitize(raw);

        expect(sanitized.length, lessThanOrEqualTo(55));
        expect(sanitized.contains('\n'), isFalse);
        expect(RegExp(r'^[\x20-\x7E]+$').hasMatch(sanitized), isTrue);

        final payload = OledTextFormatter.buildPayload(raw);
        expect(payload, startsWith('AI:'));
        expect(payload.substring(3).length, lessThanOrEqualTo(55));
      },
    );
  });

  group('HermesResponseParser (Defensive JSON Parser)', () {
    test(
      'mem-parse amplop standar OpenAI /v1/chat/completions dengan JSON murni',
      () {
        final rawEnvelope = jsonEncode({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': jsonEncode({
                  'speech':
                      'Alhamdulillah kondisi kesehatan Anda sangat stabil.',
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
      },
    );

    test(
      'mengekstrak JSON meskipun dibungkus markdown ```json ... ``` dan tag <think>',
      () {
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
      },
    );

    test('tidak pernah crash jika LLM membalas teks biasa (bukan JSON)', () {
      const plainText =
          'Bapak berada 12 meter dari pendamping, masih sangat aman di dalam radius rombongan.';

      final reply = HermesResponseParser.parseModelContent(plainText);
      expect(reply.isStructured, isFalse);
      expect(reply.speech, equals(plainText));
      expect(reply.oled.length, lessThanOrEqualTo(55));
      expect(reply.oled, startsWith('Bapak berada 12 meter'));
    });

    test(
      'menolak amplop chat.completion yang terpotong (content: null, finish_reason: length) agar JSON mentah tidak pernah bocor ke gelembung chat',
      () {
        final truncatedReasoningEnvelope = jsonEncode({
          'id': 'gen-1793472299-SD6e1tsNWod3Zl11AFsh',
          'object': 'chat.completion',
          'created': 1793472299,
          'model': 'dots-studio/dots-3-note-preview:free',
          'provider': 'AtlasCloud',
          'system_fingerprint': null,
          'service_tier': null,
          'choices': [
            {
              'index': 0,
              'logprobs': null,
              'finish_reason': 'length',
              'native_finish_reason': 'length',
              'message': {
                'role': 'assistant',
                'content': null,
                'refusal': null,
                'reasoning':
                    'The user is asking in Indonesian what I can do and whether I only access the smartband. I need to respond in terse caveman style...',
              },
            },
          ],
        });

        expect(
          () => HermesResponseParser.parseHttpBody(truncatedReasoningEnvelope),
          throwsFormatException,
        );
      },
    );

    test(
      'membersihkan tag bracket waktu [0.0:], [3.8:], [26.2:29.5] dan kurung siku [...] dari speech dan oled',
      () {
        const rawWithBrackets = '''
{
  "speech": "[0.0:] Assalamualaikum, jamaah-001. [3.8:] Jamaah terdekat Anda bernama Ferdi, [7.5:] berjarak tiga puluh sembilan ribu dua puluh sembilan meter. [12.5:] Saat ini semua anggota rombongan berada di luar radius aman. [18.8:] Saya dapat membantu dengan panduan ibadah, doa, dan informasi kesehatan. [26.2:29.5] Ada lagi yang bisa saya bantu?",
  "oled": "[0.0:] Assalamualaikum Ferdi 39029m [Aman]"
}
''';

        final reply = HermesResponseParser.parseModelContent(rawWithBrackets);
        expect(reply.speech.contains('['), isFalse);
        expect(reply.speech.contains(']'), isFalse);
        expect(reply.speech.contains('0.0:'), isFalse);
        expect(reply.speech.contains('26.2:29.5'), isFalse);
        expect(
          reply.speech,
          startsWith(
            'Assalamualaikum, jamaah-001. Jamaah terdekat Anda bernama Ferdi,',
          ),
        );

        expect(reply.oled.contains('['), isFalse);
        expect(reply.oled.contains(']'), isFalse);
        expect(reply.oled.contains('0.0:'), isFalse);
        expect(reply.oled, equals('Assalamualaikum Ferdi 39029m'));

        // Pastikan prompt tidak mengandung karakter [ atau ] yang memicu halusinasi LLM
        final emptySensor = SensorContext(
          isSmartbandConnected: false,
          heartRateBpm: 0,
          temperatureC: 0.0,
          isFallDetected: false,
          source: SensorDataSource.disconnected,
          capturedAt: DateTime.fromMillisecondsSinceEpoch(0),
        );
        final sysPrompt = HermesAiService.buildSystemPrompt(emptySensor);
        final userCtx = HermesAiService.buildContextualUserMessage(
          'kamu bisa apa saja',
          emptySensor,
        );
        expect(sysPrompt.contains('['), isFalse);
        expect(sysPrompt.contains(']'), isFalse);
        expect(userCtx.contains('['), isFalse);
        expect(userCtx.contains(']'), isFalse);
      },
    );

    test(
      'mendukung multi-bahasa penuh (id, en, jv, su) pada AppTranslations dan HajiCareAiController',
      () {
        final settings = Get.put(AppSettingsController());

        for (final code in ['id', 'en', 'jv', 'su']) {
          settings.rxLocale.value = Locale(code);
          expect(AppTranslations.tr('ai.title'), isNotEmpty);
          expect(AppTranslations.tr('ai.welcomeMessage'), isNotEmpty);
          expect(AppTranslations.tr('ai.inputHint'), isNotEmpty);
          expect(
            HajiCareAiController.localizedQuickPrompts,
            hasLength(6),
          );
          expect(
            HajiCareAiController.localizedFeaturedTopics,
            hasLength(4),
          );
        }

        settings.rxLocale.value = const Locale('en');
        expect(
          AppTranslations.tr('ai.bandDisconnectedCompact'),
          equals('Band Not Connected (-- BPM)'),
        );

        settings.rxLocale.value = const Locale('jv');
        expect(
          AppTranslations.tr('ai.bandDisconnectedCompact'),
          equals('Gelang Dèrèng Sambung (-- BPM)'),
        );

        settings.rxLocale.value = const Locale('su');
        expect(
          AppTranslations.tr('ai.bandDisconnectedCompact'),
          equals('Geulang Teu Acan Nyambung (-- BPM)'),
        );

        settings.rxLocale.value = const Locale('id');
      },
    );
  });

  group('SmartbandAiBridgeService (100% Real Data, Zero Simulation)', () {
    test(
      'melaporkan status jujur saat gelang BLE belum terhubung tanpa angka simulasi dan beralih ke live saat BLE tersambung',
      () {
        final fakeBle = _FakeSmartbandBleService()..mockConnected = false;
        final bridge = SmartbandAiBridgeService(bleService: fakeBle);

        final disconnectedSnapshot = bridge.readCurrentSensorContext();
        expect(disconnectedSnapshot.isSmartbandConnected, isFalse);
        expect(disconnectedSnapshot.source, equals(SensorDataSource.disconnected));
        expect(disconnectedSnapshot.heartRateBpm, equals(0));
        expect(disconnectedSnapshot.temperatureC, equals(0.0));
        expect(disconnectedSnapshot.distanceToCompanionMeters, isNull);
        expect(
          disconnectedSnapshot.fallStatusLabel,
          equals('Gelang Belum Terhubung'),
        );

        // Saat gelang belum terhubung, fallback AI mengatakan jujur bahwa gelang belum terhubung
        final replyWhenDisconnected = HermesAiService.buildOfflineFallbackReply(
          question: 'Bagaimana kondisi kesehatan saya sekarang?',
          sensor: disconnectedSnapshot,
        );
        expect(
          replyWhenDisconnected.speech.toLowerCase(),
          contains('belum terhubung'),
        );

        // Saat BLE terhubung secara nyata
        fakeBle.mockConnected = true;
        final connectedSnapshot = bridge.readCurrentSensorContext();
        expect(connectedSnapshot.isSmartbandConnected, isTrue);
        expect(connectedSnapshot.source, equals(SensorDataSource.live));

        // Saat pengguna bertanya siapa jamaah yang paling dekat, AI menjawab lengkap
        final snapshotWithMembers = connectedSnapshot.copyWith(
          hasActiveRoom: true,
          roomName: 'Rombongan Maktab 48',
          closestJamaahSummary:
              'Jamaah paling dekat (terdekat) dengan Anda: Ahmad (15m, Aman). Jamaah paling jauh (terjauh) dari Anda: Budi (140m)',
          roomMembersSummary:
              'Total anggota room: 4 orang (1 pendamping, 3 jamaah). Daftar lengkap anggota: Ahmad [Jamaah, 15m (Aman)]; Budi [Jamaah, 140m (Aman)]; Ustadz Hasan [Pendamping, 42m (Aman)]',
        );
        final closestReply = HermesAiService.buildOfflineFallbackReply(
          question: 'siapa jamaah yang paling dekat dengan saya',
          sensor: snapshotWithMembers,
        );
        expect(
          closestReply.speech,
          contains('Jamaah paling dekat (terdekat) dengan Anda: Ahmad (15m, Aman)'),
        );
      },
    );
  });

  group('HermesAiService & AiAssistantRepository', () {
    test(
      'menyertakan critical headers, system prompt sensor, mengirim payload AI:<oled> ke BLE RX, dan menginferensi aksi jamaah',
      () async {
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

        // Verifikasi konfigurasi default final (Groq Cloud)
        final defaultConfig = await repo.loadServerConfig(forceReload: true);
        expect(defaultConfig, equals(AiServerConfig.defaults));
        expect(
          defaultConfig.baseUrl,
          equals(AiServerConfig.defaultBaseUrl),
        );
        expect(
          defaultConfig.chatCompletionsUri.toString(),
          equals(
            'https://api.groq.com/openai/v1/chat/completions',
          ),
        );
        expect(
          defaultConfig.apiKey,
          equals(AiServerConfig.defaultApiKey),
        );
        expect(defaultConfig.model, equals(AiServerConfig.defaultModel));

        final health = await repo.checkServerHealth();
        expect(health.health, equals(AiServerHealth.online));
        expect(
          capturedRequest.headers['Authorization'],
          equals('Bearer ${defaultConfig.resolvedApiKey}'),
        );

        final outcome = await repo.askQuestion(
          question: 'Bagaimana kondisi kesehatan saya sekarang?',
          allowOfflineFallback: false,
        );

        // Verifikasi endpoint & headers
        expect(
          capturedRequest.url.toString(),
          equals(
            'https://api.groq.com/openai/v1/chat/completions',
          ),
        );
        expect(
          capturedRequest.headers['Content-Type'],
          contains('application/json'),
        );
        expect(
          capturedRequest.headers['Authorization'],
          equals('Bearer ${defaultConfig.resolvedApiKey}'),
        );

        // Verifikasi body & system prompt
        final sentJson =
            jsonDecode(capturedRequest.body) as Map<String, dynamic>;
        expect(sentJson['model'], equals(AiServerConfig.defaultModel));
        final messages = sentJson['messages'] as List<dynamic>;
        final sysPrompt = (messages.first as Map)['content'] as String;
        expect(sysPrompt, contains('Detak Jantung='));
        expect(sysPrompt, contains('Suhu='));
        expect(sysPrompt, contains('Status Jatuh='));
        expect(sysPrompt, contains('Jarak ke Pendamping='));

        // Verifikasi BLE RX payload ("AI:<teks>" <= 55 char ASCII tanpa emoji)
        expect(
          outcome.oledState.status,
          equals(OledDeliveryStatus.deliveredBle),
        );
        expect(fakeBle.writtenPayloads, hasLength(1));
        expect(
          fakeBle.writtenPayloads.first,
          equals('AI:Aman HR:80 BPM T:36.7C'),
        );

        // Verifikasi contextual actions untuk jamaah
        final doaActions = HermesAiService.inferContextualActions(
          question: 'Panduan doa saat thawaf dan sai',
          replySpeech: 'Berikut panduan doa thawaf untuk Bapak/Ibu jamaah.',
          sensor: outcome.sensorSnapshot,
        );
        expect(doaActions, contains(AiContextualAction.openDua));
      },
    );

    test(
      'checkHealth mengutamakan /v1/models (bebas 404 /health di Ngrok) dan askQuestion menangani content:null tanpa pernah menampilkan JSON mentah',
      () async {
        final requestedPaths = <String>[];
        final mockHttp = MockClient((request) async {
          requestedPaths.add(request.url.path);
          if (request.url.path == '/v1/models') {
            return http.Response('{"object":"list","data":[]}', 200);
          }
          // Simulasikan bug persis pada screenshot: model reasoning kehabisan token (content: null)
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'id': 'gen-1793472299-SD6e1tsNWod3Zl11AFsh',
                'object': 'chat.completion',
                'model': 'dots-studio/dots-3-note-preview:free',
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'length',
                    'message': {
                      'role': 'assistant',
                      'content': null,
                      'reasoning': 'The user is asking in Indonesian...',
                    },
                  },
                ],
              }),
            ),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final fakeBle = _FakeSmartbandBleService()..mockConnected = false;
        final repo = AiAssistantRepository(
          hermesService: HermesAiService(httpClient: mockHttp),
          smartbandBridge: SmartbandAiBridgeService(bleService: fakeBle),
        );

        final health = await repo.checkServerHealth();
        expect(health.health, equals(AiServerHealth.online));
        // Pastikan /v1/models dipanggil langsung tanpa memicu 404 pada /health
        expect(requestedPaths.first.endsWith('/v1/models'), isTrue);
        expect(requestedPaths.contains('/health'), isFalse);

        final outcome = await repo.askQuestion(
          question: 'kamu bisa apa saja? apakah cuman meng akses smartband',
          allowOfflineFallback: true,
        );

        // Tidak boleh ada JSON mentah yang tampil di speech
        expect(outcome.reply.speech.contains('"object"'), isFalse);
        expect(outcome.reply.speech.contains('chat.completion'), isFalse);
        expect(outcome.reply.speech.contains('finishreason'), isFalse);
        // Harus menjelaskan kemampuan seluruh aplikasi HajiCare dalam Bahasa Indonesia
        expect(
          outcome.reply.speech.toLowerCase(),
          contains('seluruh fitur aplikasi hajicare'),
        );
      },
    );
  });

  group('HajiCareAiAssistantPage Redesigned UI & UX Test', () {
    testWidgets(
      'merender UI minimalis sesuai referensi, starter cards 2x2, compact OLED strip, modal OLED 128x64, dan mode suara tanpa overflow',
      (tester) async {
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
            theme: AppTheme.darkTheme,
            home: const HajiCareAiAssistantPage(),
          ),
        );
        await tester.pump();

        // 1. Header minimalis & compact Smartband/OLED status strip tampil rapi
        expect(find.text('HajiCare AI Assistant'), findsOneWidget);
        expect(
          find.byKey(const Key('compact_smartband_oled_strip')),
          findsOneWidget,
        );
        expect(find.text('Gelang Belum Terhubung (-- BPM)'), findsOneWidget);
        expect(find.text('Cek Kesehatan'), findsOneWidget);
        expect(find.text('Jarak Pendamping'), findsOneWidget);
        expect(find.text('Jadwal Salat & Kiblat'), findsOneWidget);
        expect(find.text('Panduan Doa Ibadah'), findsOneWidget);

        // 2. Ketuk kartu starter "Cek Kesehatan"
        await tester.tap(find.text('Cek Kesehatan'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(controller.messages.length, greaterThanOrEqualTo(3));
        expect(controller.oledState.value.payload, startsWith('AI:'));
        expect(controller.isOledLedActive.value, isTrue);
        expect(fakeVoice.spokenTexts, isNotEmpty);

        // 3. Tombol Stop TTS muncul saat AI sedang berbicara
        expect(find.byKey(const Key('stop_tts_button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('stop_tts_button')));
        await tester.pump();
        expect(controller.isSpeaking.value, isFalse);

        // 4. Ketuk compact strip untuk membuka bottom sheet OLED 128x64 & Sensor Gelang
        await tester.tap(find.byKey(const Key('compact_smartband_oled_strip')));
        await tester.pumpAndSettle();

        expect(
          find.text('Status Gelang & Layar OLED 128x64'),
          findsOneWidget,
        );
        expect(
          find.text('Layar Gelang OLED 0.96" (128x64)'),
          findsOneWidget,
        );
        expect(find.text('Konteks Sensor Gelang'), findsOneWidget);
        expect(
          find.text('Kondisi Nyata Aplikasi & Posisi HP'),
          findsOneWidget,
        );
        expect(find.text('Sambungkan Gelang Bluetooth'), findsOneWidget);

        // Tutup bottom sheet
        Navigator.of(
          tester.element(find.text('Status Gelang & Layar OLED 128x64')),
        ).pop();
        await tester.pumpAndSettle();

        // 5. Buka Immersive Voice Orb Mode
        await tester.tap(find.byKey(const Key('voice_orb_mode_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(controller.isVoiceModeOpen.value, isTrue);
        expect(find.byKey(const Key('voice_orb_mic_button')), findsOneWidget);
        expect(find.byKey(const Key('voice_orb_close_button')), findsOneWidget);

        // Tutup Immersive Voice Orb Mode
        await tester.tap(find.byKey(const Key('voice_orb_close_button')));
        await tester.pump();
        expect(controller.isVoiceModeOpen.value, isFalse);

        // Selesaikan timer indikator LED hijau (6 detik)
        await tester.pump(const Duration(seconds: 6));
        expect(controller.isOledLedActive.value, isFalse);
      },
    );

    testWidgets(
      'HajiCareDraggableAiOverlay dapat digeser ke kiri/kanan dan otomatis mengecil saat digeser ke sudut layar',
      (tester) async {
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
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: Stack(
                children: [
                  SizedBox.expand(),
                  Positioned.fill(
                    child: HajiCareDraggableAiOverlay(bottomClearance: 114),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        final fabFinder = find.byKey(const Key('tanya_ai_fab_button'));
        expect(fabFinder, findsOneWidget);
        expect(controller.fabDockedRight.value, isTrue);
        // Di awal tampil tulisan "AI Assistant" agar pengguna tahu fungsinya
        expect(find.text('AI Assistant'), findsOneWidget);

        // Geser tombol ke samping kiri layar (snap ke samping)
        await tester.drag(fabFinder, const Offset(-340, -120));
        await tester.pumpAndSettle();

        expect(controller.fabDockedRight.value, isFalse);
        expect(controller.fabCornerMinimized.value, isTrue);
        // Setelah di-snap ke samping, tulisan "AI Assistant" hilang menyisakan ikon kompak
        expect(find.text('AI Assistant'), findsNothing);
      },
    );
  });
}
