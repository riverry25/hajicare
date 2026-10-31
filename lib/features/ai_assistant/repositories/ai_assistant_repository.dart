import '../../../core/utils/app_logger.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_reply.dart';
import '../models/ai_server_config.dart';
import '../models/ai_server_status.dart';
import '../models/oled_display_state.dart';
import '../models/sensor_context.dart';
import '../services/hermes_ai_service.dart';
import '../services/smartband_ai_bridge_service.dart';

/// Hasil lengkap satu siklus tanya-jawab dengan Hermes Agent + pengiriman OLED.
class AiTurnOutcome {
  const AiTurnOutcome({
    required this.reply,
    required this.sensorSnapshot,
    required this.oledState,
    this.errorBannerMessage,
  });

  final AiReply reply;
  final SensorContext sensorSnapshot;
  final OledDisplayState oledState;
  final String? errorBannerMessage;
}

/// Repository (Single Source of Truth / SSOT) untuk fitur
/// **HajiCare AI Voice Assistant (Powered by Hermes Agent)**.
///
/// Mengisolasi komunikasi HTTP (`HermesAiService`), penyimpanan lokal
/// (`SharedPreferences`), dan jembatan perangkat BLE (`SmartbandAiBridgeService`)
/// dari layer Controller/ViewModel dan View.
class AiAssistantRepository {
  AiAssistantRepository({
    HermesAiService? hermesService,
    SmartbandAiBridgeService? smartbandBridge,
  }) : _hermesService = hermesService ?? HermesAiService(),
       _smartbandBridge = smartbandBridge ?? SmartbandAiBridgeService();

  final HermesAiService _hermesService;
  final SmartbandAiBridgeService _smartbandBridge;

  AiServerConfig _cachedConfig = AiServerConfig.defaults;
  bool _configLoaded = false;

  AiServerConfig get currentConfig => _cachedConfig;
  SmartbandAiBridgeService get smartbandBridge => _smartbandBridge;

  /// Muat konfigurasi server dari `SharedPreferences` (SSOT).
  Future<AiServerConfig> loadServerConfig({bool forceReload = false}) async {
    if (_configLoaded && !forceReload) return _cachedConfig;
    _cachedConfig = await _hermesService.loadConfig();
    _configLoaded = true;
    return _cachedConfig;
  }

  /// Simpan konfigurasi server baru dan perbarui cache SSOT.
  Future<AiServerConfig> saveServerConfig(AiServerConfig config) async {
    _cachedConfig = await _hermesService.saveConfig(config);
    _configLoaded = true;
    return _cachedConfig;
  }

  /// Reset konfigurasi server ke default bawaan.
  Future<AiServerConfig> resetServerConfig() async {
    _cachedConfig = await _hermesService.resetConfigToDefault();
    _configLoaded = true;
    return _cachedConfig;
  }

  /// Cek status kesehatan server Hermes via `/health`.
  Future<AiServerStatus> checkServerHealth([AiServerConfig? overrideConfig]) async {
    final config = overrideConfig ?? await loadServerConfig();
    return _hermesService.checkHealth(config);
  }

  /// Ambil snapshot konteks sensor gelang terbaru (live / simulasi / fallback).
  SensorContext getLatestSensorContext() {
    return _smartbandBridge.readCurrentSensorContext();
  }

  /// Kirim pertanyaan ke Hermes Agent dan teruskan ringkasan `oled` ke gelang BLE.
  ///
  /// Jika server sedang offline/placeholder dan [allowOfflineFallback] bernilai
  /// `true`, otomatis menghasilkan respons cerdas berbasis sensor lokal agar
  /// demo suara TTS dan pratinjau OLED gelang tetap berjalan tanpa pernah crash.
  Future<AiTurnOutcome> askQuestion({
    required String question,
    List<AiChatMessage> history = const <AiChatMessage>[],
    bool allowOfflineFallback = true,
  }) async {
    final config = await loadServerConfig();
    final sensor = _smartbandBridge.readCurrentSensorContext();

    AiReply reply;
    String? bannerNotice;

    try {
      reply = await _hermesService.sendChatCompletion(
        config: config,
        userQuestion: question,
        sensorContext: sensor,
        history: history,
      );
    } on HermesAiException catch (e) {
      AppLogger.warn(
        'HermesAiException saat askQuestion: ${e.userMessage}',
        tag: 'AiAssistantRepo',
      );
      if (!allowOfflineFallback) rethrow;
      bannerNotice = e.userMessage;
      reply = HermesAiService.buildOfflineFallbackReply(
        question: question,
        sensor: sensor,
      );
    } catch (e) {
      AppLogger.warn(
        'Error tak terduga saat askQuestion: $e',
        tag: 'AiAssistantRepo',
      );
      if (!allowOfflineFallback) rethrow;
      bannerNotice = 'Server Hermes belum terjangkau, menggunakan asisten lokal.';
      reply = HermesAiService.buildOfflineFallbackReply(
        question: question,
        sensor: sensor,
      );
    }

    final oledState = await _smartbandBridge.sendOledToSmartband(reply.oled);

    return AiTurnOutcome(
      reply: reply,
      sensorSnapshot: sensor,
      oledState: oledState,
      errorBannerMessage: bannerNotice,
    );
  }

  /// Kirim ulang teks OLED tertentu ke gelang pintar / pratinjau.
  Future<OledDisplayState> resendOled(String oledText) {
    return _smartbandBridge.sendOledToSmartband(oledText);
  }

  void dispose() {
    _hermesService.dispose();
  }
}

