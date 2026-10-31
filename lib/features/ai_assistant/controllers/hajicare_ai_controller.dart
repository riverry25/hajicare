import 'dart:async';

import 'package:get/get.dart';

import '../models/ai_chat_message.dart';
import '../models/ai_server_config.dart';
import '../models/ai_server_status.dart';
import '../models/oled_display_state.dart';
import '../models/sensor_context.dart';
import '../repositories/ai_assistant_repository.dart';
import '../services/ai_voice_service.dart';
import '../services/smartband_ai_bridge_service.dart';

/// ViewModel / Controller untuk fitur **HajiCare AI Voice Assistant (Powered by Hermes Agent)**.
///
/// Mengikuti aturan Clean Architecture & MVVM:
/// - Bebas dari `BuildContext` (murni state & logika presentasi).
/// - Seluruh akses data eksternal didelegasikan ke [AiAssistantRepository] dan [AiVoiceService].
/// - Mendukung Constructor Injection untuk kemudahan unit testing.
class HajiCareAiController extends GetxController {
  HajiCareAiController({
    AiAssistantRepository? repository,
    AiVoiceService? voiceService,
    bool autoInitPlatformServices = true,
  }) : _repository =
           repository ??
           (Get.isRegistered<AiAssistantRepository>()
               ? Get.find<AiAssistantRepository>()
               : AiAssistantRepository()),
       _voiceService =
           voiceService ??
           (Get.isRegistered<AiVoiceService>()
               ? Get.find<AiVoiceService>()
               : AiVoiceService()),
       _autoInitPlatformServices = autoInitPlatformServices;

  final AiAssistantRepository _repository;
  final AiVoiceService _voiceService;
  final bool _autoInitPlatformServices;

  /// Deretan tombol cepat (Quick Prompts) sekali sentuh untuk demo cepat.
  static const List<String> quickPrompts = <String>[
    'Bagaimana kondisi kesehatan saya sekarang?',
    'Berapa jarak saya dengan pendamping?',
    'Saya merasa pusing dan lelah, apa yang harus saya lakukan?',
    'Panduan doa saat thawaf',
  ];

  // State Konfigurasi & Kesehatan Server Hermes
  final Rx<AiServerConfig> serverConfig = AiServerConfig.defaults.obs;
  final Rx<AiServerStatus> serverStatus = AiServerStatus.initial.obs;

  // State Konteks Sensor Gelang & BLE
  final Rx<SensorContext> sensorContext = SensorContext(
    heartRateBpm: SmartbandAiBridgeService.defaultHeartRateBpm,
    temperatureC: SmartbandAiBridgeService.defaultTemperatureC,
    isFallDetected: false,
    latitude: SmartbandAiBridgeService.defaultLatitude,
    longitude: SmartbandAiBridgeService.defaultLongitude,
    distanceToCompanionMeters: SmartbandAiBridgeService.defaultDistanceMeters,
    safeRadiusMeters: SmartbandAiBridgeService.defaultSafeRadiusMeters,
    source: SensorDataSource.simulation,
    capturedAt: DateTime.fromMillisecondsSinceEpoch(0),
  ).obs;

  final Rx<SmartbandLinkStatus> bleLinkStatus =
      SmartbandLinkStatus.disconnected.obs;
  final RxBool isSimulationMode = true.obs;
  final RxBool isSensorCardExpanded = true.obs;

  // State Layar OLED Smartband 128x64
  final Rx<OledDisplayState> oledState = OledDisplayState.initial.obs;
  final RxBool isOledLedActive = false.obs;

  // State Percakapan & Suara (TTS / STT)
  final RxList<AiChatMessage> messages = <AiChatMessage>[].obs;
  final RxBool isSending = false.obs;
  final RxBool isSpeaking = false.obs;
  final RxnString activeSpeakingMessageId = RxnString();
  final RxBool isListening = false.obs;
  final RxString recognizedText = ''.obs;
  final RxString voiceStatusMessage = 'Tekan mikrofon untuk mulai berbicara'.obs;
  final RxDouble soundLevel = 0.0.obs;
  final RxnString statusBannerMessage = RxnString();

  Timer? _sensorSyncTimer;
  Timer? _ledPulseTimer;

  AiAssistantRepository get repository => _repository;

  @override
  void onInit() {
    super.onInit();
    _seedInitialWelcomeMessage();
    _bindVoiceCallbacks();
    _refreshSensorSnapshot();

    if (_autoInitPlatformServices) {
      unawaited(_initializeAsync());
      _startSensorSyncTimer();
    }
  }

  Future<void> _initializeAsync() async {
    final loaded = await _repository.loadServerConfig();
    serverConfig.value = loaded;
    await _voiceService.initTts();
    await checkServerHealth();
  }

