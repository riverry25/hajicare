import 'package:get/get.dart';

/// Controller managing the dashboard navigation tabs and selected jamaah for pendamping.
class DashboardController extends GetxController {
  final currentIndex = 0.obs;
  final visitedTabs = <int>{0}.obs;
  final selectedJamaahIndex = 0.obs;

  void changeTab(int index) {
    visitedTabs.add(index);
    currentIndex.value = index;
  }

  void selectJamaah(int index) {
    selectedJamaahIndex.value = index;
  }
}

/// Type alias for compatibility with code or routes referencing HomeController
typedef HomeController = DashboardController;
