import 'package:get/get.dart';

import '../controllers/hajicare_ai_controller.dart';
import '../repositories/ai_assistant_repository.dart';
import '../services/ai_voice_service.dart';
import '../services/hermes_ai_service.dart';
import '../services/smartband_ai_bridge_service.dart';

/// Dependency Injection Binding untuk fitur **HajiCare AI Voice Assistant**.
class HajiCareAiBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HermesAiService>()) {
      Get.lazyPut<HermesAiService>(() => HermesAiService(), fenix: true);
    }
    if (!Get.isRegistered<SmartbandAiBridgeService>()) {
      Get.lazyPut<SmartbandAiBridgeService>(
        () => SmartbandAiBridgeService(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<AiAssistantRepository>()) {
      Get.lazyPut<AiAssistantRepository>(
        () => AiAssistantRepository(
          hermesService: Get.find<HermesAiService>(),
          smartbandBridge: Get.find<SmartbandAiBridgeService>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<AiVoiceService>()) {
      Get.lazyPut<AiVoiceService>(() => AiVoiceService(), fenix: true);
    }
    if (!Get.isRegistered<HajiCareAiController>()) {
      Get.lazyPut<HajiCareAiController>(
        () => HajiCareAiController(
          repository: Get.find<AiAssistantRepository>(),
          voiceService: Get.find<AiVoiceService>(),
        ),
        fenix: true,
      );
    }
  }

  /// Helper untuk memastikan seluruh dependensi terdaftar ketika dibuka
  /// melalui Bottom Sheet atau Dialog dari halaman mana pun (mis. Profile / Dashboard).
  static HajiCareAiController ensureRegistered() {
    HajiCareAiBinding().dependencies();
    return Get.find<HajiCareAiController>();
  }
}

