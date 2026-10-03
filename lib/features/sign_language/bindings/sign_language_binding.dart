import 'package:get/get.dart';

import '../controllers/bisindo_recognition_controller.dart';
import '../services/bisindo_inference_service.dart';

class SignLanguageBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BisindoInferenceService>()) {
      Get.lazyPut<BisindoInferenceService>(
        () => BisindoInferenceService(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<BisindoRecognitionController>()) {
      Get.lazyPut<BisindoRecognitionController>(
        () => BisindoRecognitionController(
          config: const BisindoRecognitionConfig(
            confidenceThreshold: 0.50,
            stablePredictionsRequired: 3,
            duplicateCooldown: Duration(milliseconds: 1200),
            handPresenceTimeout: Duration(milliseconds: 1000),
          ),
        ),
      );
    }
  }
}
