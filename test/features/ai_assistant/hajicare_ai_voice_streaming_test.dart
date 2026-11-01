import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/features/ai_assistant/controllers/hajicare_ai_controller.dart';
import 'package:hajicare/features/ai_assistant/models/ai_server_config.dart';
import 'package:hajicare/features/ai_assistant/models/ai_stream_event.dart';
import 'package:hajicare/features/ai_assistant/models/ai_voice_phase.dart';
import 'package:hajicare/features/ai_assistant/models/sensor_context.dart';
import 'package:hajicare/features/ai_assistant/repositories/ai_assistant_repository.dart';
import 'package:hajicare/features/ai_assistant/services/ai_voice_service.dart';
import 'package:hajicare/features/ai_assistant/services/hermes_ai_service.dart';
import 'package:hajicare/features/ai_assistant/services/sentence_speech_queue.dart';
import 'package:hajicare/features/ai_assistant/services/smartband_ai_bridge_service.dart';
import 'package:hajicare/features/ai_assistant/services/streaming_speech_extractor.dart';
import 'package:hajicare/features/smartband/services/smartband_ble_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSmartbandBleService extends SmartbandBleService {
  @override
  SmartbandBleStatus get currentStatus => SmartbandBleStatus.disconnected;
  @override
  bool get isConnected => false;
  @override
  bool get canWriteCommand => false;
  @override
  Future<bool> sendAiOledPayload(String payload) async => false;
}

class _TestVoiceService extends AiVoiceService {
  final List<String> queuedSentences = <String>[];
  final List<String> spokenTexts = <String>[];
  bool mockIsSpeaking = false;

  @override
  Future<void> initTts() async {}

  @override
  void feedStreamingSpeech(String speechText) {
    queuedSentences.add(speechText);
  }

  @override
  Future<void> speak(String text) async {
    spokenTexts.add(text);
    mockIsSpeaking = true;
    onSpeakingChanged?.call(true);
  }

