import 'package:get/get.dart';
import '../controllers/smartband_ldr_controller.dart';
import '../services/smartband_ble_service.dart';

class SmartbandLdrBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SmartbandBleService>()) {
      Get.lazyPut<SmartbandBleService>(() => SmartbandBleService());
    }
    Get.lazyPut<SmartbandLdrController>(
      () => SmartbandLdrController(bleService: Get.find<SmartbandBleService>()),
    );
  }
}
