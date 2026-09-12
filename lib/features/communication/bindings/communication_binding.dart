import 'package:get/get.dart';
import '../controllers/communication_controller.dart';

class CommunicationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommunicationController>(() => CommunicationController());
  }
}
