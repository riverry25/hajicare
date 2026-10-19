import 'package:get/get.dart';
import '../controllers/map_controller.dart';

class MapBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<MapController>() &&
        Get.find<MapController>().isClosed) {
      Get.delete<MapController>(force: true);
    }
    Get.lazyPut<MapController>(() => MapController(), fenix: true);
  }
}
