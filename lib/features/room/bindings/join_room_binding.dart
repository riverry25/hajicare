import 'package:get/get.dart';

import '../controllers/join_room_controller.dart';

class JoinRoomBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JoinRoomController>(() => JoinRoomController());
  }
}
