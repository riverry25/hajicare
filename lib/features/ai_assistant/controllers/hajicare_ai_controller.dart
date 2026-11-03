import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/app_settings_controller.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_messaging_config.dart';
import '../services/ai_external_messaging_service.dart';
import '../models/ai_server_config.dart';
import '../models/ai_server_status.dart';
import '../models/ai_stream_event.dart';
import '../models/ai_voice_phase.dart';
import '../models/oled_display_state.dart';
import '../models/sensor_context.dart';
import '../repositories/ai_assistant_repository.dart';
import '../services/ai_voice_service.dart';
import '../services/hermes_ai_service.dart';
import 'dart:typed_data';
import '../../../core/utils/app_logger.dart';
import '../../smartband/services/smartband_ble_service.dart';
import '../../smartband/controllers/smartband_ldr_controller.dart';
import '../services/audio_transcription_service.dart';
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
class HajiCareAiController extends GetxController with WidgetsBindingObserver {
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
    'Kabari pendamping kondisi & lokasi saya lewat WhatsApp',
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

  // State Konfigurasi & Kesehatan Server Hermes + Integrasi WhatsApp
  final Rx<AiServerConfig> serverConfig = AiServerConfig.defaults.obs;
  final Rx<AiServerStatus> serverStatus = AiServerStatus.initial.obs;
  final Rx<AiMessagingConfig> messagingConfig = AiMessagingConfig.defaults.obs;

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

  // State Fase Suara, Streaming Turn, & Mute Sesi
  final Rx<AiVoicePhase> voicePhase = AiVoicePhase.idle.obs;
  final RxString currentTurnQuestion = ''.obs;
  final RxString currentTurnReply = ''.obs;
  final RxBool isMuted = false.obs;
  final RxBool isAppInForeground = true.obs;

  int _turnGeneration = 0;
  StreamSubscription<AiTurnEvent>? _currentTurnSubscription;
  StreamSubscription<bool>? _smartbandAiListeningSub;
  StreamSubscription<Uint8List>? _smartbandAudioSub;
  StreamSubscription<Uint8List>? _smartbandLivePacketsSub;

  // State Posisi & Pengecilan Tombol Floating AI (Sinkron di Beranda, Jadwal Salat, & Profil)
  final RxBool fabDockedRight = true.obs;
  final RxDouble fabVerticalFraction = 0.76.obs;
  final RxBool fabCornerMinimized = false.obs;

  Timer? _sensorSyncTimer;
  Timer? _ledPulseTimer;
  Timer? _streamingTimer;
  Worker? _localeWorker;
  String? _activeStreamingMessageId;
  String _streamingTargetText = '';
  String _streamingDisplayedText = '';
  bool _streamingTargetDone = false;
  AiTurnDone? _pendingTurnDone;
  String? _currentTurnPromptQuestion;

