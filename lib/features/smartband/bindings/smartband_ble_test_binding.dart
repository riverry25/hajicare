import 'package:get/get.dart';
import '../controllers/smartband_ble_test_controller.dart';
import '../services/smartband_ble_service.dart';

class SmartbandBleTestBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SmartbandBleService>()) {
      Get.put<SmartbandBleService>(SmartbandBleService(), permanent: true);
    }
    Get.lazyPut<SmartbandBleTestController>(
      () =>
          SmartbandBleTestController(service: Get.find<SmartbandBleService>()),
    );
  }
}
