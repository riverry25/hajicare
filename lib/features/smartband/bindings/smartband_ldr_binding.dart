import 'package:get/get.dart';
import '../controllers/smartband_ldr_controller.dart';

class SmartbandLdrBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SmartbandLdrController>(
      () => SmartbandLdrController(),
    );
  }
}
