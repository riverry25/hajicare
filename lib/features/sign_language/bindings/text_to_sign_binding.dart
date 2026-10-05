import 'package:get/get.dart';
import '../controllers/text_to_sign_controller.dart';

class TextToSignBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TextToSignController>(() => TextToSignController());
  }
}
