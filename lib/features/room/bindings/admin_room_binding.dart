import 'package:get/get.dart';

import '../controllers/admin_room_controller.dart';

class AdminRoomBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminRoomController>(() => AdminRoomController());
  }
}