  void _seedInitialWelcomeMessage() {
    if (messages.isNotEmpty) return;
    messages.add(
      AiChatMessage(
        id: 'welcome-msg',
        role: AiChatRole.assistant,
        text:
            'Assalamualaikum Bapak/Ibu jamaah HajiCare. Saya asisten suara pintar Hermes yang terhubung dengan sensor gelang Anda. '
            'Silakan tekan tombol mikrofon untuk berbicara, pilih pertanyaan cepat di bawah, atau ketik pertanyaan Anda.',
        oledText: 'Siap bantu jamaah HajiCare',
        createdAt: DateTime.now(),
      ),
    );
    oledState.value = OledDisplayState(
      text: 'Siap bantu jamaah HajiCare',
      payload: 'AI:Siap bantu jamaah HajiCare',
      status: OledDeliveryStatus.previewOnly,
      updatedAt: DateTime.now(),
    );
  }

  void _bindVoiceCallbacks() {
    _voiceService.onSpeakingChanged = (speaking) {
      isSpeaking.value = speaking;
      if (!speaking) {
        activeSpeakingMessageId.value = null;
      }
    };

    _voiceService.onListeningChanged = (listening, statusMsg) {
      isListening.value = listening;
      voiceStatusMessage.value = statusMsg;
      if (!listening) {
        soundLevel.value = 0.0;
      }
    };

    _voiceService.onSpeechResult = (words, isFinal) {
      recognizedText.value = words;
      if (isFinal && words.trim().isNotEmpty) {
        isListening.value = false;
        final finalQuery = words.trim();
        recognizedText.value = '';
        unawaited(sendQuestion(finalQuery, autoSpeak: true));
      }
    };

    _voiceService.onSoundLevelChanged = (level) {
      soundLevel.value = level.clamp(-2.0, 10.0);
    };
  }

