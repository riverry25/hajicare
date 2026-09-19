import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controls search, category filtering, and FAQ expansion state.
class HelpCenterController extends GetxController {
  final TextEditingController searchTextController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxnString selectedCategory = RxnString();
  final RxInt expandedIndex = (-1).obs;

  void updateSearch(String query) {
    searchQuery.value = query.toLowerCase().trim();
    if (searchQuery.value.isNotEmpty) {
      selectedCategory.value = null;
      expandedIndex.value = -1;
    }
  }

  void clearSearch() {
    searchTextController.clear();
    searchQuery.value = '';
    expandedIndex.value = -1;
  }

  void selectCategory(String category) {
    clearSearch();
    selectedCategory.value = selectedCategory.value == category
        ? null
        : category;
  }

  void clearCategory() {
    selectedCategory.value = null;
    expandedIndex.value = -1;
  }

  void toggleFaq(int index) {
    expandedIndex.value = expandedIndex.value == index ? -1 : index;
  }

  bool isExpanded(int index) => expandedIndex.value == index;

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }
}
