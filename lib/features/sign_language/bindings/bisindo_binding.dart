import 'package:get/get.dart';

import '../controllers/bisindo_recognition_controller.dart';
import '../services/bisindo_inference_service.dart';

class BisindoBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BisindoInferenceService>()) {
      Get.lazyPut<BisindoInferenceService>(BisindoInferenceService.new);
    }
    if (!Get.isRegistered<BisindoRecognitionController>()) {
      Get.lazyPut<BisindoRecognitionController>(
        BisindoRecognitionController.new,
      );
    }
  }
}