  void _startSensorSyncTimer() {
    _sensorSyncTimer?.cancel();
    _sensorSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isSimulationMode.value) {
        _repository.smartbandBridge.stepSimulationTick();
      }
      _refreshSensorSnapshot();
    });
  }

  void _refreshSensorSnapshot() {
    bleLinkStatus.value = _repository.smartbandBridge.bleLinkStatus;
    isSimulationMode.value = _repository.smartbandBridge.isSimulationEnabled;
    final nextContext = _repository.getLatestSensorContext();
    if (sensorContext.value != nextContext) {
      sensorContext.value = nextContext;
    }
  }

  /// Segarkan data sensor secara manual.
  void refreshSensorsNow() {
    if (isSimulationMode.value) {
      _repository.smartbandBridge.stepSimulationTick();
    }
    _refreshSensorSnapshot();
  }

  /// Cek status kesehatan server Hermes via `/health`.
  Future<AiServerStatus> checkServerHealth([AiServerConfig? customConfig]) async {
    serverStatus.value = const AiServerStatus(
      health: AiServerHealth.checking,
      message: 'Memeriksa koneksi server Hermes...',
    );
    final result = await _repository.checkServerHealth(customConfig);
    serverStatus.value = result;
    return result;
  }

  /// Simpan konfigurasi URL Server & API Key baru ke `SharedPreferences` dan cek `/health`.
  Future<AiServerStatus> saveServerConfiguration({
    required String baseUrl,
    required String apiKey,
    String? model,
  }) async {
    final updated = await _repository.saveServerConfig(
      AiServerConfig(
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model ?? serverConfig.value.model,
      ),
    );
    serverConfig.value = updated;
    statusBannerMessage.value = null;
    return checkServerHealth(updated);
  }

  /// Reset konfigurasi server ke nilai default bawaan.
  Future<void> resetServerConfiguration() async {
    final defaults = await _repository.resetServerConfig();
    serverConfig.value = defaults;
    await checkServerHealth(defaults);
  }

  /// Ubah status saklar "Mode Simulasi Sensor".
  void toggleSimulationMode(bool enabled) {
    _repository.smartbandBridge.setSimulationEnabled(enabled);
    isSimulationMode.value = enabled;
    _refreshSensorSnapshot();
  }

  /// Ubah simulasi status jatuh untuk keperluan demo.
  void toggleSimulatedFall(bool fallDetected) {
    _repository.smartbandBridge.setSimulatedFallDetected(fallDetected);
    _refreshSensorSnapshot();
  }

  /// Buka/tutup kartu konteks sensor live.
  void toggleSensorCardExpanded() {
    isSensorCardExpanded.value = !isSensorCardExpanded.value;
  }

  /// Hubungkan ke perangkat gelang BLE.
  Future<void> connectSmartbandBle() async {
    await _repository.smartbandBridge.connectSmartband();
    _refreshSensorSnapshot();
  }

  /// Kirim pertanyaan pengguna ke Hermes Agent, tampilkan di chat,
  /// kirim ringkasan ke OLED gelang, dan bacakan dengan TTS.
  Future<void> sendQuestion(
    String rawQuestion, {
    bool autoSpeak = true,
  }) async {
    final question = rawQuestion.trim();
    if (question.isEmpty || isSending.value) return;

    if (isListening.value) {
      await _voiceService.stopListening();
    }
    await _voiceService.stopSpeaking();

    final historySnapshot = List<AiChatMessage>.from(messages);
    final userMsg = AiChatMessage.user(question);
    final pendingMsg = AiChatMessage.pending();

    messages.addAll([userMsg, pendingMsg]);
    isSending.value = true;
    statusBannerMessage.value = null;
    _refreshSensorSnapshot();

    try {
      final outcome = await _repository.askQuestion(
        question: question,
        history: historySnapshot,
      );

      final assistantMsg = pendingMsg.copyWith(
        text: outcome.reply.speech,
        oledText: outcome.oledState.text,
        status: AiChatStatus.done,
        isOfflineFallback: outcome.reply.isOfflineFallback,
      );

      final idx = messages.indexWhere((m) => m.id == pendingMsg.id);
      if (idx >= 0) {
        messages[idx] = assistantMsg;
      } else {
        messages.add(assistantMsg);
      }

      oledState.value = outcome.oledState;
      _triggerOledLedPulse();

      if (outcome.reply.isOfflineFallback) {
        statusBannerMessage.value =
            outcome.errorBannerMessage ??
            'Mode demo lokal aktif (atur URL Ngrok di ⚙️ untuk koneksi Hermes live).';
      } else {
        // Jika request berhasil, otomatis tandai server online
        serverStatus.value = AiServerStatus(
          health: AiServerHealth.online,
          message: 'Terhubung ke Hermes Agent',
          checkedAt: DateTime.now(),
        );
      }

      if (autoSpeak) {
        await speakMessage(assistantMsg);
      }
    } catch (e) {
      final errMsg = pendingMsg.copyWith(
        text: 'Maaf, terjadi kendala saat memproses pertanyaan. Silakan coba lagi.',
        status: AiChatStatus.error,
        retryPrompt: question,
      );
      final idx = messages.indexWhere((m) => m.id == pendingMsg.id);
      if (idx >= 0) {
        messages[idx] = errMsg;
      }
    } finally {
      isSending.value = false;
    }
  }

  /// Nyalakan indikator LED hijau pada widget OLED saat payload `"AI:..."` dikirim.
  void _triggerOledLedPulse() {
    _ledPulseTimer?.cancel();
    isOledLedActive.value = true;
    _ledPulseTimer = Timer(const Duration(seconds: 6), () {
      isOledLedActive.value = false;
    });
  }

  /// Kirim ulang teks OLED ke gelang dari pesan tertentu.
  Future<void> resendOledFromMessage(AiChatMessage message) async {
    final text = message.oledText ?? message.text;
    if (text.trim().isEmpty) return;
    final state = await _repository.resendOled(text);
    oledState.value = state;
    _triggerOledLedPulse();
  }

  /// Bacakan ulang pesan balasan AI menggunakan `flutter_tts` (tombol 🔊 Speak).
  Future<void> speakMessage(AiChatMessage message) async {
    if (!message.isSpeakable) return;
    if (isSpeaking.value && activeSpeakingMessageId.value == message.id) {
      await stopSpeaking();
      return;
    }
    activeSpeakingMessageId.value = message.id;
    await _voiceService.speak(message.text);
  }

  /// Hentikan suara TTS yang sedang aktif (`flutter_tts.stop()`).
  Future<void> stopSpeaking() async {
    activeSpeakingMessageId.value = null;
    await _voiceService.stopSpeaking();
  }

  /// Mulai atau hentikan perekaman suara mikrofon (`speech_to_text` `id_ID`).
  Future<void> toggleVoiceRecording() async {
    if (isListening.value) {
      await stopListeningAndSendIfAny();
    } else {
      recognizedText.value = '';
      await _voiceService.startListening(localeId: 'id_ID');
    }
  }

  /// Hentikan mikrofon, dan jika sudah ada kata yang dikenali, langsung kirim.
  Future<void> stopListeningAndSendIfAny() async {
    final captured = recognizedText.value.trim();
    await _voiceService.stopListening();
    isListening.value = false;
    if (captured.isNotEmpty) {
      recognizedText.value = '';
      await sendQuestion(captured, autoSpeak: true);
    }
  }

  /// Bersihkan riwayat percakapan dan kembali ke sapaan awal.
  Future<void> clearConversation() async {
    await stopSpeaking();
    messages.clear();
    statusBannerMessage.value = null;
    _seedInitialWelcomeMessage();
  }

  @override
  void onClose() {
    _sensorSyncTimer?.cancel();
    _ledPulseTimer?.cancel();
    _voiceService.dispose();
    super.onClose();
  }
}

