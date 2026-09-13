import 'package:get/get.dart';

/// GetX controller for the Help Center screen.
/// Manages reactive search filtering and single-open FAQ expansion.
class HelpCenterController extends GetxController {
  // Search
  final RxString searchQuery = ''.obs;

  void updateSearch(String query) {
    searchQuery.value = query.toLowerCase().trim();
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  // FAQ expansion: one open at a time
  final RxInt expandedIndex = (-1).obs;

  void toggleFaq(int index) {
    if (expandedIndex.value == index) {
      expandedIndex.value = -1;
    } else {
      expandedIndex.value = index;
    }
  }

  bool isExpanded(int index) => expandedIndex.value == index;
}
