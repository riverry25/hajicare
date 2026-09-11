import 'package:get/get.dart';
import '../state/hajicare_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HajiCareController>(() => HajiCareController(), fenix: true);
  }
}
