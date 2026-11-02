import 'package:get/get.dart';
import '../controllers/smartband_ldr_controller.dart';
import '../services/smartband_ble_service.dart';

class SmartbandLdrBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SmartbandBleService>()) {
      Get.put<SmartbandBleService>(SmartbandBleService(), permanent: true);
    }
    if (!Get.isRegistered<SmartbandLdrController>()) {
      Get.put<SmartbandLdrController>(
        SmartbandLdrController(bleService: Get.find<SmartbandBleService>()),
        permanent: true,
      );
    }
  }
}
