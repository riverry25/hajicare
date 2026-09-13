import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/app_settings_controller.dart';
import '../../../core/state/app_startup_controller.dart';

/// Manages onboarding page state.
/// PageController stays as a plain object (not Rx) — it is a UI lifecycle
/// object that owns an animation, not application data.
class OnboardingController extends GetxController {
  final currentPage = 0.obs;
  final PageController pageController = PageController();

  AppSettingsController get settings => Get.find<AppSettingsController>();

  void changePage(int index) {
    currentPage.value = index;
  }

  Future<void> completeOnboarding() async {
    final startup = Get.find<AppStartupController>();
    await startup.setOnboardingDone();
    Get.offAllNamed(AppRoutes.login);
  }

  void nextPage(int totalPages) {
    if (currentPage.value < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      completeOnboarding();
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
