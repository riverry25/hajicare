import 'package:get/get.dart';

import '../../ai_assistant/bindings/hajicare_ai_binding.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
    HajiCareAiBinding().dependencies();
  }
}