  AiAssistantRepository get repository => _repository;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
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
      _bindSmartbandAiVoiceStream();
    }
  }

  Future<void> _initializeAsync() async {
    await _loadFabPreferences();
    final loaded = await _repository.loadServerConfig();
    serverConfig.value = loaded;
    messagingConfig.value = await AiExternalMessagingService.instance.loadConfig();
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

  void _recomputeVoicePhase() {
    if (isListening.value) {
      voicePhase.value = AiVoicePhase.listening;
    } else if (isSending.value) {
      if (currentTurnReply.value.trim().isEmpty) {
        voicePhase.value = AiVoicePhase.thinking;
      } else {
        voicePhase.value = AiVoicePhase.answering;
      }
    } else if (isSpeaking.value) {
      voicePhase.value = AiVoicePhase.answering;
    } else {
      voicePhase.value = AiVoicePhase.idle;
    }
  }


  /// Kaitkan aliran perekaman audio INMP441 & status mic dari gelang fisik ESP32-S3
  void _bindSmartbandAiVoiceStream() {
    try {
      SmartbandBleService? bleService;
      if (Get.isRegistered<SmartbandBleService>()) {
        bleService = Get.find<SmartbandBleService>();
      } else if (Get.isRegistered<SmartbandLdrController>()) {
        bleService = Get.find<SmartbandLdrController>().bleService;
      }

      if (bleService == null) {
        AppLogger.warn(
          'SmartbandBleService belum siap untuk audio, akan auto-bind saat snapshot berikutnya.',
          tag: 'HajiCareAi',
        );
        return;
      }

      _smartbandAiListeningSub?.cancel();
      _smartbandAiListeningSub = bleService.smartbandAiListeningStream.listen(
        (isListeningFromBand) {
          isListening.value = isListeningFromBand;
          if (isListeningFromBand) {
            voicePhase.value = AiVoicePhase.listening;
            voiceStatusMessage.value = 'Mendengarkan suara dari Smartband (INMP441)...';
            recognizedText.value = 'Mendengarkan ucapan Anda dari gelang...';

            if (isAppInForeground.value && Get.currentRoute != AppRoutes.aiAssistant) {
              Get.toNamed(AppRoutes.aiAssistant);
            }
          } else {
            if (voicePhase.value == AiVoicePhase.listening) {
              voicePhase.value = AiVoicePhase.thinking;
              voiceStatusMessage.value = 'Memproses rekaman suara gelang...';
            }
          }
        },
      );

      _smartbandLivePacketsSub?.cancel();
      _smartbandLivePacketsSub = bleService.audioStream.listen(
        (chunk) {
          if (chunk.length >= 2) {
            int peak = 0;
            final bd = ByteData.sublistView(chunk);
            final samples = chunk.length ~/ 2;
            for (var i = 0; i < samples; i += 2) {
              final val = bd.getInt16(i * 2, Endian.little).abs();
              if (val > peak) peak = val;
            }
            soundLevel.value = (peak / 32768.0).clamp(0.0, 1.0) * 10.0;
          }
        },
      );

      _smartbandAudioSub?.cancel();
      _smartbandAudioSub = bleService.completePcmAudioRecordingStream.listen(
        (pcmBytes) async {
          AppLogger.info(
            'Menerima aliran rekaman audio smartband: ${pcmBytes.length} bytes',
            tag: 'HajiCareAi',
          );
          await _handleSmartbandAudioRecording(pcmBytes);
        },
      );
      AppLogger.info('Aliran suara Smartband BLE berhasil dikaitkan ke HajiCare AI', tag: 'HajiCareAi');
    } catch (e) {
      AppLogger.warn('Gagal mengaitkan aliran suara Smartband BLE: $e', tag: 'HajiCareAi');
    }
  }

  /// Memproses rekaman audio PCM mentah dari gelang via AudioTranscriptionService lalu menjalankan AI
  Future<void> _handleSmartbandAudioRecording(Uint8List pcmBytes) async {
    try {
      isListening.value = false;
      soundLevel.value = 0.0;
      voicePhase.value = AiVoicePhase.thinking;
      voiceStatusMessage.value = 'Mentranskripsi suara dari gelang...';
      unawaited(_repository.smartbandBridge.streamTokenToSmartbandOled('Memproses suara...'));

      final text = await AudioTranscriptionService.instance.transcribePcm(pcmBytes);
      if (text.trim().isEmpty) {
        voiceStatusMessage.value = 'Suara tidak terdengar jelas';
        recognizedText.value = '';
        unawaited(_repository.smartbandBridge.streamTokenToSmartbandOled('Suara tidak jelas. Coba lagi.', isFinal: true));
        voicePhase.value = AiVoicePhase.idle;
        return;
      }

      voiceStatusMessage.value = text;
      recognizedText.value = text;
      AppLogger.info('Smartband STT berhasil ditranskripsi: "$text"', tag: 'HajiCareAi');

      // Jalankan proses tanya-jawab AI streaming otomatis.
      // Jika HP di saku / layar terkunci (!isAppInForeground.value):
      // TTS speaker dimatikan agar senyap di saku, jawaban hanya tampil di layar OLED gelang.
      // Jika HP dibuka di foreground, TTS dibacakan normal.
      final shouldAutoSpeak = isAppInForeground.value && !isMuted.value;
      await sendQuestion(text, autoSpeak: shouldAutoSpeak);
    } catch (e) {
      AppLogger.error('Gagal memproses audio dari smartband: $e', tag: 'HajiCareAi');
      unawaited(_repository.smartbandBridge.streamTokenToSmartbandOled('Gagal proses audio', isFinal: true));
      isListening.value = false;
      soundLevel.value = 0.0;
      recognizedText.value = '';
      voicePhase.value = AiVoicePhase.idle;
    }
  }

  void _bindVoiceCallbacks() {
    _voiceService.onSpeakingChanged = (speaking) {
      isSpeaking.value = speaking;
      if (!speaking) {
        activeSpeakingMessageId.value = null;
      }
      _recomputeVoicePhase();
    };

    _voiceService.onListeningChanged = (listening, statusMsg) {
      isListening.value = listening;
      voiceStatusMessage.value = statusMsg;
      if (!listening) {
        soundLevel.value = 0.0;
      }
      _recomputeVoicePhase();
    };

    _voiceService.onSpeechResult = (words, isFinal) {
      recognizedText.value = words;
      if (isFinal && words.trim().isNotEmpty) {
        isListening.value = false;
        final finalQuery = words.trim();
        recognizedText.value = '';
        currentTurnQuestion.value = finalQuery;
        currentTurnReply.value = '';
        isSending.value = true;
        _recomputeVoicePhase();
        unawaited(sendQuestion(finalQuery, autoSpeak: !isMuted.value));
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
    if (_smartbandAudioSub == null) {
      _bindSmartbandAiVoiceStream();
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
    isVoiceModeOpen.value = false;
    if (isListening.value) {
      await _voiceService.stopListening();
      isListening.value = false;
    }
    await cancelCurrentTurn();
  }

  /// Aktifkan / nonaktifkan suara AI untuk sesi saat ini (mute suara).
  void toggleMute() {
    isMuted.value = !isMuted.value;
    if (isMuted.value) {
      stopSpeaking();
    }
  }

  /// Batalkan permintaan tanya-jawab yang sedang berjalan dan hentikan suara TTS.
  Future<void> cancelCurrentTurn() async {
    _turnGeneration++;
    await _currentTurnSubscription?.cancel();
    _currentTurnSubscription = null;
    isSending.value = false;
    await stopSpeaking();
    _recomputeVoicePhase();
  }

  /// Kirim pertanyaan pengguna ke Hermes Agent, tampilkan secara streaming
  /// langsung dari token pertama, kirim ringkasan ke OLED gelang,
  /// dan bacakan beruntun per kalimat dengan TTS.
  Future<void> sendQuestion(String rawQuestion, {bool autoSpeak = true}) async {
    final question = rawQuestion.trim();
    if (question.isEmpty) return;

    // Batalkan turn streaming sebelumnya jika masih berjalan
    _turnGeneration++;
    final currentGen = _turnGeneration;
    await _currentTurnSubscription?.cancel();
    _currentTurnSubscription = null;
    completeActiveStreamImmediately();

    if (isListening.value) {
      await _voiceService.stopListening();
      isListening.value = false;
    }
    await _voiceService.stopSpeaking();

    // Hapus balasan lama dan simpan pertanyaan turn saat ini agar UI tidak menampilkan jawaban lama
    currentTurnQuestion.value = question;
    currentTurnReply.value = '';

    final historySnapshot = List<AiChatMessage>.from(messages);
    final userMsg = AiChatMessage.user(question);
    final pendingMsg = AiChatMessage.pending(promptQuestion: question);

    messages.addAll([userMsg, pendingMsg]);
    isSending.value = true;
    statusBannerMessage.value = null;
    _refreshSensorSnapshot();
    _recomputeVoicePhase(); // Otomatis beralih ke AiVoicePhase.thinking

    final effectiveAutoSpeak = autoSpeak && !isMuted.value;
    _streamingTargetText = '';
    _streamingDisplayedText = '';
    _streamingTargetDone = false;
    _pendingTurnDone = null;
    _activeStreamingMessageId = pendingMsg.id;
    _currentTurnPromptQuestion = question;

    try {
      final stream = _repository.askQuestionStream(
        question: question,
        history: historySnapshot,
        concise: isVoiceModeOpen.value,
      );

      _currentTurnSubscription = stream.listen(
        (event) {
          if (_turnGeneration != currentGen) return;

          if (event is AiTurnDelta) {
            currentTurnReply.value = event.speechSoFar;
            _recomputeVoicePhase(); // Beralih ke AiVoicePhase.answering

            _feedStreamingText(
              messageId: pendingMsg.id,
              promptQuestion: question,
              targetText: event.speechSoFar,
              currentGen: currentGen,
            );

            if (effectiveAutoSpeak) {
              _voiceService.feedStreamingSpeech(event.speechSoFar);
            }
            unawaited(_repository.smartbandBridge.streamTokenToSmartbandOled(event.speechSoFar));
          } else if (event is AiTurnDone) {
            final fullSpeech = event.reply.speech;

            currentTurnReply.value = fullSpeech;
            lastSpokenOrReplyText.value = fullSpeech;
            oledState.value = event.oledState;
            _triggerOledLedPulse();

            if (!event.reply.isOfflineFallback) {
              serverStatus.value = AiServerStatus(
                health: AiServerHealth.online,
                message: 'Terhubung ke Hermes Agent',
                checkedAt: DateTime.now(),
              );
            }

            isSending.value = false;
            _recomputeVoicePhase();

            if (effectiveAutoSpeak) {
              _voiceService.finishStreamingSpeech(fullSpeech);
            }
            final oledText = event.reply.oled.trim().isNotEmpty
                ? event.reply.oled.trim()
                : fullSpeech;
            unawaited(_repository.smartbandBridge.streamTokenToSmartbandOled(oledText, isFinal: true));

            _streamingTargetText = fullSpeech;
            _streamingTargetDone = true;
            _pendingTurnDone = event;

            _feedStreamingText(
              messageId: pendingMsg.id,
              promptQuestion: question,
              targetText: fullSpeech,
              currentGen: currentGen,
            );

            if (AiExternalMessagingService.shouldSendToWhatsApp(
              userQuestion: question,
              reply: event.reply,
            )) {
              unawaited(
                _autoDispatchWhatsAppForTurn(
                  messageId: pendingMsg.id,
                  question: question,
                  reply: event.reply,
                  sensor: event.sensorSnapshot,
                ),
              );
            }
          }
        },
        onError: (err) {
          if (_turnGeneration != currentGen) return;
          isSending.value = false;
          _recomputeVoicePhase();
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
        },
        onDone: () {
          if (_turnGeneration == currentGen) {
            isSending.value = false;
            _recomputeVoicePhase();
          }
        },
      );
    } catch (_) {
      if (_turnGeneration != currentGen) return;
      isSending.value = false;
      _recomputeVoicePhase();
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

  void _feedStreamingText({
    required String messageId,
    required String promptQuestion,
    required String targetText,
    required int currentGen,
  }) {
    if (_turnGeneration != currentGen) return;
    _activeStreamingMessageId = messageId;
    _currentTurnPromptQuestion = promptQuestion;
    _streamingTargetText = targetText;

    if (_streamingTimer == null) {
      _stepStreamingPacer(currentGen);
    }
  }

  void _scheduleNextPacerTick(int currentGen) {
    _streamingTimer?.cancel();
    if (_activeStreamingMessageId == null || _turnGeneration != currentGen) return;
    _streamingTimer = Timer(const Duration(milliseconds: 25), () {
      _stepStreamingPacer(currentGen);
    });
  }

  void _stepStreamingPacer(int currentGen) {
    if (_turnGeneration != currentGen) {
      _streamingTimer?.cancel();
      _streamingTimer = null;
      return;
    }

    final messageId = _activeStreamingMessageId;
    if (messageId == null) {
      _streamingTimer?.cancel();
      _streamingTimer = null;
      return;
    }

    if (_streamingDisplayedText.length < _streamingTargetText.length) {
      final remaining = _streamingTargetText.substring(_streamingDisplayedText.length);
      final lag = remaining.length;

      // Adaptive word pacing:
      // - Normal: ambil 1 kata
      // - Sedang (lag > 40): ambil 2 kata
      // - Cepat (lag > 120): ambil 3-4 kata agar tidak tertinggal jauh
      final int minStep;
      if (lag > 120) {
        minStep = 28;
      } else if (lag > 40) {
        minStep = 14;
      } else {
        minStep = 4;
      }

      final charsToTake = _findWordBoundary(remaining, minStep);
      _streamingDisplayedText = _streamingTargetText.substring(
        0,
        _streamingDisplayedText.length + charsToTake,
      );

      final idx = messages.indexWhere((m) => m.id == messageId);
      if (idx >= 0) {
        final currentMsg = messages[idx];
        messages[idx] = currentMsg.copyWith(
          text: _streamingDisplayedText,
          fullText: _streamingTargetText,
          isStreaming: true,
          status: AiChatStatus.done,
          promptQuestion: _currentTurnPromptQuestion,
        );
      }
    }

    if (_streamingDisplayedText.length < _streamingTargetText.length) {
      _scheduleNextPacerTick(currentGen);
    } else if (_streamingTargetDone) {
      _finalizeStreaming(messageId, currentGen);
    } else {
      _streamingTimer?.cancel();
      _streamingTimer = null;
    }
  }

  int _findWordBoundary(String text, int minLength) {
    if (text.length <= minLength) return text.length;
    for (var i = minLength; i < text.length; i++) {
      final c = text[i];
      if (c == ' ' || c == '\n' || c == '\t' || c == '.' || c == ',' || c == '!' || c == '?') {
        return i + 1;
      }
    }
    return text.length;
  }

  void _finalizeStreaming(String messageId, int currentGen) {
    if (_turnGeneration != currentGen) return;
    _streamingTimer?.cancel();
    _streamingTimer = null;
    _activeStreamingMessageId = null;

    final doneEvent = _pendingTurnDone;
    _pendingTurnDone = null;
    _streamingTargetDone = false;

    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx >= 0) {
      final currentMsg = messages[idx];
      final fullSpeech = doneEvent?.reply.speech ?? _streamingTargetText;
      final actions = doneEvent != null
          ? HermesAiService.inferContextualActions(
              question: currentMsg.promptQuestion ?? '',
              replySpeech: fullSpeech,
              sensor: doneEvent.sensorSnapshot,
            )
          : currentMsg.contextualActions;

      messages[idx] = currentMsg.copyWith(
        text: fullSpeech,
        fullText: fullSpeech,
        isStreaming: false,
        oledText: doneEvent?.reply.oled ?? currentMsg.oledText,
        status: AiChatStatus.done,
        isOfflineFallback: doneEvent?.reply.isOfflineFallback ?? currentMsg.isOfflineFallback,
        promptQuestion: currentMsg.promptQuestion,
        contextualActions: actions,
      );
    }
  }

  /// Selesaikan animasi ketik kata demi kata secara instan (misal saat gelembung diketuk).
  void completeActiveStreamImmediately() {
    _streamingTimer?.cancel();
    _streamingTimer = null;
    final id = _activeStreamingMessageId;
    final doneEvent = _pendingTurnDone;
    final target = _streamingTargetText;

    _activeStreamingMessageId = null;
    _streamingTargetDone = false;
    _pendingTurnDone = null;

    if (id == null) return;
    final idx = messages.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      final currentMsg = messages[idx];
      final fullSpeech = doneEvent?.reply.speech ?? (target.isNotEmpty ? target : currentMsg.effectiveFullText);
      final actions = doneEvent != null
          ? HermesAiService.inferContextualActions(
              question: currentMsg.promptQuestion ?? '',
              replySpeech: fullSpeech,
              sensor: doneEvent.sensorSnapshot,
            )
          : currentMsg.contextualActions;

      messages[idx] = currentMsg.copyWith(
        text: fullSpeech,
        fullText: fullSpeech,
        isStreaming: false,
        oledText: doneEvent?.reply.oled ?? currentMsg.oledText,
        status: AiChatStatus.done,
        isOfflineFallback: doneEvent?.reply.isOfflineFallback ?? currentMsg.isOfflineFallback,
        promptQuestion: currentMsg.promptQuestion,
        contextualActions: actions,
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
      await sendQuestion(captured, autoSpeak: !isMuted.value);
    }
  }

  /// Eksekusi pengiriman otomatis ke WhatsApp ketika terdeteksi dari perintah suara / chat AI.
  Future<void> _autoDispatchWhatsAppForTurn({
    required String messageId,
    required String question,
    required dynamic reply,
    required SensorContext sensor,
  }) async {
    try {
      final customMsg = (reply.notifyMessage as String?)?.trim();
      final bodyText = (customMsg != null && customMsg.isNotEmpty)
          ? customMsg
          : '${reply.speech}\n(Permintaan Jamaah: "$question")';

      final result = await AiExternalMessagingService.instance.sendWhatsAppReport(
        aiOrAlertMessage: bodyText,
        sensor: sensor,
      );

      final badgeText = result.isBackgroundApi
          ? 'Terkirim otomatis ke WhatsApp (+${result.targetPhone})'
          : (result.openedWhatsAppApp
                ? 'Laporan siap dikirim di WhatsApp'
                : result.message);

      final idx = messages.indexWhere((m) => m.id == messageId);
      if (idx >= 0) {
        messages[idx] = messages[idx].copyWith(whatsAppStatusText: badgeText);
      }

      if (result.success) {
        unawaited(
          _repository.smartbandBridge.streamTokenToSmartbandOled(
            result.oledConfirmation,
            isFinal: true,
          ),
        );
      }
    } catch (e) {
      AppLogger.warn('Gagal auto-dispatch WhatsApp: $e', tag: 'HajiCareAi');
    }
  }

  /// Bagikan balasan AI tertentu beserta telemetri gelang & link Google Maps ke WhatsApp.
  Future<WhatsAppDeliveryResult> shareMessageToWhatsApp(
    AiChatMessage message,
  ) async {
    _refreshSensorSnapshot();
    final result = await AiExternalMessagingService.instance.sendWhatsAppReport(
      aiOrAlertMessage: message.effectiveFullText,
      sensor: sensorContext.value,
    );

    final badgeText = result.isBackgroundApi
        ? 'Terkirim otomatis ke WhatsApp (+${result.targetPhone})'
        : (result.openedWhatsAppApp
              ? 'Dibuka di WhatsApp'
              : result.message);

    final idx = messages.indexWhere((m) => m.id == message.id);
    if (idx >= 0) {
      messages[idx] = messages[idx].copyWith(whatsAppStatusText: badgeText);
    }

    if (result.success) {
      unawaited(
        _repository.smartbandBridge.streamTokenToSmartbandOled(
          result.oledConfirmation,
          isFinal: true,
        ),
      );
    }
    return result;
  }

  /// Simpan konfigurasi WhatsApp (Nomor Tujuan, Token Fonnte/CallMeBot, & Toggle Auto-Alert).
  Future<AiMessagingConfig> saveWhatsAppConfiguration(
    AiMessagingConfig config,
  ) async {
    final saved = await AiExternalMessagingService.instance.saveConfig(config);
    messagingConfig.value = saved;
    return saved;
  }

  /// Tes kirim laporan kondisi & lokasi nyata ke WhatsApp dari dialog pengaturan.
  Future<WhatsAppDeliveryResult> testWhatsAppConnection(
    AiMessagingConfig customConfig,
  ) async {
    _refreshSensorSnapshot();
    return AiExternalMessagingService.instance.sendWhatsAppReport(
      aiOrAlertMessage:
          'Tes Koneksi Integrasi WhatsApp HajiCare AI & Smartband berhasil terhubung.',
      sensor: sensorContext.value,
      overrideConfig: customConfig,
    );
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    isAppInForeground.value = (state == AppLifecycleState.resumed);
    AppLogger.debug(
      'HajiCare AI lifecycle changed: $state (isAppInForeground=${isAppInForeground.value})',
      tag: 'HajiCareAi',
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _currentTurnSubscription?.cancel();
    _smartbandAiListeningSub?.cancel();
    _smartbandAudioSub?.cancel();
    _smartbandLivePacketsSub?.cancel();
    _localeWorker?.dispose();
    _sensorSyncTimer?.cancel();
    _ledPulseTimer?.cancel();
    _streamingTimer?.cancel();
    _voiceService.dispose();
    super.onClose();
  }
}
