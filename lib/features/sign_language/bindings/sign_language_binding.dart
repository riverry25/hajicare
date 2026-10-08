import 'package:get/get.dart';

import '../controllers/bisindo_recognition_controller.dart';
import '../controllers/sign_language_controller.dart';

class SignLanguageBinding extends Bindings {
  @override
  void dependencies() {
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

    if (!Get.isRegistered<SignLanguageController>()) {
      Get.lazyPut<SignLanguageController>(
        () => SignLanguageController(
          onPredictionAccepted: (prediction) {
            // Shared transcript + immediate TTS for BISINDO words.
            Get.find<BisindoRecognitionController>().commitWord(
              prediction.label,
              speak: true,
            );
          },
        ),
      );
    }
  }
}