  @override
  Future<void> stopSpeaking() async {
    mockIsSpeaking = false;
    onSpeakingChanged?.call(false);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Get.testMode = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    Get.reset();
  });

  group('StreamingSpeechExtractor', () {
    test('mengekstrak field speech dari chunk JSON bertahap', () {
      final extractor = StreamingSpeechExtractor();

      expect(extractor.addChunk('{"speech": "Halo '), 'Halo');
      expect(extractor.addChunk('Bapak '), 'Halo Bapak');
      expect(extractor.addChunk('Haji, '), 'Halo Bapak Haji,');
      expect(extractor.addChunk('semoga lancar."'), 'Halo Bapak Haji, semoga lancar.');
      expect(extractor.addChunk(', "oled": "HALO"}'), 'Halo Bapak Haji, semoga lancar.');
    });

    test('membersihkan tag <think>...</think> pada streaming', () {
      final extractor = StreamingSpeechExtractor();

      extractor.addChunk('<think>Menganalisis pertanyaan jamaah...</think>');
      expect(extractor.currentSpeech, isEmpty);

      extractor.addChunk('{"speech": "Detak jantung Anda normal."}');
      expect(extractor.currentSpeech, 'Detak jantung Anda normal.');
    });

    test('menangani unclosed <think> saat streaming', () {
      final extractor = StreamingSpeechExtractor();
      extractor.addChunk('<think>Sedang memproses...');
      expect(extractor.currentSpeech, isEmpty);
    });

    test('mendukung mode teks biasa tanpa JSON jika model tidak menghasilkan JSON', () {
      final extractor = StreamingSpeechExtractor();

      extractor.addChunk('Assalamu alaikum Bapak Haji, ');
      expect(extractor.currentSpeech, contains('Assalamu alaikum Bapak Haji,'));
      extractor.addChunk('kondisi Anda terpantau aman.');
      expect(extractor.currentSpeech, 'Assalamu alaikum Bapak Haji, kondisi Anda terpantau aman.');
    });

    test('melakukan unescape karakter khusus JSON seperti kutip dan baris baru', () {
      final extractor = StreamingSpeechExtractor();
      extractor.addChunk(r'{"speech": "Gunakan masker \"N95\" dan minum air."}');
      expect(extractor.currentSpeech, 'Gunakan masker "N95" dan minum air.');
    });
  });

  group('SentenceSpeechQueue', () {
    test('memecah teks kumulatif menjadi kalimat lengkap dan melindungi angka desimal', () async {
      final spoken = <String>[];
      final queue = SentenceSpeechQueue(
        speakFunction: (sentence) async {
          spoken.add(sentence);
        },
        stopFunction: () async {},
      );

      // Suhu 36.5 tidak boleh diputus di titik 36.5
      queue.feed('Suhu tubuh Anda 36.5 derajat Celcius.');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(spoken, <String>['Suhu tubuh Anda 36.5 derajat Celcius.']);

      queue.feed(
        'Suhu tubuh Anda 36.5 derajat Celcius. Detak jantung 80 BPM normal! Silakan duduk dan istirahat sejenak.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(spoken, contains('Detak jantung 80 BPM normal!'));
      expect(spoken, contains('Silakan duduk dan istirahat sejenak.'));

      // Teks belum selesai tetap di-buffer
      queue.feed(
        'Suhu tubuh Anda 36.5 derajat Celcius. Detak jantung 80 BPM normal! Silakan duduk dan istirahat sejenak. Tetap jaga',
      );
      // Belum diputar karena belum ada tanda baca penutup
      expect(spoken.length, 3);

      // Saat streaming finish, sisa buffer diputar
      queue.finish();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(spoken.last, 'Tetap jaga');
    });

    test('stop mengosongkan antrean dan menghentikan pembacaan', () async {
      final spoken = <String>[];
      var stopped = false;
      final queue = SentenceSpeechQueue(
        speakFunction: (sentence) async {
          spoken.add(sentence);
        },
        stopFunction: () async {
          stopped = true;
        },
      );

      queue.feed('Kalimat pertama.');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await queue.stop();
      expect(stopped, isTrue);
      expect(queue.isPlaying, isFalse);
    });
  });

  group('HermesAiService streamChatCompletion', () {
    test('menghasilkan stream AiStreamDelta dan AiStreamDone dengan format SSE', () async {
      final sseBody = [
        'data: {"choices":[{"delta":{"content":"{\\"speech\\": \\"Alhamdulillah, "}}]}',
        '',
        'data: {"choices":[{"delta":{"content":"kesehatan Anda baik.\\", \\"oled\\": \\"SEHAT\\"}"}}]}',
        '',
        'data: [DONE]',
        '',
      ].join('\n');

      final mockClient = MockClient((request) async {
        return http.Response(
          sseBody,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });

      final service = HermesAiService(httpClient: mockClient);
      const config = AiServerConfig(
        baseUrl: 'https://api.groq.com/openai',
        apiKey: 'gsk_test_key_groq',
        model: 'qwen/qwen3.8-27b',
      );

      final events = <AiStreamEvent>[];
      await for (final event in service.streamChatCompletion(
        config: config,
        userQuestion: 'Bagaimana kondisi saya?',
        sensorContext: SensorContext(
          heartRateBpm: 76,
          temperatureC: 36.6,
          isFallDetected: false,
          source: SensorDataSource.disconnected,
          capturedAt: DateTime.now(),
          isSmartbandConnected: true,
        ),
      )) {
        events.add(event);
      }

      expect(events.any((e) => e is AiStreamDelta), isTrue);
      expect(events.last, isA<AiStreamDone>());
      final done = events.last as AiStreamDone;
      expect(done.reply.speech, contains('Alhamdulillah'));
    });
  });

  group('HajiCareAiController Voice Phase & Streaming Logic', () {
    test('transisi voicePhase dari idle -> listening -> thinking -> answering -> idle', () async {
      final mockBle = _MockSmartbandBleService();
      final bridge = SmartbandAiBridgeService(bleService: mockBle);
      final voice = _TestVoiceService();

      final mockClient = MockClient((request) async {
        final sseBody = [
          'data: {"choices":[{"delta":{"content":"{\\"speech\\": \\"Jamaah terdekat berjarak 10 meter.\\", \\"oled\\": \\"DEKAT 10M\\"}"}}]}',
          '',
          'data: [DONE]',
          '',
        ].join('\n');
        return http.Response(
          sseBody,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });

      final hermes = HermesAiService(httpClient: mockClient);
      final repo = AiAssistantRepository(
        hermesService: hermes,
        smartbandBridge: bridge,
      );

      final controller = HajiCareAiController(
        repository: repo,
        voiceService: voice,
        autoInitPlatformServices: false,
      );
      controller.onInit();

      expect(controller.voicePhase.value, AiVoicePhase.idle);

      // Simulasi mulai mendengar suara
      voice.onListeningChanged?.call(true, 'Mendengarkan...');
      expect(controller.voicePhase.value, AiVoicePhase.listening);

      // Simulasi pengguna selesai bicara
      voice.onSpeechResult?.call('Siapa paling dekat?', true);
      // Begitu ucapan final diterima, turnReply langsung di-reset dan fase menjadi thinking
      expect(controller.currentTurnQuestion.value, 'Siapa paling dekat?');
      expect(controller.currentTurnReply.value, isEmpty);
      expect(controller.voicePhase.value, AiVoicePhase.thinking);

      // Tunggu stream selesai diproses
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(controller.currentTurnReply.value, contains('Jamaah terdekat berjarak 10 meter.'));
      expect(controller.voicePhase.value, AiVoicePhase.idle);
      controller.dispose();
    });

    test('toggleMute membisukan auto-speak selama sesi aktif', () async {
      final mockBle = _MockSmartbandBleService();
      final bridge = SmartbandAiBridgeService(bleService: mockBle);
      final voice = _TestVoiceService();

      final mockClient = MockClient((request) async {
        final sseBody = [
          'data: {"choices":[{"delta":{"content":"{\\"speech\\": \\"Jawaban suara dibisukan.\\", \\"oled\\": \\"BISU\\"}"}}]}',
          '',
          'data: [DONE]',
          '',
        ].join('\n');
        return http.Response(
          sseBody,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });

      final repo = AiAssistantRepository(
        hermesService: HermesAiService(httpClient: mockClient),
        smartbandBridge: bridge,
      );

      final controller = HajiCareAiController(
        repository: repo,
        voiceService: voice,
        autoInitPlatformServices: false,
      );

      expect(controller.isMuted.value, isFalse);
      controller.toggleMute();
      expect(controller.isMuted.value, isTrue);

      await controller.sendQuestion('Tes mode mute');
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Karena isMuted true, feedStreamingSpeech tidak boleh dipanggil
      expect(voice.queuedSentences, isEmpty);
      controller.dispose();
    });

    test('cancelCurrentTurn membatalkan turn aktif dan menghentikan suara', () async {
      final mockBle = _MockSmartbandBleService();
      final bridge = SmartbandAiBridgeService(bleService: mockBle);
      final voice = _TestVoiceService();

      // Mock streaming tak terbatas
      final completer = Completer<http.StreamedResponse>();
      final mockClient = MockClient.streaming((request, bodyStream) async {
        return completer.future;
      });

      final repo = AiAssistantRepository(
        hermesService: HermesAiService(httpClient: mockClient),
        smartbandBridge: bridge,
      );

      final controller = HajiCareAiController(
        repository: repo,
        voiceService: voice,
        autoInitPlatformServices: false,
      );
      controller.onInit();

      controller.isSending.value = true;
      controller.voicePhase.value = AiVoicePhase.thinking;
      expect(controller.isSending.value, isTrue);
      expect(controller.voicePhase.value, AiVoicePhase.thinking);

      await controller.cancelCurrentTurn();
      expect(controller.isSending.value, isFalse);
      expect(controller.voicePhase.value, AiVoicePhase.idle);
      controller.dispose();
    });

    test('chat session menampilkan fase thinking (isPending) lalu mengalirkan teks per kata (isStreaming) secara bertahap', () async {
      final mockBle = _MockSmartbandBleService();
      final bridge = SmartbandAiBridgeService(bleService: mockBle);
      final voice = _TestVoiceService();

      final responseCompleter = Completer<http.StreamedResponse>();
      final chunkController = StreamController<List<int>>();

      final mockClient = MockClient.streaming((request, bodyStream) async {
        return responseCompleter.future;
      });

      final repo = AiAssistantRepository(
        hermesService: HermesAiService(httpClient: mockClient),
        smartbandBridge: bridge,
      );

      final controller = HajiCareAiController(
        repository: repo,
        voiceService: voice,
        autoInitPlatformServices: false,
      );
      controller.onInit();

      // 1. Kirim pertanyaan di chat: pesan asisten harus berstatus isPending (Thinking)
      final sendFuture = controller.sendQuestion('Bagaimana kondisi kesehatan saya di Mina?');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.messages.last.isPending, isTrue);
      expect(controller.messages.last.isStreaming, isFalse);

      // 2. Server mulai mengirim header SSE
      responseCompleter.complete(
        http.StreamedResponse(
          chunkController.stream,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 3. Kirim kalimat panjang dalam satu chunk cepat: harus di-pace per kata (bukan langsung keluar penuh tanpa streaming)
      const fullSentence = 'Alhamdulillah kondisi kesehatan Anda saat ini sangat stabil dan aman untuk beribadah.';
      final sseContent = jsonEncode({'speech': fullSentence, 'oled': 'SEHAT AMAN'});
      final sseEnvelope = jsonEncode({
        'choices': [
          {
            'delta': {'content': sseContent}
          }
        ]
      });
      chunkController.add(utf8.encode('data: $sseEnvelope\n\n'));
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final midMsg = controller.messages.last;
      expect(midMsg.isPending, isFalse);
      expect(midMsg.isStreaming, isTrue);
      expect(midMsg.text, isNotEmpty);
      expect(midMsg.text.length, lessThan(fullSentence.length));

      // 4. Akhiri stream SSE dan tunggu word pacer menyelesaikan seluruh kata
      chunkController.add(utf8.encode('data: [DONE]\n\n'));
      await chunkController.close();
      await sendFuture;
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final finalMsg = controller.messages.last;
      expect(finalMsg.isPending, isFalse);
      expect(finalMsg.isStreaming, isFalse);
      expect(finalMsg.text, equals(fullSentence));
      expect(finalMsg.oledText, equals('SEHAT AMAN'));

      controller.dispose();
    });
  });
}
