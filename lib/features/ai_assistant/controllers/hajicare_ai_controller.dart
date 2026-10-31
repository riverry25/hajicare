import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/state/app_settings_controller.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_server_config.dart';
import '../models/ai_server_status.dart';
import '../models/oled_display_state.dart';
import '../models/sensor_context.dart';
import '../repositories/ai_assistant_repository.dart';
import '../services/ai_voice_service.dart';
import '../services/hermes_ai_service.dart';
import '../services/smartband_ai_bridge_service.dart';

/// Item topik bantuan cepat untuk pengguna pada tampilan awal & quick chips.
class AiPromptTopic {
  const AiPromptTopic({
    required this.title,
    required this.subtitle,
    required this.prompt,
  });

  final String title;
  final String subtitle;
  final String prompt;
}

/// ViewModel / Controller untuk fitur **HajiCare AI Voice Assistant (Powered by Hermes Agent)**.
///
/// Mengikuti aturan Clean Architecture & MVVM:
/// - Bebas dari `BuildContext` (murni state & logika presentasi).
/// - Seluruh akses data nyata didelegasikan ke [AiAssistantRepository] dan [AiVoiceService].
/// - 100% menggunakan data nyata dari seluruh aplikasi (GPS HP, Jarak Pendamping,
///   Room/Kloter/Maktab, Jadwal Salat, Kiblat, SOS, Notifikasi, dan BLE Gelang Asli).
/// - Mendukung efek pengetikan kata demi kata (*word-by-word streaming*).
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

  static const String _prefFabDockedRight = 'hajicare_ai_fab_docked_right';
  static const String _prefFabVerticalFraction = 'hajicare_ai_fab_v_fraction';
  static const String _prefFabCornerMinimized = 'hajicare_ai_fab_minimized';

  /// Deretan tombol cepat (Quick Prompts) sekali sentuh yang mencakup seluruh fitur aplikasi.
  static const List<String> quickPrompts = <String>[
    'Bagaimana kondisi kesehatan saya sekarang?',
    'Berapa jarak saya dengan pendamping dan dimana posisi saya sekarang?',
    'Kapan jadwal salat berikutnya dan berapa derajat arah kiblat?',
    'Saya merasa pusing dan lelah, apa yang harus saya lakukan?',
    'Panduan doa saat thawaf',
    'Apa status rombongan, kloter, maktab, dan pesan notifikasi saya?',
  ];

  /// Daftar Quick Prompts yang otomatis mengikuti bahasa aplikasi aktif (`id`, `en`, `jv`, `su`).
  static List<String> get localizedQuickPrompts => <String>[
    AppTranslations.tr('ai.prompt.health'),
    AppTranslations.tr('ai.prompt.distance'),
    AppTranslations.tr('ai.prompt.prayer'),
    AppTranslations.tr('ai.prompt.dizzy'),
    AppTranslations.tr('ai.prompt.tawafDua'),
    AppTranslations.tr('ai.prompt.roomStatus'),
  ];

  /// Kartu topik unggulan untuk tampilan awal (mencakup seluruh modul aplikasi).
  static const List<AiPromptTopic> featuredTopics = <AiPromptTopic>[
    AiPromptTopic(
      title: 'Cek Kesehatan',
      subtitle: 'Status gelang BLE, BPM & suhu',
      prompt: 'Bagaimana kondisi kesehatan saya sekarang?',
    ),
    AiPromptTopic(
      title: 'Jarak Pendamping',
      subtitle: 'Posisi GPS HP, gelang & rombongan',
      prompt: 'Berapa jarak saya dengan pendamping?',
    ),
    AiPromptTopic(
      title: 'Jadwal Salat & Kiblat',
      subtitle: 'Waktu adzan berikutnya & kompas',
      prompt: 'Kapan jadwal salat berikutnya dan berapa derajat arah kiblat?',
    ),
    AiPromptTopic(
      title: 'Panduan Doa Ibadah',
      subtitle: 'Doa Thawaf, Sa\'i & Zamzam',
      prompt: 'Panduan doa saat thawaf',
    ),
  ];

  /// Kartu topik unggulan yang otomatis mengikuti bahasa aplikasi aktif (`id`, `en`, `jv`, `su`).
  static List<AiPromptTopic> get localizedFeaturedTopics => <AiPromptTopic>[
    AiPromptTopic(
      title: AppTranslations.tr('ai.topic.health.title'),
      subtitle: AppTranslations.tr('ai.topic.health.subtitle'),
      prompt: AppTranslations.tr('ai.prompt.health'),
    ),
    AiPromptTopic(
      title: AppTranslations.tr('ai.topic.companion.title'),
      subtitle: AppTranslations.tr('ai.topic.companion.subtitle'),
      prompt: AppTranslations.tr('ai.prompt.distanceShort'),
    ),
    AiPromptTopic(
      title: AppTranslations.tr('ai.topic.prayer.title'),
      subtitle: AppTranslations.tr('ai.topic.prayer.subtitle'),
      prompt: AppTranslations.tr('ai.prompt.prayer'),
    ),
    AiPromptTopic(
      title: AppTranslations.tr('ai.topic.dua.title'),
      subtitle: AppTranslations.tr('ai.topic.dua.subtitle'),
      prompt: AppTranslations.tr('ai.prompt.tawafDua'),
    ),
  ];

  // State Konfigurasi & Kesehatan Server Hermes
  final Rx<AiServerConfig> serverConfig = AiServerConfig.defaults.obs;
  final Rx<AiServerStatus> serverStatus = AiServerStatus.initial.obs;

  // State Konteks Nyata Aplikasi & Sensor Gelang BLE (Tanpa Simulasi)
  final Rx<SensorContext> sensorContext = SensorContext(
    isSmartbandConnected: false,
    heartRateBpm: 0,
    temperatureC: 0.0,
    isFallDetected: false,
    safeRadiusMeters: SmartbandAiBridgeService.defaultSafeRadiusMeters,
    source: SensorDataSource.disconnected,
    capturedAt: DateTime.fromMillisecondsSinceEpoch(0),
  ).obs;

  final Rx<SmartbandLinkStatus> bleLinkStatus =
      SmartbandLinkStatus.disconnected.obs;
  final RxBool isSensorCardExpanded = false.obs;

  // State Layar OLED Smartband 128x64
  final Rx<OledDisplayState> oledState = OledDisplayState.initial.obs;
  final RxBool isOledLedActive = false.obs;

  // State Percakapan, Streaming Kata Demi Kata, & Mode Suara Penuh
  final RxList<AiChatMessage> messages = <AiChatMessage>[].obs;
  final RxBool isSending = false.obs;
  final RxBool isSpeaking = false.obs;
  final RxnString activeSpeakingMessageId = RxnString();
  final RxBool isListening = false.obs;
  final RxBool isVoiceModeOpen = false.obs;
  final RxString recognizedText = ''.obs;
  final RxString voiceStatusMessage =
      'Ketuk mikrofon untuk mulai berbicara'.obs;
  final RxDouble soundLevel = 0.0.obs;
  final RxnString statusBannerMessage = RxnString();
  final RxString lastSpokenOrReplyText = ''.obs;

  // State Posisi & Pengecilan Tombol Floating AI (Sinkron di Beranda, Jadwal Salat, & Profil)
  final RxBool fabDockedRight = true.obs;
  final RxDouble fabVerticalFraction = 0.76.obs;
  final RxBool fabCornerMinimized = false.obs;

  Timer? _sensorSyncTimer;
  Timer? _ledPulseTimer;
  Timer? _streamingTimer;
  Worker? _localeWorker;
  String? _activeStreamingMessageId;

  AiAssistantRepository get repository => _repository;

  @override
  void onInit() {
    super.onInit();
    _refreshSensorSnapshot();
    _seedInitialWelcomeMessage();
    _bindVoiceCallbacks();

    if (Get.isRegistered<AppSettingsController>()) {
      _localeWorker = ever(Get.find<AppSettingsController>().rxLocale, (_) {
        voiceStatusMessage.value = AppTranslations.tr('ai.voiceTapToAskStatus');
        if (messages.length == 1 && messages.first.id == 'welcome-msg') {
          messages.clear();
          _seedInitialWelcomeMessage();
        } else {
          messages.refresh();
        }
      });
    }

    if (_autoInitPlatformServices) {
      unawaited(_initializeAsync());
      _startSensorSyncTimer();
    }
  }

  Future<void> _initializeAsync() async {
    await _loadFabPreferences();
    final loaded = await _repository.loadServerConfig();
    serverConfig.value = loaded;
    await _voiceService.initTts();
    await checkServerHealth();
  }

  Future<void> _loadFabPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dockedRight = prefs.getBool(_prefFabDockedRight);
      final vFrac = prefs.getDouble(_prefFabVerticalFraction);
      if (dockedRight != null) fabDockedRight.value = dockedRight;
      if (vFrac != null) fabVerticalFraction.value = vFrac.clamp(0.0, 1.0);
      // Di awal aplikasi dibuka, selalu tampilkan label "AI Assistant" terlebih dahulu
      // agar pengguna tidak bingung itu ikon apa; label akan hilang otomatis saat di-snap ke samping.
      fabCornerMinimized.value = false;
    } catch (_) {}
  }

  /// Simpan posisi tempel kiri/kanan, rasio vertikal, dan mode mengecil di sudut layar.
  Future<void> updateFloatingButtonPosition({
    required bool dockedRight,
    required double verticalFraction,
    required bool cornerMinimized,
  }) async {
    final clampedV = verticalFraction.clamp(0.0, 1.0);
    fabDockedRight.value = dockedRight;
    fabVerticalFraction.value = clampedV;
    fabCornerMinimized.value = cornerMinimized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefFabDockedRight, dockedRight);
      await prefs.setDouble(_prefFabVerticalFraction, clampedV);
      await prefs.setBool(_prefFabCornerMinimized, cornerMinimized);
    } catch (_) {}
  }

  void _seedInitialWelcomeMessage() {
    if (messages.isNotEmpty) return;
    final ctx = sensorContext.value;
    final bandStatus = ctx.isSmartbandConnected
        ? AppTranslations.tr('ai.welcomeConnected')
        : AppTranslations.tr('ai.welcomeDisconnected');
    final welcomeText = AppTranslations.tr('ai.welcomeMessage', {
      'name': ctx.userName,
      'bandStatus': bandStatus,
    });
    final oledWelcome = AppTranslations.tr('ai.oledReadyDefault');
    messages.add(
      AiChatMessage(
        id: 'welcome-msg',
        role: AiChatRole.assistant,
        text: welcomeText,
        fullText: welcomeText,
        oledText: oledWelcome,
        createdAt: DateTime.now(),
      ),
    );
    lastSpokenOrReplyText.value = welcomeText;
    oledState.value = OledDisplayState(
      text: oledWelcome,
      payload: 'AI:$oledWelcome',
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
    // Sinkronisasi ringan setiap 5 detik untuk menjaga frame budget <16ms
    _sensorSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshSensorSnapshot();
    });
  }

  void _refreshSensorSnapshot() {
    final nextBle = _repository.smartbandBridge.bleLinkStatus;
    if (bleLinkStatus.value != nextBle) {
      bleLinkStatus.value = nextBle;
    }
    final nextContext = _repository.getLatestSensorContext();
    if (sensorContext.value != nextContext) {
      sensorContext.value = nextContext;
    }
  }

  /// Segarkan data aplikasi & sensor gelang secara manual.
  void refreshSensorsNow() {
    _refreshSensorSnapshot();
  }

  /// Cek status kesehatan server Hermes via `/health` (atau `/v1/models`).
  Future<AiServerStatus> checkServerHealth([
    AiServerConfig? customConfig,
  ]) async {
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

  /// Buka/tutup kartu konteks sensor live.
  void toggleSensorCardExpanded() {
    isSensorCardExpanded.value = !isSensorCardExpanded.value;
  }

  /// Hubungkan ke perangkat gelang BLE fisik.
  Future<void> connectSmartbandBle() async {
    await _repository.smartbandBridge.connectSmartband();
    _refreshSensorSnapshot();
  }

  /// Buka Mode Suara Penuh (Immersive Voice Orb seperti referensi desain).
  Future<void> openVoiceMode({bool autoStartListening = true}) async {
    isVoiceModeOpen.value = true;
    if (autoStartListening && !isListening.value) {
      recognizedText.value = '';
      await _voiceService.startListening();
    }
  }

  /// Tutup Mode Suara Penuh dan kembali ke ruang chat.
  Future<void> closeVoiceMode() async {
    if (isListening.value) {
      await _voiceService.stopListening();
      isListening.value = false;
    }
    isVoiceModeOpen.value = false;
  }

  /// Kirim pertanyaan pengguna ke Hermes Agent, tampilkan dengan efek
  /// pengetikan kata demi kata (*word-by-word*), kirim ringkasan ke OLED gelang,
  /// dan bacakan dengan TTS.
  Future<void> sendQuestion(String rawQuestion, {bool autoSpeak = true}) async {
    final question = rawQuestion.trim();
    if (question.isEmpty || isSending.value) return;

    completeActiveStreamImmediately();

    if (isListening.value) {
      await _voiceService.stopListening();
      isListening.value = false;
    }
    await _voiceService.stopSpeaking();

    final historySnapshot = List<AiChatMessage>.from(messages);
    final userMsg = AiChatMessage.user(question);
    final pendingMsg = AiChatMessage.pending(promptQuestion: question);

    messages.addAll([userMsg, pendingMsg]);
    isSending.value = true;
    statusBannerMessage.value = null;
    _refreshSensorSnapshot();

    try {
      final outcome = await _repository.askQuestion(
        question: question,
        history: historySnapshot,
      );

      final fullSpeech = outcome.reply.speech;
      final actions = HermesAiService.inferContextualActions(
        question: question,
        replySpeech: fullSpeech,
        sensor: outcome.sensorSnapshot,
      );

      lastSpokenOrReplyText.value = fullSpeech;
      oledState.value = outcome.oledState;
      _triggerOledLedPulse();

      if (!outcome.reply.isOfflineFallback) {
        serverStatus.value = AiServerStatus(
          health: AiServerHealth.online,
          message: 'Terhubung ke Hermes Agent',
          checkedAt: DateTime.now(),
        );
      }

      if (_autoInitPlatformServices) {
        final initialMsg = pendingMsg.copyWith(
          text: _takeFirstWords(fullSpeech, 3),
          fullText: fullSpeech,
          isStreaming: true,
          oledText: outcome.oledState.text,
          status: AiChatStatus.done,
          isOfflineFallback: outcome.reply.isOfflineFallback,
          promptQuestion: question,
          contextualActions: actions,
        );
        _replaceMessage(pendingMsg.id, initialMsg);
        isSending.value = false;
        _startWordByWordStream(initialMsg.id, fullSpeech);
        if (autoSpeak) {
          unawaited(speakMessage(initialMsg));
        }
      } else {
        final doneMsg = pendingMsg.copyWith(
          text: fullSpeech,
          fullText: fullSpeech,
          isStreaming: false,
          oledText: outcome.oledState.text,
          status: AiChatStatus.done,
          isOfflineFallback: outcome.reply.isOfflineFallback,
          promptQuestion: question,
          contextualActions: actions,
        );
        _replaceMessage(pendingMsg.id, doneMsg);
        isSending.value = false;
        if (autoSpeak) {
          await speakMessage(doneMsg);
        }
      }
    } catch (_) {
      final errText = AppTranslations.tr('ai.errorProcessingQuestion');
      final errMsg = pendingMsg.copyWith(
        text: errText,
        fullText: errText,
        isStreaming: false,
        status: AiChatStatus.error,
        retryPrompt: question,
        promptQuestion: question,
      );
      _replaceMessage(pendingMsg.id, errMsg);
    } finally {
      isSending.value = false;
    }
  }

  /// Ulangi / Regenerate jawaban untuk pesan asisten tertentu (tombol ↻).
  Future<void> regenerateMessage(AiChatMessage message) async {
    final prompt = message.promptQuestion ?? message.retryPrompt;
    if (prompt != null && prompt.trim().isNotEmpty) {
      await sendQuestion(prompt, autoSpeak: true);
      return;
    }
    final idx = messages.indexWhere((m) => m.id == message.id);
    for (var i = (idx >= 0 ? idx - 1 : messages.length - 1); i >= 0; i--) {
      if (messages[i].isUser && messages[i].text.trim().isNotEmpty) {
        await sendQuestion(messages[i].text, autoSpeak: true);
        return;
      }
    }
  }

  void _replaceMessage(String id, AiChatMessage updated) {
    final idx = messages.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      messages[idx] = updated;
    } else {
      messages.add(updated);
    }
  }

  static String _takeFirstWords(String text, int count) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length <= count) return text;
    return words.take(count).join(' ');
  }

  /// Efek pengetikan kata demi kata (*word-by-word typewriter streaming*)
  /// yang dioptimasi (50ms per 4 kata) agar mulus 60fps tanpa membebani main thread.
  void _startWordByWordStream(String messageId, String fullText) {
    _streamingTimer?.cancel();
    _activeStreamingMessageId = messageId;

    final words = fullText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length <= 3) {
      completeActiveStreamImmediately();
      return;
    }

    var currentWordCount = 3;
    _streamingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final idx = messages.indexWhere((m) => m.id == messageId);
      if (idx < 0) {
        timer.cancel();
        _activeStreamingMessageId = null;
        return;
      }

      currentWordCount += 4;
      if (currentWordCount >= words.length) {
        messages[idx] = messages[idx].copyWith(
          text: fullText,
          isStreaming: false,
        );
        timer.cancel();
        _activeStreamingMessageId = null;
      } else {
        messages[idx] = messages[idx].copyWith(
          text: words.take(currentWordCount).join(' '),
          isStreaming: true,
        );
      }
    });
  }

  /// Selesaikan animasi ketik kata demi kata secara instan (misal saat diketuk).
  void completeActiveStreamImmediately() {
    _streamingTimer?.cancel();
    _streamingTimer = null;
    final id = _activeStreamingMessageId;
    _activeStreamingMessageId = null;
    if (id == null) return;

    final idx = messages.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      final msg = messages[idx];
      messages[idx] = msg.copyWith(
        text: msg.effectiveFullText,
        isStreaming: false,
      );
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
    final text = message.oledText ?? message.effectiveFullText;
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
    lastSpokenOrReplyText.value = message.effectiveFullText;
    await _voiceService.speak(message.effectiveFullText);
  }

  /// Bacakan ulang jawaban terakhir (digunakan di Mode Suara Penuh).
  Future<void> replayLastAssistantReply() async {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isSpeakable) {
        await speakMessage(messages[i]);
        return;
      }
    }
  }

  /// Hentikan suara TTS yang sedang aktif (`flutter_tts.stop()`).
  Future<void> stopSpeaking() async {
    activeSpeakingMessageId.value = null;
    await _voiceService.stopSpeaking();
  }

  /// Mulai atau hentikan perekaman suara mikrofon sesuai bahasa aktif.
  Future<void> toggleVoiceRecording() async {
    if (isListening.value) {
      await stopListeningAndSendIfAny();
    } else {
      recognizedText.value = '';
      await _voiceService.startListening();
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
    completeActiveStreamImmediately();
    await stopSpeaking();
    messages.clear();
    statusBannerMessage.value = null;
    _seedInitialWelcomeMessage();
  }

  @override
  void onClose() {
    _localeWorker?.dispose();
    _sensorSyncTimer?.cancel();
    _ledPulseTimer?.cancel();
    _streamingTimer?.cancel();
    _voiceService.dispose();
    super.onClose();
  }
}
