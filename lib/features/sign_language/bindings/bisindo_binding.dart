import 'package:get/get.dart';

import '../controllers/bisindo_recognition_controller.dart';

class BisindoBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BisindoRecognitionController>()) {
      Get.lazyPut<BisindoRecognitionController>(
        BisindoRecognitionController.new,
      );
    }
  }
}
