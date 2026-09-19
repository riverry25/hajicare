import 'package:get/get.dart';
import '../services/bisindo_inference_service.dart';

class BisindoBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BisindoInferenceService>()) {
      Get.put<BisindoInferenceService>(BisindoInferenceService(), permanent: true);
    }
  }
}
