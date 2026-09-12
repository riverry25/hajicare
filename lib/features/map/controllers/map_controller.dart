import 'package:get/get.dart';

class MapController extends GetxController {
  final selectedFilter = 0.obs;
  final currentIndex = 1.obs;

  void selectFilter(int index) {
    selectedFilter.value = index;
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }
}
